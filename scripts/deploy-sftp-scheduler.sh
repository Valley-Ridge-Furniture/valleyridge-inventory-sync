#!/bin/bash

# Deploy SFTP Scheduler for Cost Optimization
# This reduces AWS Transfer Family costs from $254/month to ~$50-80/month

set -e

echo "🚀 Deploying SFTP Scheduler for Cost Optimization..."

# Change to the scheduler directory
cd functions/sftp-scheduler

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Deploy the stack
echo "🚀 Deploying SFTP Scheduler stack..."
sam deploy --config-file samconfig.toml

echo "✅ SFTP Scheduler deployed successfully!"
echo ""
echo "📊 Cost Savings Summary:"
echo "  • Current cost: ~$216/month (24/7 SFTP server)"
echo "  • New cost: ~$13.50/month (1.5 hours daily)"
echo "  • Monthly savings: ~$202.50"
echo "  • Annual savings: ~$2,430"
echo ""
echo "⏰ Schedule:"
echo "  • Start: 5:30 AM EST (30 min before upload)"
echo "  • Stop: 7:00 AM ET (1 hour after upload)"
echo "  • Daily runtime: ~1.5 hours"
echo ""
echo "🔍 Monitoring:"
echo "  • CloudWatch metrics: ValleyRidge/SFTP"
echo "  • Logs: /aws/lambda/valleyridge-sftp-scheduler-prod"
echo ""
echo "🎯 Next steps:"
echo "  1. Monitor the first scheduled start/stop"
echo "  2. Set up CloudWatch alarms for failures"
echo "  3. Verify cost reduction in AWS Cost Explorer"

