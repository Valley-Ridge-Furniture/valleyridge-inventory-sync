# AWS Transfer Family Cost Findings - Actual vs Expected

**Date:** January 2025  
**Based on:** Actual AWS Cost Explorer data

---

## 📊 **Actual Cost Data**

### **Monthly Transfer Family Costs:**

| Month | Transfer Family Cost | Total AWS Cost | Transfer Family % |
|-------|---------------------|----------------|-------------------|
| **June 2025** | $0.00 | $0.02 | 0% |
| **July 2025** | $10.18 | $11.81 | 86% |
| **August 2025** | $223.29 | $256.74 | **87%** |
| **September 2025** | $216.02 | $248.53 | **87%** |
| **October 2025** | $223.20 | $256.80 | **87%** |
| **November 2025** | $216.00 | $248.54 | **87%** |

**Average Transfer Family Cost:** ~$216/month  
**Transfer Family = 87% of total AWS costs**

---

## 🚨 **Critical Discovery**

### **What the Cost Data Tells Us:**

At **$0.30/hour** AWS Transfer Family pricing:
- **$216/month ÷ $0.30/hour = 720 hours/month**
- **720 hours ÷ 30 days = 24 hours/day**

**The SFTP server WAS running 24/7 in August-November!**

### **Timeline Analysis:**

1. **June 2025:** $0 (server not created or inactive)
2. **July 2025:** $10.18 (~34 hours, partial month or testing)
3. **August-October 2025:** ~$220/month (24/7 operation)
4. **November 2025:** $216 (24/7 operation, scheduler deployed mid-month on Nov 13)

---

## 🔍 **Deployment Timeline**

### **According to CHANGELOG.md:**

- **Version 2.2.0:** Deployed November 13, 2025
  - Switched to EventBridge Scheduler
  - Should have reduced costs to ~$13.50/month

### **What Actually Happened:**

- **November 2025:** Still $216 (scheduler deployed mid-month, but costs still show 24/7)
- **Possible explanations:**
  1. Scheduler not working properly (server not stopping)
  2. Costs billed at month-end (includes pre-deployment days)
  3. Server restarting automatically after stops
  4. Stop schedule failing silently

---

## 💰 **Impact Analysis**

### **Current Situation (November 2025):**
- **Transfer Family:** $216/month (87% of total)
- **Total AWS:** $248.54/month
- **Server Status:** Appears to be running 24/7 despite scheduler

### **Expected (If Scheduler Works):**
- **Transfer Family:** $13.50/month (1.5 hours/day) or $5.25/month (35 min/day)
- **Total AWS:** ~$50/month
- **Savings:** $198-211/month (**94-97% reduction**)

### **Annual Impact:**
- **Current Annual Cost:** ~$2,592/year (Transfer Family only)
- **Optimized Annual Cost:** $63-162/year
- **Potential Annual Savings:** **$2,430-2,529/year**

---

## 🔧 **Immediate Actions Required**

### **1. Verify Current Server State**
```bash
# Check if server is currently running
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.State' --output text

# Should show: OFFLINE (if scheduler working) or ONLINE (if running 24/7)
```

### **2. Check Scheduler Status**
```bash
# Verify schedules exist and are enabled
aws scheduler get-schedule --name StartSFTPServer
aws scheduler get-schedule --name StopSFTPServer

# Check recent scheduler executions
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 2592000))000 \
  --query 'events[-50:].{Time:timestamp,Message:message}'
```

### **3. Verify Stop Functionality**
```bash
# Check if server actually stops when scheduled
# Look for "OFFLINE" messages in logs after stop attempts
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 604800))000 \
  --filter-pattern "OFFLINE"
```

### **4. Check for Manual Starts**
```bash
# Check if server is being started manually or by another process
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 2592000))000 \
  --filter-pattern "start" \
  | grep -v "scheduled"
```

---

## 🎯 **Optimization Strategy**

### **Phase 1: Fix Current Issue (IMMEDIATE)**

1. **Verify scheduler is working**
2. **Stop server immediately** if it's running outside schedule
3. **Test stop functionality** manually
4. **Monitor for 1 week** to ensure it stays OFF

### **Phase 2: Optimize Window (Once Working)**

1. **Reduce runtime window** from 1.5 hours to 35 minutes
2. **Monitor upload patterns** to fine-tune timing
3. **Set up alerts** for late uploads or schedule failures

### **Phase 3: Long-Term Monitoring**

1. **Track monthly costs** to verify optimization
2. **Set up CloudWatch alarms** for unexpected server state
3. **Review costs monthly** to catch issues early

---

## 📋 **Expected Results After Fix**

### **If We Fix Scheduling (1.5 hours/day):**
- **Transfer Family:** $13.50/month
- **Total AWS:** ~$50/month
- **Monthly Savings:** $198.54/month
- **Annual Savings:** $2,382/year

### **If We Optimize Further (35 minutes/day):**
- **Transfer Family:** $5.25/month
- **Total AWS:** ~$42/month
- **Monthly Savings:** $206.54/month
- **Annual Savings:** $2,478/year

---

## ⚠️ **Risk Factors**

### **Why Scheduler Might Not Be Working:**

1. **Server State Stuck:** Server may be stuck in "STOPPING" state
2. **Stop Command Failing:** Lambda might not have proper permissions
3. **Auto-Restart:** Server might be configured to auto-restart
4. **Timezone Issues:** Schedules might be using wrong timezone
5. **Schedule Not Enabled:** Schedules might exist but be disabled

### **Mitigation:**

- Test stop functionality manually
- Add CloudWatch alarms for server state
- Monitor logs daily for first week after fix
- Verify schedules are enabled and in correct timezone

---

## 📊 **Comparison: Expected vs Actual**

| Metric | Expected (Documented) | Actual (Cost Data) | Gap |
|--------|----------------------|-------------------|-----|
| **Runtime** | 1.5 hours/day | 24 hours/day | **16x longer** |
| **Monthly Cost** | $13.50 | $216 | **$202.50 overspend** |
| **% of Total Cost** | ~27% | 87% | **3x higher** |

---

**Last Updated:** January 2025  
**Priority:** 🔴 **URGENT**  
**Status:** Investigation needed to determine why scheduler isn't working  
**Potential Savings:** **$2,400+ per year**

