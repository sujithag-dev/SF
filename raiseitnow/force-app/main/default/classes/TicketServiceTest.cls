/**
* @description       : TicketServiceTest is a comprehensive test class that validates the functionality of TicketService.
*                      It ensures proper handling of Bug_Tracking__c record retrieval, JSON parsing, field merging,
*                      and error handling for ServiceNow, Azure, and Jira integrations.
* author             : Minuscule Technologies
* @group             : 
* @last modified on  : 10-10-2025
* @last modified by  : 
**/
/**
* @description Ensures TicketService methods correctly handle Bug_Tracking__c queries,
*              merge external service responses, and manage JSON parse scenarios.
*/
@IsTest
public class TicketServiceTest {

   /**
     * @description Helper method to create a Bug_Tracking__c record for testing.
     * @param uniqueId The unique identifier for the bug record.
     * @return Bug_Tracking__c The inserted bug record.
     */
    private static Bug_Tracking__c createBug(String uniqueId) {
        Bug_Tracking__c bug = new Bug_Tracking__c(
            Unique_Id__c = uniqueId,
            Title__c = 'Test Bug',
            Description__c = 'Bug description'
        );
        insert bug;
        return bug;
    }

   /**
     * @description Helper method to create a Bug_Response__c record for testing.
     * @param azureJson The Azure JSON string.
     * @param jiraJson The Jira JSON string.
     * @param snJson The ServiceNow JSON string.
     * @return Bug_Response__c The inserted response record.
     */
    private static Bug_Response__c createResponse(String azureJson, String jiraJson, String snJson) {
        Bug_Response__c resp = new Bug_Response__c(
            Azure_Response__c = azureJson,
            Jira_Response__c = jiraJson,
            ServiceNow_Response__c = snJson
        );
        insert resp;
        return resp;
    }

