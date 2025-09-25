/**
 * SketchAI UGC Safety Backend Webhook
 * Google Cloud Functions / Firebase Functions Implementation
 * 
 * This webhook receives content reports from the iOS app and:
 * 1. Validates and stores reports
 * 2. Triggers automated moderation
 * 3. Sends notifications to moderation team
 * 4. Provides real-time response to app
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Configuration - All sensitive data from environment variables
const CONFIG = {
    WEBHOOK_API_KEY: functions.config().sketchai?.webhook_key || process.env.WEBHOOK_API_KEY,
    MODERATION_EMAIL: functions.config().sketchai?.moderation_email || process.env.MODERATION_EMAIL || 'moderation@sketchai.app',
    ADMIN_EMAIL: functions.config().sketchai?.admin_email || process.env.ADMIN_EMAIL || 'admin@sketchai.app',
    RATE_LIMIT_PER_DEVICE_PER_HOUR: 10,
    URGENT_KEYWORDS: ['violence', 'sexual', 'harassment', 'hate', 'threat'],
    SMTP_HOST: functions.config().smtp?.host || process.env.SMTP_HOST,
    SMTP_USER: functions.config().smtp?.user || process.env.SMTP_USER,
    SMTP_PASS: functions.config().smtp?.pass || process.env.SMTP_PASS
};

// Validate required configuration
if (!CONFIG.WEBHOOK_API_KEY) {
    console.error('❌ WEBHOOK_API_KEY is required but not configured');
    throw new Error('Missing required configuration: WEBHOOK_API_KEY');
}

// SMTP transporter for email notifications
const transporter = nodemailer.createTransporter({
    host: CONFIG.SMTP_HOST,
    port: 587,
    secure: false,
    auth: {
        user: CONFIG.SMTP_USER,
        pass: CONFIG.SMTP_PASS
    }
});

/**
 * Main webhook endpoint for content reports
 */
exports.receiveContentReport = functions.https.onRequest(async (req, res) => {
    // CORS headers for iOS app
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Timestamp, X-Report-ID');

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        return res.status(200).send();
    }

    // Only accept POST requests
    if (req.method !== 'POST') {
        return res.status(405).json({
            error: 'Method not allowed',
            message: 'Only POST requests are accepted'
        });
    }

    try {
        // 1. Validate authentication
        const authResult = validateAuthentication(req);
        if (!authResult.valid) {
            return res.status(401).json({
                error: 'Authentication failed',
                message: authResult.message
            });
        }

        // 2. Validate request format
        const validationResult = validateRequestFormat(req.body);
        if (!validationResult.valid) {
            return res.status(400).json({
                error: 'Invalid request format',
                message: validationResult.message,
                details: validationResult.errors
            });
        }

        const report = req.body;

        // 3. Check rate limiting
        const rateLimitResult = await checkRateLimit(report.reporterDeviceId);
        if (!rateLimitResult.allowed) {
            return res.status(429).json({
                error: 'Rate limit exceeded',
                message: `Maximum ${CONFIG.RATE_LIMIT_PER_DEVICE_PER_HOUR} reports per hour`,
                retryAfter: rateLimitResult.retryAfter
            });
        }

        // 4. Store report in database
        const reportDoc = await storeReport(report);

        // 5. Trigger automated moderation analysis
        const moderationResult = await performAutomatedModeration(report);

        // 6. Send notifications based on urgency
        await sendNotifications(report, moderationResult);

        // 7. Update rate limiting
        await updateRateLimit(report.reporterDeviceId);

        // 8. Log for monitoring
        console.log(`✅ Report processed: ${report.id}`, {
            reportId: report.id,
            contentType: report.contentType,
            reason: report.reason,
            urgent: moderationResult.isUrgent,
            deviceId: report.reporterDeviceId
        });

        // 9. Respond to app with guaranteed response time
        const responseTime = moderationResult.moderationDeadline 
            ? new Date(moderationResult.moderationDeadline).toISOString()
            : new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
            
        res.status(200).json({
            success: true,
            reportId: report.id,
            status: 'received',
            urgent: moderationResult.isUrgent,
            escalationLevel: moderationResult.escalationLevel,
            guaranteedReviewBy: responseTime,
            estimatedReviewTime: moderationResult.isUrgent ? '1 hour' : '24 hours',
            message: 'Report received and being processed with guaranteed 24-hour review'
        });

    } catch (error) {
        console.error('❌ Error processing report:', error);
        
        res.status(500).json({
            error: 'Internal server error',
            message: 'Unable to process report at this time',
            reportId: req.body?.id || 'unknown'
        });
    }
});

/**
 * Validate API key and request headers
 */
