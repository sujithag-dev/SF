/**
* @description       : ConnectionHandler Class is used to acts as the top-level Apex controller to route service template and connection requests.                   
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Acts as the top-level Apex controller to route service template and connection requests.
 */
public with sharing class ConnectionHandler {
        // Keep default false in production. Tests can toggle this flag.
       @TestVisible private static Boolean useMockConnections = false;
    
	 /**
     * @description Retrieves available RaiseItNow connections from Named Credentials.
     * @return A ResultMessage object containing NamedCredential records and connection names.
     */
    @AuraEnabled
    public static ResultMessage getRaiseItNowConnections() {
        ResultMessage result = new ResultMessage(true, 'Get RaiseItNow Connections');
      
        try {
            if (!NamedCredential.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
                result.success = false;
                result.payloadMap.put('message', 'Insufficient access to NamedCredential object.');
                return result;
            }
            
             if (useMockConnections) {
                result.payloadMap.put('connectionNames', new List<String>{'Jira','ServiceNow','Azure Devops'});
                result.payloadMap.put('connections', new List<NamedCredential>());
                return result;
            }

            List<NamedCredential> namedCredentials = [
                SELECT Id, DeveloperName 
                FROM NamedCredential 
                WHERE DeveloperName IN :Constant.LEGACY_LIST 
                WITH USER_MODE
            ];

            result.payloadMap.put('connections', namedCredentials);
            result.payloadMap.put('connectionNames', extractConnectionNames(namedCredentials));
        } catch (Exception e) {
            result.success = false;
            result.payloadMap.put('message', 'Error occurred: ' + e.getMessage());
        }
        return result;
    }

    private static List<String> extractConnectionNames(List<NamedCredential> credentials) {
        Map<String, String> keywordToName = new Map<String, String>{
            'Jira' => 'Jira',
            'ServiceNow' => 'ServiceNow',
            'Azure' => 'Azure Devops'
        };

        Set<String> names = new Set<String>();
        for (NamedCredential nc : credentials) {
            for (String keyword : keywordToName.keySet()) {
                if (nc.DeveloperName.contains(keyword)) {
                    names.add(keywordToName.get(keyword));
                    break;
                }
            }
        }
        return new List<String>(names);
    }

	/**
 * @description Retrieves the connection status of the RaiseItNow service.
 * @param serviceName The name of the service (Jira, Azure, ServiceNow).
 * @return ResultMessage containing the connection status and user info if available.
 */
@AuraEnabled
public static ResultMessage getRaiseItNowConnectionStatus(String serviceName) {
    ResultMessage result = new ResultMessage(true, 'Get RaiseItNow Connection Status');

    if (!isSupportedService(serviceName)) {
        return buildError(result, 'Invalid service name: ' + serviceName);
    }

    ResultMessage connectionResult = getRaiseItNowConnections();
    if (!hasValidConnections(connectionResult, serviceName)) {
        return buildError(result, 'Connection data not available for ' + serviceName);
    }

    String endpoint = getEndpoint(serviceName);
    HttpResponse response = ApiUtility.sendGetRequest(endpoint);

    if (response != null && response.getStatusCode() == 200) {
        handleSuccessfulResponse(serviceName, response, result);
    } else {
        return buildError(result, 'Please check and re-configure Named Credentials for ' + serviceName);
    }

    return result;
}

/**
 * @description Checks if the given service name is supported.
 * @param serviceName The name of the service.
 * @return true if the service is supported, false otherwise.
 */
private static Boolean isSupportedService(String serviceName) {
    return new Set<String>{
        Constant.JIRA_SERVICE, Constant.AZURE_SERVICE, Constant.SERVICENOW_SERVICE
    }.contains(serviceName);
}

/**
 * @description Validates if the connection result contains the required data for the given service.
 * @param connResult The result from getRaiseItNowConnections().
 * @param serviceName The name of the service.
 * @return true if valid connections exist, false otherwise.
 */
private static Boolean hasValidConnections(ResultMessage connResult, String serviceName) {
    if (connResult == null || connResult.payloadMap == null) 
    {
        return false;
    }
    if (!connResult.payloadMap.containsKey('connectionNames')) 
    {
        return false;
    }

    List<String> names = (List<String>) connResult.payloadMap.get('connectionNames');
    return names.contains(serviceName);
}

/**
 * @description Retrieves the endpoint URL for the given service.
 * @param serviceName The name of the service.
 * @return The endpoint URL as a string.
 */
private static String getEndpoint(String serviceName) {
    Map<String, String> endpointMap = new Map<String, String>{
        Constant.JIRA_SERVICE       => Constant.JIRA_LEGACY + Constant.JIRA_MYSELF_ENDPOINT,
        Constant.AZURE_SERVICE      => Constant.AZURE_LEGACY + Constant.AZURE_CONNECTION_DATA_ENDPOINT,
        Constant.SERVICENOW_SERVICE => Constant.SERVICE_NOW_LEGACY + Constant.SERVICENOW_USER_INFO_ENDPOINT
    };
    return endpointMap.get(serviceName);
}

/**
 * @description Handles successful API responses and extracts the user’s email.
 * @param serviceName The name of the service.
 * @param response The HTTP response from the external system.
 * @param result The ResultMessage object to update with connection info.
 */
private static void handleSuccessfulResponse(String serviceName, HttpResponse response, ResultMessage result) {
    Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

    if (serviceName == Constant.AZURE_SERVICE) {
        Map<String, Object> authUser = (Map<String, Object>) bodyMap.get('authenticatedUser');
        Map<String, Object> properties = (Map<String, Object>) authUser.get('properties');
        Map<String, Object> accountProp = (Map<String, Object>) properties.get('Account');
        result.payloadMap.put('emailAddress', (String) accountProp.get('$value'));
    } else {
        result.payloadMap.put('emailAddress', String.valueOf(bodyMap.get('emailAddress')));
    }

    result.payloadMap.put('message', serviceName + ' is connected.');
}

/**
 * @description Builds an error response and updates the given ResultMessage.
 * @param result The ResultMessage object to update.
 * @param message The error message to include.
 * @return The updated ResultMessage object with success=false.
 */
private static ResultMessage buildError(ResultMessage result, String message) {
    result.success = false;
    result.payloadMap.put('message', message);
    return result;
}

}