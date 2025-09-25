/**
 * SketchAI UGC Safety Backend Webhook
 * Express.js / Node.js Implementation
 * 
 * Alternative implementation for those who prefer traditional servers
 * Deploy to AWS, Heroku, DigitalOcean, etc.
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult, header } = require('express-validator');
const nodemailer = require('nodemailer');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuration - All sensitive data from environment variables
const CONFIG = {
    WEBHOOK_API_KEY: process.env.WEBHOOK_API_KEY,
    MODERATION_EMAIL: process.env.MODERATION_EMAIL || 'moderation@sketchai.app',
    ADMIN_EMAIL: process.env.ADMIN_EMAIL || 'admin@sketchai.app',
    SMTP_HOST: process.env.SMTP_HOST,
    SMTP_USER: process.env.SMTP_USER,
    SMTP_PASS: process.env.SMTP_PASS,
    DATABASE_PATH: process.env.DATABASE_PATH || './sketchai_reports.db',
    RATE_LIMIT_PER_DEVICE_PER_HOUR: 10,
    URGENT_KEYWORDS: ['violence', 'sexual', 'harassment', 'hate', 'threat']
};

// Validate required configuration
if (!CONFIG.WEBHOOK_API_KEY) {
    console.error('❌ WEBHOOK_API_KEY is required but not configured');
    process.exit(1);
}

// Initialize database
const db = new sqlite3.Database(CONFIG.DATABASE_PATH);

// Create tables if they don't exist
db.serialize(() => {
    db.run(`
        CREATE TABLE IF NOT EXISTS content_reports (
            id TEXT PRIMARY KEY,
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            reason TEXT NOT NULL,
            additional_details TEXT,
            reporter_device_id TEXT NOT NULL,
            timestamp DATETIME NOT NULL,
            app_version TEXT NOT NULL,
            received_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'pending',
            reviewed_by TEXT,
            reviewed_at DATETIME,
            resolution TEXT,
            is_urgent BOOLEAN DEFAULT 0,
            risk_score INTEGER DEFAULT 0
        )
    `);

    db.run(`
        CREATE TABLE IF NOT EXISTS rate_limits (
            device_id TEXT PRIMARY KEY,
            report_timestamps TEXT, -- JSON array of timestamps
            last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `);

    db.run(`
        CREATE TABLE IF NOT EXISTS admin_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            report_id TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            action TEXT,
            details TEXT
        )
    `);
});

// Middleware
app.use(helmet());
app.use(cors({
    origin: true, // Allow all origins for iOS app
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting middleware
const globalRateLimit = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false
});

app.use('/api/', globalRateLimit);

// SMTP transporter
const transporter = nodemailer.createTransporter({
    host: CONFIG.SMTP_HOST,
    port: 587,
    secure: false,
    auth: {
        user: CONFIG.SMTP_USER,
        pass: CONFIG.SMTP_PASS
    }
});

// Validation middleware
const validateContentReport = [
    body('id').isUUID().withMessage('Invalid report ID format'),
    body('contentId').notEmpty().withMessage('Content ID is required'),
    body('contentType').isIn(['drawing', 'profile', 'comment', 'gallery']).withMessage('Invalid content type'),
    body('reason').isIn(['inappropriate', 'spam', 'harassment', 'violence', 'hate_speech', 'sexual_content', 'copyright', 'impersonation', 'other']).withMessage('Invalid reason'),
    body('reporterDeviceId').notEmpty().withMessage('Reporter device ID is required'),
    body('timestamp').isISO8601().withMessage('Invalid timestamp format'),
    body('appVersion').notEmpty().withMessage('App version is required'),
    body('additionalDetails').optional().isLength({ max: 1000 }).withMessage('Additional details too long'),
    header('authorization').matches(/^Bearer .+/).withMessage('Invalid authorization header'),
    header('x-timestamp').isNumeric().withMessage('Invalid timestamp header'),
    header('x-report-id').isUUID().withMessage('Invalid report ID header')
];

// Authentication middleware
const authenticate = (req, res, next) => {
    const authHeader = req.headers.authorization;
    const timestamp = req.headers['x-timestamp'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            error: 'Authentication required',
            message: 'Missing or invalid Authorization header'
        });
    }

    const apiKey = authHeader.substring(7);
    if (apiKey !== CONFIG.WEBHOOK_API_KEY) {
        return res.status(401).json({
            error: 'Authentication failed',
            message: 'Invalid API key'
        });
    }

    // Check timestamp to prevent replay attacks
    if (timestamp) {
        const requestTime = parseFloat(timestamp);
        const currentTime = Date.now() / 1000;
        const timeDiff = Math.abs(currentTime - requestTime);

        if (timeDiff > 300) { // 5 minutes
            return res.status(401).json({
                error: 'Request expired',
                message: 'Request timestamp too old'
            });
        }
    }

    next();
};

/**
 * Main content report endpoint
 */
