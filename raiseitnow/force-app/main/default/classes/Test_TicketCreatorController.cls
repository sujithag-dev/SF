/**
* @description       : Test_TicketCreatorController Class is used to test the functionality of the all the methods in the TicketCreatorController class.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 18-05-2024
* last modified by   : 
**/

/**
* @description  Test_TicketCreatorController is used to test the functionality of the all the methods in the TicketCreatorController class.
*/
@isTest
public with sharing class Test_TicketCreatorController {
    /**
* @description Mock implementation of the HttpCalloutMock interface to simulate HTTP responses for testing purposes.
*/
    public class Mock_TicketCreatorController implements HttpCalloutMock{      
        private String body;
        private String statusMsg;
        private integer statusCode;
        private Boolean throwException = false;
        /**
* @description Constructor to initialize the mock response attributes.
* @param body The body content of the mock HTTP response.
* @param statusMsg The status message of the mock HTTP response.
* @param statusCode The status code of the mock HTTP response.
*/
        public Mock_TicketCreatorController(String body, String statusMsg, Integer statusCode)
        {
            this.body = body;
            this.statusMsg = statusMsg;
            this.statusCode = statusCode;
        }
        /**
* @description Enables the simulated exception behavior for the mock callout.
* When invoked, the next call to respond() will throw an exception to simulate a failure.
*/
        public void enableException() {
            this.throwException = true;
        }
        
        /**
* @description Method to generate a mock HTTP response based on the initialized attributes.
* @param req The HTTP request for which the response is being mocked.
* @return The mocked HTTP response.
*/
        public HTTPResponse respond(HTTPRequest req) 
        {
            if (throwException) {
                throw new CalloutException('Simulated callout failure');
            }
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');
            res.setBody(this.body);
            res.setStatus(this.statusMsg);
            res.setStatusCode(this.statusCode);
            res.setStatus('Created');
            return res;
        }        	
    }
    
    
    @isTest
    static void getDocumentSizeTest(){
        
        Test.startTest();
        Integer attch = AttachmentManager.getDocumentSize(null);
        Test.stopTest();
        System.assertEquals(0, attch, 'getDocumentSize should return 0 for null input');
    }
    
    @TestSetup
    static void setupTestData() {
        Service_Template__c template = new Service_Template__c();
        template.Project_Keys__c = 'TS';
        template.Service_Name__c = 'Service';
        template.Project_Name__c = 'Testing Jira';
        template.Project_Fields__c = '{"field1": "value1", "field2": "value2"}';
        insert template;
        
    }
    
    @isTest
    static void testGetTemplateDetailsloopAndSuccess() {
        // Mock connection names (simulate AdminController)
        MockAdminController mockAdmin1 = new MockAdminController();
        mockAdmin1.mockConnectionResult(new List<String>{'Jira'});
        
        
        
        // Create mock Service_Template__c record
        Service_Template__c template = new Service_Template__c(
            Username__c = 'demo@example.com',
            Project_Fields__c = '{"key":"value"}',
            Project_Keys__c = 'PROJ001',
            Project_Name__c = 'Demo Project',
            Service_Name__c = 'Jira', 
            User_Lookup__c = UserInfo.getUserId()
        );
        insert template;
        
        Test.startTest();
        ResultMessage result = TicketCreatorController.getTemplateDetails();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Expected result to not be null');
        System.assertEquals(true, result.success, 'Expected success to be true');
        System.assert(result.payloadMap.containsKey('templates'), 'Expected templates in payload');
        
        List<WrapperContainer.TemplateWrapper> wrappers = 
            (List<WrapperContainer.TemplateWrapper>) result.payloadMap.get('templates');
        
        System.assertEquals(1, wrappers.size(), 'Expected one wrapper');
        System.assertEquals('Demo Project', wrappers[0].projectName, 'Project name mismatch');
        System.assertEquals('PROJ001', wrappers[0].projectKey, 'Project key mismatch');
    }
    
    
    
    @isTest
    static void testGetTemplateDetails() {
        List<Service_Template__c> templates = new List<Service_Template__c>();
        for (Integer i = 0; i < 5; i++) {
            Service_Template__c template = new Service_Template__c(
                Service_Name__c = 'Service ' + i,
                Project_Name__c = 'Project ' + i,
                Project_Keys__c = 'Key ' + i,
                Project_Fields__c = '{"field1": "value1", "field2": "value2"}'
            );
            templates.add(template);
        }
        insert templates;
        Test.startTest();
        ResultMessage result = TicketCreatorController.getTemplateDetails();
        Test.stopTest();
        System.assert(result.success, 'Expected result success to be true');
        System.assertEquals('Get Template Details', result.message, 'Expected message to be "Get Template Details"');
    }   
    @isTest
    static void testGetTemplateDetail() {         
        Service_Template__c template = new Service_Template__c(
            Service_Name__c = null,
            Project_Name__c = 'Project ' + 0,
            Project_Keys__c = 'Key ' + 0,
            Project_Fields__c = '{"field1": "value1", "field2": "value2"}');                 
        insert template;
        
        Test.startTest();
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        system.runas(u){            
            ResultMessage result = TicketCreatorController.getTemplateDetails();
            System.assertEquals(true, result.success,'success');            
        }
        Test.stopTest();
        
    }
    
    
    
    @isTest
    static void testAccessDenied() {
        ResultMessage result = new ResultMessage(true, 'initial');
        Test.startTest();
        ResultMessage updated = AttachmentManager.accessDenied(result, 'ContentDocumentLink');
        Test.stopTest();
        System.assertEquals(false, updated.success, 'Expected success to be false after accessDenied() is called.');
        System.assertEquals(
            'You don\'t have read access to the ContentDocumentLink.',
            updated.message,
            'Expected message mismatch for accessDenied() method.'
        );
    }
    
    @isTest
    static void testConfiguationItemListCatchBlock() {
        // Simulate an exception via mock
        Mock_TicketCreatorController mock = new Mock_TicketCreatorController('', 'Internal Server Error', 500);
        mock.enableException();
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        ResultMessage result = TicketCreatorController.configuationItemList();
        Test.stopTest();
        
        // Assert failure and that error message is present
        System.assertEquals(false, result.success, 'Expected success=false due to exception');
        System.assertNotEquals(null, result.message, 'Expected an error message from catch block');
    }
    
    @isTest
    static void testSuccess() {
        String mockResponse = '{"result":[{"sys_id":"123","name":"Item 1"},{"sys_id":"456","name":"Item 2"}]}';
        Test.setMock(HttpCalloutMock.class,new Mock_TicketCreatorController(mockResponse,'OK',200));
        Test.startTest();
        ResultMessage result = TicketCreatorController.configuationItemList();
        Test.stopTest();
        System.assertEquals(true, result.success,'success');
    }
    
    @isTest
    static void testFailure() {
        String mockResponse = '';
        Test.setMock(HttpCalloutMock.class,new Mock_TicketCreatorController(mockResponse,'Bad Request',500));
        Test.startTest();
        ResultMessage result = TicketCreatorController.configuationItemList();
        Test.stopTest();
        System.assertEquals(false, result.success, 'Expected success to be false');
    }
    
    @isTest
    static void testgetReporterJira() {
        String mockResponse = '{"displayName": "John Doe", "emailAddress": "john.doe@example.com"}';
        Test.setMock(HttpCalloutMock.class,new Mock_TicketCreatorController(mockResponse,'OK',200));
        Test.startTest();
        ResultMessage resultJira = TicketCreatorController.getReporter('Jira');
        Test.stopTest();    
        System.assertEquals(true, resultJira.success, 'Expected success to be true');
        System.assertNotEquals(null, resultJira.message, 'Expected message to be populated');
    }
    
    @isTest
    static void testgetReporterServiceNow() {
        String mockResponse = '{"result": [{"name": "Administrator", "sys_id": "1234567890"}]}';
        Test.setMock(HttpCalloutMock.class,new Mock_TicketCreatorController(mockResponse,'OK',200));
        Test.startTest();
        ResultMessage resultServiceNow = TicketCreatorController.getReporter('ServiceNow');
        ResultMessage resultInvalid2 = TicketCreatorController.getReporter('');
        Test.stopTest();
        System.assertEquals(true, resultServiceNow.success, 'Expected success to be true');
        System.assertNotEquals(null, resultServiceNow.message, 'Expected message to be populated');
        System.assertEquals(false, resultInvalid2.success, 'Expected success to be false');
    }
    
    @isTest
    static void testgetReporterNegative() {
        String mockResponse = '';
        Test.setMock(HttpCalloutMock.class,new Mock_TicketCreatorController(mockResponse,'Bad Request',500));
        Test.startTest();
        ResultMessage resultInvalid = TicketCreatorController.getReporter('InvalidService');
        Test.stopTest();
        
        System.assertEquals(false, resultInvalid.success, 'Expected success to be false');
        System.assertEquals('Invalid service.', resultInvalid.payloadMap.get('message'), 'Expected message to be populated');
    }      
    @isTest
    static void testGetReporterException() {
        // Set a mock response with invalid JSON to force deserialization error
        String invalidJson = 'invalid_json_response';
        Test.setMock(HttpCalloutMock.class, new Mock_TicketCreatorController(invalidJson, 'Bad Request', 200));
        
        Test.startTest();
        ResultMessage result = TicketCreatorController.getReporter('Jira');
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Expected success to be false due to exception');
        System.assert(result.payloadMap.get('message') != null && String.valueOf(result.payloadMap.get('message')).contains('Error occurred'),
                      'Expected error message in payload');
    }
    
    /**
     * @description Mocks the connection result by creating a sample ResultMessage 
     *              containing the provided connection names and assigns it to 
     *              TemplateService.testConnectionResult for testing purposes.
     * @param connectionNames List of connection names to include in the mock ResultMessage.
     * @return void
     */
    public class MockAdminController {
        void mockConnectionResult(List<String> connectionNames) {
            ResultMessage mockResult = new ResultMessage(true, 'Mock connections');
            mockResult.payloadMap.put('connectionNames', connectionNames);
            TemplateService.testConnectionResult = mockResult;
        }
    }
    
    @isTest
    static void testServiceNowTicketCreation() {
        // Prepare ServiceNow input wrapper
        WrapperContainer.InputWrapper snInput = new WrapperContainer.InputWrapper();
        Service_Template__c template = [SELECT Id FROM Service_Template__c LIMIT 1];
        snInput.templateId = String.valueOf(template.Id);
        snInput.projectName = 'Incident';
        snInput.assigneeName = 'Test User';
        snInput.valuesMap = new Map<String,String>{
            'impact'=>'2',
                'urgency'=>'3',
                'short_description'=>'Test SN',
                'description'=>'Hello World'
                };
                    String snJson = JSON.serialize(snInput);
        String snMock = '{"result":{"sys_id":"abc123"}}';

        Test_TicketCreatorController.TestRunConfig cfg = new Test_TicketCreatorController.TestRunConfig()
            .withSystemName(Constant.SERVICENOW_SERVICE)
            .withTicketInputs(snJson)
            .withMockResponseBody(snMock)
            .withExpectedStatusCode(201)
            .withExpectedMessage('ServiceNow Ticket Created Successfully');

        Test_TicketCreatorController.runTicketCreationTest(cfg);

        System.assertEquals(true, true, 'ServiceNow ticket creation test executed successfully');
    }
    
    @isTest
    static void testJiraTicketCreation() {
        // Prepare Jira input wrapper
        WrapperContainer.InputWrapper jiraInput = new WrapperContainer.InputWrapper();
        Service_Template__c template = [SELECT Id FROM Service_Template__c LIMIT 1];
        jiraInput.templateId = String.valueOf(template.Id);
        jiraInput.projectName = 'TEST';
        jiraInput.assigneeName = 'Test User';
        jiraInput.projectKey = 'TEST';
        jiraInput.valuesMap = new Map<String,String>{
            'summary'=>'Test Jira',
                'description'=>'Jira test description',
                'priority'=>'High',
                'issuetype'=>'Task'
                };
                    String jiraJson = JSON.serialize(jiraInput);
        String jiraMock = '{"key":"JIRA-123"}';
        
        Test_TicketCreatorController.TestRunConfig cfg = new Test_TicketCreatorController.TestRunConfig()
            .withSystemName(Constant.JIRA_SERVICE)
            .withTicketInputs(jiraJson)
            .withMockResponseBody(jiraMock)
            .withExpectedStatusCode(201)
            .withExpectedMessage('Jira Ticket Created Successfully');

        Test_TicketCreatorController.runTicketCreationTest(cfg);

        System.assertEquals(true, true, 'Jira ticket creation test executed successfully');
    }
    
    @isTest
    static void testAzureTicketCreation() {
        // Prepare Azure input wrapper
        WrapperContainer.InputWrapper azureInput = new WrapperContainer.InputWrapper();
        Service_Template__c template = [SELECT Id FROM Service_Template__c LIMIT 1];
        azureInput.templateId = String.valueOf(template.Id);
        azureInput.projectName = 'Test Project';
        azureInput.assigneeName = 'Test User';
        azureInput.projectKey = 'Test Project';
        azureInput.valuesMap = new Map<String,String>{
            'System.Title'=>'Azure Test',
                'System.State'=>'New',
                'Priority'=>'High',
                'description'=>'Azure test description'
                };
                    String azureJson = JSON.serialize(azureInput);
        String azureMock = '{"id":12345}';

        Test_TicketCreatorController.TestRunConfig cfg = new Test_TicketCreatorController.TestRunConfig()
            .withSystemName(Constant.AZURE_SERVICE)
            .withTicketInputs(azureJson)
            .withMockResponseBody(azureMock)
            .withExpectedStatusCode(200)
            .withExpectedMessage('Azure Ticket Created Successfully');

        Test_TicketCreatorController.runTicketCreationTest(cfg);

        System.assertEquals(true, true, 'Azure ticket creation test executed successfully');
    }


   /**
     * @description Wrapper class used to configure and pass test parameters 
     *              for ticket creation tests (Jira, ServiceNow, Azure).
     *              Supports builder-style method chaining to avoid long parameter lists.
     */
    public class TestRunConfig {

        /** @description Name of the external system (Jira, ServiceNow, or Azure). */
        public String systemName;

        /** @description Serialized JSON input for the ticket creation request. */
        public String ticketInputs;

        /** @description Mock API response body to simulate an external system response. */
        public String mockResponseBody;

        /** @description Expected HTTP status code from the mock callout. */
        public Integer expectedStatusCode;

        /** @description Expected success message to verify in assertions. */
        public String expectedMessage;

        /**
         * @description Creates an empty TestRunConfig instance.
         *              Use builder methods to set configuration values fluently.
         */
        public TestRunConfig() {
            // intentionally empty for builder-style pattern
            return;
        }

        /**
         * @description Sets the external system name.
         * @param systemName The name of the external system (Jira, ServiceNow, or Azure).
         * @return The current TestRunConfig instance for chaining.
         */
        public TestRunConfig withSystemName(String systemName) {
            this.systemName = systemName;
            return this;
        }

        /**
         * @description Sets the serialized ticket input JSON.
         * @param ticketInputs The input JSON used for ticket creation.
         * @return The current TestRunConfig instance for chaining.
         */
        public TestRunConfig withTicketInputs(String ticketInputs) {
            this.ticketInputs = ticketInputs;
            return this;
        }

        /**
         * @description Sets the mock API response body for testing.
         * @param mockResponseBody The simulated API response to be returned by the mock callout.
         * @return The current TestRunConfig instance for chaining.
         */
        public TestRunConfig withMockResponseBody(String mockResponseBody) {
            this.mockResponseBody = mockResponseBody;
            return this;
        }

        /**
         * @description Sets the expected HTTP status code.
         * @param expectedStatusCode The expected HTTP status code returned by the mock callout.
         * @return The current TestRunConfig instance for chaining.
         */
        public TestRunConfig withExpectedStatusCode(Integer expectedStatusCode) {
            this.expectedStatusCode = expectedStatusCode;
            return this;
        }

        /**
         * @description Sets the expected success message.
         * @param expectedMessage The expected success message to assert in the test.
         * @return The current TestRunConfig instance for chaining.
         */
        public TestRunConfig withExpectedMessage(String expectedMessage) {
            this.expectedMessage = expectedMessage;
            return this;
        }
    }


    /**
     * @description Helper container for storing the results of attachment-related tests.
     */
    private class AttachmentResults {
        public ResultMessage badgetUploadedAttachments1;
        public ResultMessage deleteAttachment;
        public ResultMessage badRequestdeleteAttachment;
        public ResultMessage badServiceNowAttachment;
        public ResultMessage badJiraAttachment;
        public ResultMessage badAzureAttachment;
    }

    /**
     * @description Executes the unified ticket creation test for Jira, ServiceNow, or Azure systems.
     *              Validates HTTP mock responses, controller outcomes, and attachment service methods.
     * @param cfg Configuration wrapper containing all required test parameters.

     */
    public static void runTicketCreationTest(TestRunConfig cfg) {
        Service_Template__c template = [SELECT Id FROM Service_Template__c LIMIT 1];
        ContentDocumentLink cdl = createContentVersionAndLink(template);

        Test.setMock(HttpCalloutMock.class, new Mock_TicketCreatorController(cfg.mockResponseBody, 'Created', cfg.expectedStatusCode));
        WrapperContainer.InputWrapper input = (WrapperContainer.InputWrapper) JSON.deserialize(cfg.ticketInputs, WrapperContainer.InputWrapper.class);

        Test.startTest();
        HttpResponse diagResp = doDiagnosticCall(cfg.systemName, input, cfg.mockResponseBody);

        System.assertNotEquals(null, diagResp, 'DIAG FAILURE: ApiUtility returned NULL');
        System.assertEquals(cfg.expectedStatusCode, diagResp.getStatusCode(), 'DIAG: status code mismatch');

        ResultMessage result = invokeController(cfg.systemName, cfg.ticketInputs);
        AttachmentResults attachResults = runAttachmentHelpers(cdl.ContentDocumentId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.success, 'Expected success = true. If false, inspect result.message');
        System.assertEquals(cfg.expectedMessage, result.message, 'Expected result message to match the expectedMessage value');
        System.assert(result.payloadMap != null && result.payloadMap.size() > 0, 'payloadMap should not be empty');
        System.assert(result.payloadMap.containsKey('recordId'), 'Expected recordId in payloadMap');

        System.assertEquals(false, attachResults.badgetUploadedAttachments1.success, 'Expected success = true for null recordId');
        System.assertEquals(true, attachResults.deleteAttachment.success, 'Expected deleteAttachment.success to be true');
        System.assertEquals(false, attachResults.badRequestdeleteAttachment.success, 'Expected badRequestdeleteAttachment.success = false');
        System.assertEquals(false, attachResults.badServiceNowAttachment.success, 'Expected uploadAttachmentServiceNow to fail when given null attachments');
        System.assertEquals(false, attachResults.badJiraAttachment.success, 'Expected uploadAttachmentJira to fail when given null attachments');
        System.assertEquals(false, attachResults.badAzureAttachment.success, 'Expected uploadAttachmentAzure to fail when given null attachments');
    }

    /**
     * @description Creates and links a ContentVersion record to a Service_Template__c record
     *              to simulate attachment linkage during tests.
     * @param template The Service_Template__c record used as the parent.
     * @return ContentDocumentLink The created document link record.
     */
    private static ContentDocumentLink createContentVersionAndLink(Service_Template__c template) {
        ContentVersion cv = new ContentVersion(
            Title = 'testfile',
            PathOnClient = 'testfile.jpg',
            VersionData = Blob.valueOf('TestContent')
        );
        insert cv;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = template.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        return cdl;
    }

    /**
     * @description Performs a diagnostic HTTP call to validate that the registered HttpCalloutMock
     *              responds correctly for the given system and input configuration.
     * @param systemName The external system name (Jira, ServiceNow, or Azure).
     * @param input Deserialized input wrapper for the ticket creation call.
     * @param mockResponseBody The mock response body to simulate an API response.
     * @return HttpResponse The mock response returned by ApiUtility.httpPostRequest.
     */
    private static HttpResponse doDiagnosticCall(String systemName, WrapperContainer.InputWrapper input, String mockResponseBody) {
        HttpResponse diagResp;
        try {
            String endpoint;
            String contentType = Constant.CONTENT_TYPE_JSON_UTF8;

            if (systemName == Constant.JIRA_SERVICE) {
                endpoint = Constant.JIRA_LEGACY + Constant.JIRA_ISSUE_ENDPOINT;
            } else if (systemName == Constant.SERVICENOW_SERVICE) {
                endpoint = Constant.SERVICE_NOW_LEGACY + Constant.SERVICENOW_INCIDENTS_ENDPOINT;
            } else if (systemName == Constant.AZURE_SERVICE) {
                String projKey = input.projectKey;
                endpoint = Constant.AZURE_LEGACY + '/' + projKey + Constant.AZURE_WORKITEMS_ENDPOINT;
                contentType = Constant.CONTENT_TYPE_JSON_PATCH;
            } else {
                System.assert(false, 'Invalid system name for test: ' + systemName);
                return null;
            }

            diagResp = ApiUtility.httpPostRequest(endpoint, mockResponseBody, contentType);

        } catch (Exception ex) {
            diagResp = null;
        }
        return diagResp;
    }

    /**
     * @description Invokes the appropriate controller method based on the external system name.
     * @param systemName The target system (Jira, ServiceNow, or Azure).
     * @param ticketInputs The serialized input JSON string for the ticket creation call.
     * @return ResultMessage The result object returned by the corresponding controller.
     */
    private static ResultMessage invokeController(String systemName, String ticketInputs) {
        if (systemName == Constant.JIRA_SERVICE) {
            return TicketCreatorController.createJiraTicket(ticketInputs);
        } else if (systemName == Constant.SERVICENOW_SERVICE) {
            return TicketCreatorController.createServiceNowTicket(ticketInputs);
        } else if (systemName == Constant.AZURE_SERVICE) {
            return TicketCreatorController.createAzureTicket(ticketInputs);
        } else {
            System.assert(false, 'Invalid system name for test: ' + systemName);
            return null;
        }
    }

    /**
     * @description Executes and gathers results from all attachment helper methods to ensure
     *              attachment upload, deletion, and retrieval methods handle invalid input correctly.
     * @param contentDocumentId The ContentDocumentId used for testing valid and invalid scenarios.
     * @return AttachmentResults A structured object holding the outcomes of all attachment operations.
     */
    private static AttachmentResults runAttachmentHelpers(Id contentDocumentId) {
        AttachmentResults ar = new AttachmentResults();
        ar.badgetUploadedAttachments1 = TicketCreatorController.getUploadedAttachments(null);
        ar.deleteAttachment = TicketCreatorController.deleteAttachment(new List<Id>{contentDocumentId});
        ar.badRequestdeleteAttachment = TicketCreatorController.deleteAttachment(null);
        ar.badServiceNowAttachment = TicketAttachmentService.uploadAttachmentServiceNow(null, null);
        ar.badJiraAttachment = TicketAttachmentService.uploadAttachmentJira(null, null);
        ar.badAzureAttachment = TicketAttachmentService.uploadAttachmentAzure(null, null, null);
        return ar;
    }

}