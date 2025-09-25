# 🚀 SketchAI UGC Safety Webhook Deployment Guide

This guide provides step-by-step instructions for deploying the UGC Safety webhook to various cloud platforms.

---

## 📋 Prerequisites

Before deploying, ensure you have:

- ✅ **SMTP Email Service** (Gmail, SendGrid, etc.)
- ✅ **API Key** for webhook authentication
- ✅ **Domain/Subdomain** for webhook URL
- ✅ **SSL Certificate** (automatically handled by most platforms)

---

## 🎯 Quick Start (Recommended)

### **Option 1: Firebase Functions (Easiest)**

**Perfect for:**
- ✅ **Zero server management**
- ✅ **Automatic scaling**
- ✅ **Built-in security**
- ✅ **99.9% uptime**

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Initialize project
firebase init functions

# 4. Copy CloudFunctionWebhook.js to functions/index.js
cp CloudFunctionWebhook.js functions/index.js
cp package.json functions/package.json

# 5. Set environment variables
firebase functions:config:set \
  sketchai.webhook_key="your_secure_api_key" \
  sketchai.moderation_email="moderation@yourcompany.com" \
  sketchai.admin_email="admin@yourcompany.com" \
  smtp.host="smtp.gmail.com" \
  smtp.user="your-email@gmail.com" \
  smtp.pass="your-app-password"

# 6. Deploy
firebase deploy --only functions
```

**Your webhook URL will be:**
`https://your-region-your-project.cloudfunctions.net/receiveContentReport`

---

### **Option 2: Railway (Simple)**

**Perfect for:**
- ✅ **Easy deployment**
- ✅ **Automatic HTTPS**
- ✅ **Environment variables**
- ✅ **Affordable pricing**

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login to Railway
railway login

# 3. Initialize project
railway init

# 4. Set environment variables
railway variables set WEBHOOK_API_KEY=your_secure_api_key
railway variables set MODERATION_EMAIL=moderation@yourcompany.com
railway variables set ADMIN_EMAIL=admin@yourcompany.com
railway variables set SMTP_HOST=smtp.gmail.com
railway variables set SMTP_USER=your-email@gmail.com
railway variables set SMTP_PASS=your-app-password

# 5. Deploy
railway up
```

---

### **Option 3: Heroku (Popular)**

```bash
# 1. Install Heroku CLI
# Download from: https://devcenter.heroku.com/articles/heroku-cli

# 2. Create Heroku app
heroku create sketchai-ugc-webhook

# 3. Set environment variables
heroku config:set WEBHOOK_API_KEY=your_secure_api_key
heroku config:set MODERATION_EMAIL=moderation@yourcompany.com
heroku config:set ADMIN_EMAIL=admin@yourcompany.com
heroku config:set SMTP_HOST=smtp.gmail.com
heroku config:set SMTP_USER=your-email@gmail.com
heroku config:set SMTP_PASS=your-app-password

# 4. Deploy
git push heroku main
```

---

## 🔧 Configuration

### **Required Environment Variables**

| Variable | Description | Example |
|----------|-------------|---------|
| `WEBHOOK_API_KEY` | Secure API key for authentication | `sketchai_prod_key_2024` |
| `MODERATION_EMAIL` | Email for content moderation alerts | `moderation@yourcompany.com` |
| `ADMIN_EMAIL` | Email for urgent/admin notifications | `admin@yourcompany.com` |
| `SMTP_HOST` | SMTP server hostname | `smtp.gmail.com` |
| `SMTP_USER` | SMTP username/email | `your-email@gmail.com` |
| `SMTP_PASS` | SMTP password/app password | `your-app-password` |

### **Optional Environment Variables**

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment mode | `production` |
| `DATABASE_PATH` | SQLite database path | `./sketchai_reports.db` |
| `RATE_LIMIT_PER_DEVICE_PER_HOUR` | Rate limiting | `10` |

---

## 📧 Email Configuration

### **Gmail Setup (Recommended)**

1. **Enable 2-Factor Authentication** in your Google account
2. **Generate App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
3. **Use App Password** (not your regular password) in `SMTP_PASS`

### **SendGrid Setup (Professional)**

```bash
# Set SendGrid configuration
SMTP_HOST=smtp.sendgrid.net
SMTP_USER=apikey
SMTP_PASS=your_sendgrid_api_key
```

---

## 🏗️ iOS App Integration

### **Update iOS Configuration**

Update `UGCSafetyManager.swift` with your deployed webhook URL:

```swift
// In UGCSafetyManager.swift - Config struct
static let reportWebhookURL = "https://your-deployed-webhook.com/api/reports"
static let webhookAPIKey = "your_secure_api_key" // Same as WEBHOOK_API_KEY
```

### **Test Integration**

```swift
// Test the webhook from your iOS app
let testReport = ContentReport(
    id: UUID().uuidString,
    contentId: "test_content",
    contentType: .drawing,
    reason: .other,
    additionalDetails: "Test report from iOS",
    reporterDeviceId: "test_device",
    timestamp: Date(),
    appVersion: "1.0.0"
)

