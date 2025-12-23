const AWS = require('aws-sdk');
const path = require('path');

const s3 = new AWS.S3();
const S3_BUCKET = process.env.S3_BUCKET || 'valleyridge-inventory-sync';

/**
 * Lambda function to preserve original files before processing
 * This runs independently and doesn't affect the main processing Lambda
 */
exports.handler = async (event) => {
    console.log('File Preserver Lambda triggered');
    console.log('Event:', JSON.stringify(event, null, 2));
    
    const results = [];
    
    // Process each S3 event record
    for (const record of event.Records) {
        try {
            const bucket = record.s3.bucket.name;
            const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
            
            console.log(`Processing file: s3://${bucket}/${key}`);
            
            // Only process delta files (which means processing completed successfully)
            if (!key.startsWith('processed/delta/')) {
                console.log(`Skipping file - not a delta file: ${key}`);
                continue;
            }
            
            // Extract the original filename from the delta filename
            // Delta format: processed/delta/Loloi_Inventory w. UPC-delta-2025-10-07T10-00-56-623Z.csv
            const deltaFileName = path.basename(key);
            const originalFileName = deltaFileName.split('-delta-')[0];
            
            // Find the original file in incoming/ (could be .csv, .xls, or .xlsx)
            const possibleExtensions = ['.csv', '.CSV', '.xls', '.XLS', '.xlsx', '.XLSX'];
            let originalKey = null;
            let originalExtension = null;
            
            for (const ext of possibleExtensions) {
                const testKey = `incoming/${originalFileName}${ext}`;
                try {
                    await s3.headObject({ Bucket: S3_BUCKET, Key: testKey }).promise();
                    originalKey = testKey;
                    originalExtension = ext;
                    console.log(`Found original file: ${originalKey}`);
                    break;
                } catch (error) {
                    // File doesn't exist with this extension, try next
                    continue;
                }
            }
            
            if (!originalKey) {
                console.log(`Original file not found for ${originalFileName}, skipping`);
                results.push({
                    sourceFile: key,
                    status: 'skipped',
                    reason: 'Original file not found in incoming/'
                });
                continue;
            }
            
            // Generate timestamped filename for preserved file
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const preservedKey = `processed/originals/${originalFileName}-${timestamp}${originalExtension}`;
            
            console.log(`Copying ${originalKey} to ${preservedKey}`);
            
            // Copy original file to processed/originals/ with timestamp
            const copyParams = {
                Bucket: S3_BUCKET,
                CopySource: `${S3_BUCKET}/${encodeURIComponent(originalKey)}`,
                Key: preservedKey,
                MetadataDirective: 'COPY'
            };
            
            await s3.copyObject(copyParams).promise();
            
            console.log(`Successfully preserved original file: ${preservedKey}`);
            
            results.push({
                deltaFile: key,
                originalFile: originalKey,
                preservedFile: preservedKey,
                status: 'success'
            });
            
        } catch (error) {
            console.error(`Error preserving file:`, error);
            results.push({
                sourceFile: record.s3.object.key,
                status: 'error',
                error: error.message
            });
            // Don't throw - we want to continue processing other files
        }
    }
    
    console.log('File preservation complete:', JSON.stringify(results, null, 2));
    
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'File preservation complete',
            results: results
        })
    };
};