app.post('/api/reports', authenticate, validateContentReport, async (req, res) => {
    try {
        // Check validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                error: 'Validation failed',
                details: errors.array()
            });
        }

        const report = req.body;

        // Check rate limiting
        const rateLimitResult = await checkRateLimit(report.reporterDeviceId);
        if (!rateLimitResult.allowed) {
            return res.status(429).json({
                error: 'Rate limit exceeded',
                message: `Maximum ${CONFIG.RATE_LIMIT_PER_DEVICE_PER_HOUR} reports per hour`,
                retryAfter: rateLimitResult.retryAfter
            });
        }

        // Store report in database
        await storeReport(report);

        // Perform automated moderation
        const moderationResult = await performAutomatedModeration(report);

        // Send notifications
        await sendNotifications(report, moderationResult);

        // Update rate limiting
        await updateRateLimit(report.reporterDeviceId);

        // Log for monitoring
        console.log(`✅ Report processed: ${report.id}`, {
            reportId: report.id,
            contentType: report.contentType,
            reason: report.reason,
            urgent: moderationResult.isUrgent
        });

        res.status(200).json({
            success: true,
            reportId: report.id,
            status: 'received',
            urgent: moderationResult.isUrgent,
            estimatedReviewTime: moderationResult.isUrgent ? '1 hour' : '24 hours',
            message: 'Report received and being processed'
        });

    } catch (error) {
        console.error('❌ Error processing report:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Unable to process report at this time'
        });
    }
});

/**
 * Health check endpoint
 */
