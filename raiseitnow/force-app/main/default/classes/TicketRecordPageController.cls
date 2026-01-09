/**
* @description       : TicketRecordPageController Class is used to retrieve and manage Bug_Tracking__c records 
*                      and their related responses from Jira, Azure, and ServiceNow. 
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Retrieve and manage Bug_Tracking__c records 
 *              and their related responses from Jira, Azure, and ServiceNow. 
 */
public with sharing class TicketRecordPageController {
    
     /**
     * @description Retrieves a Bug_Tracking__c record by Id with field-level and object-level access checks.
     * @param recordId The Id of the Bug_Tracking__c record.
     * @return The secured Bug_Tracking__c record.
     */
 @AuraEnabled(cacheable=true)
    public static Bug_Tracking__c getTicketRecord(Id recordId) {
        // Check object-level read access
        if (!Bug_Tracking__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            throw new AuraHandledException('Bug_Tracking__c is not accessible.');
        }
        
        // Run the query
        List<Bug_Tracking__c> rawRecords = [
            SELECT Id, Name, Project__c, Bug_Type__c, Service_Template__r.Name,
            CreatedBy.Name, Owner.Name, LastModifiedBy.Name
            FROM Bug_Tracking__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        // Apply field-level access control
        List<SObject> secureRecords = Security.stripInaccessible(AccessType.READABLE, rawRecords).getRecords();
        return secureRecords.isEmpty() ? null : (Bug_Tracking__c) secureRecords[0];
        
    }
        /**
        * @description Returns key details of a Bug_Tracking__c record by Id.
        * @param id Id of the Bug_Tracking__c record.
        * @return ResultMessage Contains success status, message, and payload with BugType and Unique_Id.
        * @throws AuraHandledException If object is not accessible or record not found.
        */
        @AuraEnabled(cacheable=true)
        public static ResultMessage getBugvalue(String id) {
            checkBugTrackingAccess();

            Bug_Tracking__c rawBug = [
                SELECT Bug_Type__c, Unique_Id__c
                FROM Bug_Tracking__c
                WHERE Id = :id
                LIMIT 1
            ];

            Bug_Tracking__c bug = getSecureBugRecord(new List<Bug_Tracking__c>{rawBug});

            ResultMessage result = new ResultMessage(true, 'Get bug details');
            result.payloadMap.put('BugType', bug.Bug_Type__c);
            result.payloadMap.put('Unique_Id', bug.Unique_Id__c);

            return result;
        }

        /**
        * @description Helper method to check object-level access for Bug_Tracking__c.
        * Throws an AuraHandledException if access is denied.
        */
        private static void checkBugTrackingAccess() {
            if (!Bug_Tracking__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
                throw new AuraHandledException('Bug_Tracking__c is not accessible.');
            }
        }
        /**
        * @description Returns the first accessible Bug_Tracking__c record from a list.
        * @param rawRecords List of Bug_Tracking__c records to check.
        * @return First accessible Bug_Tracking__c record.
        * @throws AuraHandledException If no records are accessible.
        */
        private static Bug_Tracking__c getSecureBugRecord(List<Bug_Tracking__c> rawRecords) {
            List<SObject> secureRecords = Security.stripInaccessible(AccessType.READABLE, rawRecords).getRecords();
            if (secureRecords.isEmpty()) {
                throw new AuraHandledException('Bug not found or access denied.');
            }
            return (Bug_Tracking__c) secureRecords[0];
        }
  /**
 * @description Retrieves a Bug_Tracking__c record by Id and merges it with the latest Azure response.
 * @param id Id of the Bug_Tracking__c record.
 * @return ResultMessage Contains success status, message, and payload with merged fields.
 */
@AuraEnabled
public static ResultMessage getAzureTicketRecord(String id) {
    ResultMessage result = new ResultMessage(true, 'Get Azure Record');

    try {
        // Fetch the Bug_Tracking__c record
        Bug_Tracking__c bug = TicketService.getBugRecord(id);
        Map<String, Object> recordMap = bug.getPopulatedFieldsAsMap();

        // Fetch latest Azure JSON response
        String azureJson = TicketService.getLatestAzureResponse();

        // Merge Azure fields if JSON is not blank
        if (!String.isBlank(azureJson)) {
            Map<String, Object> mergeResult = TicketService.mergeAzureFields(bug, recordMap, azureJson);
            if (!(Boolean)mergeResult.get('success')) {
                result.success = false;
                result.payloadMap.put('message', (String)mergeResult.get('message'));
            }
        }

        result.payload.add(recordMap);

    } catch (Exception e) {
        result.success = false;
        result.message = 'Failed: ' + e.getMessage();
    }

    return result;
}

/**
 * @description Retrieves a Bug_Tracking__c record by Id and merges it with the latest ServiceNow response.
 * @param id Id of the Bug_Tracking__c record.
 * @return ResultMessage Contains success status, message, and payload with merged fields.
 */
@AuraEnabled
public static ResultMessage getServiceNowRecord(String id) {
    ResultMessage result = new ResultMessage(true, 'Get ServiceNow Record');

    try {
        // Fetch the Bug_Tracking__c record
        Bug_Tracking__c bug = TicketService.getServiceNowBugRecord(id);
        Map<String, Object> recordMap = bug.getPopulatedFieldsAsMap();

        // Fetch latest ServiceNow JSON response
        String snJson = TicketService.getLatestServiceNowResponse();

        // Merge ServiceNow fields if JSON is not blank
        if (!String.isBlank(snJson)) {
            Map<String, Object> mergeResult = TicketService.mergeServiceNowFields(bug, recordMap, snJson);
            if (!(Boolean)mergeResult.get('success')) {
                result.success = false;
                result.payloadMap.put('message', (String)mergeResult.get('message'));
            }
        }

        result.payload.add(recordMap);

    } catch (Exception e) {
        result.success = false;
        result.message = 'Failed: ' + e.getMessage();
    }

    return result;
}

  /**
 * @description Saves Jira, Azure, and ServiceNow responses into Bug_Response__c.
 *
 * @param jiraResponse JSON string response from Jira.
 * @param azureResponse JSON string response from Azure.
 * @param serviceResponse JSON string response from ServiceNow.
 * @return ResultMessage success/failure status and message.
 */
@AuraEnabled
public static ResultMessage saveResponses(String jiraResponse, String azureResponse, String serviceResponse) {
    ResultMessage result = new ResultMessage(true, 'Save Response');

    try {
        Bug_Response__c bugResp = getOrCreateBugResponse();

        // Apply truncated values
        setResponseField(bugResp, 'Jira_Response__c', jiraResponse);
        setResponseField(bugResp, 'Azure_Response__c', azureResponse);
        setResponseField(bugResp, 'ServiceNow_Response__c', serviceResponse);

        // Insert or update the record
        upsertBugResponse(bugResp);

    } catch (Exception ex) {
        result.success = false;
        result.payloadMap.put('message', 'Error while saving Bug_Response__c: ' + ex.getMessage());
    }

    return result;
}
 
/**
 * @description Gets the first Bug_Response__c record or creates a new one.
 * @return Bug_Response__c The first existing Bug_Response__c record,or a new instance if none exist.
 */
private static Bug_Response__c getOrCreateBugResponse() {
    try {
        return [
            SELECT Id, Jira_Response__c, Azure_Response__c, ServiceNow_Response__c
            FROM Bug_Response__c
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
    } catch (QueryException qe) {
        return new Bug_Response__c();
    }
}

/**
 * @description Safely sets a response field with truncation and FLS checks.
 *
 * @param bugResp Bug_Response__c record to update.
 * @param fieldName API name of the response field.
 * @param response Raw response string.
 */
private static void setResponseField(Bug_Response__c bugResp, String fieldName, String response) {
    Integer maxLen = 131071;
    String value = null;

    if (!String.isBlank(response)) {
        value = (response.length() > maxLen)
            ? response.substring(0, maxLen - 15) + '---TRUNCATED---'
            : response;
    }

    FieldAccessUtil.setIfCreateableAndUpdateable(bugResp, fieldName, value);
}

/**
 * @description Inserts or updates the Bug_Response__c record depending on whether Id exists.
 *
 * @param bugResp Bug_Response__c record to persist.
 */
private static void upsertBugResponse(Bug_Response__c bugResp) {
    if (bugResp.Id == null) {
        if (Schema.sObjectType.Bug_Response__c.isCreateable()) {
            insert bugResp;
        }
    } else {
        if (Schema.sObjectType.Bug_Response__c.isUpdateable()) {
            update bugResp;
        }
    }
}

/**
 * @description Retrieves a Bug_Tracking__c record by Id and merges it with the latest Jira response.
 * @param id Id of the Bug_Tracking__c record.
 * @return ResultMessage Contains success status, message, and payload with merged fields.
 */
@AuraEnabled
public static ResultMessage getJiraTicketRecord(String id) {
    ResultMessage result = new ResultMessage(true, 'Get Jira Record');
 
    try {
        // Fetch the Bug_Tracking__c record
        Bug_Tracking__c bug = TicketService.getJiraBugRecord(id);
        Map<String, Object> recordMap = bug.getPopulatedFieldsAsMap();
 
        // Fetch latest Jira JSON response
        String jiraJson = TicketService.getLatestJiraResponse();
 
        // Merge Jira fields if JSON is not blank
        if (!String.isBlank(jiraJson)) {
            Map<String, Object> mergeResult = TicketService.mergeJiraFields(bug, recordMap, jiraJson);
            if (!(Boolean)mergeResult.get('success')) {
                result.success = false;
                result.payloadMap.put('message', (String)mergeResult.get('message'));
            }
        }
 
        result.payload.add(recordMap);
 
    } catch (Exception e) {
        result.success = false;
        result.message = 'Failed: ' + e.getMessage();
    }
 
    return result;
}
 
}