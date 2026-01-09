/**
* @description       : ExternalUserIntegrationService Class is used to provides integration support for retrieving user and team data from external platforms
*                      such as Jira, ServiceNow, and Azure DevOps. It centralizes external system interactions and returns
*                      results in a standardized `ResultMessage` wrapper for downstream processing or UI display.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description  This class provides integration support for retrieving user and team data from external platforms
 *  such as Jira, ServiceNow, and Azure DevOps. It centralizes external system interactions and returns
 *  results in a standardized `ResultMessage` wrapper for downstream processing or UI display.
 *
 */
public with sharing class ExternalUserIntegrationService {

   /**
    * @description Retrieves the list of users from Jira.
    * @return A ResultMessage object containing the list of Jira users.
    */
    @AuraEnabled
    public static ResultMessage getJiraUsersList() {
        ResultMessage result = new ResultMessage(true, 'Get Jira Users List');
        try {
            HttpResponse response = ApiUtility.sendGetRequest(Constant.JIRA_LEGACY + Constant.JIRA_USERS_ENDPOINT);
            if(response.getStatusCode() == 200) {
                List<WrapperContainer.UserWrapper> parsedData = (List<WrapperContainer.UserWrapper>) JSON.deserialize(response.getBody(), List<WrapperContainer.UserWrapper>.class);
                result = new ResultMessage(true, 'Get Jira Users List');
                result.payloadMap.put('UsersList' ,  parsedData);
            } else {
                result = new ResultMessage(false, 'Failed to fetch Jira users. Status code: ' + response.getStatusCode());
            }
        }catch(Exception e) {
            result = new ResultMessage(false, 'An unexpected error occurred: ' + e.getMessage());
        }
        return result;
    }

    /**
    * @description Retrieves a list of users from ServiceNow based on the specified field name.
    * @param fieldName The field name to retrieve the users for.
    * @return A ResultMessage object containing the list of ServiceNow users.
    */
    @AuraEnabled
    public static ResultMessage serviceNowLookup(String fieldName) {
        String setEndpoint;
        Map<String, String> lookupUsers = new Map<String, String>();        
        ResultMessage result;
        try {
            if(fieldName == 'assigned_to') {
                setEndpoint = Constant.SERVICE_NOW_LEGACY + '/api/now/table/sys_user?sysparm_fields=name,sys_id';
            } else {
                throw new CustomException('Invalid fieldName: ' + fieldName);
            }
            HttpResponse response = ApiUtility.sendGetRequest(setEndpoint);
            if(response.getStatusCode() == 200) {
                WrapperContainer.ServiceNowLookupWrapper responseWrapper = (WrapperContainer.ServiceNowLookupWrapper) JSON.deserialize(response.getBody(), WrapperContainer.ServiceNowLookupWrapper.class);        
                for(WrapperContainer.ResultItem item : responseWrapper.result) {
                    lookupUsers.put(item.name,item.sys_id);
                }   

                result = new ResultMessage(true, 'Successfully fetched ServiceNow lookup users');
                result.payloadMap.put('serviceNowLookupList', lookupUsers);
            } else {
                result = new ResultMessage(false, 'Failed to fetch ServiceNow lookup users. Status code: ' + response.getStatusCode());
            }
        } catch(Exception e) {
            result = new ResultMessage(false, 'An unexpected error occurred: ' + e.getMessage());
        }
        return result;
    }

   /**
    * @description Retrieves a list of teams and their members from Azure DevOps for the specified project ID.
    * @param projectId The ID of the Azure DevOps project.
    * @return A ResultMessage object containing the list of teams and their members.
    */
    @AuraEnabled
    public static ResultMessage getAzureTeams(String projectId) {
        ResultMessage result;
        List<String> teamIds = new List<String>(); 
        Map<String,String> teamMembers = new Map<String,String>();        
        try {
            if (projectId != null) {
                String setEndpoint = Constant.AZURE_LEGACY + '/_apis/projects/' + projectId + '/teams?api-version=7.2-preview.3';
                HttpResponse response = ApiUtility.sendGetRequest(setEndpoint);
                String jsonResponse = response.getBody();
                WrapperContainer.TeamInfoWrapper wrapper = (WrapperContainer.TeamInfoWrapper)JSON.deserialize(jsonResponse, WrapperContainer.TeamInfoWrapper.class);
                if (wrapper != null && wrapper.value != null) {
                    for(WrapperContainer.TeamInfo team : wrapper.value) {
                        teamIds.add(team.id); 
                    }
                    teamMembers = getAzureTeamMembers(teamIds, projectId);
                } else {
                    result = new ResultMessage(false, 'No Teams were found for the specified project.');
                }
                result = new ResultMessage(true, 'Get Azure Users List');
                result.payloadMap.put('Users' , teamMembers);
            }
            else{
                result = new ResultMessage(false, 'Project ID is null.');
            }
        } catch(Exception e) {
            result = new ResultMessage(false, 'An unexpected error occurred: ' + e.getMessage());
        }
        return result;
    }

	 /**
    * @description Retrieves the members of the specified Azure DevOps teams for the given project ID.
    * @param teamIds The list of team IDs.
    * @param projectId The ID of the Azure DevOps project.
    * @return A map containing the members of each team, where the key is the display name and the value is the unique name.
    */
    @AuraEnabled
    public static Map<String,String> getAzureTeamMembers(List<String> teamIds, String projectId) {
        Map<String,String> teamMembers = new Map<String,String>();     
        try {
            for (String teamId : teamIds) {
                String endpointUrl = Constant.AZURE_LEGACY + '/_apis/projects/' + projectId + '/teams/' + teamId + '/members?api-version=7.2-preview.2';
                HttpResponse response = ApiUtility.sendGetRequest(endpointUrl);
                if (response.getStatusCode() == 200) {
                    String jsonResponse = response.getBody();
                    WrapperContainer.IdentityResponse wrap = (WrapperContainer.IdentityResponse)JSON.deserialize(jsonResponse, WrapperContainer.IdentityResponse.class);
                    for (WrapperContainer.IdentityWrapper identityWrapper : wrap.value) {
                        WrapperContainer.Identity identity = identityWrapper.identity;
                        String displayName = identity.displayName;
                        String uniqueName = identity.uniqueName;
                        teamMembers.put(displayName,uniqueName);
                    }
                } else {
                    throw new CustomException('Failed to fetch team members for team ID: ' + teamId + '. Status code: ' + response.getStatusCode());       
                }
            }
        } catch(Exception e) {
            throw e;
        }
        return teamMembers;
    }
    
}