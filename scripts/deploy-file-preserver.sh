#!/bin/bash

# Deploy File Preserver Lambda
# This script deploys the file preserver Lambda function

set -e

echo "======================================"
echo "File Preserver Lambda Deployment"
echo "======================================"
echo ""

cd "$(dirname "$0")/../functions/file-preserver"

echo "Building Lambda function..."
sam build

echo ""
echo "Deploying to AWS..."
sam deploy --config-file samconfig.toml --no-confirm-changeset

echo ""
echo "✅ File Preserver Lambda deployed successfully!"
echo ""
echo "Function: valleyridge-file-preserver"
echo "Trigger: S3 ObjectCreated on processed/delta/*.csv"
echo "Action: Preserves original files to processed/originals/"
echo ""

