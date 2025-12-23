# Incremental Import System - Valley Ridge Inventory Sync

## Overview

The incremental import system processes inventory files by comparing new data with a baseline to generate delta files containing only changed records. This significantly reduces processing time and file sizes for Matrixify imports.

## How It Works

### 1. **Baseline Storage**
- The system maintains a baseline file (`baseline/inventory-baseline.json`) containing the last processed inventory data
- This baseline serves as the reference point for change detection

### 2. **Change Detection Process**
When a new inventory file is uploaded:

1. **Load Baseline**: Retrieve the previous baseline data from S3
2. **Process New File**: Convert the new file (Excel .xls/.xlsx or CSV) to structured data
3. **Preserve Original**: Copy original file to `processed/originals/` with timestamp
4. **Compare Data**: Identify changes between new and baseline data
5. **Generate Delta**: Create a CSV file with only changed records
6. **Update Baseline**: Save the new data as the new baseline
7. **Send Daily Report**: Automatically send processing summary via SNS

### 3. **Change Types Detected**

#### **New Products** (`changeType: 'new'`)
- UPCs that exist in the new file but not in the baseline
- These are new products added to the inventory

#### **Updated Products** (`changeType: 'updated'`)
- UPCs that exist in both files but have different values for:
  - `Variant Inventory Qty` (quantity changes)
  - `Variant Metafield: custom.internal_discontinued [single_line_text_field]` (discontinued status changes)

**Important**: The system tracks discontinued status changes independently of quantity changes. This means:
- A product with only discontinued status changes (no quantity change) will be included in the delta file
- This ensures Shopify receives updates for discontinued status changes even when inventory quantities remain the same
- Change reasons will clearly indicate "Discontinued status changed" for these updates

#### **Deleted Products** (`changeType: 'deleted'`)
- UPCs that exist in the baseline but not in the new file
- These products are set to quantity 0 and marked as removed
- **Daily Reporting**: UPC/Variant Barcodes are included in daily reports for store review
- **Context Information**: Shows last known quantity and discontinued status

## File Structure

```
S3 Bucket: valleyridge-inventory-sync/
├── incoming/                    # Original files from vendor (.xls, .xlsx, .csv)
├── processed/
│   ├── delta/                   # Delta files (only changes)
│   │   └── loloi-inventory-delta-2024-01-15T10-00-00-000Z.csv
│   ├── latest/
│   │   └── inventory-delta.csv  # Latest delta file for Matrixify
│   └── originals/               # Preserved original files with timestamps
│       └── Loloi_Inventory w. UPC-2024-01-15T10-00-00-000Z.csv
└── baseline/
    └── inventory-baseline.json  # Baseline data for comparison
```

## Delta File Format

The delta CSV files include all standard Matrixify columns plus change tracking and tags:

```csv
Variant Barcode,Variant Inventory Qty,Variant Metafield: custom.internal_discontinued [single_line_text_field],changeType,changeReason,Tags
1234567890123,50,No,new,New product,
9876543210987,25,No,updated,Quantity changed from 30 to 25,
5556667778889,0,Yes,deleted,Product removed from inventory,Discontinued
```

### **Tags Column**
- **Purpose**: Provides product categorization for Shopify/Matrixify imports
- **Discontinued Items**: Items with `discontinued = Yes` automatically get `Tags: "Discontinued"`
- **Active Items**: Items with `discontinued = No` have empty Tags column
- **All Change Types**: Tags column is included for new, updated, and deleted products

## Benefits

### **Performance Improvements**
- **Smaller Files**: Delta files typically contain 5-20% of the original data
- **Faster Processing**: Reduced Matrixify import time
- **Lower Bandwidth**: Smaller file transfers
- **Reduced Costs**: Less S3 storage and transfer costs

### **Operational Benefits**
- **Better Tracking**: Clear visibility into what changed
- **Audit Trail**: Change reasons provide context
- **Error Recovery**: Easier to identify and fix import issues
- **Monitoring**: Detailed metrics on change patterns

## Implementation

### **Deployment**

1. **Deploy the Incremental Processor**:
   ```bash
   cd functions/process-inventory
   sam deploy --config-file samconfig-incremental.toml
   ```

2. **Update S3 Notifications** (if needed):
   ```bash
   aws s3api put-bucket-notification-configuration \
     --bucket valleyridge-inventory-sync \
     --notification-configuration file://s3-notification-incremental.json
   ```

### **Configuration**

The system can be configured via environment variables:

- `S3_BUCKET`: S3 bucket name (default: valleyridge-inventory-sync)
- `SUPPORT_EMAIL`: Email for error notifications
- `LOG_LEVEL`: Logging level (INFO, DEBUG, ERROR)
- `SNS_TOPIC_ARN`: SNS topic ARN for daily reports and error notifications

### **File Format Support**

The system supports multiple file formats:
- **Excel Files**: `.xls` and `.xlsx` formats
- **CSV Files**: Direct CSV processing with support for Loloi's format
- **Column Mapping**: Automatically handles different column names:
  - Quantity: `Available Qty` or `ATSQty`
  - UPC: `UPC` (case-insensitive)
  - Discontinued: `Discontinued` (case-insensitive)

