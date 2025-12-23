# Cost Optimization Quick Start Guide

**Estimated Savings:** $10-20/month (20-40% reduction from current $50-80/month)  
**Implementation Time:** 15-30 minutes  
**Risk Level:** Low to Medium

---

## 🚀 Quick Implementation

### Option 1: Automated Script (Recommended)
```bash
./scripts/optimize-aws-costs.sh
```

This script will:
- ✅ Set CloudWatch log retention (7-14 days)
- ✅ Implement S3 lifecycle policies
- ✅ Optimize Lambda memory (optional, with confirmation)

### Option 2: Manual Implementation

#### Step 1: CloudWatch Log Retention (5 minutes)
```bash
# Set retention for all Lambda log groups
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

**Savings:** $4-12/month

---

#### Step 2: S3 Lifecycle Policies (5 minutes)
```bash
# Create lifecycle policy file
cat > lifecycle-policy.json <<EOF
{
  "Rules": [
    {
      "Id": "DeleteOldIncomingFiles",
      "Status": "Enabled",
      "Filter": {"Prefix": "incoming/"},
      "Expiration": {"Days": 30}
    },
    {
      "Id": "ArchiveDeltaFiles",
      "Status": "Enabled",
      "Filter": {"Prefix": "processed/delta/"},
      "Transitions": [{"Days": 7, "StorageClass": "STANDARD_IA"}],
      "Expiration": {"Days": 90}
    },
    {
      "Id": "ArchiveOriginalFiles",
      "Status": "Enabled",
      "Filter": {"Prefix": "processed/originals/"},
      "Transitions": [{"Days": 30, "StorageClass": "GLACIER"}],
      "Expiration": {"Days": 365}
    }
  ]
}
EOF

# Apply policy
aws s3api put-bucket-lifecycle-configuration \
  --bucket valleyridge-inventory-sync \
  --lifecycle-configuration file://lifecycle-policy.json

# Clean up
rm lifecycle-policy.json
```

**Savings:** $3-5/month

---

#### Step 3: Lambda Memory Optimization (Optional, 2 minutes)
```bash
# Reduce incremental processor from 512MB to 384MB
aws lambda update-function-configuration \
  --function-name valleyridge-process-inventory-incremental \
  --memory-size 384
```

**Savings:** $2-4/month  
**Note:** Test first to ensure no performance issues. Current usage is ~202MB, so 384MB provides good headroom.

---

## 📊 Verify Optimizations

### Check Log Retention
```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/valleyridge" \
  --query 'logGroups[].{Name:logGroupName,Retention:retentionInDays}' \
  --output table
```

### Check S3 Lifecycle Policy
```bash
aws s3api get-bucket-lifecycle-configuration \
  --bucket valleyridge-inventory-sync
```

### Check Lambda Memory
```bash
aws lambda get-function-configuration \
  --function-name valleyridge-process-inventory-incremental \
  --query '{Memory:MemorySize,Timeout:Timeout}' \
  --output json
```

---

## 💰 Expected Results

| Optimization | Monthly Savings | Annual Savings |
|-------------|-----------------|----------------|
| CloudWatch Log Retention | $4-12 | $48-144 |
| S3 Lifecycle Policies | $3-5 | $36-60 |
| Lambda Memory | $2-4 | $24-48 |
| **Total** | **$10-20** | **$120-240** |

---

## ⚠️ Important Notes

1. **CloudWatch Logs**: Logs older than retention period will be deleted. 7-14 days is sufficient for troubleshooting.

2. **S3 Lifecycle**: 
   - Files in `incoming/` will be deleted after 30 days
   - Delta files will move to cheaper storage after 7 days
   - Original files will archive to Glacier after 30 days
   - **Latest files are always kept** in standard storage

3. **Lambda Memory**: Monitor for 1-2 weeks after optimization to ensure no performance issues.

---

## 🔍 Monitoring

### Check Costs After 30 Days
```bash
# View in AWS Cost Explorer (web console)
# Or check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Billing \
  --metric-name EstimatedCharges \
  --start-time $(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Maximum
```

### Monitor Lambda Performance
```bash
# Check for errors or timeouts
aws logs filter-log-events \
  --log-group-name "/aws/lambda/valleyridge-process-inventory-incremental" \
  --start-time $(($(date +%s) - 86400))000 \
  --filter-pattern "ERROR"
```

---

## 📞 Support

For questions or issues:
1. Review `COST_OPTIMIZATION_ANALYSIS.md` for detailed information
2. Check AWS CloudWatch logs for any errors
3. Monitor AWS Cost Explorer for actual savings

---

**Last Updated:** January 2025  
**Status:** Ready to Implement

