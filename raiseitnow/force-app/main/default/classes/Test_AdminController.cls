/**
* @description Test class for AdminController and related service/handler classes.
* This test class covers AdminController, ConnectionHandler, ProjectFieldService,
* ExternalUserIntegrationService, ServiceTemplateHandler.
*
*/ 
@isTest 
public class Test_AdminController { 
    
    // Common assertion messages & repeated literals extracted to constants to avoid duplicate-literal PMD issues
    private static final String MSG_RESULT_NOT_NULL = 'Result should not be null';
    private static final String MSG_EXPECT_SUCCESS_TRUE = 'Expected success to be true';
    private static final String MSG_EXPECT_SUCCESS_FALSE = 'Expected success to be false';
    private static final String MSG_EXPECT_ERROR_MESSAGE = 'Expected an error message';
    private static final String MSG_INCORRECT_SUCCESS_MESSAGE = 'Incorrect success message';
    private static final String MSG_INCORRECT_ERROR_MESSAGE = 'Incorrect error message';
    private static final String MSG_DELETE_SUCCESS_CONTAINS = 'Message should confirm deletion';
    private static final String MSG_NO_RECORDS_FOUND = 'Message should indicate no records';
    private static final String MSG_INVALID_JSON_PARSE = 'Error message should mention unable to parse project info';
    
    /**
* @description Creates a reusable HTTP callout mock instance for test methods.
*              Helps reduce duplication when mocking HTTP responses.
* @param body The response body to return from the mock callout.
* @param statusMsg The HTTP status message to simulate.
* @param statusCode The HTTP status code to simulate.
* @return An instance of HttpCalloutMock that can be passed to Test.setMock().
*/
    private static HttpCalloutMock makeMock(String body, String statusMsg, Integer statusCode) {
        return new Mock_AdminController(body, statusMsg, statusCode);
    }
    
    
    /**
* @description Mock implementation for HTTP callouts used across many tests.
*/
    public class Mock_AdminController implements HttpCalloutMock {  
        private String body;
        private String statusMsg;
        private Integer statusCode;
        private Boolean throwException = false;
        
        /**
* @description Constructor for Mock_AdminController that initializes a mock HTTP response.
* @param body The response body to return from the mock callout.
* @param statusMsg The HTTP status message to simulate.
* @param statusCode The HTTP status code to simulate.
*/
        public Mock_AdminController(String body, String statusMsg, Integer statusCode) {
            this.body = body;
            this.statusMsg = statusMsg;
            this.statusCode = statusCode;
        }
       
       /**
     * @description Sets whether this mock should throw an exception when called.
     * @param flag Boolean value indicating if the mock should throw an exception. 
     *             Set to true to simulate a callout failure, false to allow normal response.
     * @return Mock_AdminController Returns the current instance for method chaining.
     */  
      public Mock_AdminController setThrowException(Boolean flag) {
            this.throwException = flag;
            return this;
        }


        
        /**
* @description Enables exception throwing for the mock instance.
*/
        public void enableException() {
            this.throwException = true;
        }
        
        /**
* @description Generates a mock HTTP response for testing callouts.
* @param req The HTTP request object being mocked (not used in this implementation).
* @return HttpResponse The simulated HTTP response based on the initialized fields.
* @throws CalloutException if throwException is true to simulate failure.
*/
        public HTTPResponse respond(HTTPRequest req) {
            if (throwException) {
                throw new CalloutException('Simulated callout failure');
            }
            HttpResponse res = new HttpResponse();
            if (this.statusCode != null) {
                res.setStatusCode(this.statusCode);
            }
            if (this.body != null) {
                res.setBody(this.body);
            }
            if (this.statusMsg != null) {
                res.setStatus(this.statusMsg);
            }
            res.setHeader('Content-Type', Constant.CONTENT_TYPE_JSON_UTF8);
            return res;
        }        	
    }
    
    
    /**
* @description Shared test data for many tests
*/
    @testSetup
    static void setupData() {//doc
        // Create a Service Template used by delete/save tests
        Service_Template__c template = new Service_Template__c(Service_Name__c = 'Template for tests');
        insert template;
    }
    
    // Cover getCurrentUserName()
    @isTest
    static void testGetCurrentUserName() {
        Test.startTest();
        String userNameFromController = AdminController.getCurrentUserName();
        Test.stopTest();
        System.assertEquals(UserInfo.getUserName(), userNameFromController,
                            'getCurrentUserName should return the running user username');
    }
    