## Daily Reporting System

### **Automated Daily Reports**

The system automatically sends detailed daily reports via SNS notifications after each processing run:

#### **Report Contents**
- **Processing Summary**: Total records processed, delta records generated
- **Change Breakdown**: 
  - Inventory changes only
  - Discontinued status changes only  
  - Both inventory and discontinued changes
- **Discontinued with Zero Inventory**: List of UPCs that are discontinued and have zero inventory
- **Tags Column**: All delta files now include Tags column for discontinued product categorization
- **Processing Status**: Success/failure status and file locations

#### **Report Format**
```
📊 Valley Ridge Inventory Sync - Daily Report
⏰ Processed: Jan 15, 2024, 6:05 AM EST
📁 File: incoming/loloi-inventory-2024-01-15.xlsx

📈 SUMMARY:
• Total Records Processed: 43,188
• Delta Records Generated: 1,247
• New Products: 23
• Updated Products: 1,201
• Deleted Products: 23

🔄 CHANGE BREAKDOWN:
• Inventory Changes Only: 1,156
• Discontinued Status Changes Only: 32
• Both Changes: 13

⚠️ DISCONTINUED WITH ZERO INVENTORY (45 items):
• UPC: 123456789012
• UPC: 987654321098
• ... and 43 more

✅ Status: success
📊 Delta file: processed/delta/loloi-inventory-delta-2024-01-15T06-05-00-000Z.csv
```

### **Setup Daily Reports**

1. **Deploy with SNS Support**:
   ```bash
   ./scripts/setup-daily-reporting.sh
   ```

2. **Subscribe Email Addresses**: The script will prompt for email addresses to receive reports

3. **Confirm Subscriptions**: Check email and confirm SNS subscriptions

### **Manual Subscription Management**

```bash
# Add email subscription
aws sns subscribe --topic-arn arn:aws:sns:us-east-1:ACCOUNT:valleyridge-inventory-daily-reports \
  --protocol email --notification-endpoint your-email@example.com

# List current subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT:valleyridge-inventory-daily-reports
```

## Monitoring and Metrics

### **CloudWatch Metrics**

The system sends detailed metrics to CloudWatch:

- `FilesProcessed`: Number of files processed
- `TotalRecordsProcessed`: Total records in new files
- `DeltaRecordsGenerated`: Number of records in delta files
- `ProcessingTime`: Time taken to process files
- `Errors`: Error count by type

### **Log Analysis**

Key log entries to monitor:

```
[request-id] Generating delta: 1000 new vs 950 baseline
[request-id] Delta generated: 45 changes
[request-id] - New: 12
[request-id] - Updated: 28
[request-id] - Deleted: 5
```

## Migration from Full Import

### **Phase 1: Parallel Deployment**
1. Deploy incremental processor alongside existing system
2. Test with sample files
3. Verify delta generation and baseline storage

### **Phase 2: Gradual Transition**
1. Process one file with incremental system
2. Compare results with full import
3. Validate Matrixify import success

### **Phase 3: Full Switch**
1. Update S3 notifications to use incremental processor
2. Monitor performance improvements
3. Archive old full-import files

## Troubleshooting

### **Common Issues**

#### **No Baseline Found**
- **Symptom**: "No baseline found, starting fresh"
- **Cause**: First run or baseline file deleted
- **Solution**: System will create new baseline from first file

#### **Large Delta Files**
- **Symptom**: Delta file size similar to full file
- **Cause**: Many changes or baseline corruption
- **Solution**: Check baseline file integrity, consider baseline reset

#### **Missing Changes**
- **Symptom**: Expected changes not in delta file
- **Cause**: Data format issues or comparison logic
- **Solution**: Check data format, review change detection logic

### **Baseline Management**

#### **Reset Baseline**
To reset the baseline (start fresh):
```bash
aws s3 rm s3://valleyridge-inventory-sync/baseline/inventory-baseline.json
```

#### **Backup Baseline**
To backup the current baseline:
```bash
aws s3 cp s3://valleyridge-inventory-sync/baseline/inventory-baseline.json \
  s3://valleyridge-inventory-sync/baseline/backup/inventory-baseline-$(date +%Y%m%d).json
```

## Security Considerations

- **Baseline Data**: Contains sensitive inventory information
- **Access Control**: Baseline files should have restricted access
- **Encryption**: All data encrypted in transit and at rest
- **Audit Logging**: All baseline changes logged

## Future Enhancements

### **Advanced Features**
- **Change Thresholds**: Only include changes above certain thresholds
- **Batch Processing**: Process multiple files in sequence
- **Change Summaries**: Generate change summary reports
- **Rollback Capability**: Ability to revert to previous baseline

### **Integration Options**
- **Email Notifications**: Send change summaries via email
- **Slack Integration**: Post change notifications to Slack
- **Dashboard**: Web dashboard for monitoring changes
- **API Endpoints**: REST API for manual baseline management 