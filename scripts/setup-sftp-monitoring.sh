#!/bin/bash

# Setup CloudWatch Monitoring for SFTP Scheduler
# This creates alarms to alert on failures

set -e

FUNCTION_NAME="valleyridge-sftp-scheduler-prod"
ALARM_TOPIC_ARN="arn:aws:sns:us-east-1:413362489612:valleyridge-alerts"

echo "🔔 Setting up SFTP Scheduler Monitoring..."
echo ""

# Create SNS topic if it doesn't exist
echo "📧 Creating SNS topic for alerts..."
aws sns create-topic --name valleyridge-alerts --region us-east-1 2>/dev/null || echo "Topic already exists"
echo ""

# Create CloudWatch alarms
echo "🚨 Creating CloudWatch alarms..."

# Alarm for Lambda function errors
aws cloudwatch put-metric-alarm \
  --alarm-name "SFTP-Scheduler-Errors" \
  --alarm-description "Alert when SFTP scheduler encounters errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions $ALARM_TOPIC_ARN \
  --dimensions Name=FunctionName,Value=$FUNCTION_NAME
echo "✅ Error alarm created"

# Alarm for SFTP server not starting
aws cloudwatch put-metric-alarm \
  --alarm-name "SFTP-Server-Start-Failure" \
  --alarm-description "Alert when SFTP server fails to start" \
  --metric-name SFTP_Action_Error \
  --namespace ValleyRidge/SFTP \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions $ALARM_TOPIC_ARN \
  --dimensions Name=Action,Value=start
echo "✅ Start failure alarm created"

# Alarm for SFTP server not stopping
aws cloudwatch put-metric-alarm \
  --alarm-name "SFTP-Server-Stop-Failure" \
  --alarm-description "Alert when SFTP server fails to stop" \
  --metric-name SFTP_Action_Error \
  --namespace ValleyRidge/SFTP \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions $ALARM_TOPIC_ARN \
  --dimensions Name=Action,Value=stop
echo "✅ Stop failure alarm created"

# Alarm for processing failures
aws cloudwatch put-metric-alarm \
  --alarm-name "Inventory-Processing-Failure" \
  --alarm-description "Alert when inventory processing fails" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions $ALARM_TOPIC_ARN \
  --dimensions Name=FunctionName,Value=valleyridge-process-inventory
echo "✅ Processing failure alarm created"

echo ""
echo "✅ Monitoring setup complete!"
echo ""
echo "📊 Alarms created:"
echo "  • SFTP-Scheduler-Errors"
echo "  • SFTP-Server-Start-Failure"
echo "  • SFTP-Server-Stop-Failure"
echo "  • Inventory-Processing-Failure"
echo ""
echo "📧 SNS Topic: $ALARM_TOPIC_ARN"
echo ""
echo "💡 Next steps:"
echo "  1. Subscribe to SNS topic for email alerts"
echo "  2. Test alarms by manually triggering failures"
echo "  3. Monitor CloudWatch dashboard for daily operations"

