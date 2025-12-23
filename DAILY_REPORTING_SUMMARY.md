# Daily Reporting System - Valley Ridge Inventory Sync

## 🎯 **Overview**

The daily reporting system provides comprehensive visibility into inventory processing, specifically tracking discontinued status changes and ensuring reliable verification that the delta processing is working correctly each day.

## 📊 **What You'll Receive Daily**

### **Email Report Contents**

After each inventory file is processed, you'll receive a detailed email report containing:

1. **📈 Processing Summary**
   - Total records processed
   - Delta records generated (only changed records)
   - New products added
   - Updated products
   - Deleted products

2. **🔄 Change Breakdown**
   - **Inventory Changes Only**: Products where only quantity changed
   - **Discontinued Status Changes Only**: Products where only discontinued status changed
   - **Both Changes**: Products where both quantity and discontinued status changed

3. **🗑️ Deleted Products (Enhanced)**
   - Complete list of UPC/Variant Barcodes that were removed from Loloi's daily file
   - Shows last known quantity and discontinued status for context
   - Explains that these are likely discontinued products with zero inventory
   - Provides actionable list for store review and updates

4. **✅ Processing Status**
   - Success/failure status
   - File locations and timestamps

## 🔧 **Setup Instructions**

### **1. Deploy the Updated System**

```bash
cd /Users/dl/Documents/valleyridge-inventory-sync
./scripts/setup-daily-reporting.sh
```

This script will:
- Deploy the updated Lambda function with reporting capabilities
- Create the SNS topic for notifications
- Prompt you to enter email addresses for reports
- Set up email subscriptions

### **2. Confirm Email Subscriptions**

After running the setup script:
1. Check your email for SNS subscription confirmation messages
2. Click the confirmation links in each email
3. You'll start receiving daily reports after the next file is processed

## 📧 **Sample Daily Report**

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
• UPC: 555666777888
• ... and 42 more

✅ Status: success
📊 Delta file: processed/delta/loloi-inventory-delta-2024-01-15T06-05-00-000Z.csv
```

## 🔍 **Key Metrics to Monitor**

### **Daily Verification Checklist**

1. **✅ Discontinued Status Changes Are Tracked**
   - Look for "Discontinued Status Changes Only" count > 0
   - This confirms discontinued status changes are being detected independently

2. **✅ Inventory Changes Are Tracked**
   - Look for "Inventory Changes Only" count > 0
   - This confirms quantity changes are being detected

3. **✅ Both Types of Changes Are Tracked**
   - Look for "Both Changes" count > 0
   - This confirms products with both changes are properly categorized

4. **✅ Discontinued with Zero Inventory List**
   - Review the list of discontinued items with zero inventory
   - These should be removed from sale in Shopify

### **Expected Daily Patterns**

- **Normal Day**: 50-200 delta records with mix of inventory and discontinued changes
- **High Change Day**: 500+ delta records (new product launches, major updates)
- **Low Change Day**: 10-50 delta records (minimal updates)

## 🛠️ **Management Commands**

### **Add More Email Subscriptions**

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT:valleyridge-inventory-daily-reports \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### **List Current Subscriptions**

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT:valleyridge-inventory-daily-reports
```

### **Remove Email Subscription**

```bash
aws sns unsubscribe --subscription-arn SUBSCRIPTION_ARN
```

## 🚨 **Troubleshooting**

### **No Reports Received**

1. **Check SNS Subscriptions**: Ensure email subscriptions are confirmed
2. **Check Lambda Logs**: Look for errors in CloudWatch logs
3. **Verify SNS Topic**: Ensure the topic ARN is correctly configured

### **Missing Change Types**

1. **Check Change Detection Logic**: Verify the hasChanges function is working
2. **Review Baseline Data**: Ensure baseline is being updated correctly
3. **Check Data Format**: Verify Excel file format matches expected columns

### **Incorrect Discontinued Tracking**

1. **Verify Column Mapping**: Ensure "Discontinued" column is mapped correctly
2. **Check Data Values**: Verify discontinued values are "Yes"/"No" format
3. **Review Change Reasons**: Check if change reasons include discontinued status

## 📈 **Benefits**

### **Operational Benefits**
- **Daily Verification**: Confirm system is working correctly each day
- **Change Visibility**: See exactly what changed in your inventory
- **Discontinued Tracking**: Ensure discontinued products are properly updated
- **Zero Inventory Alerts**: Identify products that should be removed from sale

### **Business Benefits**
- **Data Accuracy**: Ensure Shopify inventory matches vendor data
- **Customer Experience**: Prevent sales of discontinued/out-of-stock items
- **Operational Efficiency**: Automated monitoring reduces manual checks
- **Audit Trail**: Complete record of all inventory changes

## 🔄 **Integration with Existing Workflow**

The daily reporting system integrates seamlessly with your existing workflow:

1. **6:00 AM**: Loloi uploads file via SFTP
2. **6:00-6:05 AM**: Lambda processes file and generates delta
3. **6:05 AM**: Daily report email sent to subscribers
4. **7:00 AM**: Matrixify imports delta file to Shopify
5. **8:00 AM**: SFTP server stops

The daily report provides verification that steps 2-4 completed successfully and shows exactly what changes were processed.

## 📞 **Support**

If you encounter any issues with the daily reporting system:

1. Check the CloudWatch logs for the Lambda function
2. Verify SNS topic and subscription status
3. Review the change detection logic in the code
4. Contact support with specific error messages or unexpected behavior

The reporting system is designed to be reliable and provide clear visibility into your inventory synchronization process.


