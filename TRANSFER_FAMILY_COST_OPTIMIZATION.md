# AWS Transfer Family Cost Optimization Analysis

**Date:** January 2025  
**Primary Cost Center:** AWS Transfer Family (SFTP Server)  
**Current Estimated Cost:** $13.50/month (1.5 hours/day)  
**Potential Additional Savings:** $3-6/month (22-44% reduction)

---

## 📊 Current Transfer Family Configuration

### **Current Schedule**
- **Start Time:** 5:30 AM EST (`cron(30 5 * * ? *)`)
- **Expected Upload:** 6:00 AM EST
- **Stop Time:** 7:00 AM EST (`cron(0 7 * * ? *)`)
- **Daily Runtime:** 1.5 hours
- **Monthly Runtime:** ~45 hours (1.5 × 30 days)
- **Current Cost:** ~$13.50/month (45 hours × $0.30/hour)

### **Transfer Family Pricing (2025)**
- **Hourly Rate:** $0.30/hour when server is ONLINE
- **Data Transfer:** 
  - Inbound: Free
  - Outbound: $0.09/GB (first 10TB/month)
- **Storage:** Uses S3 storage (separate cost)
- **No minimum charges** when server is OFFLINE

---

## 🎯 Optimization Opportunities

### 1. **Reduce Runtime Window** ⚠️ HIGH IMPACT

**Current State:**
- Server runs for **1.5 hours** (5:30 AM - 7:00 AM EST)
- 30-minute buffer before upload
- 1-hour buffer after upload

**Analysis:**
- File upload takes **~1 minute** (based on file sizes ~2MB)
- Server startup takes **~2-3 minutes** (from logs)
- Server shutdown is **immediate** (just stops accepting connections)

**Optimization Options:**

#### **Option A: Aggressive Optimization (Recommended)**
- **Start:** 5:55 AM EST (5 minutes before upload)
- **Stop:** 6:15 AM EST (15 minutes after upload)
- **Runtime:** 20 minutes/day
- **Monthly Cost:** $3.00/month (20 min × 30 days = 10 hours)
- **Savings:** $10.50/month (78% reduction from current)

#### **Option B: Conservative Optimization**
- **Start:** 5:50 AM EST (10 minutes before upload)
- **Stop:** 6:30 AM EST (30 minutes after upload)
- **Runtime:** 40 minutes/day
- **Monthly Cost:** $6.00/month (40 min × 30 days = 20 hours)
- **Savings:** $7.50/month (56% reduction from current)

#### **Option C: Balanced (Recommended for Production)**
- **Start:** 5:55 AM EST (5 minutes before upload)
- **Stop:** 6:30 AM EST (30 minutes after upload)
- **Runtime:** 35 minutes/day
- **Monthly Cost:** $5.25/month (35 min × 30 days = 17.5 hours)
- **Savings:** $8.25/month (61% reduction from current)

**Risk Assessment:**
- ⚠️ **Low Risk:** If uploads are consistently at 6:00 AM EST
- ⚠️ **Medium Risk:** If uploads vary by ±15 minutes
- ⚠️ **High Risk:** If uploads are unpredictable

**Recommendation:** Start with **Option C (Balanced)** - provides good safety margin while maximizing savings.

---

### 2. **Monitor Actual Upload Times** ⚠️ MEDIUM IMPACT

**Current Issue:**
- We don't have visibility into actual upload completion times
- Buffer times are based on assumptions, not data

**Solution:**
- Add S3 event monitoring to track when files arrive
- Use CloudWatch metrics to track upload patterns
- Adjust schedule based on actual data

**Implementation:**
```bash
# Check actual file arrival times
aws s3 ls s3://valleyridge-inventory-sync/incoming/ --recursive \
  | awk '{print $1, $2}' \
  | sort
```

**Expected Savings:** $2-4/month (by optimizing buffer times)

---

### 3. **Verify Server Actually Stops** ⚠️ LOW IMPACT

**Current State:**
- Server should stop at 7:00 AM EST
- Need to verify it's actually stopping and not running longer

**Check:**
```bash
# Monitor server state over time
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.State' \
  --output text
```

**Expected Savings:** $0-3/month (if server is running longer than expected)

---

### 4. **Consider Alternative Solutions** ⚠️ LONG-TERM

**Current:** AWS Transfer Family SFTP Server  
**Alternatives:**

1. **S3 Direct Upload (via Pre-signed URLs)**
   - **Cost:** $0 (no Transfer Family needed)
   - **Complexity:** Requires vendor to use S3 API instead of SFTP
   - **Savings:** $13.50/month (100% reduction)
   - **Feasibility:** Depends on vendor's technical capabilities

2. **AWS DataSync**
   - **Cost:** Similar to Transfer Family
   - **Use Case:** Better for large batch transfers
   - **Not Recommended:** More expensive for small daily files

