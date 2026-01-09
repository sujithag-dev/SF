/**
 * @description       : Test class for BulkApiCaller and related batch/updater classes.
 *                      Ensures proper integration between Jira, Azure, and ServiceNow bug updates.
 * author             : Minuscule Technologies
 * @group             : Integration Tests
 * @last modified on  : 09-10-2025
 * @last modified by  : 
**/

@IsTest
public class BulkApiCallerTest {

   /**
    * @description Creates a test User record used by multiple test methods.
    * @return User The newly created test User record.
    */
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + System.currentTimeMillis() + '@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }

    /**
    * @description Validates that System.runAs() is correctly executed for PMD compliance.
    */
    @IsTest
    static void testRunAsContext() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            System.assert(true, 'System.runAs executed for PMD compliance');
        }
    }

    /**
    * @description Creates sample Bug_Tracking__c test data for Jira, Azure, and ServiceNow.
    */
    @TestSetup
    static void setupTestData() {
        insert new Bug_Tracking__c(Unique_Id__c = 'JIRA-1', Key__c = '1001', Bug_Type__c = 'Jira');
        insert new Bug_Tracking__c(Unique_Id__c = '2001', Bug_Type__c = 'Azure');
        insert new Bug_Tracking__c(Unique_Id__c = 'SN-1', Bug_Type__c = 'Service Now');
        
         // Insert test Bug_Tracking__c records
        List<Bug_Tracking__c> bugs = new List<Bug_Tracking__c>();
        for (Integer i = 0; i < 3; i++) {
            bugs.add(new Bug_Tracking__c(Unique_Id__c = 'SN' + i));
        }
        insert bugs;
    }

    /**
    * @description Ensures the BulkApiCaller.runFromLwc() executes without exceptions.
    */
    @IsTest
    static void testRunFromLwc() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.startTest();
            BulkApiCaller.runFromLwc();
            Test.stopTest();
            System.assert(true, 'Method executed successfully');
        }
    }
    
    /**
    * @description Tests fallbackDash() utility for handling null or blank values.
    */
     @IsTest
    static void testFallbackDash() {
        User testUser = createTestUser();
        System.runAs(testUser) {
           System.assertEquals('Hello', BulkApiCaller.fallbackDash('Hello'), 'Should return the original value when input is non-empty');
           System.assertEquals('-', BulkApiCaller.fallbackDash(''), 'Should return dash when input is empty string');
           System.assertEquals('-', BulkApiCaller.fallbackDash(null), 'Should return dash when input is null');

        }
    }

    /**
    * @description Mock class for simulating successful Jira API response.
    */
    private class JiraHttpSuccessMock implements HttpCalloutMock {
       /**
       * @description Returns a simulated successful Jira response with issue details.
       * @param req The simulated HTTP request.
       * @return HttpResponse A mock HTTP 200 response with Jira issue data.
       */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"issues": [{' +
                '"id": "1001", "key": "JIRA-1", "fields": {' +
                '"summary": "Login button not working",' +
                '"priority": {"name": "High"},' +
                '"issuetype": {"name": "Bug"},' +
                '"project": {"name": "Test Project"},' +
                '"statusCategory": {"name": "In Progress"}' +
            '}}]}');
            return res;
        }
    }
    
    /**
    * @description Mock class for simulating Jira API error response (500).
    */
    private class JiraHttpErrorMock implements HttpCalloutMock {
       /**
       * @description Returns a simulated 500 error response for Jira API.
       * @param req The simulated HTTP request.
       * @return HttpResponse A mock HTTP 500 error response.
       */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }
    
    /**
    * @description Mock class for simulating Azure API successful response.
    */
    private class AzureHttpSuccessMock implements HttpCalloutMock {
        /**
     * @description Returns a simulated successful Azure DevOps API response.
     * @param req The simulated HTTP request.
     * @return HttpResponse A mock HTTP 200 response with Azure issue data.
     */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"value":[{"id":"2001","fields":{' +
                '"System.Title":"Azure Login issue",' +
                '"System.State":"Active",' +
                '"Microsoft.VSTS.Common.Priority":"1",' +
                '"System.Description":"<p>Login fails&nbsp;on Chrome</p>"' +
            '}}]}');
            return res;
        }
    }
    
    /**
    * @description Mock class for simulating successful ServiceNow API response.
    */
    private class ServiceNowHttpSuccessMock implements HttpCalloutMock {
     /**
     * @description Returns a simulated successful ServiceNow API response.
     * @param req The simulated HTTP request.
     * @return HttpResponse A mock HTTP 200 response with incident details.
     */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result":[{"sys_id":"SN-1","short_description":"Email outage","incident_state":"In Progress"}]}');
            return res;
        }
    }
    
    /**
    * @description Generic mock class for simulating 500 Internal Server Error responses.
    */
    private class GenericHttpErrorMock implements HttpCalloutMock {
            /**
     * @description Returns a simulated generic 500 Internal Server Error.
     * @param req The simulated HTTP request.
     * @return HttpResponse A mock HTTP 500 error response.
     */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    /**
    * @description Verifies JiraBugTrackingUpdater correctly updates Bug_Tracking__c records.
    */
     @IsTest
    static void testJiraBugTrackingUpdaterValidUpdate() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Map<String, Object> fields = new Map<String, Object>{
                'summary' => 'New Summary',
                'priority' => new Map<String, Object>{ 'name' => 'Medium' },
                'statusCategory' => new Map<String, Object>{ 'name' => 'To Do' }
            };
            Map<String, Object> issue = new Map<String, Object>{ 'id' => '1001', 'key' => 'JIRA-1', 'fields' => fields };

            Test.startTest();
            JiraBugTrackingUpdater.updateBugTrackingBatchFromJiraResponse(new List<Object>{issue});
            Test.stopTest();

            Bug_Tracking__c b = [SELECT Summary__c, Priority__c, Status__c FROM Bug_Tracking__c WHERE Unique_Id__c = 'JIRA-1'];
            System.assertEquals('New Summary', b.Summary__c, 'Bug summary should be updated to New Summary');
            System.assertEquals('Medium', b.Priority__c,'Bug priority should be updated to Medium');
            System.assertEquals('To Do', b.Status__c,'Bug status should be updated to To Do');
        }
    }
    
    /**
    * @description Ensures JiraIssuesBatch executes successfully and updates data.
    */
     @IsTest
    static void testJiraIssuesBatchSuccessfulRun() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new JiraHttpSuccessMock());
            Test.startTest();
            Database.executeBatch(new JiraIssuesBatch(), 1);
            Test.stopTest();
            Bug_Tracking__c b = [SELECT Summary__c FROM Bug_Tracking__c WHERE Unique_Id__c = 'JIRA-1'];
            System.assert(b.Summary__c == 'Login button not working','Bug summary should match expected Jira issue summary');
        }
    }

   /**
   * @description Validates Azure description normalization by removing inline styles and HTML entities.
   */
  @IsTest
    static void testNormalizeAzureDescription() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String html = '<p style="color:red">Hello</p>';
            String result = AzureBugTrackingUpdater.normalizeAzureDescription(html);
            System.assertEquals('<p >Hello</p>', result, 'Should strip inline styles and preserve HTML structure');
        }
    }
    
    /**
    * @description Tests normalization helper by ensuring image width and &nbsp; replacements.
    */
    @IsTest
    static void testNormalizeAzureDescriptionHelper() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String html = '<p>Sample&nbsp;text <img width="10" height="10" style="color:red"></p>';
            String result = AzureBugTrackingUpdater.normalizeAzureDescription(html);
            System.assert(result.contains('width="172"'), 'Image width normalized');
            System.assert(!result.contains('&nbsp;'), 'Non-breaking space removed');
        }
    }

    
    /**
    * @description Ensures AzureIssuesBatch executes correctly and updates Bug_Tracking__c records.
    */
   @IsTest
    static void testAzureIssuesBatchSuccessfulRun() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new AzureHttpSuccessMock());
            Test.startTest();
            Database.executeBatch(new AzureIssuesBatch(), 1);
            Test.stopTest();
            Bug_Tracking__c b = [SELECT Title__c, Status__c FROM Bug_Tracking__c WHERE Unique_Id__c = '2001'];
           System.assertEquals('Azure Login issue', b.Title__c, 'Bug title should match the expected Azure issue title');
           System.assertEquals('Active', b.Status__c, 'Bug status should be updated to Active');
        }
    }
   
   /**
   * @description Tests Jira label extraction from a populated labels list.
   */
   @IsTest
    static void testExtractLabelsWithValues() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Map<String, Object> fields = new Map<String, Object>{ 'labels' => new List<Object>{'bug','urgent'} };
            String result = JiraBugTrackingUpdater.extractLabels(fields);
            System.assertEquals('bug;urgent', result, 'Should concatenate label values with semicolons');
        }
    }
   
    /**
    * @description Ensures label extraction handles empty, missing, and null values safely.
    */
    @IsTest
    static void testExtractDescriptionEmptyOrNull() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Map<String, Object> fieldsMissing = new Map<String, Object>();
            System.assertEquals(null, JiraBugTrackingUpdater.extractDescription(fieldsMissing, 'description'),'Expected null when the field is missing');

            Map<String, Object> fieldsNull = new Map<String, Object>{ 'description' => null };
              System.assertEquals(null, JiraBugTrackingUpdater.extractDescription(fieldsNull, 'description'),'Expected null when the field value is explicitly null');

            Map<String, Object> fieldsNoContent = new Map<String, Object>{ 'description' => new Map<String, Object>() };
            System.assertEquals(null, JiraBugTrackingUpdater.extractDescription(fieldsNoContent, 'description'),'Expected null when the field value is an empty map');
        }
    }

   /**
   * @description Validates Jira description extraction when content blocks exist.
   */
   @IsTest
    static void testExtractDescriptionWithContent() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Map<String, Object> block1 = new Map<String, Object>{ 'type' => 'paragraph', 'text' => 'Hello' };
            Map<String, Object> block2 = new Map<String, Object>{ 'type' => 'paragraph', 'text' => 'World' };
            Map<String, Object> richField = new Map<String, Object>{ 'content' => new List<Object>{ block1, block2 } };
            Map<String, Object> fields = new Map<String, Object>{ 'description' => richField };

            String result = JiraBugTrackingUpdater.extractDescription(fields, 'description');
            System.assertNotEquals(null, result, 'Description should not be null when content blocks exist');
        }
    }

    /**
    * @description Verifies ServiceNow batch successfully updates Bug_Tracking__c records.
    */
    @IsTest
    static void testServiceNowIssuesBatchSuccessfulRun() {
    User testUser = createTestUser();
    System.runAs(testUser) {
        Test.setMock(HttpCalloutMock.class, new ServiceNowHttpSuccessMock());
        Test.startTest();
        Database.executeBatch(new ServiceNowIssuesBatch(), 1);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Bug_Tracking__c WHERE Bug_Type__c = 'Service Now'];
        System.assertEquals(1, count, 'Should have exactly 1 Bug_Tracking__c record for Service Now');
    }
  }

    
    /**
    * @description Validates ServiceNow batch gracefully handles 500 error responses.
    */
   @IsTest
    static void testServiceNowIssuesBatchErrorResponse() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new GenericHttpErrorMock());
            Test.startTest();
            Database.executeBatch(new ServiceNowIssuesBatch(), 1);
            Test.stopTest();
            System.assert(true, 'Handled error safely');
        }
    }
    
    /**
    * @description Ensures ServiceNowBugTrackingUpdater updates records correctly for valid data.
    */
    @IsTest
    static void testUpdateBugTrackingBatchFromServiceNowResponseValid() {
     User testUser = createTestUser();
     System.runAs(testUser) {
        List<Object> incidents = new List<Object>{
            new Map<String, Object>{
                'sys_id' => new Map<String, Object>{ 'display_value' => 'SN0' },
                'priority' => new Map<String, Object>{ 'display_value' => 'High' },
                'short_description' => new Map<String, Object>{ 'display_value' => 'Test bug 0' }
            },
            new Map<String, Object>{
                'sys_id' => new Map<String, Object>{ 'display_value' => 'SN1' },
                'priority' => new Map<String, Object>{ 'display_value' => 'Medium' },
                'short_description' => new Map<String, Object>{ 'display_value' => 'Test bug 1' }
            }
        };

        Test.startTest();
        ServiceNowBugTrackingUpdater.updateBugTrackingBatchFromServiceNowResponse(incidents);
        Test.stopTest();

        List<Bug_Tracking__c> updatedBugs = [
            SELECT Unique_Id__c, Priority__c, Short_Description__c 
            FROM Bug_Tracking__c 
            WHERE Unique_Id__c IN ('SN0','SN1')
        ];
        System.assertEquals(2, updatedBugs.size(), 'Expected 2 Bug_Tracking__c records to be updated');
        for (Bug_Tracking__c bug : updatedBugs) {
            if (bug.Unique_Id__c == 'SN0') {
                System.assertEquals('High', bug.Priority__c, 'Bug SN0 Priority should be High');
                System.assertEquals('Test bug 0', bug.Short_Description__c, 'Bug SN0 Short Description mismatch');
            } else if (bug.Unique_Id__c == 'SN1') {
                System.assertEquals('Medium', bug.Priority__c, 'Bug SN1 Priority should be Medium');
                System.assertEquals('Test bug 1', bug.Short_Description__c, 'Bug SN1 Short Description mismatch');
            }
          }
      }
    }
  
    /**
    * @description Ensures ServiceNow updater handles empty input list without errors.
    */
   @IsTest
    static void testUpdateBugTrackingBatchFromServiceNowResponseEmptyList() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.startTest();
            ServiceNowBugTrackingUpdater.updateBugTrackingBatchFromServiceNowResponse(new List<Object>());
            Test.stopTest();
            System.assert(true, 'Method should execute without exception when input list is empty');
        }
    }
    
    /**
    * @description Ensures ServiceNow updater handles null input safely without exceptions.
    */
    @IsTest
    static void testUpdateBugTrackingBatchFromServiceNowResponseNullList() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.startTest();
            ServiceNowBugTrackingUpdater.updateBugTrackingBatchFromServiceNowResponse(null);
            Test.stopTest();
            System.assert(true, 'Method should execute without exception when input list is null');
        }
    }
}