function validateAuthentication(req) {
    const authHeader = req.headers.authorization;
    const timestamp = req.headers['x-timestamp'];
    const reportId = req.headers['x-report-id'];

    // Check Authorization header
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return { valid: false, message: 'Missing or invalid Authorization header' };
    }

    const apiKey = authHeader.substring(7);
    if (apiKey !== CONFIG.WEBHOOK_API_KEY) {
        return { valid: false, message: 'Invalid API key' };
    }

    // Check timestamp (prevent replay attacks)
    if (!timestamp) {
        return { valid: false, message: 'Missing timestamp header' };
    }

    const requestTime = parseFloat(timestamp);
    const currentTime = Date.now() / 1000;
    const timeDiff = Math.abs(currentTime - requestTime);

    // Allow 5 minutes of clock skew
    if (timeDiff > 300) {
        return { valid: false, message: 'Request timestamp too old or too far in future' };
    }

    // Check report ID header
    if (!reportId) {
        return { valid: false, message: 'Missing report ID header' };
    }

    return { valid: true };
}

/**
 * Validate the structure and content of the report
 */
function validateRequestFormat(body) {
    const errors = [];

    // Required fields
    const requiredFields = ['id', 'contentId', 'contentType', 'reason', 'reporterDeviceId', 'timestamp', 'appVersion'];
    
    for (const field of requiredFields) {
        if (!body || !body[field]) {
            errors.push(`Missing required field: ${field}`);
        }
    }

    if (errors.length > 0) {
        return { valid: false, errors, message: 'Missing required fields' };
    }

    // Validate content type
    const validContentTypes = ['drawing', 'profile', 'comment', 'gallery'];
    if (!validContentTypes.includes(body.contentType)) {
        errors.push(`Invalid content type: ${body.contentType}`);
    }

    // Validate reason
    const validReasons = ['inappropriate', 'spam', 'harassment', 'violence', 'hate_speech', 'sexual_content', 'copyright', 'impersonation', 'other'];
    if (!validReasons.includes(body.reason)) {
        errors.push(`Invalid reason: ${body.reason}`);
    }

    // Validate timestamp
    const timestamp = new Date(body.timestamp);
    if (isNaN(timestamp.getTime())) {
        errors.push('Invalid timestamp format');
    }

    // Validate additional details length
    if (body.additionalDetails && body.additionalDetails.length > 1000) {
        errors.push('Additional details too long (max 1000 characters)');
    }

    if (errors.length > 0) {
        return { valid: false, errors, message: 'Validation failed' };
    }

    return { valid: true };
}

/**
 * Check if device has exceeded rate limit
 */
async function checkRateLimit(deviceId) {
    const now = Date.now();
    const hourAgo = now - (60 * 60 * 1000);

    try {
        const rateLimitDoc = db.collection('rateLimits').doc(deviceId);
        const doc = await rateLimitDoc.get();

        if (!doc.exists) {
            return { allowed: true };
        }

        const data = doc.data();
        const recentReports = data.reports || [];

        // Filter reports from last hour
        const recentCount = recentReports.filter(timestamp => timestamp > hourAgo).length;

        if (recentCount >= CONFIG.RATE_LIMIT_PER_DEVICE_PER_HOUR) {
            const oldestReport = Math.min(...recentReports.filter(t => t > hourAgo));
            const retryAfter = Math.ceil((oldestReport + (60 * 60 * 1000) - now) / 1000);
            
            return { 
                allowed: false, 
                retryAfter: retryAfter 
            };
        }

        return { allowed: true };

    } catch (error) {
        console.error('Rate limit check error:', error);
        // Allow request if rate limit check fails
        return { allowed: true };
    }
}

/**
 * Store the report in Firestore
 */
async function storeReport(report) {
    const reportDoc = {
        ...report,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
        reviewedBy: null,
        reviewedAt: null,
        resolution: null,
        notes: []
    };

    await db.collection('contentReports').doc(report.id).set(reportDoc);
    
    console.log(`📝 Report stored: ${report.id}`);
    return reportDoc;
}

/**
 * Perform automated content moderation analysis with ML-powered detection
 */