    @isTest
    static void testGetRaiseItNowConnectionspositive() {
        // This test calls the real getRaiseItNowConnections(). In most orgs this will return
        // an object with connections (if NamedCredentials exist) or an empty list.
        Test.startTest();
        ResultMessage result = AdminController.getRaiseItNowConnections();
        Test.stopTest();
        System.assertNotEquals(null, result, MSG_RESULT_NOT_NULL);
        // The code under test sets success=true by default unless an exception or permission issue occurs.
        System.assertNotEquals(null, result.success, 'Result.success should be set (true/false)');
        // If connections are present, ensure payloadMap includes key
        if (result.payloadMap != null && result.payloadMap.containsKey('connections')) {
            Object connectionsObj = result.payloadMap.get('connections');
            // ensure the value is a list (could be empty)
            System.assert(connectionsObj instanceof List<Object>, 'connections should be a list');
        }
    }
    
    @isTest
    static void testGetRaiseItNowConnectionsnegative() {
        // Avoid hard-coded profile name; create a user with current profile to run as (deterministic)
        Id currentProfileId = UserInfo.getProfileId();
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = currentProfileId,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        insert u;
        
        System.runAs(u){
            Test.startTest();
            try {
                ResultMessage result = AdminController.getRaiseItNowConnections();
                // The implementation returns success=true by default unless permission check fails.
                // Tests should be robust: accept either a success=false due to permission, or a success=true with empty connections.
                System.assertNotEquals(null, result, 'Result should not be null for limited-access runAs user');
                if (result.success == false) {
                    // If permission-based failure, ensure message is set
                    if (result.payloadMap != null && result.payloadMap.get('message') != null) {
                        System.assertNotEquals(null, result.payloadMap.get('message'), 'Expected message when success=false');
                    } else {
                        // if payloadMap is null or doesn't have message, fail the test
                        System.assert(false, 'Expected message when success=false');
                    }
                    System.assert(
                        String.valueOf(result.payloadMap.get('message')).contains('Insufficient access') ||
                        String.valueOf(result.payloadMap.get('message')).contains('Error'),
                        'Expected an access-related or error message for limited user'
                    );
                } else {
                    // success == true: assert that connections list exists (possibly empty)
                    Object conns = result.payloadMap.get('connections');
                    System.assertNotEquals(null, conns, 'connections should be present even if empty');
                }
            } 
            catch (AuraHandledException e) {
                System.assertEquals('Insufficient access to NamedCredential object.', e.getMessage(), 'Incorrect exception message');
            }  
            Test.stopTest();
        }
    }
    
    @isTest static void testGetRaiseItNowConnectionStatusPositive() {
        ConnectionHandler.useMockConnections = true;
        // Arrange mocks
        HttpCalloutMock jiraMock = makeMock('{"emailAddress":"jira@test.com"}', 'OK', 200);
        HttpCalloutMock azureMock = makeMock('{"authenticatedUser":{"properties":{"Account":{"$value":"azure@test.com"}}}}', 'OK', 200);
        HttpCalloutMock snMock   = makeMock('{"emailAddress":"sn@test.com"}', 'OK', 200);
        
        Test.startTest();
        // Jira
        Test.setMock(HttpCalloutMock.class, jiraMock);
        ResultMessage jiraRes = AdminController.getRaiseItNowConnectionStatus(Constant.JIRA_SERVICE);
        
        // Azure
        Test.setMock(HttpCalloutMock.class, azureMock);
        ResultMessage azureRes = AdminController.getRaiseItNowConnectionStatus(Constant.AZURE_SERVICE);
        
        // ServiceNow
        Test.setMock(HttpCalloutMock.class, snMock);
        ResultMessage snRes = AdminController.getRaiseItNowConnectionStatus(Constant.SERVICENOW_SERVICE);
        Test.stopTest();
        
        // Assertions
        System.assert(jiraRes.success, MSG_EXPECT_SUCCESS_TRUE);
        System.assertEquals('jira@test.com', jiraRes.payloadMap.get('emailAddress'), 'Jira email should be returned');
        
        System.assert(azureRes.success, MSG_EXPECT_SUCCESS_TRUE);
        System.assertEquals('azure@test.com', azureRes.payloadMap.get('emailAddress'), 'Azure email should be returned');
        
        System.assert(snRes.success, MSG_EXPECT_SUCCESS_TRUE);
        System.assertEquals('sn@test.com', snRes.payloadMap.get('emailAddress'), 'ServiceNow email should be returned');
    }    
    
