#!/bin/bash

# Setup script for Valley Ridge Inventory Sync Daily Reporting
# This script helps configure SNS topic and email subscriptions for daily reports

set -e

echo "🔧 Setting up Valley Ridge Inventory Sync Daily Reporting..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    print_error "SAM CLI is not installed. Please install it first."
    exit 1
fi

# Get the stack name
STACK_NAME="valleyridge-inventory-sync-incremental"
REGION="us-east-1"

print_status "Using stack: $STACK_NAME in region: $REGION"

# Deploy the updated stack with SNS topic
print_status "Deploying updated stack with SNS topic..."
cd functions/process-inventory
sam deploy --config-file samconfig-incremental.toml

if [ $? -eq 0 ]; then
    print_success "Stack deployed successfully!"
else
    print_error "Stack deployment failed!"
    exit 1
fi

# Get the SNS topic ARN from the stack output
print_status "Getting SNS topic ARN from stack output..."
SNS_TOPIC_ARN=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`DailyReportTopic`].OutputValue' \
    --output text)

if [ -z "$SNS_TOPIC_ARN" ] || [ "$SNS_TOPIC_ARN" = "None" ]; then
    print_error "Could not retrieve SNS topic ARN from stack output"
    exit 1
fi

print_success "SNS Topic ARN: $SNS_TOPIC_ARN"

# Ask for email addresses to subscribe
echo ""
print_status "Setting up email subscriptions for daily reports..."
echo "Enter email addresses to receive daily reports (press Enter after each, empty line to finish):"

EMAILS=()
while true; do
    read -p "Email address: " email
    if [ -z "$email" ]; then
        break
    fi
    
    # Basic email validation
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        EMAILS+=("$email")
        print_success "Added email: $email"
    else
        print_warning "Invalid email format: $email (skipping)"
    fi
done

if [ ${#EMAILS[@]} -eq 0 ]; then
    print_warning "No email addresses provided. You can add subscriptions later using:"
    echo "aws sns subscribe --topic-arn $SNS_TOPIC_ARN --protocol email --notification-endpoint your-email@example.com"
    exit 0
fi

# Subscribe emails to the SNS topic
print_status "Subscribing email addresses to SNS topic..."
for email in "${EMAILS[@]}"; do
    print_status "Subscribing $email..."
    
    aws sns subscribe \
        --topic-arn "$SNS_TOPIC_ARN" \
        --protocol email \
        --notification-endpoint "$email" \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        print_success "Subscription request sent to $email"
        print_warning "Check your email and confirm the subscription!"
    else
        print_error "Failed to subscribe $email"
    fi
done

echo ""
print_success "Daily reporting setup completed!"
echo ""
print_status "Next steps:"
echo "1. Check your email and confirm the SNS subscriptions"
echo "2. Test the system by uploading a file to the S3 bucket"
echo "3. Monitor CloudWatch logs for daily report notifications"
echo ""
print_status "To add more email subscriptions later:"
echo "aws sns subscribe --topic-arn $SNS_TOPIC_ARN --protocol email --notification-endpoint your-email@example.com"
echo ""
print_status "To view current subscriptions:"
echo "aws sns list-subscriptions-by-topic --topic-arn $SNS_TOPIC_ARN"
echo ""
print_status "To test the reporting system:"
echo "Upload a test file to s3://valleyridge-inventory-sync/incoming/ and check the logs"


