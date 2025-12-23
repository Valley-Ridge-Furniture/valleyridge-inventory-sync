#!/bin/bash

# AWS Transfer Family Cost Optimization Script
# This script optimizes the SFTP server runtime window to reduce costs
# Estimated savings: $8.25-10.50/month (61-78% reduction)

set -e

echo "💰 AWS Transfer Family Cost Optimization"
echo "========================================"
echo ""
echo "Current Configuration:"
echo "  • Start: 5:30 AM EST (30 min before upload)"
echo "  • Stop: 7:00 AM EST (1 hour after upload)"
echo "  • Runtime: 1.5 hours/day"
echo "  • Monthly Cost: ~\$13.50"
echo ""
echo "Optimization Options:"
echo ""
echo "  A) Aggressive (20 min/day): Start 5:55 AM, Stop 6:15 AM"
echo "     Cost: \$3.00/month | Savings: \$10.50/month (78%)"
echo ""
echo "  B) Conservative (40 min/day): Start 5:50 AM, Stop 6:30 AM"
echo "     Cost: \$6.00/month | Savings: \$7.50/month (56%)"
echo ""
echo "  C) Balanced (35 min/day): Start 5:55 AM, Stop 6:30 AM [RECOMMENDED]"
echo "     Cost: \$5.25/month | Savings: \$8.25/month (61%)"
echo ""
read -p "Choose option (A/B/C) or 'cancel' to abort: " OPTION

case $OPTION in
  A|a)
    START_CRON="55 5 * * ? *"
    STOP_CRON="15 6 * * ? *"
    RUNTIME="20 minutes"
    COST="\$3.00"
    SAVINGS="\$10.50"
    ;;
  B|b)
    START_CRON="50 5 * * ? *"
    STOP_CRON="30 6 * * ? *"
    RUNTIME="40 minutes"
    COST="\$6.00"
    SAVINGS="\$7.50"
    ;;
  C|c)
    START_CRON="55 5 * * ? *"
    STOP_CRON="30 6 * * ? *"
    RUNTIME="35 minutes"
    COST="\$5.25"
    SAVINGS="\$8.25"
    ;;
  cancel|CANCEL)
    echo "Aborted."
    exit 0
    ;;
  *)
    echo "Invalid option. Aborted."
    exit 1
    ;;
esac

echo ""
echo "⚠️  WARNING: This will update the SFTP server schedule!"
echo ""
echo "New Configuration:"
echo "  • Start: ${START_CRON} (EST)"
echo "  • Stop: ${STOP_CRON} (EST)"
echo "  • Runtime: ${RUNTIME}/day"
echo "  • Monthly Cost: ${COST}"
echo "  • Monthly Savings: ${SAVINGS}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "🔧 Updating EventBridge schedules..."
echo ""

# Update start schedule
aws scheduler update-schedule \
  --name StartSFTPServer \
  --schedule-expression "cron(${START_CRON})" \
  --schedule-expression-timezone "America/New_York" \
  --description "Start SFTP server 5 minutes before expected upload (optimized)" \
  && echo "✅ Updated StartSFTPServer schedule" \
  || { echo "❌ Failed to update StartSFTPServer schedule"; exit 1; }

# Update stop schedule
aws scheduler update-schedule \
  --name StopSFTPServer \
  --schedule-expression "cron(${STOP_CRON})" \
  --schedule-expression-timezone "America/New_York" \
  --description "Stop SFTP server 30 minutes after expected upload (optimized)" \
  && echo "✅ Updated StopSFTPServer schedule" \
  || { echo "❌ Failed to update StopSFTPServer schedule"; exit 1; }

echo ""
echo "✅ Schedule optimization complete!"
echo ""
echo "📊 New Configuration:"
echo "  • Start: ${START_CRON} (EST)"
echo "  • Stop: ${STOP_CRON} (EST)"
echo "  • Runtime: ${RUNTIME}/day"
echo "  • Monthly Cost: ${COST}"
echo "  • Monthly Savings: ${SAVINGS}"
echo ""
echo "📋 Next Steps:"
echo "  1. Monitor the next scheduled start/stop (check tomorrow)"
echo "  2. Verify file uploads complete within the window"
echo "  3. Set up CloudWatch alarms for late uploads"
echo "  4. Monitor costs in AWS Cost Explorer after 30 days"
echo ""
echo "🔍 To verify:"
echo "  aws scheduler get-schedule --name StartSFTPServer"
echo "  aws scheduler get-schedule --name StopSFTPServer"
echo ""

