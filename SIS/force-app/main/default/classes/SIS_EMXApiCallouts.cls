public with sharing class SIS_EMXApiCallouts {
    public static final String EMX_LEGACY ='callout:EMX_HostUrl';
    public static String accessToken;
    public static String emxId;
    @future(callout=true)
    public static void sendStudentDeatils(String crmJson, String progAppId, String objName){
        String clientID = System.Label.SIS_clientID;
        System.debug('clientID---'+ clientID);
        String hostUrl = System.Label.SIS_HostUrl;
        System.debug('hostUrl---'+ hostUrl);
        System.debug('crmJson---'+ crmJson);
        System.debug('progAppId---'+ progAppId);
        List<Programme_Application__c> progApplication = new List<Programme_Application__c>();
        List<Student__c> std =new List<Student__c>();
        

        try{
            Map<String, String> authCodeJsonBody = new Map<String, String>();
            authCodeJsonBody.put('client_id', clientID);
            String authCodeBody = JSON.serialize(authCodeJsonBody);
            System.debug('authCodeBody---'+ authCodeBody);
            String authCodeEndpoint = EMX_LEGACY + '/auth/code';
            System.debug('authCodeEndpoint---'+ authCodeEndpoint);
            //Get the authorization code
            HttpResponse authCodeRes = httpPostRequest(authCodeEndpoint, authCodeBody, 'basic');
            System.debug('authCodeRes---'+ authCodeRes);
            if(authCodeRes.getStatusCode() == 200){
                //Get the access token
                Map<String, Object> acResMap = (Map<String, Object>) JSON.deserializeUntyped(authCodeRes.getBody());
                String authCode = (String) acResMap.get('code');
                System.debug('authCode---'+ authCode);
                Map<String, String> accessTokenJsonBody = new Map<String, String>();
                accessTokenJsonBody.put('client_id', clientID);
                accessTokenJsonBody.put('auth_code', authCode);
                String accTokenBody = JSON.serialize(accessTokenJsonBody);
                System.debug('accTokenBody---'+ accTokenBody);
                String accTokenEndpoint = EMX_LEGACY + '/auth/token';
                System.debug('accTokenEndpoint---'+ accTokenEndpoint);
                HttpResponse accTokenRes = httpPostRequest(accTokenEndpoint, accTokenBody, 'basic');
                System.debug('accTokenRes---'+ accTokenRes);
                if(accTokenRes.getStatusCode() == 200){
                    Map<String, Object> atResMap = (Map<String, Object>) JSON.deserializeUntyped(accTokenRes.getBody());
                    accessToken = (String) atResMap.get('access');
                    System.debug('accessToken---'+ accessToken);

                    //Send the details to EMX
                    String crmEndPoint = hostUrl + '/crm';
                    System.debug('crmEndPoint---'+ crmEndPoint);
                    HttpResponse crmResponse = httpPostRequest(crmEndPoint, crmJson, 'bearer');
                    System.debug('crmJson->'+crmJson);
                    System.debug('crmResponse---'+ crmResponse.getBody());
                    if(crmResponse.getStatusCode() == 200){
                        Map<String, Object> crmResMap = (Map<String, Object>) JSON.deserializeUntyped(crmResponse.getBody());
                        emxId = (String) crmResMap.get('transaction_id');
                        System.debug('emxId---'+ emxId);
                        if(objName == 'Programme Application'){
                            progApplication = [SELECT Id, EMX_ID__c FROM Programme_Application__c WHERE Id =: progAppId LIMIT 1];
                            progApplication[0].EMX_ID__c = emxId;
                            update progApplication;
                        }else if(objName == 'Student'){
                             std = [SELECT Id, EMX_ID__c FROM Student__c WHERE Id = :progAppId LIMIT 1];
                             std[0].EMX_ID__c=emxId;
                             update std;
                        }
                        SISIntegrationLog.createLog(crmJson, crmResponse.getBody(), 'Success');
                    }else{
                        SISIntegrationLog.createLog(crmJson, crmResponse.getBody(), 'Failure');
                    }
                }else{
                    SISIntegrationLog.createLog(crmJson, accTokenRes.getBody(), 'Failure');
                }
            }else{
                SISIntegrationLog.createLog(crmJson, authCodeRes.getBody(), 'Failure');
            }
        }catch(Exception e){
            System.debug('error---'+ e.getStackTraceString()+ e.getMessage());
            SISIntegrationLog.createLog(crmJson, e.getMessage(), 'Failure');
        }
    }

    public static HttpResponse httpPostRequest(String setEndpoint, String body, String authType){
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(body);
            req.setEndpoint(setEndpoint);
            if(authType == 'bearer'){
                System.debug('accessToken---'+ accessToken);
                req.setHeader('Authorization', 'Bearer ' + accessToken);
            }
            Http http = new Http();
            HttpResponse res = http.send(req);
            return res;
        }catch(Exception e){
            System.debug(e.getMessage() +'----'+ e.getLineNumber());
            return null;
        }
    }
}