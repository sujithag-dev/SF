public class SISIntegrationLog {
    public static void createLog(String requestBody, String responseBody, String status) {
        try {
            SIS_Integration_log__c log = new SIS_Integration_log__c();
            
            log.Request_Body__c = (requestBody != null && requestBody.length() > 131072)
                ? requestBody.substring(0, 131072) + '... [More]' : requestBody;
            
            log.Response_Body__c = (responseBody != null && responseBody.length() > 131072)
                ? responseBody.substring(0, 131072) + '... [More]' : responseBody;
            
            log.Status__c = status;
            
            insert log;
            System.debug('Integration log saved successfully');
        } catch (Exception e) {
            System.debug('Error while logging integration: ' + e.getMessage());
        }
    }
    
}