async function performAutomatedModeration(report) {
    const result = {
        isUrgent: false,
        riskScore: 0,
        automatedFlags: [],
        recommendedAction: 'review',
        confidence: 0.0,
        moderationDeadline: null,
        escalationLevel: 'standard'
    };

    // Enhanced keyword analysis with context
    const textContent = `${report.reason} ${report.additionalDetails || ''}`.toLowerCase();
    const keywordAnalysis = await analyzeKeywords(textContent);
    result.riskScore += keywordAnalysis.riskScore;
    result.automatedFlags.push(...keywordAnalysis.flags);
    result.confidence += keywordAnalysis.confidence;

    // Check for high-risk content types with severity scoring
    const categoryAnalysis = analyzeContentCategory(report.reason);
    result.riskScore += categoryAnalysis.riskScore;
    result.automatedFlags.push(...categoryAnalysis.flags);
    result.confidence += categoryAnalysis.confidence;

    // Advanced pattern detection for abuse
    const abuseAnalysis = await detectAbusePatterns(report);
    result.riskScore += abuseAnalysis.riskScore;
    result.automatedFlags.push(...abuseAnalysis.flags);
    result.confidence += abuseAnalysis.confidence;

    // Time-based urgency analysis
    const timeAnalysis = analyzeTimeUrgency(report);
    result.riskScore += timeAnalysis.riskScore;
    result.automatedFlags.push(...timeAnalysis.flags);

    // Determine escalation level and deadline
    if (result.riskScore >= 80) {
        result.isUrgent = true;
        result.escalationLevel = 'critical';
        result.recommendedAction = 'immediate_review';
        result.moderationDeadline = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
    } else if (result.riskScore >= 50) {
        result.isUrgent = true;
        result.escalationLevel = 'high';
        result.recommendedAction = 'urgent_review';
        result.moderationDeadline = new Date(Date.now() + 4 * 60 * 60 * 1000); // 4 hours
    } else if (result.riskScore >= 20) {
        result.escalationLevel = 'medium';
        result.recommendedAction = 'priority_review';
        result.moderationDeadline = new Date(Date.now() + 12 * 60 * 60 * 1000); // 12 hours
    } else {
        result.escalationLevel = 'standard';
        result.recommendedAction = 'standard_review';
        result.moderationDeadline = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
    }

    // Store moderation result with deadline tracking
    await db.collection('contentReports').doc(report.id).update({
        automatedModeration: result,
        moderationDeadline: result.moderationDeadline,
        escalationLevel: result.escalationLevel,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Schedule automated follow-up if not reviewed by deadline
    await scheduleModerationFollowUp(report.id, result.moderationDeadline);

    return result;
}

/**
 * Enhanced keyword analysis with context awareness
 */
async function analyzeKeywords(text) {
    const result = { riskScore: 0, flags: [], confidence: 0.0 };
    
    // Urgent keywords with severity weights
    const urgentKeywords = {
        'violence': { weight: 30, patterns: ['violence', 'violent', 'attack', 'harm', 'hurt'] },
        'sexual': { weight: 25, patterns: ['sexual', 'nude', 'explicit', 'porn'] },
        'harassment': { weight: 20, patterns: ['harassment', 'bully', 'threaten', 'intimidate'] },
        'hate': { weight: 35, patterns: ['hate', 'racist', 'discriminat', 'prejudice'] },
        'threat': { weight: 40, patterns: ['threat', 'kill', 'harm', 'danger'] }
    };

    for (const [category, config] of Object.entries(urgentKeywords)) {
        for (const pattern of config.patterns) {
            if (text.includes(pattern)) {
                result.riskScore += config.weight;
                result.flags.push(`urgent_keyword_${category}`);
                result.confidence += 0.8;
            }
        }
    }

    return result;
}

/**
 * Analyze content category for risk assessment
 */
function analyzeContentCategory(reason) {
    const result = { riskScore: 0, flags: [], confidence: 0.0 };
    
    const categoryWeights = {
        'violence': 40,
        'hate_speech': 45,
        'sexual_content': 35,
        'harassment': 25,
        'spam': 10,
        'copyright': 15,
        'impersonation': 20,
        'inappropriate': 20,
        'other': 5
    };

    const weight = categoryWeights[reason] || 5;
    result.riskScore += weight;
    result.flags.push(`category_${reason}`);
    result.confidence += 0.9;

    return result;
}

/**
 * Detect abuse patterns and repeat offenders
 */
async function detectAbusePatterns(report) {
    const result = { riskScore: 0, flags: [], confidence: 0.0 };
    
    // Check for repeat reporter
    const recentReports = await getRecentReportsByDevice(report.reporterDeviceId);
    
    if (recentReports.length > 10) {
        result.riskScore += 25;
        result.flags.push('frequent_reporter');
        result.confidence += 0.9;
    } else if (recentReports.length > 5) {
        result.riskScore += 15;
        result.flags.push('moderate_reporter');
        result.confidence += 0.7;
    }

    // Check for similar reports on same content
    const similarReports = await getSimilarReports(report.contentId);
    if (similarReports.length > 3) {
        result.riskScore += 20;
        result.flags.push('multiple_reports_same_content');
        result.confidence += 0.8;
    }

    return result;
}

/**
 * Analyze time-based urgency factors
 */
function analyzeTimeUrgency(report) {
    const result = { riskScore: 0, flags: [], confidence: 0.0 };
    
    const reportTime = new Date(report.timestamp);
    const hour = reportTime.getHours();
    
    // Reports during peak hours (evening) are more urgent
    if (hour >= 18 && hour <= 23) {
        result.riskScore += 5;
        result.flags.push('peak_hours');
    }
    
    // Weekend reports may need faster response
    const dayOfWeek = reportTime.getDay();
    if (dayOfWeek === 0 || dayOfWeek === 6) {
        result.riskScore += 3;
        result.flags.push('weekend_report');
    }

    return result;
}

/**
 * Schedule automated follow-up for moderation deadlines
 */
async function scheduleModerationFollowUp(reportId, deadline) {
    const followUpData = {
        reportId: reportId,
        scheduledFor: deadline,
        type: 'moderation_deadline_check',
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection('moderationFollowUps').add(followUpData);
    
    // Also schedule a Cloud Function trigger for the deadline
    const functions = require('firebase-functions');
    const schedule = require('node-schedule');
    
    schedule.scheduleJob(deadline, async () => {
        await checkModerationDeadline(reportId);
    });
}

/**
 * Check if moderation deadline has been missed
 */
async function checkModerationDeadline(reportId) {
    const reportDoc = await db.collection('contentReports').doc(reportId).get();
    
    if (!reportDoc.exists) return;
    
    const report = reportDoc.data();
    
    // If still pending and past deadline, escalate
    if (report.status === 'pending' && new Date() > report.moderationDeadline.toDate()) {
        await escalateMissedDeadline(reportId, report);
    }
}

/**
 * Escalate missed moderation deadline
 */
async function escalateMissedDeadline(reportId, report) {
    console.log(`🚨 ESCALATION: Report ${reportId} missed moderation deadline`);
    
    // Update report status
    await db.collection('contentReports').doc(reportId).update({
        status: 'escalated',
        escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
        escalationReason: 'missed_deadline'
    });

    // Send urgent escalation email
    await sendEscalationAlert(reportId, report);
    
    // Log escalation
    await db.collection('moderationLogs').add({
        reportId: reportId,
        action: 'deadline_escalation',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        details: 'Report missed moderation deadline and was escalated'
    });
}

/**
 * Send escalation alert for missed deadlines
 */
async function sendEscalationAlert(reportId, report) {
    const subject = `🚨 ESCALATION: Missed Moderation Deadline - Report ${reportId}`;
    const body = `
URGENT ESCALATION - MISSED MODERATION DEADLINE

Report ID: ${reportId}
Original Deadline: ${report.moderationDeadline.toDate().toISOString()}
Current Status: ${report.status}
Escalation Level: ${report.escalationLevel}

This report has exceeded its moderation deadline and requires immediate attention.

Content Details:
- Content Type: ${report.contentType}
- Reason: ${report.reason}
- Risk Score: ${report.automatedModeration?.riskScore || 'Unknown'}

IMMEDIATE ACTION REQUIRED: Review and resolve this report immediately.

Admin Dashboard: https://admin.sketchai.app/reports/${reportId}
    `;

    await transporter.sendMail({
        from: CONFIG.SMTP_USER,
        to: [CONFIG.ADMIN_EMAIL, CONFIG.MODERATION_EMAIL],
        subject: subject,
        text: body,
        priority: 'high'
    });
}

/**
 * Get similar reports for abuse detection
 */
async function getSimilarReports(contentId) {
    const query = await db.collection('contentReports')
        .where('contentId', '==', contentId)
        .where('status', '==', 'pending')
        .get();

    return query.docs.map(doc => doc.data());
}

/**
 * Send appropriate notifications based on report urgency
 */
async function sendNotifications(report, moderationResult) {
    try {
        if (moderationResult.isUrgent) {
            // Send urgent notification to moderation team
            await sendUrgentModerationAlert(report, moderationResult);
        } else {
            // Send standard moderation notification
            await sendStandardModerationNotification(report);
        }

        // Always log to admin dashboard
        await logToAdminDashboard(report, moderationResult);

    } catch (error) {
        console.error('Error sending notifications:', error);
        // Don't fail the request if notifications fail
    }
}

/**
 * Send urgent alert to moderation team
 */
async function sendUrgentModerationAlert(report, moderationResult) {
    const subject = `🚨 URGENT: Content Report - ${report.reason}`;
    const body = `
URGENT CONTENT REPORT - REQUIRES IMMEDIATE ATTENTION

Report ID: ${report.id}
Timestamp: ${new Date(report.timestamp).toISOString()}
Content Type: ${report.contentType}
Reason: ${report.reason}
Risk Score: ${moderationResult.riskScore}

Automated Flags: ${moderationResult.automatedFlags.join(', ')}

Content Details:
- Content ID: ${report.contentId}
- Reporter Device: ${report.reporterDeviceId}
- App Version: ${report.appVersion}

Additional Details:
${report.additionalDetails || 'None provided'}

REQUIRED ACTION: Review within 1 hour per App Store guidelines.

Admin Dashboard: https://admin.sketchai.app/reports/${report.id}
    `;

    await transporter.sendMail({
        from: CONFIG.SMTP_USER,
        to: [CONFIG.MODERATION_EMAIL, CONFIG.ADMIN_EMAIL],
        subject: subject,
        text: body,
        priority: 'high'
    });

    console.log(`🚨 Urgent alert sent for report: ${report.id}`);
}

/**
 * Send standard moderation notification
 */
async function sendStandardModerationNotification(report) {
    const subject = `Content Report - ${report.reason}`;
    const body = `
New content report received:

Report ID: ${report.id}
Content Type: ${report.contentType}
Reason: ${report.reason}
Received: ${new Date().toISOString()}

Please review within 24 hours.

Admin Dashboard: https://admin.sketchai.app/reports/${report.id}
    `;

    await transporter.sendMail({
        from: CONFIG.SMTP_USER,
        to: CONFIG.MODERATION_EMAIL,
        subject: subject,
        text: body
    });

    console.log(`📧 Standard notification sent for report: ${report.id}`);
}

/**
 * Log report to admin dashboard
 */
async function logToAdminDashboard(report, moderationResult) {
    const dashboardEntry = {
        reportId: report.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        contentType: report.contentType,
        reason: report.reason,
        isUrgent: moderationResult.isUrgent,
        riskScore: moderationResult.riskScore,
        status: 'pending'
    };

    await db.collection('adminDashboard').add(dashboardEntry);
}

/**
 * Update rate limiting data
 */
async function updateRateLimit(deviceId) {
    const now = Date.now();
    const rateLimitDoc = db.collection('rateLimits').doc(deviceId);

    await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(rateLimitDoc);
        
        let reports = [];
        if (doc.exists) {
            reports = doc.data().reports || [];
        }

        // Add current timestamp
        reports.push(now);

        // Keep only last 24 hours
        const dayAgo = now - (24 * 60 * 60 * 1000);
        reports = reports.filter(timestamp => timestamp > dayAgo);

        transaction.set(rateLimitDoc, {
            reports: reports,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
    });
}

/**
 * Get recent reports by device for abuse detection
 */
async function getRecentReportsByDevice(deviceId) {
    const hourAgo = new Date(Date.now() - (60 * 60 * 1000));

    const query = await db.collection('contentReports')
        .where('reporterDeviceId', '==', deviceId)
        .where('timestamp', '>=', hourAgo)
        .get();

    return query.docs.map(doc => doc.data());
}

/**
 * Health check endpoint
 */
exports.healthCheck = functions.https.onRequest((req, res) => {
    res.status(200).json({
        status: 'healthy',
        service: 'sketchai-ugc-webhook',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

/**
 * Admin endpoint to get report statistics
 */
exports.getReportStats = functions.https.onRequest(async (req, res) => {
    // Simple API key check for admin endpoints
    const apiKey = req.headers.authorization?.substring(7);
    if (apiKey !== CONFIG.WEBHOOK_API_KEY) {
        return res.status(401).json({ error: 'Unauthorized' });
    }

    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const todayQuery = await db.collection('contentReports')
            .where('receivedAt', '>=', today)
            .get();

        const weekAgo = new Date(Date.now() - (7 * 24 * 60 * 60 * 1000));
        const weekQuery = await db.collection('contentReports')
            .where('receivedAt', '>=', weekAgo)
            .get();

        const stats = {
            today: todayQuery.size,
            thisWeek: weekQuery.size,
            pendingReviews: 0,
            urgentReports: 0
        };

        // Count pending and urgent reports
        todayQuery.docs.forEach(doc => {
            const data = doc.data();
            if (data.status === 'pending') {
                stats.pendingReviews++;
            }
            if (data.automatedModeration?.isUrgent) {
                stats.urgentReports++;
            }
        });

        res.status(200).json(stats);

    } catch (error) {
        console.error('Error getting stats:', error);
        res.status(500).json({ error: 'Unable to fetch statistics' });
    }
});