 /**
     * @description Tests fetching a ServiceNow Bug record by Id.
     */
    @IsTest
    static void testGetServiceNowBugRecord() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('SN-123');
            Test.startTest();
            Bug_Tracking__c result = TicketService.getServiceNowBugRecord(bug.Id);
            Test.stopTest();
            System.assertNotEquals(null, result, 'ServiceNow Bug record should be returned');
        }
    }

      /**
     * @description Tests fetching latest ServiceNow JSON response.
     */
    @IsTest
    static void testGetLatestServiceNowResponse() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            createResponse(null, null, '{"fields":{"Unique_Id__c":"SN-123"}}');
            Test.startTest();
            String result = TicketService.getLatestServiceNowResponse();
            Test.stopTest();
            System.assertNotEquals(null, result, 'Expected ServiceNow JSON response to be returned');
        }
    }

    /**
     * @description Tests merging valid ServiceNow JSON fields.
     */
    @IsTest
    static void testMergeServiceNowFields() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('SN-123');
            Map<String, Object> recordMap = new Map<String, Object>();
            String json = '{"fields":{"Unique_Id__c":"SN-123","Status__c":"Open"}}';

            Map<String, Object> result = TicketService.mergeServiceNowFields(bug, recordMap, json);
            System.assertEquals(true, result.get('success'), 'Expected ServiceNow merge success');
            System.assertEquals('Open', recordMap.get('Status__c'), 'Expected Status__c field to merge correctly');
        }
    }

   /**
     * @description Tests fetching Azure Bug record.
     */
    @IsTest
    static void testGetAzureBugRecord() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('AZ-123');
            Test.startTest();
            Bug_Tracking__c result = TicketService.getBugRecord(bug.Id);
            Test.stopTest();
            System.assertNotEquals(null, result, 'Expected Azure Bug record to be returned');
        }
    }

  /**
     * @description Tests fetching latest Azure response.
     */
    @IsTest
    static void testGetLatestAzureResponse() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            createResponse('{"fields":{"Unique_Id__c":"AZ-123"}}', null, null);
            Test.startTest();
            String result = TicketService.getLatestAzureResponse();
            Test.stopTest();
            System.assertNotEquals(null, result, 'Expected Azure JSON response to be returned');
        }
    }

    /**
     * @description Tests merging valid Azure fields.
     */
    @IsTest
    static void testMergeAzureFields() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('AZ-123');
            Map<String, Object> recordMap = new Map<String, Object>();
            String json = '{"fields":{"Unique_Id__c":"AZ-123","Priority__c":"High"}}';

            Map<String, Object> result = TicketService.mergeAzureFields(bug, recordMap, json);
            System.assertEquals(true, result.get('success'), 'Expected Azure merge success');
            System.assertEquals('High', recordMap.get('Priority__c'), 'Expected Priority__c to merge correctly');
        }
    }

     /**
     * @description Tests fetching Jira Bug record.
     */
    @IsTest
    static void testGetJiraBugRecord() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('JIRA-123');
            Test.startTest();
            Bug_Tracking__c result = TicketService.getJiraBugRecord(bug.Id);
            Test.stopTest();
            System.assertNotEquals(null, result, 'Expected Jira Bug record to be returned');
        }
    }

   /**
     * @description Tests fetching latest Jira JSON response.
     */
    @IsTest
    static void testGetLatestJiraResponse() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            createResponse(null, '{"fields":{"Unique_Id__c":"JIRA-123"}}', null);
            Test.startTest();
            String result = TicketService.getLatestJiraResponse();
            Test.stopTest();
            System.assertNotEquals(null, result, 'Expected Jira JSON response to be returned');
        }
    }

   
    /**
     * @description Tests merging valid Jira JSON fields.
     */
    @IsTest
    static void testMergeJiraFields() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('JIRA-123');
            Map<String, Object> recordMap = new Map<String, Object>();
            String json = '{"fields":{"Unique_Id__c":"JIRA-123","Summary__c":"Test Summary"}}';

            Map<String, Object> result = TicketService.mergeJiraFields(bug, recordMap, json);
            System.assertEquals(true, result.get('success'), 'Expected Jira merge success');
            System.assertEquals('Test Summary', recordMap.get('Summary__c'), 'Expected Summary__c to merge correctly');
        }
    }

 /**
     * @description Tests empty JSON merge case.
     */
    @IsTest
    static void testEmptyJsonMerge() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('SN-EMPTY');
            Map<String, Object> recordMap = new Map<String, Object>();
            Map<String, Object> result = TicketService.mergeServiceNowFields(bug, recordMap, '{}');
            System.assertEquals(true, result.get('success'), 'Expected success for empty JSON');
            System.assertEquals(true, recordMap.isEmpty(), 'Expected no fields merged for empty JSON');
        }
    }

    /**
     * @description Tests latest response fetch methods when no responses exist.
     */
    @IsTest
    static void testGetLatestResponsesWhenNoneExist() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            String snResp = TicketService.getLatestServiceNowResponse();
            String azResp = TicketService.getLatestAzureResponse();
            String jiraResp = TicketService.getLatestJiraResponse();
            Test.stopTest();

            System.assertEquals(null, snResp, 'Expected null ServiceNow response when none exist');
            System.assertEquals(null, azResp, 'Expected null Azure response when none exist');
            System.assertEquals(null, jiraResp, 'Expected null Jira response when none exist');
        }
    }

   /**
     * @description Tests invalid non-JSON string for Azure.
     */
    @IsTest
    static void testInvalidJsonHandling() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('BAD-JSON');
            Map<String, Object> recordMap = new Map<String, Object>();
            String badJson = 'NOT_JSON';

            Map<String, Object> result = TicketService.mergeAzureFields(bug, recordMap, badJson);
            System.assertEquals(false, result.get('success'), 'Expected failure for invalid Azure JSON');
            System.assert(result.get('message').toString().contains('not JSON'), 'Expected invalid JSON message');
        }
    }

   /**
     * @description Tests Jira JSON parse exception (malformed input).
     */
    @IsTest
    static void testJsonParseException() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('ERR-JSON');
            Map<String, Object> recordMap = new Map<String, Object>();
            String badJson = '{"fields":'; 

            Map<String, Object> result = TicketService.mergeJiraFields(bug, recordMap, badJson);
            System.assertEquals(false, result.get('success'), 'Expected Jira parse exception failure');
            System.assert(result.get('message').toString().startsWith('Failed to parse'), 'Expected message to indicate Jira parse failure');
        }
    }
    
    /**
     * @description Tests invalid (non-JSON) ServiceNow response handling.
     */
    @IsTest
    static void testInvalidServiceNowJson() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('SN-BAD');
            Map<String, Object> recordMap = new Map<String, Object>();
            String invalidJson = 'NOT_JSON';

            Map<String, Object> result = TicketService.mergeServiceNowFields(bug, recordMap, invalidJson);
            System.assertEquals(false, result.get('success'), 'Expected ServiceNow merge to fail for invalid JSON');
            System.assert(result.get('message').toString().contains('not JSON'), 'Expected message to mention invalid JSON format');
        }
    }

    /**
     * @description Tests Azure invalid JSON handling.
     */
    @IsTest
    static void testInvalidAzureJson() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('AZ-BAD');
            Map<String, Object> recordMap = new Map<String, Object>();
            String invalidJson = '{"fields":';  // malformed JSON

            Map<String, Object> result = TicketService.mergeAzureFields(bug, recordMap, invalidJson);
            System.assertEquals(false, result.get('success'), 'Expected Azure JSON parse failure');
            System.assert(result.get('message').toString().startsWith('Failed to parse Azure JSON'), 'Expected message to indicate Azure parse failure');
        }
    }

     /**
     * @description Tests Jira invalid non-JSON input handling.
     */
    @IsTest
    static void testInvalidJiraJson() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('JIRA-BAD');
            Map<String, Object> recordMap = new Map<String, Object>();
            String invalidJson = 'NOT_JSON';

            Map<String, Object> result = TicketService.mergeJiraFields(bug, recordMap, invalidJson);
            System.assertEquals(false, result.get('success'), 'Expected Jira merge failure for invalid JSON');
            System.assert(result.get('message').toString().contains('not JSON'), 'Expected invalid JSON message');
        }
    }

      /**
     * @description Tests ServiceNow JSON parse exception (invalid JSON structure).
     */
    @IsTest
    static void testServiceNowJsonParseException() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(testUser) {
            Bug_Tracking__c bug = createBug('SN-PARSE');
            Map<String, Object> recordMap = new Map<String, Object>();
            String badJson = '{"fields":'; // malformed JSON

            Map<String, Object> result = TicketService.mergeServiceNowFields(bug, recordMap, badJson);
            System.assertEquals(false, result.get('success'), 'Expected merge failure due to invalid JSON');
            System.assert(result.get('message').toString().startsWith('Failed to parse ServiceNow JSON'), 'Expected message to indicate parse failure');
        }
    }
}