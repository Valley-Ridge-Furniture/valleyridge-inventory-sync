#!/bin/bash

# AWS Cost Optimization Script
# This script implements cost-saving optimizations identified in COST_OPTIMIZATION_ANALYSIS.md
# Estimated savings: $10-20/month (20-40% reduction)

set -e

echo "💰 AWS Cost Optimization Script"
echo "================================"
echo ""
echo "This script will implement the following optimizations:"
echo "  1. Set CloudWatch log retention (saves $4-12/month)"
echo "  2. Implement S3 lifecycle policies (saves $3-5/month)"
echo "  3. Optimize Lambda memory allocation (saves $2-4/month)"
echo ""
echo "Total estimated savings: $10-20/month"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "🔧 Starting optimization..."
echo ""

# Configuration
S3_BUCKET="valleyridge-inventory-sync"
INCREMENTAL_FUNCTION="valleyridge-process-inventory-incremental"

# Phase 1: CloudWatch Log Retention
echo "📊 Phase 1: Setting CloudWatch Log Retention..."
echo ""

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-process-inventory-incremental" \
  --retention-in-days 14 \
  && echo "✅ Set 14-day retention for incremental processor" \
  || echo "⚠️  Failed to set retention for incremental processor"

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-sftp-scheduler-prod" \
  --retention-in-days 7 \
  && echo "✅ Set 7-day retention for SFTP scheduler" \
  || echo "⚠️  Failed to set retention for SFTP scheduler"

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-file-preserver" \
  --retention-in-days 7 \
  && echo "✅ Set 7-day retention for file preserver" \
  || echo "⚠️  Failed to set retention for file preserver"

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/valleyridge-process-inventory" \
  --retention-in-days 14 \
  && echo "✅ Set 14-day retention for main processor" \
  || echo "⚠️  Failed to set retention for main processor"

echo ""
echo "✅ Phase 1 complete: CloudWatch log retention configured"
echo ""

# Phase 2: S3 Lifecycle Policies
echo "📦 Phase 2: Implementing S3 Lifecycle Policies..."
echo ""

# Create lifecycle policy JSON
LIFECYCLE_POLICY=$(cat <<EOF
{
  "Rules": [
    {
      "Id": "DeleteOldIncomingFiles",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "incoming/"
      },
      "Expiration": {
        "Days": 30
      }
    },
    {
      "Id": "ArchiveDeltaFiles",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "processed/delta/"
      },
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
      "Filter": {
        "Prefix": "processed/originals/"
      },
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
EOF
)

# Save policy to temp file
TEMP_POLICY=$(mktemp)
echo "$LIFECYCLE_POLICY" > "$TEMP_POLICY"

# Apply lifecycle policy
aws s3api put-bucket-lifecycle-configuration \
  --bucket "$S3_BUCKET" \
  --lifecycle-configuration "file://$TEMP_POLICY" \
  && echo "✅ S3 lifecycle policy applied successfully" \
  || echo "⚠️  Failed to apply S3 lifecycle policy"

# Clean up temp file
rm "$TEMP_POLICY"

echo ""
echo "✅ Phase 2 complete: S3 lifecycle policies configured"
echo ""

# Phase 3: Lambda Memory Optimization
echo "⚡ Phase 3: Optimizing Lambda Memory Allocation..."
echo ""
echo "⚠️  WARNING: This will update the Lambda function configuration."
echo "    The incremental processor will be reduced from 512MB to 384MB."
echo "    This should be safe based on actual usage (~202MB), but monitor for issues."
echo ""
read -p "Continue with Lambda memory optimization? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    aws lambda update-function-configuration \
      --function-name "$INCREMENTAL_FUNCTION" \
      --memory-size 384 \
      && echo "✅ Lambda memory optimized: 512MB → 384MB" \
      || echo "⚠️  Failed to update Lambda memory"
else
    echo "⏭️  Skipping Lambda memory optimization"
fi

echo ""
echo "✅ Phase 3 complete: Lambda memory optimization"
echo ""

# Summary
echo ""
echo "🎉 Cost Optimization Complete!"
echo "================================"
echo ""
echo "✅ Implemented optimizations:"
echo "  • CloudWatch log retention: 7-14 days"
echo "  • S3 lifecycle policies: Auto-archive and delete old files"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  • Lambda memory: Reduced from 512MB to 384MB"
fi
echo ""
echo "💰 Expected savings: $10-20/month"
echo ""
echo "📊 Next steps:"
echo "  1. Monitor AWS costs for 30 days"
echo "  2. Check CloudWatch logs for any issues"
echo "  3. Verify S3 lifecycle policies are working (check after 7-30 days)"
echo "  4. Review actual savings in AWS Cost Explorer"
echo ""
echo "🔍 To verify optimizations:"
echo "  • Check log retention: aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/valleyridge'"
echo "  • Check lifecycle policy: aws s3api get-bucket-lifecycle-configuration --bucket $S3_BUCKET"
echo "  • Check Lambda memory: aws lambda get-function-configuration --function-name $INCREMENTAL_FUNCTION"
echo ""

