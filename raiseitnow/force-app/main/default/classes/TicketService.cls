/**
* @description       : TicketService is used to handle Bug_Tracking__c queries, merge responses from Azure, Jira, and ServiceNow,
*                      manage Bug_Response__c records, and build API endpoints.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
* @description Handle Bug_Tracking__c queries, merge responses from Azure, Jira, and ServiceNow,
*                      manage Bug_Response__c records, and build API endpoints.
*/

public with sharing class TicketService {
/**
 * @description Fetches a Bug_Tracking__c record by Id with standard ServiceNow fields.
 * @param id Id of the Bug_Tracking__c record.
 * @return Bug_Tracking__c The record fetched.
 */
public static Bug_Tracking__c getServiceNowBugRecord(String id) {
    return [
        SELECT Id, Unique_Id__c, Key__c, Created_By__c, Created_Date__c,
               Project__c, Configuration_item__c, Category__c, Assignee__c,
               Status__c, Priority__c, Urgency__c, Impact__c, Subcategory__c,
               Short_Description__c, Description__c,
               Last_Modified_Date__c, Last_Modified_By__c
        FROM Bug_Tracking__c
        WHERE Id = :id
        WITH USER_MODE
    ];
}

/**
 * @description Fetches the latest ServiceNow JSON response from Bug_Response__c.
 * @return String The ServiceNow_Response__c JSON string or null if not available.
 */
public static String getLatestServiceNowResponse() {
    List<Bug_Response__c> resp = [
        SELECT ServiceNow_Response__c
        FROM Bug_Response__c
        WITH SECURITY_ENFORCED
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    return (!resp.isEmpty()) ? resp[0].ServiceNow_Response__c : null;
}

/**
 * @description Parses ServiceNow JSON and merges fields into recordMap if Unique_Id__c matches.
 * @param bug Bug_Tracking__c record to match.
 * @param recordMap Map of existing fields to merge into.
 * @param snJson JSON string from ServiceNow.
 * @return Map<String, Object> Contains:
 *         - 'success' (Boolean)
 *         - 'message' (String) optional error message
 */
public static Map<String, Object> mergeServiceNowFields(Bug_Tracking__c bug, Map<String, Object> recordMap, String snJson) {
    Map<String, Object> result = new Map<String, Object>{ 'success' => true, 'message' => null };

    try {
        String trimmed = snJson.trim();
        if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) {
            result.put('success', false);
            result.put('message', 'ServiceNow response not JSON. First chars: ' + trimmed.substring(0, Math.min(100, trimmed.length())));
            return result;
        }

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(trimmed);
        Map<String, Object> fieldsMap = responseMap.containsKey('fields') ? (Map<String, Object>) responseMap.get('fields') : responseMap;

        if (fieldsMap.get('Unique_Id__c') == bug.Unique_Id__c) {
            for (String key : fieldsMap.keySet()) {
                if (!recordMap.containsKey(key)) {
                    recordMap.put(key, fieldsMap.get(key));
                }
            }
        }

    } catch (Exception e) {
        result.put('success', false);
        result.put('message', 'Failed to parse ServiceNow JSON: ' + e.getMessage());
    }

    return result;
}


/**
 * @description Fetches a Bug_Tracking__c record by Id with standard Azure fields.
 * @param id Id of the Bug_Tracking__c record.
 * @return Bug_Tracking__c The record fetched.
 */
public static Bug_Tracking__c getBugRecord(String id) {
    return [
        SELECT Id, Unique_Id__c, Title__c, Created_By__c, Created_Date__c,
               Project__c, Sprint__c, Work_Item_Type__c, Assignee__c,
               Status__c, Reason__c, Priority__c, Effort__c, Comment__c,
               Description__c, Last_Modified_Date__c, Last_Modified_By__c
        FROM Bug_Tracking__c
        WHERE Id = :id
        WITH USER_MODE
    ];
}

/**
 * @description Fetches the latest Azure JSON response from Bug_Response__c.
 * @return String The Azure_Response__c JSON string or null if not available.
 */
public static String getLatestAzureResponse() {
    List<Bug_Response__c> resp = [
        SELECT Azure_Response__c
        FROM Bug_Response__c
        WITH SECURITY_ENFORCED
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    return (!resp.isEmpty()) ? resp[0].Azure_Response__c : null;
}

/**
 * @description Parses Azure JSON and merges fields into recordMap if Unique_Id__c matches.
 * @param bug Bug_Tracking__c record to match.
 * @param recordMap Map of existing fields to merge into.
 * @param azureJson JSON string from Azure.
 * @return Map<String, Object> Contains:
 *         - 'success' (Boolean)
 *         - 'message' (String) optional error message
 */
public static Map<String, Object> mergeAzureFields(Bug_Tracking__c bug, Map<String, Object> recordMap, String azureJson) {
    Map<String, Object> result = new Map<String, Object>{ 'success' => true, 'message' => null };

    try {
        String trimmed = azureJson.trim();
        if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) {
            result.put('success', false);
            result.put('message', 'Azure response not JSON. First chars: ' + trimmed.substring(0, Math.min(100, trimmed.length())));
            return result;
        }

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(trimmed);
        Map<String, Object> fieldsMap = responseMap.containsKey('fields') ? (Map<String, Object>) responseMap.get('fields') : responseMap;

        if (fieldsMap.get('Unique_Id__c') == bug.Unique_Id__c) {
            for (String key : fieldsMap.keySet()) {
                if (!recordMap.containsKey(key)) {
                    recordMap.put(key, fieldsMap.get(key));
                }
            }
        }

    } catch (Exception e) {
        result.put('success', false);
        result.put('message', 'Failed to parse Azure JSON: ' + e.getMessage());
    }

    return result;
}
/**
 * @description Fetches a Bug_Tracking__c record by Id with standard Jira fields.
 * @param id Id of the Bug_Tracking__c record.
 * @return Bug_Tracking__c The record fetched.
 */
public static Bug_Tracking__c getJiraBugRecord(String id) {
    return [
        SELECT Id, Unique_Id__c, Key__c, Created_By__c, Created_Date__c,
               Project__c, Reporter__c, Status__c, Label__c, Last_Modified_Date__c,
               Issue_Type__c, Assignee__c, Priority__c, Summary__c, Environment__c,
               Description__c, Last_Modified_By__c
        FROM Bug_Tracking__c
        WHERE Id = :id
        WITH USER_MODE
    ];
}
 
/**
 * @description Fetches the latest Jira JSON response from Bug_Response__c.
 * @return String The Jira_Response__c JSON string or null if not available.
 */
public static String getLatestJiraResponse() {
    List<Bug_Response__c> resp = [
        SELECT Jira_Response__c
        FROM Bug_Response__c
        WITH USER_MODE
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    return (!resp.isEmpty()) ? resp[0].Jira_Response__c : null;
}
 
/**
 * @description Parses Jira JSON and merges fields into recordMap if Unique_Id__c matches.
 * @param bug Bug_Tracking__c record to match.
 * @param recordMap Map of existing fields to merge into.
 * @param jiraJson JSON string from Jira.
 * @return Map<String, Object> Contains:
 *         - 'success' (Boolean)
 *         - 'message' (String) optional error message
 */
public static Map<String, Object> mergeJiraFields(Bug_Tracking__c bug, Map<String, Object> recordMap, String jiraJson) {
    Map<String, Object> result = new Map<String, Object>{ 'success' => true, 'message' => null };
 
    try {
        String trimmed = jiraJson.trim();
        if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) {
            result.put('success', false);
            result.put('message', 'Jira response not JSON. First chars: ' + trimmed.substring(0, Math.min(100, trimmed.length())));
            return result;
        }
 
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(trimmed);
        Map<String, Object> fieldsMap = responseMap.containsKey('fields') ? (Map<String, Object>) responseMap.get('fields') : responseMap;
 
        if (fieldsMap.get('Unique_Id__c') == bug.Unique_Id__c) {
            for (String key : fieldsMap.keySet()) {
                if (!recordMap.containsKey(key)) {
                    recordMap.put(key, fieldsMap.get(key));
                }
            }
        }
 
    } catch (Exception e) {
        result.put('success', false);
        result.put('message', 'Failed to parse Jira JSON: ' + e.getMessage());
    }
 
    return result;
}  
}