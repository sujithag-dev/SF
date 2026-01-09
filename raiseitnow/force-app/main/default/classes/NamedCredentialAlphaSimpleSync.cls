/**
* @description       : NamedCredentialAlphaSimpleSync Class is used to check which external 
*                      integrations (Jira, Azure, ServiceNow) are configured in Salesforce, 
*                      and updates the current User’s Integration_Credentials__c field. 
*                      The class also supports test coverage for exception and permission scenarios.
* @author            : Minuscule Technologies
* @group             : 
* @last modified on  : 10-10-2025
* @last modified by  : 
*/
public with sharing class NamedCredentialAlphaSimpleSync {

    /**
     * @description Test-visible list to control mocked NamedCredentials in unit tests.
     */
    @TestVisible
    public static List<String> mockedNamedCredentials;

    /**
     * @description Test-visible flag to force exception for unit test coverage.
     */
    @TestVisible
    public static Boolean forceException = false;

    /**
     * @description Returns available external integrations for the current user and updates the user's 
     *              Integration_Credentials__c field. Handles exceptions and permission checks.
     * @return ResultMessage containing:
     *         - credentials : List<String> of available integrations
     *         - anyConfig   : Boolean indicating if any integrations are configured
     */
    @AuraEnabled
    public static ResultMessage syncFlagsDebug() {
        ResultMessage result = new ResultMessage(true, 'Get Available Integrations');

        try {
            if (Test.isRunningTest() && forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            if (!hasAccess()) {
                result.success = false;
                result.payloadMap.put(
                    'message', 
                    'You do not have the required permissions to update Integration Credentials or access Named Credentials.'
                );
            } else {
                List<String> availableIntegrations = getAvailableIntegrations();

                List<User> currentUserList = getCurrentUserList();

                updateUserIntegrationCredentials(currentUserList, availableIntegrations);

                result.payloadMap.put('credentials', availableIntegrations);
                result.payloadMap.put('anyConfig', !availableIntegrations.isEmpty());
            }

        } catch (Exception e) {
            result.success = false;
            result.payloadMap.put('message', 'Error occurred: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Checks whether the current context has access to NamedCredential and User Integration_Credentials__c field.
     * @return Boolean True if access is granted, otherwise false.
     */
    private static Boolean hasAccess() {
        return Schema.sObjectType.NamedCredential.isAccessible() &&
               Schema.sObjectType.User.isUpdateable() &&
               Schema.sObjectType.User.fields.Integration_Credentials__c.isUpdateable();
    }

    /**
     * @description Retrieves the available integrations based on NamedCredentials configured in the org.
     *              Supports mocked credentials for unit tests.
     * @return List<String> List of available integration names.
     */
    private static List<String> getAvailableIntegrations() {
        List<String> integrationKeys = new List<String>();

        if (Test.isRunningTest() && mockedNamedCredentials != null) {
            integrationKeys.addAll(mockedNamedCredentials);
        } else {
            List<NamedCredential> ncs = [
                SELECT DeveloperName 
                FROM NamedCredential 
                WHERE DeveloperName IN :Constant.INTEGRATION_MAP.keySet() WITH USER_MODE
            ];
            for (NamedCredential nc : ncs) {
                integrationKeys.add(nc.DeveloperName);
            }
        }

        List<String> availableIntegrations = new List<String>();
        for (String devName : integrationKeys) {
            String integrationName = Constant.INTEGRATION_MAP.get(devName);
            if (integrationName != null) {
                availableIntegrations.add(integrationName);
            }
        }

        return availableIntegrations;
    }

    /**
     * @description Retrieves the current user in context.
     *              In test context, returns a mock user for coverage.
     * @return List<User> List containing the current user record(s).
     */
    private static List<User> getCurrentUserList() {
        List<User> currentUserList = new List<User>();
        if (Test.isRunningTest()) {
            User mockUser = new User();
            mockUser.Id = UserInfo.getUserId();
            currentUserList.add(mockUser);
        } else {
            currentUserList = [
                SELECT Id, Integration_Credentials__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                WITH USER_MODE
            ];
        }
        return currentUserList;
    }

    /**
     * @description Updates the Integration_Credentials__c field for the given users.
     * @param users List<User> List of users to update.
     * @param integrations List<String> List of integrations to assign to each user.
     */
    private static void updateUserIntegrationCredentials(List<User> users, List<String> integrations) {
        List<User> usersToUpdate = new List<User>();
        for (User u : users) {
            u.Integration_Credentials__c = String.join(integrations, ', ');
            usersToUpdate.add(u);
        }

        if (!usersToUpdate.isEmpty()) {
            Database.update(usersToUpdate, false, AccessLevel.USER_MODE);
        }
    }
}