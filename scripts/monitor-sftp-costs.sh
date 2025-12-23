#!/bin/bash

# Monitor SFTP Server Status and Costs
# This script helps track the cost optimization implementation

set -e

SFTP_SERVER_ID="s-34ce3bb4895a4fac8"
FUNCTION_NAME="valleyridge-sftp-scheduler-prod"

echo "🔍 Valley Ridge SFTP Cost Optimization Monitor"
echo "=============================================="
echo ""

# Check SFTP server status
echo "📊 SFTP Server Status:"
aws transfer describe-server --server-id $SFTP_SERVER_ID --query 'Server.{State:State,Endpoint:EndpointDetails.Address,LastModified:LastModified}' --output table
echo ""

# Check recent Lambda executions
echo "⏰ Recent Scheduler Executions:"
aws logs describe-log-streams --log-group-name "/aws/lambda/$FUNCTION_NAME" --order-by LastEventTime --descending --max-items 3 --query 'logStreams[].{LogStream:logStreamName,LastEvent:lastEventTimestamp}' --output table
echo ""

# Compute timestamps (portable across BSD/GNU date)
START_TIME=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(hours=24)).strftime('%Y-%m-%dT%H:%M:%S'))
PY
)

END_TIME=$(python3 - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S'))
PY
)

# Check CloudWatch metrics
echo "📈 CloudWatch Metrics (Last 24 hours):"
aws cloudwatch get-metric-statistics \
  --namespace "ValleyRidge/SFTP" \
  --metric-name "SFTP_Action_Success" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 3600 \
  --statistics Sum \
  --query 'Datapoints[].{Time:Timestamp,SuccessCount:Sum}' \
  --output table
echo ""

# Check for errors
echo "🚨 Recent Errors:"
START_EPOCH_MS=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
import math
start = datetime.now(timezone.utc) - timedelta(hours=24)
print(math.floor(start.timestamp() * 1000))
PY
)
aws logs filter-log-events \
  --log-group-name "/aws/lambda/$FUNCTION_NAME" \
  --start-time "$START_EPOCH_MS" \
  --filter-pattern "ERROR" \
  --query 'events[].{Time:timestamp,Message:message}' \
  --output table
echo ""

# Cost estimation
echo "💰 Cost Estimation:"
echo '  • Current setup: SFTP server running 24/7'
echo '  • Transfer Family cost: ~$0.30/hour = $216/month'
echo '  • With scheduler: ~1.5 hours/day = $13.50/month'
echo '  • Estimated savings: $202.50/month'
echo ""

# Next scheduled events (EventBridge Scheduler)
echo "⏰ Next Scheduled Events (Scheduler):"
for schedule in StartSFTPServer StopSFTPServer; do
  if ! aws scheduler get-schedule --name "$schedule" \
    --query '{Name:Name,Expression:ScheduleExpression,Timezone:ScheduleExpressionTimezone,State:State,NextInvocation:NextInvocationTime}' \
    --output table; then
    echo "  • ${schedule}: schedule not found"
  fi
done
echo ""

echo "✅ Monitor complete!"
echo ""
echo "💡 Tips:"
echo "  • Check this daily to ensure scheduler is working"
echo "  • Set up CloudWatch alarms for failures"
echo "  • Monitor AWS Cost Explorer for actual savings"

