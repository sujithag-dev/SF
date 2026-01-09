/**
 * @description       : Test_AdminServiceTemplateHelper Class is used to test the AdminController class functionality.
 * author             : Minuscule Technologies 
 * @group             : 
 * @last modified on  : 
 * last modified by   : 
**/

/**
* @description  Test_AdminServiceTemplateHelper is used to test the AdminServiceTemplateHelper class functionality.
*
*/

 @IsTest
public class Test_AdminServiceTemplateHelper {
	/**
     * @description This nested class is a mock implementation of the HttpCalloutMock interface
     * It is used to simulate HTTP responses for testing purposes.
     */
	  public class Mock_AdminServiceTemplateHelper implements HttpCalloutMock{ 
		 private String body;
         private String statusMsg;
         private integer statusCode;              
        /**
         * @description Constructor to initialize the mock response attributes.
         * @param body The body content of the mock HTTP response.
         * @param statusMsg The status message of the mock HTTP response.
         * @param statusCode The status code of the mock HTTP response.
         */
        public Mock_AdminServiceTemplateHelper(String body, String statusMsg, Integer statusCode){
            this.body = body;
            this.statusMsg = statusMsg;
            this.statusCode = statusCode;
        }
		 /**
         * @description Method to generate a mock HTTP response based on the initialized attributes.
         * @param req The HTTP request for which the response is being mocked.
         * @return The mocked HTTP response.
         */
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type',Constant.CONTENT_TYPE_JSON_UTF8);
            res.setBody(this.body);
            res.setStatus(this.statusMsg);
            res.setStatusCode(this.statusCode);
            res.setStatus('Created');
            return res;
        } 

	  }
      @TestSetup
     static void setupTestData() {
        // Insert a record with null Project_Name__c
        insert new Service_Template__c();
     }

	    @isTest
    static void testGetProjectNamesInvalidService() {
        Test.setMock(HttpCalloutMock.class, new Mock_AdminServiceTemplateHelper('', 'Bad Request', 400));
        Test.startTest();
        try {
            AdminServiceTemplateHelper.getProjectNames('InvalidService');
            System.assert(false, 'Expected CustomException');
        } catch (CustomException e) {
            System.assert(e.getMessage().contains('Invalid service name'), 'Expected invalid service message');
        }
        Test.stopTest();
    }
	
	    @isTest
    static void testGetProjectNamesValidServiceWithInvalidCode() {
        Test.setMock(HttpCalloutMock.class, new Mock_AdminServiceTemplateHelper('', 'Bad Request', 400));
        Test.startTest();
        try {
            AdminServiceTemplateHelper.getProjectNames(Constant.JIRA_SERVICE);
            System.assert(false, 'Expected CustomException');
        } catch (CustomException e) {
            System.assert(e.getMessage().contains('HTTP request failed with status code'), 'Expected HTTP status code failure message');
        }
        Test.stopTest();
    }
	 @isTest
    static void testGetProjectNamesAzure() {
        Test.setMock(HttpCalloutMock.class,new Mock_AdminServiceTemplateHelper('{"count":  1, "value":  [{"id":  "82a87cd7-a253-4153-aae6-817f8770e496", "name":  "TestProject"}]}','OK',200));
        Test.startTest();  
        Map<String, String> resultAzure = AdminServiceTemplateHelper.getProjectNames(Constant.AZURE_SERVICE);
        System.assertNotEquals(null, resultAzure, 'Expected result for Azure not to be null');
        Test.stopTest();
    }
    @isTest
    static void testGetProjectNamesJira() {
        //Test.setMock(HttpCalloutMock.class,new Mock_AdminServiceTemplateHelper('[{"projects":[{"name":"Project 2","key":"KEY2"}]},{"name":"Project 2","key":"KEY2"}]}]','OK',200));        
        String mockResponse = '{"projects":[{"name":"Project 2","key":"KEY2"}]}';
        Test.setMock(HttpCalloutMock.class,new Mock_AdminServiceTemplateHelper(mockResponse, 'OK', 200));        
		Test.startTest();  
        Map<String, String> resultJira = AdminServiceTemplateHelper.getProjectNames(Constant.JIRA_SERVICE);        
        System.assertNotEquals(null, resultJira, 'Expected result for Jira not to be null');
        Test.stopTest();
    }

	 @isTest
    static void testGetTemplatePositive() {
        Test.startTest();
        Service_Template__c template = new Service_Template__c(Service_Name__c = 'Test Service');
        insert template;
        List<Service_Template__c> result = AdminServiceTemplateHelper.getTemplate('Test Service');
        System.assertNotEquals(0, result.size(), 'Expected result size to be greater than 0');
        Test.stopTest();
    }
    
    @isTest
    static void testGetTemplateNullServiceName() {
        Test.startTest();
        try {
            String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
            Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id,
                              TimeZoneSidKey='America/Los_Angeles',
                              UserName=uniqueUserName);
            system.runas(u){
                List<Service_Template__c> result = AdminServiceTemplateHelper.getTemplate(null);
                System.assertNotEquals(null, result, 'Expected result not to be null');
            }
            
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Incorrect exception message'); 
        }
        Test.stopTest();
    }
	  @isTest
    static void testGetTemplateInaccessibleObject() {
        Test.startTest();
        try {
            String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = p.Id,
                              TimeZoneSidKey='America/Los_Angeles',
                              UserName=uniqueUserName);
            system.runas(u){
                List<Service_Template__c> result = AdminServiceTemplateHelper.getTemplate('Test Service');
                System.assertNotEquals(null, result, 'Expected result  not to be null');
            }
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Incorrect exception message');
        }
        Test.stopTest();
    }
    
    private static List<Service_Template__c> createServiceTemplatesSingleData(String serviceName,String projName) {
        List<Service_Template__c> templates = new List<Service_Template__c>();
        
            Service_Template__c template = new Service_Template__c();
            template.Project_Name__c = projName;
            template.Service_Name__c = serviceName;
            template.Project_Keys__c = 'Test';
            templates.add(template);
       
        insert templates;
        return templates;
    }
    private static List<Service_Template__c> createServiceTemplatesBulkData(Integer numRecords, String serviceName,String projName) {
       List<Service_Template__c> templates = new List<Service_Template__c>();
        for (Integer i = 0; i < numRecords; i++) {
            Service_Template__c template = new Service_Template__c();
            template.Project_Name__c = projName + i;
            template.Service_Name__c = serviceName;
            template.Project_Keys__c = 'Test ' + i;
            templates.add(template);
        }
        insert templates;
        return templates;
    }

    @isTest
    static void testGetTemplateDetailsSuccess1() {
        String serviceName = Constant.SERVICENOW_SERVICE;
        String projName = 'Incident';
        createServiceTemplatesSingleData(serviceName,projName); 
        Test.startTest();
        ResultMessage result = AdminServiceTemplateHelper.getTemplateDetails(serviceName);
        Test.stopTest();
        System.assertEquals(true, result.success, 'Expected success to be true');
         
    }
     @isTest
    static void testGetTemplateDetailsSuccess2() {
        String serviceName = Constant.SERVICENOW_SERVICE;
        String projName = 'Incident';
        createServiceTemplatesBulkData(5, serviceName,projName); 
        Test.startTest();
        ResultMessage result = AdminServiceTemplateHelper.getTemplateDetails(serviceName);
        Test.stopTest();
        System.assertEquals(true, result.success, 'Expected success to be true');
         
    }
    
    @isTest
    static void testGetTemplateDetailsCatchBlock() {      
        Test.startTest();
        ResultMessage result = AdminServiceTemplateHelper.getTemplateDetails('Invalid_Service_That_Throws');
        Test.stopTest();
        // Assert that it entered the catch block
        System.assertEquals(false, result.success,'Expected success to be false when an exception occurs in getTemplateDetails.');
        System.assert(result.message.startsWith('Error:'), 'Expected an error message to be set.');
    }
    @isTest
   static void testFetchTemplatesInvalidInputIfBlock() {
     Test.startTest();
      try {
         AdminServiceTemplateHelper.fetchTemplates('Jira');
         //System.assert(false, 'Expected AuraHandledException was not thrown');
      } catch (AuraHandledException e) {
          System.assertEquals('Script-thrown exception', e.getMessage(), 'Incorrect exception message'); 
      }
       Test.stopTest();
    }
    @isTest
  static void testParseProjectsUnsupportedService() {
      Test.startTest();
      try {
         // Pass an unsupported service name to trigger the else block
         AdminServiceTemplateHelper.parseProjects('ServiceNow', '{}'); // or any invalid name
         System.assert(false, 'Expected CustomException was not thrown');
     } catch (CustomException e) {
         System.assert(e.getMessage().contains('Unsupported service'), 'Expected unsupported service exception');
     }
     Test.stopTest();
   }

   @isTest
  static void testAzureResponseProcessorRequestNullResultAndResponse() {
    Test.startTest();
    try {
        // Create object with null result and null response
        WrapperContainer.AzureResponseProcessorRequest request = new WrapperContainer.AzureResponseProcessorRequest();
        request.projKey = 'TestProject'; // Provide valid project key to avoid second check
        request.validate(); // This should throw IllegalArgumentException
        System.assert(false, 'Expected IllegalArgumentException was not thrown');
    } catch (IllegalArgumentException e) {
        System.assertEquals('Result and Response cannot be null', e.getMessage(), 'Incorrect exception message');
    }
    Test.stopTest();
  }
  @isTest
  static void testJiraTicketResponseProjectField() {
    Test.startTest();
    // Create and populate JiraTicketResponse object
    WrapperContainer.JiraTicketResponse response = new WrapperContainer.JiraTicketResponse();
    response.key = 'PROJ-123';
    response.project = 'TestProject';
    // Assertions to verify field population
    System.assertEquals('PROJ-123', response.key, 'Ticket key should match');
    System.assertEquals('TestProject', response.project, 'Project name should match');
    Test.stopTest();
  }
   @isTest
    static void testGetUniqueIdelseBlock() {
        TicketRecordHelper.BugDataWrapper wrapper = new TicketRecordHelper.BugDataWrapper();      
        wrapper.serviceData = new WrapperContainer.ServiceNowTicketResponse();

        Test.startTest();
        String result = TicketRecordHelper.getUniqueId('RandomType', wrapper);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected null for unsupported bugType in getUniqueId');
    }

    @isTest
    static void testGetProjectNameelseBlock() {
        TicketRecordHelper.BugDataWrapper wrapper = new TicketRecordHelper.BugDataWrapper();
        wrapper.azureData = new WrapperContainer.AzureGetAPIData();
        wrapper.azureData.project = 'AzureProject';

        Test.startTest();
        String result = TicketRecordHelper.getProjectName('InvalidBugType', 'SomeProject', wrapper);
        Test.stopTest();

        System.assertEquals(null, result, 'Expected null for unsupported bugType in getProjectName');
    }
    
 @isTest
    static void testFetchContentVersionsreturnsEmptyListwhenNoFilters() {
        Test.startTest();
        List<ContentVersion> versions = AttachmentManager.fetchContentVersions( new List<Id>(),'');
        Test.stopTest();
        System.assert(versions != null, 'Returned list should not be null');
        System.assertEquals(0, versions.size(), 'Expected empty list when no filters are applied');
    }
   @isTest
    static void testFetchProjectNamereturnsEmptyStringwhenNoTemplateOrNullProjectName() {
        Test.startTest();
       
        String missingResult = AttachmentManager.fetchProjectName('a0B000000000000AAA');
        System.assertEquals('', missingResult, 'Expected empty string for non-existent record');
       
        Test.stopTest();
    }
     	
}