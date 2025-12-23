# AWS Cost Optimization Analysis

**Date:** January 2025  
**Current Estimated Monthly Cost:** $50-80  
**Primary Cost Center:** AWS Transfer Family (SFTP Server) - $13.50/month  
**Potential Additional Savings:** $18-30/month (36-60% reduction)

> **⚠️ IMPORTANT:** The primary cost center is AWS Transfer Family. See `TRANSFER_FAMILY_COST_OPTIMIZATION.md` for focused optimization strategies that can save an additional $8.25-10.50/month (61-78% reduction on Transfer Family costs).

---

## 📊 Current System Overview

### AWS Services in Use
- **AWS Lambda**: 4 functions (processing, incremental processing, SFTP scheduler, file preserver)
- **AWS S3**: File storage (586MB, 409 objects)
- **AWS Transfer Family**: SFTP server (1.5 hours/day - already optimized)
- **AWS CloudWatch**: Logging and monitoring
- **AWS EventBridge Scheduler**: SFTP start/stop scheduling
- **AWS SNS**: Daily reporting notifications

### Current Cost Breakdown (Estimated)
- **SFTP Server**: $13.50/month ✅ (already optimized)
- **Lambda Functions**: $5-10/month
- **S3 Storage**: $5-10/month
- **CloudWatch Logs**: $5-15/month ⚠️ (optimization opportunity)
- **CloudWatch Metrics**: $2-5/month
- **SNS**: $0.50-1/month
- **EventBridge Scheduler**: $0.50/month
- **Total**: $50-80/month

---

## 🎯 Cost Optimization Opportunities

### 1. **CloudWatch Log Retention** ⚠️ HIGH IMPACT

**Current State:**
- Most log groups have **no retention** (infinite storage)
- Logs accumulate forever, increasing storage costs
- Only 1 log group has 30-day retention

**Impact:**
- **Current Cost**: ~$5-15/month (growing over time)
- **After Optimization**: ~$1-3/month
- **Savings**: $4-12/month (80% reduction)

**Recommendation:**
Set log retention to **7-14 days** for all log groups:
- `/aws/lambda/valleyridge-process-inventory-incremental`: 14 days
- `/aws/lambda/valleyridge-sftp-scheduler-prod`: 7 days
- `/aws/lambda/valleyridge-file-preserver`: 7 days
- `/aws/lambda/valleyridge-process-inventory`: 14 days (already has 30 days, reduce to 14)

**Implementation:**
```bash
# Set retention for all log groups
aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-process-inventory-incremental" \
  --retention-in-days 14

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --retention-in-days 7

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-file-preserver" \
  --retention-in-days 7

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-process-inventory" \
  --retention-in-days 14
```

---

### 2. **Lambda Memory Optimization** ⚠️ MEDIUM IMPACT

**Current State:**
- **Incremental Processor**: 512MB allocated, only uses ~202MB
- **Main Processor**: 1024MB allocated (if still exists)
- **SFTP Scheduler**: 256MB (appropriate)
- **File Preserver**: 256MB (appropriate)

**Impact:**
- **Current Cost**: ~$5-10/month
- **After Optimization**: ~$3-6/month
- **Savings**: $2-4/month (40% reduction)

**Recommendation:**
- Reduce incremental processor from 512MB to **384MB** (safety margin above 202MB usage)
- This provides 25% cost reduction while maintaining performance headroom

**Lambda Pricing:**
- 512MB: $0.0000083333 per 100ms
- 384MB: $0.00000625 per 100ms
- **Savings**: 25% per execution

**Implementation:**
Update `template-incremental.yaml`:
```yaml
MemorySize: 384  # Reduced from 512
```

---

### 3. **S3 Lifecycle Policies** ⚠️ MEDIUM IMPACT

**Current State:**
- **No lifecycle policy** configured
- 409 objects, 586MB total storage
- Files accumulate indefinitely
- Old files never deleted or moved to cheaper storage

**Impact:**
- **Current Cost**: ~$5-10/month (growing over time)
- **After Optimization**: ~$2-5/month
- **Savings**: $3-5/month (50% reduction)

**Recommendation:**
Implement lifecycle policy:
1. **Incoming files**: Delete after 30 days (processed files)
2. **Delta files**: Move to Infrequent Access after 7 days, delete after 90 days
3. **Original preserved files**: Move to Glacier after 30 days, delete after 1 year
4. **Latest files**: Keep in standard storage (always needed)

**Implementation:**
```json
{
  "Rules": [
    {
      "Id": "DeleteOldIncomingFiles",
      "Status": "Enabled",
      "Prefix": "incoming/",
      "Expiration": {
        "Days": 30
      }
    },
    {
      "Id": "ArchiveDeltaFiles",
      "Status": "Enabled",
      "Prefix": "processed/delta/",
      "Transitions": [
        {
          "Days": 7,
          "StorageClass": "STANDARD_IA"
        }
      ],
      "Expiration": {
        "Days": 90
      }
    },
    {
      "Id": "ArchiveOriginalFiles",
      "Status": "Enabled",
      "Prefix": "processed/originals/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    }
  ]
}
```

---

### 4. **Lambda Timeout Optimization** ⚠️ LOW IMPACT

