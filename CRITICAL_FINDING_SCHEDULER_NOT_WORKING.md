# 🚨 CRITICAL FINDING: SFTP Scheduler NOT Working

**Date:** January 2025  
**Status:** 🔴 **URGENT ACTION REQUIRED**

---

## 📊 **Actual Usage Data (December 1-18, 2025)**

### **December Billing Period:**
- **Dates:** December 1-18, 2025 (18 days)
- **Transfer Family Cost:** $129.60
- **Hours:** 432 hours (129.60 ÷ $0.30/hour)
- **Hours/Day:** **24.0 hours/day** ❌

### **Conclusion:**
**The server is STILL running 24/7! The scheduler is NOT working.**

---

## 🔍 **Comparison Across Months**

| Month | Days | Hours | Cost | Hours/Day | Status |
|-------|------|-------|------|-----------|--------|
| **October** | 31 | 744 | $223.20 | 24.0 | ❌ 24/7 |
| **November** | 30 | 720 | $216.00 | 24.0 | ❌ 24/7 |
| **December (1-18)** | 18 | 432 | $129.60 | **24.0** | ❌ **STILL 24/7** |

**All three months show exactly 24.0 hours/day - the scheduler has NEVER worked!**

---

## 💰 **Impact Analysis**

### **Current Cost:**
- **December (18 days):** $129.60
- **Projected for full month (31 days):** $223.20 (432 ÷ 18 × 31 × $0.30)

### **If Scheduler Worked (1.5 hours/day):**
- **December (18 days):** $8.10 (27 hours × $0.30)
- **Full month (31 days):** $13.95 (46.5 hours × $0.30)
- **Savings:** $121.50/month (94% reduction)

### **If Optimized to 35 minutes/day:**
- **December (18 days):** $3.15 (10.5 hours × $0.30)
- **Full month (31 days):** $5.43 (18.1 hours × $0.30)
- **Savings:** $126.45/month (97.6% reduction)

---

## 🔧 **Root Cause: Scheduler Not Working**

### **What Should Happen:**
- **5:30 AM EST:** Server starts
- **6:00 AM EST:** File upload
- **7:00 AM EST:** Server stops
- **Runtime:** 1.5 hours/day

### **What's Actually Happening:**
- **Server runs 24/7** - never stops
- **Scheduler deployed Nov 13** but not working
- **Costs reflect 24/7 operation** consistently

### **Possible Causes:**

1. **Stop Lambda Not Invoked**
   - EventBridge schedule might not be triggering
   - Lambda permission issues
   - Schedule configuration error

2. **Stop Lambda Failing**
   - Lambda function errors
   - IAM permissions insufficient
   - API call failures

3. **Server Not Stopping**
   - `stopServer` API call not working
   - Server stuck in STOPPING state
   - Server auto-restarting

4. **Schedule Not Enabled**
   - Stop schedule might be disabled
   - Timezone configuration wrong
   - Schedule expression incorrect

---

## 🚀 **IMMEDIATE ACTIONS REQUIRED**

### **Step 1: Verify Current Server State**
```bash
# Check if server is currently running (should be OFFLINE outside 5:30-7:00 AM EST)
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.{State:State,LastModified:LastModified}' --output json
```

**Expected:** Should be OFFLINE if outside schedule window  
**If ONLINE:** Scheduler definitely not working

### **Step 2: Check Stop Schedule Status**
```bash
# Verify stop schedule exists and is enabled
aws scheduler get-schedule --name StopSFTPServer \
  --query '{Name:Name,State:State,Schedule:ScheduleExpression,Timezone:ScheduleExpressionTimezone,NextInvocation:NextInvocationTime}' \
  --output json
```

### **Step 3: Check Recent Stop Attempts**
```bash
# Look for stop Lambda invocations in last 7 days
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 604800))000 \
  --filter-pattern "stop" \
  --query 'events[-20:].{Time:timestamp,Message:message}'
```

### **Step 4: Test Stop Functionality Manually**
```bash
# Manually invoke stop Lambda
aws lambda invoke \
  --function-name valleyridge-sftp-scheduler-prod \
  --payload '{"action": "stop"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# Check response
cat response.json

# Verify server stopped
sleep 10
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.State' --output text
```

### **Step 5: Check for Errors in Lambda Logs**
```bash
# Look for errors in scheduler Lambda
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 604800))000 \
  --filter-pattern "ERROR" \
  --query 'events[-20:].{Time:timestamp,Message:message}'
```

---

## 📋 **Diagnostic Checklist**

- [ ] Server state right now (should be OFFLINE outside schedule)
- [ ] Stop schedule exists and is ENABLED
- [ ] Stop schedule timezone is correct (America/New_York)
- [ ] Stop schedule cron expression is correct (cron(0 7 * * ? *))
- [ ] Lambda function exists and has correct permissions
- [ ] Lambda function can invoke transfer:StopServer
- [ ] Server actually stops when Lambda runs
- [ ] No errors in Lambda logs
- [ ] No auto-restart configuration on server

---

## 💡 **Why Costs Are Lower in December**

**The lower December cost ($129.60 vs $216) is NOT because the scheduler is working - it's simply because December only has 18 days of billing!**

- **November:** 30 days × 24 hours = 720 hours = $216
- **December:** 18 days × 24 hours = 432 hours = $129.60
- **Both:** Exactly 24.0 hours/day

If we project December to a full month: 432 ÷ 18 × 31 = 744 hours = $223.20 (same as October!)

---

## 🎯 **Expected Savings Once Fixed**

### **Monthly Savings:**
- **Current:** $216/month (24/7)
- **Fixed (1.5 hours/day):** $13.50/month
- **Savings:** $202.50/month (94% reduction)

### **Optimized (35 minutes/day):**
- **Cost:** $5.25/month
- **Savings:** $210.75/month (97.6% reduction)

### **Annual Impact:**
- **Current:** $2,592/year
- **Fixed:** $162/year
- **Optimized:** $63/year
- **Annual Savings:** $2,430-2,529/year

---

## ⚠️ **URGENT: Fix Required Immediately**

**The scheduler has been "deployed" since November 13, but costs show it has NEVER worked. We're spending $216/month unnecessarily.**

**Next steps:**
1. **STOP THE SERVER MANUALLY** right now to stop the bleeding
2. **Diagnose why stop schedule isn't working**
3. **Fix the scheduler**
4. **Verify it works for 1 week**
5. **Then optimize the window further**

---

**Last Updated:** January 2025  
**Priority:** 🔴 **URGENT - CRITICAL**  
**Status:** Scheduler deployed but not functioning - server running 24/7  
**Waste:** $202.50/month = $2,430/year

