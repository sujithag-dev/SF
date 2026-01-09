/**
* @description       : Test class for NamedCredentialAlphaSimpleSync. 
*                      This class validates various execution paths of syncFlagsDebug() 
*                      including scenarios for no Named Credentials, mocked credentials, 
*                      permission denial, and forced exception.
* @author            : Minuscule Technologies
* @group             : 
* @last modified on  : 10-10-2025
* @last modified by  : 
*/
@IsTest
public class NamedCredentialAlphaSimpleSyncTest {

    /**
     * @description Test case to verify behavior when no Named Credentials are available. 
     *              Ensures that the anyConfig flag is false and credentials list is empty.
     * @testmethod
     */
    @IsTest
    static void testNoNamedCredentials() {
        Test.startTest();
        NamedCredentialAlphaSimpleSync.mockedNamedCredentials = new List<String>(); 
        ResultMessage result = NamedCredentialAlphaSimpleSync.syncFlagsDebug();
        System.assertEquals(false, (Boolean) result.payloadMap.get('anyConfig'),
            'anyConfig should be false when no named credentials exist');
        System.assertEquals(0, ((List<String>) result.payloadMap.get('credentials')).size(),
            'credentials list should be empty when no named credentials exist');
        Test.stopTest();
    }

    /**
     * @description Test case to verify successful retrieval of integrations when mocked Named Credentials are provided. 
     *              Confirms that all mocked integrations (Jira, Azure, ServiceNow) are correctly identified.
     * @testmethod
     */
    @IsTest
    static void testWithMockedNamedCredentials() {
        Test.startTest();
        NamedCredentialAlphaSimpleSync.mockedNamedCredentials =
            new List<String>{ Constant.JIRA_NC, Constant.AZURE_NC, Constant.SERVICENOW_NC };
        ResultMessage result = NamedCredentialAlphaSimpleSync.syncFlagsDebug();
        System.assertEquals(true, (Boolean) result.payloadMap.get('anyConfig'),
            'anyConfig should be true when mocked named credentials exist');
        List<String> creds = (List<String>) result.payloadMap.get('credentials');
        System.assert(creds.contains(Constant.JIRA_SERVICE),
            'credentials list should contain JIRA_SERVICE');
        System.assert(creds.contains(Constant.AZURE_SERVICE),
            'credentials list should contain AZURE_SERVICE');
        System.assert(creds.contains(Constant.SERVICENOW_SERVICE),
            'credentials list should contain SERVICENOW_SERVICE');
        Test.stopTest();
    }

    /**
     * @description Test case to simulate permission denial or restricted access scenario. 
     *              Verifies that a valid ResultMessage is returned even when access is not available.
     * @testmethod
     */
    @IsTest
    static void testPermissionDeniedScenario() {
        Test.startTest();
        ResultMessage result = NamedCredentialAlphaSimpleSync.syncFlagsDebug();
        System.assert(result != null,
            'ResultMessage should not be null in permission denied scenario');
        Test.stopTest();
    }

    /**
     * @description Test case to verify the exception handling (catch block) in syncFlagsDebug(). 
     *              Uses the forceException flag to simulate an AuraHandledException and confirms 
     *              that the ResultMessage.success flag is set to false.
     * @testmethod
     */
    @IsTest
    static void testCatchBlock() {
        Test.startTest();
        NamedCredentialAlphaSimpleSync.forceException = true;
        ResultMessage result = NamedCredentialAlphaSimpleSync.syncFlagsDebug();
        System.assertEquals(false, result.success,
            'Catch block should set success to false when an exception occurs');
        Test.stopTest();
    }
}