**Current State:**
- **Incremental Processor**: 300s timeout
- **SFTP Scheduler**: 900s timeout (15 minutes)
- **File Preserver**: 60s timeout
- **Main Processor**: 300s timeout

**Impact:**
- **Current Cost**: Minimal (only affects billing if functions timeout)
- **After Optimization**: Minimal savings, but better resource management
- **Savings**: <$1/month

**Recommendation:**
- **Incremental Processor**: Reduce to 180s (3 minutes) - processing takes ~1.6 seconds
- **SFTP Scheduler**: Keep at 900s (needed for server start/stop wait times)
- **File Preserver**: Keep at 60s (appropriate)

**Implementation:**
Update `template-incremental.yaml`:
```yaml
Timeout: 180  # Reduced from 300
```

---

### 5. **CloudWatch Metrics Optimization** ⚠️ LOW IMPACT

**Current State:**
- Custom metrics being sent to CloudWatch
- Standard CloudWatch metrics for Lambda functions

**Impact:**
- **Current Cost**: ~$2-5/month
- **After Optimization**: ~$1-3/month
- **Savings**: $1-2/month

**Recommendation:**
- Review custom metrics - only keep essential ones
- Use standard Lambda metrics where possible (free)
- Consider reducing metric resolution for non-critical metrics

---

## 📈 Expected Savings Summary

| Optimization | Current Cost | Optimized Cost | Monthly Savings | Annual Savings |
|-------------|--------------|----------------|-----------------|----------------|
| CloudWatch Log Retention | $5-15 | $1-3 | $4-12 | $48-144 |
| Lambda Memory | $5-10 | $3-6 | $2-4 | $24-48 |
| S3 Lifecycle Policies | $5-10 | $2-5 | $3-5 | $36-60 |
| Lambda Timeout | <$1 | <$1 | <$1 | <$12 |
| CloudWatch Metrics | $2-5 | $1-3 | $1-2 | $12-24 |
| **Total Additional Savings** | | | **$10-20/month** | **$120-240/year** |

---

## 🚀 Implementation Priority

### **Phase 1: Quick Wins (High Impact, Low Risk)**
1. ✅ **CloudWatch Log Retention** - Immediate savings, zero risk
2. ✅ **S3 Lifecycle Policies** - Prevents future cost growth

### **Phase 2: Performance Optimization (Medium Impact, Low Risk)**
3. ✅ **Lambda Memory Optimization** - Test first, then deploy
4. ✅ **Lambda Timeout Optimization** - Low risk, small savings

### **Phase 3: Fine-Tuning (Low Impact)**
5. ✅ **CloudWatch Metrics Review** - Review and optimize custom metrics

---

## ⚠️ Risk Assessment

### **Low Risk Optimizations:**
- ✅ CloudWatch log retention (logs older than retention period are deleted, but 7-14 days is sufficient)
- ✅ S3 lifecycle policies (files are archived/deleted based on age, but latest files are always kept)
- ✅ Lambda timeout reduction (only affects if functions timeout, which they don't)

### **Medium Risk Optimizations:**
- ⚠️ Lambda memory reduction (test first to ensure no performance degradation)

---

## 📋 Implementation Checklist

- [ ] Set CloudWatch log retention policies
- [ ] Implement S3 lifecycle policies
- [ ] Test Lambda memory reduction in staging
- [ ] Deploy Lambda memory optimization
- [ ] Optimize Lambda timeout settings
- [ ] Review and optimize CloudWatch custom metrics
- [ ] Monitor costs for 30 days after optimization
- [ ] Document actual savings achieved

---

## 🔍 Monitoring After Optimization

### **Key Metrics to Track:**
1. **Monthly AWS Cost** - Should decrease by $10-20/month
2. **CloudWatch Log Storage** - Should stabilize or decrease
3. **S3 Storage Size** - Should decrease as old files are cleaned up
4. **Lambda Performance** - Ensure no degradation after memory reduction
5. **Error Rates** - Ensure optimizations don't cause issues

### **Cost Monitoring:**
```bash
# Check CloudWatch log storage
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/valleyridge" \
  --query 'logGroups[].{Name:logGroupName,StoredBytes:storedBytes}' \
  --output table

# Check S3 storage
aws s3 ls s3://valleyridge-inventory-sync/ --recursive --summarize

# Check Lambda costs (via AWS Cost Explorer in console)
```

---

## 💡 Additional Future Optimizations

### **Long-Term Considerations:**
1. **Consolidate Lambda Functions** - Consider merging file preserver into main processor (if feasible)
2. **Reserved Capacity** - If Lambda usage becomes predictable, consider reserved capacity
3. **S3 Intelligent-Tiering** - For files with unpredictable access patterns
4. **CloudWatch Logs Insights** - Use only when needed, not continuously

---

## 📞 Next Steps

1. **Review this analysis** with the team
2. **Prioritize optimizations** based on risk tolerance
3. **Implement Phase 1 optimizations** (quick wins)
4. **Test Phase 2 optimizations** before production deployment
5. **Monitor results** for 30 days
6. **Document actual savings** achieved

---

**Last Updated:** January 2025  
**Status:** Ready for Implementation  
**Estimated Implementation Time:** 2-4 hours  
**Estimated Monthly Savings:** $10-20 (20-40% reduction from current $50-80/month)

