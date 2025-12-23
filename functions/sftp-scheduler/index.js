const AWS = require('aws-sdk');

const transfer = new AWS.Transfer({ region: 'us-east-1' });
const cloudwatch = new AWS.CloudWatch({ region: 'us-east-1' });

const SFTP_SERVER_ID = 's-34ce3bb4895a4fac8';
const NAMESPACE = 'ValleyRidge/SFTP';

/**
 * Lambda function to start/stop SFTP server on schedule
 * This reduces costs from $254/month to ~$50-80/month
 */
exports.handler = async (event) => {
    console.log('SFTP Scheduler triggered:', JSON.stringify(event, null, 2));
    
    const action = event.action || event.detail?.action;
    const requestId = event.requestId || 'sftp-scheduler-' + Date.now();
    
    try {
        let result;
        
        if (action === 'start') {
            result = await startSFTPServer(requestId);
        } else if (action === 'stop') {
            result = await stopSFTPServer(requestId);
        } else if (action === 'status') {
            result = await getSFTPStatus(requestId);
        } else {
            throw new Error(`Unknown action: ${action}`);
        }
        
        // Send metrics to CloudWatch
        await sendMetrics(action, result, requestId);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                success: true,
                action,
                result,
                timestamp: new Date().toISOString()
            })
        };
        
    } catch (error) {
        console.error(`[${requestId}] Error:`, error);
        
        // Send error metrics
        await sendErrorMetrics(action, error, requestId);
        
        return {
            statusCode: 500,
            body: JSON.stringify({
                success: false,
                action,
                error: error.message,
                timestamp: new Date().toISOString()
            })
        };
    }
};

/**
 * Start the SFTP server
 */
async function startSFTPServer(requestId) {
    console.log(`[${requestId}] Starting SFTP server...`);
    
    try {
        // Check current status first
        const currentStatus = await getSFTPStatus(requestId);
        if (currentStatus.state === 'ONLINE') {
            console.log(`[${requestId}] SFTP server is already running`);
            return { state: 'ONLINE', message: 'Already running' };
        }
        
        // Start the server
        const result = await transfer.startServer({
            ServerId: SFTP_SERVER_ID
        }).promise();
        
        console.log(`[${requestId}] SFTP server start initiated`);
        
        // Wait for server to be online (with timeout)
        const maxWaitTime = 300000; // 5 minutes
        const startTime = Date.now();
        
        while (Date.now() - startTime < maxWaitTime) {
            const status = await getSFTPStatus(requestId);
            if (status.state === 'ONLINE') {
                console.log(`[${requestId}] SFTP server is now ONLINE`);
                return { state: 'ONLINE', message: 'Successfully started' };
            }
            
            console.log(`[${requestId}] Waiting for server to start... (${status.state})`);
            await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
        }
        
        throw new Error('Timeout waiting for server to start');
        
    } catch (error) {
        console.error(`[${requestId}] Failed to start SFTP server:`, error);
        throw error;
    }
}

/**
 * Stop the SFTP server
 */
async function stopSFTPServer(requestId) {
    console.log(`[${requestId}] Stopping SFTP server...`);
    
    try {
        // Check current status first
        const currentStatus = await getSFTPStatus(requestId);
        if (currentStatus.state === 'OFFLINE') {
            console.log(`[${requestId}] SFTP server is already stopped`);
            return { state: 'OFFLINE', message: 'Already stopped' };
        }
        
        // Stop the server
        const result = await transfer.stopServer({
            ServerId: SFTP_SERVER_ID
        }).promise();
        
        console.log(`[${requestId}] SFTP server stop initiated`);
        
        // Wait for server to be offline (with timeout)
        const maxWaitTime = 300000; // 5 minutes
        const startTime = Date.now();
        
        while (Date.now() - startTime < maxWaitTime) {
            const status = await getSFTPStatus(requestId);
            if (status.state === 'OFFLINE') {
                console.log(`[${requestId}] SFTP server is now OFFLINE`);
                return { state: 'OFFLINE', message: 'Successfully stopped' };
            }
            
            console.log(`[${requestId}] Waiting for server to stop... (${status.state})`);
            await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
        }
        
        throw new Error('Timeout waiting for server to stop');
        
    } catch (error) {
        console.error(`[${requestId}] Failed to stop SFTP server:`, error);
        throw error;
    }
}

/**
 * Get current SFTP server status
 */
async function getSFTPStatus(requestId) {
    try {
        const result = await transfer.describeServer({
            ServerId: SFTP_SERVER_ID
        }).promise();
        
        const state = result.Server.State;
        console.log(`[${requestId}] SFTP server status: ${state}`);
        
        return {
            state,
            serverId: SFTP_SERVER_ID,
            endpoint: result.Server.EndpointDetails?.Address,
            message: `Server is ${state}`
        };
        
    } catch (error) {
        console.error(`[${requestId}] Failed to get SFTP status:`, error);
        throw error;
    }
}

/**
 * Send metrics to CloudWatch
 */
async function sendMetrics(action, result, requestId) {
    try {
        const params = {
            Namespace: NAMESPACE,
            MetricData: [
                {
                    MetricName: 'SFTP_Action_Success',
                    Value: 1,
                    Unit: 'Count',
                    Dimensions: [
                        {
                            Name: 'Action',
                            Value: action
                        }
                    ],
                    Timestamp: new Date()
                },
                {
                    MetricName: 'SFTP_Server_State',
                    Value: result.state === 'ONLINE' ? 1 : 0,
                    Unit: 'Count',
                    Dimensions: [
                        {
                            Name: 'ServerId',
                            Value: SFTP_SERVER_ID
                        }
                    ],
                    Timestamp: new Date()
                }
            ]
        };
        
        await cloudwatch.putMetricData(params).promise();
        console.log(`[${requestId}] Metrics sent to CloudWatch`);
        
    } catch (error) {
        console.error(`[${requestId}] Failed to send metrics:`, error);
        // Don't throw - metrics failure shouldn't break the main function
    }
}

/**
 * Send error metrics to CloudWatch
 */
async function sendErrorMetrics(action, error, requestId) {
    try {
        const params = {
            Namespace: NAMESPACE,
            MetricData: [
                {
                    MetricName: 'SFTP_Action_Error',
                    Value: 1,
                    Unit: 'Count',
                    Dimensions: [
                        {
                            Name: 'Action',
                            Value: action
                        },
                        {
                            Name: 'ErrorType',
                            Value: error.name || 'Unknown'
                        }
                    ],
                    Timestamp: new Date()
                }
            ]
        };
        
        await cloudwatch.putMetricData(params).promise();
        console.log(`[${requestId}] Error metrics sent to CloudWatch`);
        
    } catch (metricsError) {
        console.error(`[${requestId}] Failed to send error metrics:`, metricsError);
    }
}

