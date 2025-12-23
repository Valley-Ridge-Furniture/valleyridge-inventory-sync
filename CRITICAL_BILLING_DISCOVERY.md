# 🚨 CRITICAL DISCOVERY: AWS Transfer Family Billing Model

**Date:** January 2025  
**Status:** 🔴 **URGENT - Complete Strategy Change Required**

---

## 💡 **Critical Finding**

### **AWS Transfer Family Billing Reality:**

> **"Stopping an AWS Transfer Family server does not reduce or impact your billing; you must delete the server to stop being billed."**

**Source:** [AWS Transfer Family API Documentation](https://docs.aws.amazon.com/transfer/latest/APIReference/API_StopServer.html)

### **How AWS Transfer Family Actually Bills:**

- **Billing starts:** When you create and configure the server endpoint
- **Billing continues:** Hourly for each protocol enabled
- **Billing stops:** Only when you **DELETE** the server
- **Stopping the server:** Does NOT stop billing

---

## 🔍 **What This Means for Our System**

### **Current Approach (WRONG):**
- ✅ Scheduler is working (server goes OFFLINE)
- ❌ But billing continues because we're only stopping, not deleting
- ❌ Costs remain at $216/month despite scheduler working

### **Why Billing Shows 24/7:**
- Server was created and never deleted
- Billing continues 24/7 regardless of server state (ONLINE/OFFLINE)
- Stopping the server doesn't impact ProtocolHours billing

---

## 📊 **Evidence from Logs**

### **Scheduler IS Working:**
- ✅ Logs show server going OFFLINE regularly
- ✅ Server state transitions: ONLINE → STOPPING → OFFLINE
- ✅ Stop schedule is executing successfully

### **But Billing Continues:**
- ❌ October: 744 hours billed (24/7)
- ❌ November: 720 hours billed (24/7)
- ❌ December: 432 hours billed (24/7 for 18 days)

**Conclusion:** Server is being stopped, but AWS continues billing because the server endpoint still exists.

---

## 🚀 **Required Solution: Delete/Recreate Strategy**

### **New Approach:**

Instead of **Stop/Start**, we need **Delete/Create**:

1. **Before Upload Window:**
   - Create new server endpoint
   - Configure server settings
   - Server becomes available for uploads

2. **After Upload Window:**
   - Delete the server endpoint
   - Billing stops immediately
   - No charges until next creation

### **Implementation Changes Needed:**

1. **Lambda Function Changes:**
   - Replace `startServer()` / `stopServer()` with `createServer()` / `deleteServer()`
   - Store server configuration for recreation
   - Handle server ID changes (new ID each time)

2. **Configuration Management:**
   - Store server config in Parameter Store or S3
   - Recreate server with same settings each time
   - Update any hardcoded server IDs

3. **Vendor Configuration:**
   - May need to update SFTP connection details if server ID changes
   - Or use a static endpoint/DNS that points to current server

---

## 💰 **Expected Savings After Fix**

### **Current (Stop/Start - Not Working):**
- **Cost:** $216/month (billing continues 24/7)
- **Runtime:** Server offline but still billed

### **After Fix (Delete/Create):**
- **Cost:** $13.50/month (1.5 hours/day × $0.30/hour)
- **Savings:** $202.50/month (94% reduction)

### **Optimized (35 minutes/day):**
- **Cost:** $5.25/month
- **Savings:** $210.75/month (97.6% reduction)

---

## ⚠️ **Challenges with Delete/Create Approach**

### **1. Server ID Changes**
- Each new server gets a new ID
- Vendor SFTP connection may need updates
- Solution: Use DNS/endpoint that routes to current server

### **2. Configuration Recreation**
- Need to store and recreate:
  - Identity provider settings
  - User accounts
  - S3 bucket mappings
  - Security policies
- Solution: Store config in Parameter Store, recreate from template

### **3. Server Creation Time**
- Takes ~2-3 minutes to create and configure
- Need to account for this in schedule
- Solution: Start creation earlier (e.g., 5:25 AM instead of 5:30 AM)

### **4. Data Safety**
- Deleting server doesn't affect S3 data (confirmed by AWS)
- But need to ensure no active transfers during deletion
- Solution: Wait for transfers to complete before deleting

---

## 🔧 **Alternative Solutions**

### **Option 1: Delete/Create Daily (Recommended)**
- **Pros:** Stops billing completely
- **Cons:** More complex, server ID changes
- **Implementation:** Medium complexity

### **Option 2: Delete When Not Needed, Keep During Business Hours**
- **Pros:** Simpler than daily delete/create
- **Cons:** Still some unnecessary billing
- **Implementation:** Lower complexity

### **Option 3: Use AWS DataSync or S3 Direct Upload**
- **Pros:** No Transfer Family costs
- **Cons:** Requires vendor to change upload method
- **Implementation:** High complexity (vendor coordination)

---

## 📋 **Implementation Plan**

### **Phase 1: Research & Design (1-2 days)**
1. Review AWS Transfer Family API for create/delete
2. Identify all server configuration that needs to be preserved
3. Design configuration storage solution (Parameter Store)
4. Plan for server ID changes

### **Phase 2: Lambda Function Updates (2-3 days)**
1. Update scheduler Lambda to use create/delete
2. Implement configuration storage/retrieval
3. Add error handling for creation failures
4. Test create/delete cycle

### **Phase 3: Testing (2-3 days)**
1. Test server creation and configuration
2. Verify vendor can still upload
3. Verify billing stops when deleted
4. Monitor for 1 week

### **Phase 4: Deployment (1 day)**
1. Deploy updated scheduler
2. Monitor first few cycles
3. Verify cost reduction in billing

---

## 🎯 **Immediate Actions**

1. **Verify Current Understanding:**
   - Confirm server is being stopped (logs show OFFLINE)
   - Confirm billing continues (cost data shows 24/7)
   - This confirms the billing model issue

2. **Research Delete/Create Approach:**
   - Review AWS Transfer Family create/delete APIs
   - Identify configuration requirements
   - Design solution architecture

3. **Plan Migration:**
   - Document current server configuration
   - Design configuration storage
   - Plan for server ID changes

---

## 📚 **References**

- [AWS Transfer Family StopServer API](https://docs.aws.amazon.com/transfer/latest/APIReference/API_StopServer.html)
- [AWS Transfer Family Pricing](https://aws.amazon.com/aws-transfer-family/pricing/)
- [AWS Transfer Family FAQs](https://www.amazonaws.cn/en/amazon-transfer-family/faqs/)

---

**Last Updated:** January 2025  
**Priority:** 🔴 **CRITICAL**  
**Status:** Current approach fundamentally flawed - need delete/create strategy  
**Impact:** $2,430/year in unnecessary costs

