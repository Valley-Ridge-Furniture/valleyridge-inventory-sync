# AWS Transfer Family Cost Analysis - Based on Actual Usage Data

**Date:** January 2025  
**Based on:** AWS Cost Explorer detailed usage breakdown

---

## 📊 **Actual Usage Data from AWS**

### **October 2025:**
- **USE1-ProtocolHours:** $223.20
- **Hours:** 744 hours
- **Days:** 31 days
- **Hours/Day:** **24.0 hours/day** (running 24/7)
- **Cost/Hour:** $0.30/hour ✅ (matches AWS pricing)

### **November 2025:**
- **USE1-ProtocolHours:** $216.00
- **Hours:** 720 hours
- **Days:** 30 days
- **Hours/Day:** **24.0 hours/day** (running 24/7)
- **Cost/Hour:** $0.30/hour ✅

### **December 2025:**
- **USE1-ProtocolHours:** $130.80
- **Hours:** 436 hours (130.80 ÷ $0.30)
- **Days:** Partial month (need exact days to calculate properly)
- **Cost/Hour:** $0.30/hour ✅

---

## 🔍 **Key Findings**

### **October & November:**
- ✅ **Confirmed:** Server was running **24/7** in both months
- ✅ **No optimization active** despite scheduler being deployed Nov 13
- ⚠️ **November had 720 hours** = exactly 30 days × 24 hours

### **December (Partial Month):**
- ⚠️ **Need to know:** How many days are included in December billing?
- **If December includes all 31 days:**
  - 436 hours ÷ 31 days = **14.1 hours/day** (scheduler partially working)
- **If December is partial (e.g., 14 days):**
  - 436 hours ÷ 14 days = **31.1 hours/day** (impossible - still 24/7)
  - This would indicate costs are lower just because fewer days

---

## 💡 **Critical Question: How Many Days in December Billing?**

To determine if the scheduler is working, we need to know:

**Option A: Full Month (31 days)**
- 436 hours ÷ 31 = **14.1 hours/day**
- This suggests scheduler is working but not optimally
- Server should be running 1.5 hours/day, not 14 hours

**Option B: Partial Month (e.g., billing cycle)**
- If December billing only includes ~14 days:
  - 436 hours ÷ 14 = **31.1 hours/day** (impossible, suggests calculation error)
  - OR if actual days < 14, server still running 24/7

---

## 📈 **Usage Breakdown Analysis**

### **USE1-ProtocolHours:**
- **Purpose:** Billing for server runtime hours
- **Pricing:** $0.30/hour when server is ONLINE
- **October:** 744 hours = $223.20 ✅
- **November:** 720 hours = $216.00 ✅
- **December:** 436 hours = $130.80 ✅

### **USE1-UploadBytes:**
- **October:** 0.06 GB = $0.00 (free for inbound transfers)
- **November:** 0.06 GB = $0.00 (free for inbound transfers)
- **Impact:** Negligible - data transfer not a cost factor

---

## 🎯 **What We Know vs What We Need to Know**

### **✅ Confirmed:**
1. October & November: Server ran 24/7 (no optimization)
2. December: Costs dropped to $130.80
3. ProtocolHours are the ONLY cost driver (data transfer is free)
4. Scheduler was deployed November 13, but November still shows 24/7

### **❓ Need to Determine:**
1. **How many days are in December billing period?**
   - This will tell us if it's 14 hours/day (scheduler working) or 24 hours/day (just fewer days)
2. **Is the scheduler actually stopping the server?**
   - Need to check if server goes OFFLINE at 7:00 AM EST
3. **Why isn't it stopping properly?**
   - If it's running 14 hours/day, what's keeping it online after 7:00 AM?

---

## 🚀 **Next Steps to Diagnose**

### **1. Determine December Billing Period**
Check AWS billing for:
- What date range does "December 2025" include?
- Is it full month (Dec 1-31) or partial?

### **2. Calculate Actual Daily Rate**
Once we know the days:
```python
# Example if December has 20 days:
hours_per_day = 436 / 20 = 21.8 hours/day  # Still close to 24/7

# Example if December has 31 days:
hours_per_day = 436 / 31 = 14.1 hours/day  # Scheduler partially working
```

### **3. Check Current Server State**
```bash
# Check if server is currently OFFLINE (outside schedule window)
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.State' --output text
```

### **4. Review Recent Logs**
```bash
# Check last 7 days of scheduler activity
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --start-time $(($(date +%s) - 604800))000 \
  --query 'events[].message' \
  | grep -E "(ONLINE|OFFLINE|start|stop)"
```

---

## 💰 **Potential Savings (When Fixed)**

### **Current Situation:**
- **If still 24/7:** $216/month (720 hours @ $0.30/hour)
- **If 14 hours/day:** $130/month (still too high)

### **Target (Optimized):**
- **1.5 hours/day:** $13.50/month (45 hours @ $0.30/hour)
- **35 minutes/day:** $5.25/month (17.5 hours @ $0.30/hour)

### **Annual Savings Potential:**
- **From 24/7 to 35 min/day:** $2,529/year (97.6% reduction)
- **From 14 hours/day to 35 min/day:** $1,498/year (96% reduction)

---

## 📋 **Recommended Actions**

1. **Verify December billing period** - How many days included?
2. **Check current server state** - Is it OFFLINE right now (outside 5:30-7:00 AM window)?
3. **Monitor next full month** - January 2025 will give us complete data
4. **Fix stop schedule** - If it's not working, we need to debug why
5. **Optimize window** - Once working, reduce from 1.5 hours to 35 minutes

---

**Last Updated:** January 2025  
**Status:** Awaiting December billing period details to complete analysis  
**Priority:** 🔴 **HIGH** - Need to verify if scheduler is actually working

