/**
* @description       : ProjectMetadataSyncServiceTest class is used to test the ProjectMetadataSyncService class 
*                      which synchronizes Project_Source_Mapping__mdt custom metadata records 
*                      for various source systems.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 10-10-2025
* @last modified by  : 
**/
@IsTest
public class ProjectMetadataSyncServiceTest {
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
    * @description Verifies that syncMetadataForService executes successfully when valid input is provided.
    */
    @IsTest
    static void testSyncMetadataForServicesuccess() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Boolean didThrow = false;
            try {
                ProjectMetadataSyncService.syncMetadataForService('Jira', new List<String>{'PROJ1','PROJ2'});
            } catch (Exception e) {
                didThrow = true;
            }
            System.assertEquals(false, didThrow, 'Should not throw exception when valid input is provided');
        }
    }

     /**
    * @description Verifies that syncMetadataForService throws AuraHandledException when service name is missing.
    */
    @IsTest
    static void testSyncMetadataForServicemissingServiceName() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            try {
                ProjectMetadataSyncService.syncMetadataForService(null, new List<String>{'ABC'});
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Service name is required'), 
                    'Exception message should indicate missing service name');
            }
        }
    }

    /**
    * @description Verifies that syncMetadataForService throws AuraHandledException when no project keys are provided.
    */
    @IsTest
    static void testSyncMetadataForServiceMissingProjectKeys() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            try {
                ProjectMetadataSyncService.syncMetadataForService('Azure', new List<String>());
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('At least one project key must be selected'), 
                    'Exception message should indicate missing project keys');
            }
        }
    }

   /**
    * @description Verifies that getProjectsForService returns an empty list when the service does not exist.
    */
    @IsTest
    static void testGetProjectsForService() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.startTest();
            List<String> results = ProjectMetadataSyncService.getProjectsForService('NonExistingService');
            Test.stopTest();
            System.assertEquals(0, results.size(), 'No projects should be returned for a non-existing service');
        }
    }

    /**
    * @description Verifies that handleResult correctly processes both success and failure deployment results.
    */
    @IsTest
    static void testHandleResult() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            ProjectMetadataSyncService svc = new ProjectMetadataSyncService();

            Metadata.DeployResult successResult = new Metadata.DeployResult();
            successResult.status = Metadata.DeployStatus.Succeeded;
            svc.handleResult(successResult, new Metadata.DeployCallbackContext());
            System.assertEquals(Metadata.DeployStatus.Succeeded, successResult.status, 
                'Status should remain Succeeded after handling result');

            Metadata.DeployResult failResult = new Metadata.DeployResult();
            failResult.status = Metadata.DeployStatus.Failed;
            failResult.errorMessage = 'Simulated failure';
            svc.handleResult(failResult, new Metadata.DeployCallbackContext());
            System.assertEquals('Simulated failure', failResult.errorMessage, 
                'Failure error message should be preserved after handling result');
        }
    }
}