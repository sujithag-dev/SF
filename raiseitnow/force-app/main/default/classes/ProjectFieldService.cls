/**
* @description       : ProjectFieldService Class is used to fetch project field details from Jira, Azure, 
*                      or ServiceNow based on the provided project key and selected service name. 
*                      It builds service-specific endpoints, performs API callouts, and processes 
*                      responses into a unified ResultMessage structure.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/

/**
* @description  Fetch project field details from Jira, Azure, 
*                or ServiceNow based on the provided project key and selected service name. 
*                It builds service-specific endpoints, performs API callouts, and processes 
*                responses into a unified ResultMessage structure.
*
 */
public with sharing class ProjectFieldService {

    /**
    * @description Retrieves the list of project fields based on the provided project key and selected service name.
    * @param projKey The project key.
    * @param selectedServiceName The name of the selected service.
    * @return A ResultMessage object containing the project field list.
    */
      @AuraEnabled
     public static ResultMessage projFieldsList(String projKey, String selectedServiceName) {
        ResultMessage result = new ResultMessage(true, 'Get Project Field List');
        try {
            String setEndpoint = buildEndpoint(projKey, selectedServiceName);
            if (setEndpoint == null) {
                return new ResultMessage(false, 'Invalid service name.');
             }

            HttpResponse response = ApiUtility.sendGetRequest(setEndpoint);
            processServiceResponse(result, response, selectedServiceName);
          } catch (Exception e) {
           handleError(result, e);
         }
        return result;
     }
    private static String buildEndpoint(String projKey, String serviceName) {
       if (serviceName == Constant.JIRA_SERVICE) {
            return Constant.JIRA_LEGACY + Constant.JIRA_ISSUE_CREATE_META_ENDPOINT + projKey + Constant.JIRA_ISSUE_CREATE_META_PARAMS;
       } else if (serviceName == Constant.AZURE_SERVICE) {
            if (projKey.contains(' ')) {
                projKey = projKey.replaceAll(' ', '%20');
             }
        return Constant.AZURE_LEGACY + '/' + projKey + Constant.AZURE_DEVOPS_ISSUE_FIELDS_ENDPOINT;
       } else if (serviceName == Constant.SERVICENOW_SERVICE) {
            return Constant.SERVICE_NOW_LEGACY + Constant.SERVICENOW_INCIDENT_META_ENDPOINT;
        }
      return null;
     }

    private static void processServiceResponse(ResultMessage result, HttpResponse response, String serviceName) {
        if (response.getStatusCode() != 200) {
            result.success = false;
            result.payloadMap.put('message', 'HTTP Error : ' + response.getStatusCode() + ' ' + response.getStatus());
            return;
        }

       if (serviceName == Constant.JIRA_SERVICE) {
            result.payloadMap.put('JiraResponse', response.getBody());
            result.payloadMap.put('jiraAllowedList', Constant.JIRA_ALLOWED_FIELDS);
       } else if (serviceName == Constant.SERVICENOW_SERVICE) {
             if (response.getHeader(Constant.CONTENT_TYPE).contains(Constant.CONTENT_TYPE_JSON)) {
                   WrapperContainer.Incidentwrapper incidentWrapper = (WrapperContainer.Incidentwrapper)
                   JSON.deserialize(response.getBody(), WrapperContainer.Incidentwrapper.class);
                    result.payloadMap.put('ServiceNowResponse', incidentWrapper);
                    result.payloadMap.put('serviceNowAllowedList', Constant.SERVICE_NOW_ALLOWED_FIELDS);
              } else {
                  result.success = false;
                  result.payloadMap.put('message', 'Failed to fetch the ServiceNow instance. Please log in to ServiceNow and activate the instance.');
              }
        } else if (serviceName == Constant.AZURE_SERVICE) {
               WrapperContainer.AzureWrapper azureWrapper = (WrapperContainer.AzureWrapper)
               JSON.deserialize(response.getBody(), WrapperContainer.AzureWrapper.class);
               result.payloadMap.put('AzureResponse', azureWrapper);
               result.payloadMap.put('azureNowAllowedList', Constant.AZURE_ALLOWED_FIELDS);
        }
    }

   private static void handleError(ResultMessage result, Exception e) {
        result.success = false;
        result.payloadMap.put('message', 'Error occurred: ' + e.getMessage());
    }

}