ugcSafetyManager.reportContent(
    contentId: testReport.contentId,
    contentType: testReport.contentType,
    reason: testReport.reason,
    additionalDetails: testReport.additionalDetails
) { result in
    switch result {
    case .success():
        print("✅ Test report submitted successfully")
    case .failure(let error):
        print("❌ Test report failed: \(error)")
    }
}
```

---

## 🔒 Security Checklist

### **✅ Required Security Measures**

- [ ] **Strong API Key** (minimum 32 characters, random)
- [ ] **HTTPS Only** (enforced by deployment platform)
- [ ] **Rate Limiting** (10 requests/hour/device)
- [ ] **Input Validation** (all fields validated)
- [ ] **Timestamp Verification** (prevent replay attacks)
- [ ] **Error Logging** (for monitoring and debugging)

### **✅ Recommended Security Measures**

- [ ] **IP Whitelisting** (if using fixed infrastructure)
- [ ] **DDoS Protection** (provided by most platforms)
- [ ] **Database Encryption** (for sensitive data)
- [ ] **Log Monitoring** (alerts for unusual activity)
- [ ] **Regular Security Updates** (keep dependencies updated)

---

## 📊 Monitoring & Maintenance

### **Health Check Endpoint**

Monitor your webhook with:
```bash
curl https://your-webhook-url.com/api/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "sketchai-ugc-webhook",
  "version": "1.0.0",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### **Admin Dashboard**

Check statistics:
```bash
curl -H "Authorization: Bearer your_api_key" \
     https://your-webhook-url.com/api/admin/stats
```

### **Log Monitoring**

Monitor these key metrics:
- **Request Rate**: Should be consistent with app usage
- **Error Rate**: Should be <1%
- **Response Time**: Should be <500ms
- **Urgent Reports**: Immediate attention required

---

## 🚨 Emergency Procedures

### **If Webhook Goes Down**

1. **iOS App Behavior**: Automatically falls back to email submission
2. **Immediate Action**: Check platform status, review logs
3. **Temporary Fix**: Enable manual email processing
4. **Long-term**: Implement redundant webhook endpoints

### **High Volume Handling**

If you receive >1000 reports/hour:

1. **Scale Up**: Increase server resources
2. **Database**: Upgrade to PostgreSQL/MongoDB
3. **Queue**: Implement Redis/SQS for async processing
4. **Load Balancer**: Distribute traffic across instances

---

## 💡 Platform-Specific Tips

### **Firebase Functions**
- ✅ **Automatic scaling**
- ✅ **Built-in monitoring**
- ✅ **Free tier available**
- ⚠️ **Cold starts** (not an issue for webhook)

### **Railway**
- ✅ **Simple deployment**
- ✅ **Built-in metrics**
- ✅ **Reasonable pricing**
- ⚠️ **Less ecosystem** than AWS/GCP

### **Heroku**
- ✅ **Mature platform**
- ✅ **Extensive add-ons**
- ✅ **Easy scaling**
- ⚠️ **Higher cost** for production

### **AWS/DigitalOcean/Others**
- ✅ **Full control**
- ✅ **Cost effective** at scale
- ✅ **Advanced features**
- ⚠️ **More complex** setup

---

## 🎯 Next Steps

After successful deployment:

1. **✅ Test End-to-End**: Submit test reports from iOS app
2. **✅ Monitor Emails**: Verify notifications are working
3. **✅ Set Up Alerts**: Monitor for downtime/errors
4. **✅ Document URLs**: Update your team with webhook URLs
5. **✅ App Store Compliance**: Your UGC safety is now complete!

---

## 📞 Support

If you encounter issues:

1. **Check Logs**: Platform-specific logging dashboard
2. **Test Locally**: Use `npm run dev` for Express version
3. **Verify Config**: Double-check environment variables
4. **Email Test**: Verify SMTP settings work
5. **API Test**: Test webhook manually with curl/Postman

**Your SketchAI app now has a production-ready UGC safety system!** 🎉

---

## 🔗 Quick Links

- **Firebase Console**: https://console.firebase.google.com
- **Railway Dashboard**: https://railway.app/dashboard
- **Heroku Dashboard**: https://dashboard.heroku.com
- **Gmail App Passwords**: https://myaccount.google.com/apppasswords

**Ready to deploy? Choose your platform and follow the guide above!** 🚀