app.get('/api/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        service: 'sketchai-ugc-webhook',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

/**
 * Admin statistics endpoint
 */
app.get('/api/admin/stats', authenticate, async (req, res) => {
    try {
        const stats = await new Promise((resolve, reject) => {
            const today = new Date().toISOString().split('T')[0];
            const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

            db.all(`
                SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN date(received_at) = ? THEN 1 ELSE 0 END) as today,
                    SUM(CASE WHEN received_at >= ? THEN 1 ELSE 0 END) as thisWeek,
                    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                    SUM(CASE WHEN is_urgent = 1 THEN 1 ELSE 0 END) as urgent
                FROM content_reports
            `, [today, weekAgo], (err, rows) => {
                if (err) reject(err);
                else resolve(rows[0]);
            });
        });

        res.status(200).json(stats);

    } catch (error) {
        console.error('Error getting stats:', error);
        res.status(500).json({ error: 'Unable to fetch statistics' });
    }
});

/**
 * Get recent reports for admin dashboard
 */
app.get('/api/admin/reports', authenticate, async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const offset = parseInt(req.query.offset) || 0;

        const reports = await new Promise((resolve, reject) => {
            db.all(`
                SELECT * FROM content_reports 
                ORDER BY received_at DESC 
                LIMIT ? OFFSET ?
            `, [limit, offset], (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });

        res.status(200).json({
            reports: reports,
            limit: limit,
            offset: offset
        });

    } catch (error) {
        console.error('Error getting reports:', error);
        res.status(500).json({ error: 'Unable to fetch reports' });
    }
});

// Database helper functions
function storeReport(report) {
    return new Promise((resolve, reject) => {
        const sql = `
            INSERT INTO content_reports (
                id, content_id, content_type, reason, additional_details,
                reporter_device_id, timestamp, app_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;

        db.run(sql, [
            report.id,
            report.contentId,
            report.contentType,
            report.reason,
            report.additionalDetails || null,
            report.reporterDeviceId,
            report.timestamp,
            report.appVersion
        ], function(err) {
            if (err) reject(err);
            else resolve(this.lastID);
        });
    });
}

async function checkRateLimit(deviceId) {
    return new Promise((resolve, reject) => {
        const hourAgo = Date.now() - (60 * 60 * 1000);

        db.get(`
            SELECT report_timestamps FROM rate_limits WHERE device_id = ?
        `, [deviceId], (err, row) => {
            if (err) {
                reject(err);
                return;
            }

            let timestamps = [];
            if (row && row.report_timestamps) {
                timestamps = JSON.parse(row.report_timestamps);
            }

            // Filter to recent reports
            const recentTimestamps = timestamps.filter(ts => ts > hourAgo);
            const allowed = recentTimestamps.length < CONFIG.RATE_LIMIT_PER_DEVICE_PER_HOUR;

            if (!allowed) {
                const oldestRecent = Math.min(...recentTimestamps);
                const retryAfter = Math.ceil((oldestRecent + (60 * 60 * 1000) - Date.now()) / 1000);
                resolve({ allowed: false, retryAfter });
            } else {
                resolve({ allowed: true });
            }
        });
    });
}

async function updateRateLimit(deviceId) {
    return new Promise((resolve, reject) => {
        const now = Date.now();
        const dayAgo = now - (24 * 60 * 60 * 1000);

        // Get existing timestamps
        db.get(`
            SELECT report_timestamps FROM rate_limits WHERE device_id = ?
        `, [deviceId], (err, row) => {
            if (err) {
                reject(err);
                return;
            }

            let timestamps = [];
            if (row && row.report_timestamps) {
                timestamps = JSON.parse(row.report_timestamps);
            }

            // Add current timestamp and filter old ones
            timestamps.push(now);
            timestamps = timestamps.filter(ts => ts > dayAgo);

            // Update database
            db.run(`
                INSERT OR REPLACE INTO rate_limits (device_id, report_timestamps, last_updated)
                VALUES (?, ?, CURRENT_TIMESTAMP)
            `, [deviceId, JSON.stringify(timestamps)], (err) => {
                if (err) reject(err);
                else resolve();
            });
        });
    });
}

async function performAutomatedModeration(report) {
    const result = {
        isUrgent: false,
        riskScore: 0,
        automatedFlags: []
    };

    // Check for urgent keywords
    const textContent = `${report.reason} ${report.additionalDetails || ''}`.toLowerCase();
    
    for (const keyword of CONFIG.URGENT_KEYWORDS) {
        if (textContent.includes(keyword)) {
            result.isUrgent = true;
            result.automatedFlags.push(`urgent_keyword_${keyword}`);
            result.riskScore += 20;
        }
    }

    // Check for high-risk categories
    if (['violence', 'hate_speech', 'sexual_content'].includes(report.reason)) {
        result.isUrgent = true;
        result.riskScore += 30;
    }

    // Update report with moderation results
    await new Promise((resolve, reject) => {
        db.run(`
            UPDATE content_reports 
            SET is_urgent = ?, risk_score = ?
            WHERE id = ?
        `, [result.isUrgent ? 1 : 0, result.riskScore, report.id], (err) => {
            if (err) reject(err);
            else resolve();
        });
    });

    return result;
}

async function sendNotifications(report, moderationResult) {
    try {
        if (moderationResult.isUrgent) {
            await sendUrgentAlert(report, moderationResult);
        } else {
            await sendStandardNotification(report);
        }
    } catch (error) {
        console.error('Error sending notifications:', error);
    }
}

async function sendUrgentAlert(report, moderationResult) {
    const subject = `🚨 URGENT: Content Report - ${report.reason}`;
    const body = `
URGENT CONTENT REPORT - REQUIRES IMMEDIATE ATTENTION

Report ID: ${report.id}
Content Type: ${report.contentType}
Reason: ${report.reason}
Risk Score: ${moderationResult.riskScore}

Content ID: ${report.contentId}
Additional Details: ${report.additionalDetails || 'None'}

REQUIRED ACTION: Review within 1 hour per App Store guidelines.
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

async function sendStandardNotification(report) {
    const subject = `Content Report - ${report.reason}`;
    const body = `
New content report received:

Report ID: ${report.id}
Content Type: ${report.contentType}
Reason: ${report.reason}

Please review within 24 hours.
    `;

    await transporter.sendMail({
        from: CONFIG.SMTP_USER,
        to: CONFIG.MODERATION_EMAIL,
        subject: subject,
        text: body
    });

    console.log(`📧 Standard notification sent for report: ${report.id}`);
}

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: 'An unexpected error occurred'
    });
});

// Start server
const server = app.listen(PORT, () => {
    console.log(`🚀 SketchAI UGC Webhook server running on port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    server.close(() => {
        console.log('Server closed');
        db.close((err) => {
            if (err) {
                console.error('Error closing database:', err.message);
            } else {
                console.log('Database connection closed');
            }
            process.exit(0);
        });
    });
});

module.exports = app;