3. **Lambda-based SFTP (Custom Solution)**
   - **Cost:** Pay per use (likely cheaper)
   - **Complexity:** High (requires custom development)
   - **Not Recommended:** High maintenance overhead

**Recommendation:** Keep Transfer Family, but optimize runtime window.

---

## 📈 Expected Savings Summary

| Optimization | Current Cost | Optimized Cost | Monthly Savings | Annual Savings |
|-------------|--------------|----------------|-----------------|----------------|
| Reduce Runtime Window (Option C) | $13.50 | $5.25 | $8.25 | $99 |
| Monitor & Optimize Upload Times | $5.25 | $3.00-4.50 | $0.75-2.25 | $9-27 |
| Verify Server Stops Properly | $3.00-4.50 | $3.00-4.50 | $0-1.50 | $0-18 |
| **Total Potential Savings** | **$13.50** | **$3.00-4.50** | **$9.00-10.50** | **$108-126** |

---

## 🚀 Implementation Plan

### **Phase 1: Immediate Optimization (Low Risk)**

1. **Reduce runtime window to 35 minutes** (Option C)
   - Start: 5:55 AM EST
   - Stop: 6:30 AM EST
   - **Savings:** $8.25/month

2. **Add monitoring** to track actual upload times
   - CloudWatch metrics for file arrival
   - Alert if uploads are late

### **Phase 2: Data-Driven Optimization (Medium Risk)**

3. **Analyze upload patterns** for 2-4 weeks
   - Track actual upload times
   - Identify earliest/latest uploads
   - Calculate optimal window

4. **Further reduce window** based on data
   - Potentially reduce to 20-25 minutes
   - **Additional Savings:** $1.50-2.25/month

### **Phase 3: Long-Term Consideration**

5. **Evaluate S3 Direct Upload** as alternative
   - Discuss with vendor (Loloi)
   - Test feasibility
   - **Potential Savings:** $3.00-4.50/month (if switching)

---

## ⚠️ Risk Mitigation

### **Risk: Upload Arrives Before Server Starts**
- **Mitigation:** Monitor for 2 weeks before reducing start time
- **Fallback:** Keep 5-minute buffer minimum
- **Alert:** CloudWatch alarm if file arrives before server starts

### **Risk: Upload Takes Longer Than Expected**
- **Mitigation:** Monitor actual upload durations
- **Fallback:** Keep 30-minute buffer after upload
- **Alert:** CloudWatch alarm if upload takes >10 minutes

### **Risk: Server Doesn't Stop Properly**
- **Mitigation:** Add CloudWatch alarm for server state
- **Fallback:** Manual stop script
- **Alert:** Email notification if server runs >1 hour

---

## 📋 Implementation Checklist

- [ ] Update EventBridge schedules to new times (5:55 AM start, 6:30 AM stop)
- [ ] Add CloudWatch metrics for file arrival times
- [ ] Add CloudWatch alarm for late uploads
- [ ] Add CloudWatch alarm for server state (if running >1 hour)
- [ ] Monitor for 2 weeks to verify optimization
- [ ] Analyze upload patterns and further optimize if safe
- [ ] Document actual savings achieved

---

## 🔍 Monitoring After Optimization

### **Key Metrics to Track:**
1. **Server Runtime:** Should be ~35 minutes/day
2. **Upload Arrival Time:** Should be consistently ~6:00 AM EST
3. **Upload Duration:** Should be <5 minutes
4. **Server State:** Should be OFFLINE outside window
5. **Monthly Cost:** Should decrease to ~$5.25/month

### **Monitoring Commands:**
```bash
# Check server state
aws transfer describe-server --server-id s-34ce3bb4895a4fac8 \
  --query 'Server.State' --output text

# Check recent file uploads
aws s3 ls s3://valleyridge-inventory-sync/incoming/ --recursive \
  | tail -10

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace ValleyRidge/SFTP \
  --metric-name SFTP_Server_State \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Average
```

---

## 💡 Additional Cost Considerations

### **Data Transfer Costs**
- **Current:** Minimal (files are ~2MB, inbound is free)
- **Impact:** <$0.10/month (negligible)

### **S3 Storage Costs**
- **Current:** Files stored in S3 (separate from Transfer Family)
- **Impact:** Already optimized with lifecycle policies

### **Lambda Scheduler Costs**
- **Current:** ~$0.10/month (2 invocations/day)
- **Impact:** Negligible

---

## 📞 Next Steps

1. **Review this analysis** with the team
2. **Choose optimization option** (recommend Option C - Balanced)
3. **Update EventBridge schedules** to new times
4. **Add monitoring** for upload patterns
5. **Monitor for 2-4 weeks** to verify optimization
6. **Further optimize** based on actual data
7. **Document actual savings** achieved

---

**Last Updated:** January 2025  
**Status:** Ready for Implementation  
**Estimated Implementation Time:** 30 minutes  
**Estimated Monthly Savings:** $8.25-10.50 (61-78% reduction from current $13.50/month)