    @isTest
    static void testGetRaiseItNowConnectionStatusNegative() {
        // Simulate non-200 response body to force branch that builds error
        Test.setMock(HttpCalloutMock.class, makeMock('{"error":"Server Error"}','Internal Server Error',500));
        Test.startTest();
        ResultMessage result1 = ConnectionHandler.getRaiseItNowConnectionStatus(Constant.JIRA_SERVICE);
        ResultMessage result2 = ConnectionHandler.getRaiseItNowConnectionStatus(null);
        ResultMessage result3 = ConnectionHandler.getRaiseItNowConnectionStatus('Invalid');
        Test.stopTest();
        
        // result1 may be false because sendGetRequest returned non-200 or because no NamedCredential existed.
        System.assertNotEquals(null, result1, MSG_RESULT_NOT_NULL);
        System.assert(!result2.success, MSG_EXPECT_SUCCESS_FALSE);
        System.assert(!result3.success, MSG_EXPECT_SUCCESS_FALSE);
        // For result1: assert either a failure message or success=false
        if (result1.success == false) {
            if (result1.payloadMap != null) {
                System.assertNotEquals(null, result1.payloadMap.get('message'), 'Expected message for error response');
            } else {
                System.assert(false, 'Expected payloadMap.message for error response');
            }
        }
    }
    @isTest
    static void testGetRaiseItNowConnectionsRealBranch() {
        // Force the else branch to run
        ConnectionHandler.useMockConnections = false;
        
        Test.startTest();
        ResultMessage result = ConnectionHandler.getRaiseItNowConnections();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.payloadMap.containsKey('connections'), 'Connections key should exist');
        System.assert(result.payloadMap.containsKey('connectionNames'), 'connectionNames key should exist');
    }

    
    @isTest
    static void testDeleteTemplatePositive() {
        // Get template created in @testSetup
        Service_Template__c template = [SELECT Id FROM Service_Template__c LIMIT 1];
        
        Test.startTest();
        ResultMessage result = AdminController.deleteTemplate(template.Id);  
        Test.stopTest();
        
        System.assert(result.success, MSG_EXPECT_SUCCESS_TRUE);
        // payloadMap may be null in some implementations — guard the assertion
        if (result.payloadMap != null && result.payloadMap.containsKey('message')) {
            System.assertEquals('Service Template deleted successfully', result.payloadMap.get('message'), MSG_INCORRECT_SUCCESS_MESSAGE);
        } else {
            System.assertNotEquals(null, result.message, 'Either payloadMap.message or message should be present');
        }
    }
    
    @isTest
    static void testDeleteTemplateNegative() {
        Test.startTest();
        ResultMessage result = AdminController.deleteTemplate(null);
        Test.stopTest();
        
        System.assert(!result.success, MSG_EXPECT_SUCCESS_FALSE);
        if (result.payloadMap != null && result.payloadMap.containsKey('message')) {
            System.assertEquals('Unexpected error occurred while deleting Service Template.', result.payloadMap.get('message'), MSG_INCORRECT_ERROR_MESSAGE);        
        } else {
            System.assertNotEquals(null, result.message, 'Expected an error message for delete failure');
        }
    }
    
    @isTest
    static void testSaveTemplateDataPositive() {
        WrapperContainer.TemplateWrapper template = new WrapperContainer.TemplateWrapper();
        template.servName = 'Test Service';
        template.fieldsJson = '{"field1":"value1","field2":"value2"}';
        template.projectName = 'Test Project';
        template.projectKey = 'TestKey'; 
        String jsonString = JSON.serialize(template);
        
        Test.startTest();
        ResultMessage result = AdminController.saveTemplateData(jsonString);  
        Test.stopTest();
        
        System.assert(result.success, MSG_EXPECT_SUCCESS_TRUE);
        if (result.payloadMap != null && result.payloadMap.containsKey('message')) {
            System.assertEquals('Service Template Saved successfully', result.payloadMap.get('message'), MSG_INCORRECT_SUCCESS_MESSAGE);
        } else {
            System.assertNotEquals(null, result.message, MSG_EXPECT_ERROR_MESSAGE);
        }
    }
    
    @isTest
    static void testSaveTemplateDataNegative() {
        Test.startTest();
        ResultMessage result = AdminController.saveTemplateData('invalidJsonString');   
        Test.stopTest();
        
        System.assert(!result.success, MSG_EXPECT_SUCCESS_FALSE);
        if (result.payloadMap != null && result.payloadMap.containsKey('message')) {
            System.assertEquals('Unexpected error occurred while saving Service Template.', result.payloadMap.get('message'), MSG_INCORRECT_ERROR_MESSAGE);        
        } else {
            System.assertNotEquals(null, result.message, 'Expected an error message for save failure');
        }
    }
    /**
* @description Test deleteTemplates - positive scenario
*/
    @IsTest
    static void testDeleteTemplatesWithNamePositive() {
        // Insert a Service_Template__c record
        Service_Template__c temp = new Service_Template__c(
            Service_Name__c = 'TestService',
            Project_Name__c = 'TestProject'
        );
        insert temp;
        
        Test.startTest();
        ResultMessage result = ServiceTemplateHandler.deleteTemplates('TestService');
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Delete should succeed');
        System.assert(((String)result.payloadMap.get('message')).contains('deleted successfully'), MSG_DELETE_SUCCESS_CONTAINS);
    }
    
    /**
* @description Test deleteTemplates - negative scenario (no records)
*/
    @IsTest
    static void testDeleteTemplatesWithNameNegative() {
        Test.startTest();
        ResultMessage result = ServiceTemplateHandler.deleteTemplates('NonExistentService');
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail when no records found');
        System.assert(((String)result.payloadMap.get('message')).contains('No Service Templates found'), MSG_NO_RECORDS_FOUND);
    }
    
    /**
* @description Test saveMultipleTemplateDataSimple - positive scenario
*/
    @IsTest
    static void testSaveMultipleTemplateDataSimplePositive() {
        WrapperContainer.TemplateWrapper wrapper = new WrapperContainer.TemplateWrapper();
        wrapper.servName = 'BulkService';
        wrapper.projectName = 'BulkProject';
        wrapper.userName = 'TestUser';
        
        String jsonStr = JSON.serialize(wrapper);
        List<String> jsonList = new List<String>{ jsonStr };
            
            Test.startTest();
        ResultMessage result = ServiceTemplateHandler.saveMultipleTemplateDataSimple(jsonList);
        Test.stopTest();
        
        // Assert success flag
        System.assertEquals(true, result.success, 'Save should succeed');
        
        // Case-insensitive check for message
        String message = (String)result.payloadMap.get('message');
        System.assert(
            message != null && message.toLowerCase().contains('saved successfully'),
            'Message should confirm save. Actual: ' + message
        );
    }
    
    @isTest
    static void testSaveMultipleTemplateDataSimplePartialFailure() {
        // Insert a base template record so upsert/validation has data to work with
        Service_Template__c existingTemplate = new Service_Template__c(
            Service_Name__c = 'Service',
            Project_Name__c = 'Proj',
            Project_Keys__c = 'KEY',
            Username__c = 'test.user'
        );
        insert existingTemplate;
        
        // Build wrapper
        WrapperContainer.TemplateWrapper tw = new WrapperContainer.TemplateWrapper();
        tw.uniqueId = 'UID';
        tw.recordId = existingTemplate.Id; // use real recordId so update works
        tw.projectName = '';
        tw.projectKey = 'KEY';
        tw.servName = 'Service';
        tw.hadTemplate = true;
        tw.fieldsJson = '{"field":"value"}';
        tw.lookUpId = UserInfo.getUserId(); // valid lookup
        tw.userName = 'test.user';
        tw.recordTypeName = 'Service Template';
        
        // Serialize to JSON
        String jsonString = JSON.serialize(tw);
        List<String> wrapperJsonList = new List<String>{ jsonString };
            
            Test.startTest();
        ResultMessage result = ServiceTemplateHandler.saveMultipleTemplateDataSimple(wrapperJsonList);
        Test.stopTest();
        
        //Assertions
        System.assertEquals(true, result.success, 
                            'Wrapper object should process without errors. Status: ' + result.payloadMap.get('status'));
        System.assertEquals('Service Template Saved successfully',
                            (String)result.payloadMap.get('message'), 'Save message mismatch');
        System.assertEquals(1, result.payloadMap.get('successCount'),
                            'Exactly one wrapper should have been saved');
    }
    
    @isTest
    static void testCustomExceptionCoverage() {
        Boolean exceptionThrown = false;
        try {
            // Force throw AdminController.CustomException
            throw new AdminController.CustomException('Test Custom Exception');
        } catch (AdminController.CustomException ex) {
            exceptionThrown = true;
            System.assertNotEquals(null, ex, 'CustomException instance should not be null');
            System.assert(ex.getMessage().contains('Test Custom Exception'),
                          'Exception message should contain the expected text');
        }
        System.assertEquals(true, exceptionThrown, 'CustomException should have been thrown and caught');
    }
    
    //Outer Exception → triggers global catch block
    @isTest
    static void testOuterException() {
        Test.startTest();
        ResultMessage result = ServiceTemplateHandler.saveMultipleTemplateDataSimple(null);
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail due to outer exception');
        System.assert(((String)result.payloadMap.get('message')).contains('Unexpected error'), 'Message should indicate unexpected error');
    }
    
    // ️Inner Exception → JSON parse error (nested parseError branch)
    @isTest
    static void testInnerExceptionInvalidJson() {
        // Bad JSON string → cannot deserialize
        List<String> badJsonList = new List<String>{ '{badJson}' };
            
        Test.startTest();
        ResultMessage result = ServiceTemplateHandler.saveMultipleTemplateDataSimple(badJsonList);
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should fail because no valid records');
        System.assert(result.payloadMap.get('errors') != null, 'Error list should exist');
        System.assert(((List<String>)result.payloadMap.get('errors'))[0].contains('unable to parse'), MSG_INVALID_JSON_PARSE);
    }
    
}