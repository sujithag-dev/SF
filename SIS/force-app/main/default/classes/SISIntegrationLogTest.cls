@isTest
public class SISIntegrationLogTest {
    
    @isTest
    public static void testCreateLog_Success() {
        String requestBody = '{"key1": "value1", "key2": "value2"}';
        String responseBody = '{"status": "success"}';
        String status = 'Success';
        
        Test.startTest();
        SISIntegrationLog.createLog(requestBody, responseBody, status);
        Test.stopTest(); 
    }
    
    
    @isTest
    public static void testCreateLog_WithLargeData() {
        String largeRequestBody = 'A'.repeat(140000); 
        String largeResponseBody = 'B'.repeat(140000);
        String status = 'Failure';
        
        Test.startTest();
        SISIntegrationLog.createLog(largeRequestBody, largeResponseBody, status);
        Test.stopTest();  
    }
    
    
    @isTest
    public static void testCreateLog_ExceptionHandling() {
        Test.startTest();
        try {
            SISIntegrationLog.createLog(null, null, null);
        }catch (Exception e) {
            System.assert(false, 'Exception should not propagate');
        }
        Test.stopTest();
        
    }
}