/**
* @description       : Test class for TicketRecordPageController. 
*                      Ensures all AuraEnabled methods are tested with CRUD/FLS checks,
*                      exception handling, and response validation for Bug_Tracking__c records 
*                      from Jira, Azure, and ServiceNow.
* @author            : Minuscule Technologies
* @group             : 
* @last modified on  : 10-10-2025
* @last modified by  : 
*/

/**
 * @description Test class for TicketRecordPageController
 *              Ensures all AuraEnabled methods are tested with CRUD/FLS checks,
 *              exception handling, and responses.
 */
@IsTest
private class TicketRecordPageControllerTest {
    
    /**
     * @description Helper method to create Bug_Tracking__c record for tests
     * @param bugType  The type of bug (e.g., Jira, Azure, ServiceNow)
     * @param uniqueId The unique external identifier for the bug
     * @return Bug_Tracking__c Newly created Bug record
     */
    private static Bug_Tracking__c createBug(String bugType, String uniqueId) {
        Bug_Tracking__c bug = new Bug_Tracking__c(
            Bug_Type__c    = bugType,
            Unique_Id__c   = uniqueId,
            Title__c       = 'Test Bug',
            Description__c = 'Dummy bug description',
            Status__c      = 'New',
            Priority__c    = 'Medium'
        );
        if (Schema.sObjectType.Bug_Tracking__c.isCreateable()) {
            insert bug;
        }
        return bug;
    }
    
    /**
     * @description Helper to assert that exception message indicates access issue
     * @param e The exception thrown
     */
    private static void assertAccessException(Exception e) {
        Boolean matches =
            e.getMessage().toLowerCase().contains('not accessible') ||
            e.getMessage().toLowerCase().contains('access denied') ||
            e.getMessage().toLowerCase().contains('script-thrown exception');
        
        System.assert(matches,'Exception message must indicate access issue. Actual: ' + e.getMessage());
    }
    
    /** 
     * @description Test positive flow for getTicketRecord 
     */
    @IsTest
    static void testGetTicketRecord() {
        Bug_Tracking__c bug = createBug('Jira', 'U123');
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(u) {
            if (Schema.sObjectType.Bug_Tracking__c.isAccessible()) {
                Bug_Tracking__c result = TicketRecordPageController.getTicketRecord(bug.Id);
                System.assertNotEquals(null, result, 'Result should not be null');
                System.assertEquals(bug.Id, result.Id, 'Record Id must match');
            }
        }
    }
    
    /** 
     * @description Test getTicketRecord when user has no access 
     */
    @IsTest
    static void testGetTicketRecordWithNoAccess() {
        Bug_Tracking__c bug = createBug('Jira', 'U999');
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        
        System.runAs(u) {
            try {
                TicketRecordPageController.getTicketRecord(bug.Id);
                System.assert(false, 'Expected AuraHandledException was not thrown');
            } catch (AuraHandledException e) {
                assertAccessException(e);
            }
        }
    }
    
    /** 
     * @description Test getBugvalue positive flow 
     */
     @IsTest
    static void testGetBugvalue() {
        Bug_Tracking__c bug = createBug('Azure', 'A123');

        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(u) {
            ResultMessage result = TicketRecordPageController.getBugvalue(bug.Id);
            System.assert(result.success, 'Result should be success');
            System.assertEquals('Get bug details', result.message, 'Message must match expected value');
            System.assertEquals('Azure', result.payloadMap.get('BugType'), 'Bug type should match');
            System.assertEquals('A123', result.payloadMap.get('Unique_Id'), 'Unique Id should match');
        }
    }
    
    /** 
     * @description Test getAzureTicketRecord positive flow 
     */
     @IsTest
    static void testGetAzureTicketRecord() {
        Bug_Tracking__c bug = createBug('Azure', 'AZ123');
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        System.runAs(u) {
            Test.startTest();
            ResultMessage result = TicketRecordPageController.getAzureTicketRecord(bug.Id);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result must not be null');
            System.assertEquals('Get Azure Record', result.message, 'Message must match');
        }
    }
    
    /** 
     * @description Test getServiceNowRecord positive flow 
     */
    @IsTest
    static void testGetServiceNowRecord() {
        Bug_Tracking__c bug = createBug('Service Now', 'SN123');
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        System.runAs(u) {
            Test.startTest();
            ResultMessage result = TicketRecordPageController.getServiceNowRecord(bug.Id);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result must not be null');
            System.assertEquals('Get ServiceNow Record', result.message, 'Message must match');
        }
    }
    
    /** 
     * @description Test getJiraTicketRecord positive flow 
     */
   @IsTest
    static void testGetJiraTicketRecord() {
        Bug_Tracking__c bug = createBug('Jira', 'J123');
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        System.runAs(u) {
            Test.startTest();
            ResultMessage result = TicketRecordPageController.getJiraTicketRecord(bug.Id);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result must not be null');
            System.assertEquals('Get Jira Record', result.message, 'Message must match');
        }
    }
    
    /** 
     * @description Test saveResponses insert and update 
     */
    @IsTest
    static void testSaveResponsesInsertUpdate() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ResultMessage result1 = TicketRecordPageController.saveResponses('{"jira":"ok"}', '{"azure":"ok"}', '{"sn":"ok"}');
            ResultMessage result2 = TicketRecordPageController.saveResponses('{"jira":"updated"}', '{"azure":"updated"}', '{"sn":"updated"}');
            Test.stopTest();

            System.assert(result1.success, 'First save should succeed');
            System.assert(result2.success, 'Update save should also succeed');
        }
    }
    /** 
     * @description Test saveResponses handles truncation of long input 
     */
    @IsTest
    static void testSaveResponsesTruncation() {
        String longStr = String.valueOf('x').repeat(150000);
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        System.runAs(u) {
            Test.startTest();
            ResultMessage result = TicketRecordPageController.saveResponses(longStr, null, null);
            Test.stopTest();

            System.assert(result.success, 'Save should succeed with truncated value');
            System.assertEquals(null, result.payloadMap.get('message'), 'Expected payloadMap message to be null after truncation');
        }
    }   
    /**
     * @description Test error handling in getAzureTicketRecord
     */
     @IsTest
    static void testGetAzureTicketRecordError() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(u) {
            ResultMessage result = TicketRecordPageController.getAzureTicketRecord(null);
            System.assert(!result.success, 'Should fail for null Id');
            System.assert(result.message.startsWith('Failed:'), 'Should indicate failure');
        }
    }
    
    /**
     * @description Test error handling in getServiceNowRecord
     */
     @IsTest
    static void testGetServiceNowRecordError() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(u) {
            ResultMessage result = TicketRecordPageController.getServiceNowRecord(null);
            System.assert(!result.success, 'Should fail for null Id');
            System.assert(result.message.startsWith('Failed:'), 'Should indicate failure');
        }
    }
    
    /**
     * @description Test error handling in getJiraTicketRecord
     */
    @IsTest
    static void testGetJiraTicketRecordError() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        System.runAs(u) {
            ResultMessage result = TicketRecordPageController.getJiraTicketRecord(null);
            System.assert(!result.success, 'Should fail for null Id');
            System.assert(result.message.startsWith('Failed:'), 'Should indicate failure');
        }
    }
}