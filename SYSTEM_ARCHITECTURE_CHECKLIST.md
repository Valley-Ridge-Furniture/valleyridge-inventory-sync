# System Architecture Checklist

## 🚨 **CRITICAL: Always Check System Architecture Before Making Changes**

### **System Overview**
- **Main Processor** (`valleyridge-process-inventory`): Basic file conversion, NO incremental processing, NO daily reporting
- **Incremental Processor** (`valleyridge-process-inventory-incremental`): Delta processing, baseline comparison, daily reporting

### **File Routing**
- **CSV files** → `valleyridge-process-inventory-incremental` (has SNS, daily reports)
- **Excel files** → `valleyridge-process-inventory-incremental` (has SNS, daily reports)
- **All files** → S3 bucket `valleyridge-inventory-sync`

### **Before Making ANY Changes**

#### ✅ **Step 1: Identify the Correct System**
1. **What type of file?** (CSV, Excel, etc.)
2. **What processing is needed?** (Basic conversion vs. Incremental/delta)
3. **What notifications are needed?** (Daily reports, SNS, etc.)

#### ✅ **Step 2: Check Current Architecture**
```bash
# Check S3 notifications
aws s3api get-bucket-notification-configuration --bucket valleyridge-inventory-sync

# Check Lambda function configurations
aws lambda get-function --function-name valleyridge-process-inventory --query 'Configuration.Environment.Variables'
aws lambda get-function --function-name valleyridge-process-inventory-incremental --query 'Configuration.Environment.Variables'
```

#### ✅ **Step 3: Verify Function Capabilities**
- **Main Processor**: Only basic file conversion
- **Incremental Processor**: Has SNS, daily reporting, delta processing

### **Common Mistakes to Avoid**

❌ **DON'T**: Update main processor for incremental features
❌ **DON'T**: Add SNS to main processor (it doesn't have daily reporting)
❌ **DON'T**: Assume both processors have the same capabilities
❌ **DON'T**: Work on deprecated/old systems without checking current architecture

✅ **DO**: Always check which function processes which file types
✅ **DO**: Verify function capabilities before making changes
✅ **DO**: Test changes with actual file types
✅ **DO**: Document which system handles what

### **Quick Reference**

| Feature | Main Processor | Incremental Processor |
|---------|---------------|----------------------|
| CSV Processing | ❌ | ✅ |
| Excel Processing | ✅ | ✅ |
| Delta Processing | ❌ | ✅ |
| Daily Reports | ❌ | ✅ |
| SNS Notifications | ❌ | ✅ |
| Baseline Comparison | ❌ | ✅ |

### **Testing Checklist**
1. ✅ Test with actual file types (CSV, Excel)
2. ✅ Verify daily reports are sent
3. ✅ Check CloudWatch logs for both functions
4. ✅ Confirm S3 notifications are correct
5. ✅ Validate delta processing works

---
**Last Updated**: September 10, 2025
**Reason**: Fixed CSV processing and daily reporting system
