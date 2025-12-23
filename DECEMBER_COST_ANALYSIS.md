# December 2025 Cost Analysis - Improvement But Not Optimal

**Date:** January 2025  
**Based on:** Actual AWS Cost Explorer data for December 2025

---

## 📊 **December 2025 Costs**

### **Service Breakdown:**
- **AWS Transfer Family:** $130.80 ⬇️ (down from $216!)
- **Tax:** $19.60
- **Amazon S3:** $0.05
- **AWS Lambda:** $0.00
- **Amazon SNS:** $0.00
- **Total:** ~$150.45

### **Transfer Family Analysis:**
- **December Cost:** $130.80
- **At $0.30/hour:** 436 hours total
- **Daily Runtime:** ~14 hours/day (436 hours ÷ 31 days)
- **Target:** 1.5 hours/day = $13.50/month

---

## 📈 **Progress Analysis**

### **Cost Trend:**
| Month | Transfer Family | Runtime | Status |
|-------|----------------|---------|--------|
| **August** | $223.29 | 24 hours/day | ❌ 24/7 |
| **September** | $216.02 | 24 hours/day | ❌ 24/7 |
| **October** | $223.20 | 24 hours/day | ❌ 24/7 |
| **November** | $216.00 | 24 hours/day | ❌ 24/7 |
| **December** | $130.80 | ~14 hours/day | ⚠️ Partial fix |

### **Improvement:**
- **December vs November:** $85.20 savings (39% reduction) ✅
- **But still running 9x longer than target** (14 hours vs 1.5 hours) ⚠️

---

## 🔍 **What This Tells Us**

### **Scheduler Is Working (Partially):**
- ✅ Cost dropped significantly (from $216 to $130.80)
- ✅ Server is NOT running 24/7 anymore
- ⚠️ But it's still running ~14 hours/day instead of 1.5 hours/day

### **Possible Causes:**

1. **Stop Schedule Not Working Properly**
   - Server starts at 5:30 AM but doesn't stop at 7:00 AM
   - Stop schedule might be failing silently
   - Server might be restarting after stop

2. **Multiple Start/Stop Cycles**
   - Server might be starting multiple times per day
   - Manual starts might be happening
   - Another process might be starting the server

3. **Extended Runtime Window**
   - If server runs from 5:30 AM to 7:30 PM = 14 hours
   - This suggests stop schedule at 7:00 AM EST is not working

4. **Timezone Issues**
   - Schedules might be in wrong timezone
   - Stop time might be calculated incorrectly

---

## 💰 **Potential Savings If Fully Optimized**

### **Current (December):**
- **Transfer Family:** $130.80/month
- **Runtime:** ~14 hours/day

### **If Optimized to 1.5 Hours/Day:**
- **Transfer Family:** $13.50/month
- **Savings:** $117.30/month (90% reduction)
- **Annual Savings:** $1,407.60/year

### **If Optimized to 35 Minutes/Day (Recommended):**
- **Transfer Family:** $5.25/month
- **Savings:** $125.55/month (96% reduction)
- **Annual Savings:** $1,506.60/year

---

## 🚀 **Immediate Actions Required**

### **1. Verify Stop Schedule Is Working**

```bash
# Check if stop schedule exists and is enabled
aws scheduler get-schedule --name StopSFTPServer \
  --query '{Name:Name,State:State,Schedule:ScheduleExpression,NextInvocation:NextInvocationTime}'

# Check recent stop attempts
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 2592000))000 \
  --filter-pattern "stop" \
  --query 'events[-20:].{Time:timestamp,Message:message}'
```

### **2. Check Server State Throughout Day**

```bash
# Monitor server state at different times
# Should be OFFLINE outside 5:30 AM - 7:00 AM EST window

# Check if server is currently running (outside schedule window)
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.State' --output text
```

### **3. Review Logs for Multiple Starts**

```bash
# Check for unexpected start events
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 2592000))000 \
  --filter-pattern "start" \
  --query 'events[].{Time:timestamp,Message:message}'
```

### **4. Test Stop Functionality Manually**

```bash
# Manually trigger stop to test
aws lambda invoke \
  --function-name valleyridge-sftp-scheduler-prod \
  --payload '{"action": "stop"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# Check response
cat response.json

# Verify server stopped
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.State' --output text
```

---

## 🎯 **Root Cause Investigation**

### **Questions to Answer:**

1. **Is the stop schedule actually running?**
   - Check EventBridge Scheduler logs
   - Verify Lambda invocations for stop action

2. **Is the server actually stopping when Lambda runs?**
   - Check Lambda logs for successful stop confirmations
   - Verify server state transitions to OFFLINE

3. **Is something restarting the server?**
   - Check for manual starts
   - Check for other processes/scripts starting the server
   - Verify no auto-restart configuration

4. **What time is the server actually stopping?**
   - Analyze logs to find actual stop times
   - Compare to scheduled stop time (7:00 AM EST)

---

## 📋 **Expected Behavior**

### **With Proper Scheduling (1.5 hours/day):**
- **5:30 AM EST:** Server starts
- **6:00 AM EST:** File upload occurs
- **7:00 AM EST:** Server stops
- **Runtime:** 1.5 hours/day = 45 hours/month = $13.50/month

### **Current Behavior (14 hours/day):**
- **Server starts:** 5:30 AM EST (confirmed from logs)
- **Server stops:** ??? (need to investigate)
- **Runtime:** ~14 hours/day = 434 hours/month = $130.80/month

---

## 💡 **Recommended Fix Strategy**

### **Step 1: Diagnose Stop Schedule**
1. Check if stop schedule is enabled and correct
2. Verify stop Lambda is being invoked
3. Check if stop command is actually stopping the server

### **Step 2: Fix Stop Schedule (If Broken)**
1. Redeploy scheduler if needed
2. Test stop functionality manually
3. Verify server goes OFFLINE

### **Step 3: Monitor for 1 Week**
1. Track server start/stop times daily
2. Verify runtime is ~1.5 hours/day
3. Check costs are decreasing

### **Step 4: Optimize Window (Once Working)**
1. Reduce from 1.5 hours to 35 minutes
2. Further optimize based on actual upload patterns
3. Target: $5.25/month

---

## 📊 **Cost Projection**

### **If We Fix Stop Schedule Now:**

**January 2025 (Projected):**
- **Current rate:** $130.80/month (14 hours/day)
- **Fixed rate:** $13.50/month (1.5 hours/day)
- **Potential savings:** $117.30/month

**Optimized Rate (35 minutes/day):**
- **Cost:** $5.25/month
- **Savings:** $125.55/month

**Annual Impact:**
- **Current:** $1,569.60/year
- **Fixed:** $162/year
- **Optimized:** $63/year
- **Annual Savings:** $1,407-1,507/year

---

**Last Updated:** January 2025  
**Priority:** 🟡 **HIGH** (Scheduler partially working, needs stop schedule fix)  
**Next Steps:** Investigate why server isn't stopping at 7:00 AM EST

