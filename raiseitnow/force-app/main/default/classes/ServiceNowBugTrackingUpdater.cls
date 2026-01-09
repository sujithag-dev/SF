/**
* @description       : ServiceNowBugTrackingUpdater Class is used to handles updating Bug_Tracking__c records from ServiceNow incidents.
*                      Parses ServiceNow JSON response and updates corresponding records safely.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Handles updating Bug_Tracking__c records from ServiceNow incidents.
 *              Parses ServiceNow JSON response and updates corresponding records safely.
 */
public with sharing class ServiceNowBugTrackingUpdater {
    /**
     * @description Updates Bug_Tracking__c records based on ServiceNow incidents.
     *              Accepts deserialized JSON objects from ServiceNow API.
     *
     * @param incidents List<Object> - each object represents a ServiceNow incident
     */
    public static void updateBugTrackingBatchFromServiceNowResponse(List<Object> incidents) {
        if (incidents == null || incidents.isEmpty()){return;} 
        try {
           
            // Step 1: Collect Unique IDs
            Set<String> uniqueIds = collectUniqueIds(incidents);

            // Step 2: Query existing records (User Mode)
            Map<String, Bug_Tracking__c> existingBugs = loadExistingBugs(uniqueIds);

            // Step 3: Map updates
            List<Bug_Tracking__c> recordsToUpdate = mapServiceNowRecords(incidents, existingBugs);

            // Step 4: DML (User Mode)
            if (!recordsToUpdate.isEmpty() && Schema.sObjectType.Bug_Tracking__c.isUpdateable()) {
                Database.update(recordsToUpdate, false, AccessLevel.USER_MODE);
            }

        } catch (Exception ex) {
            throw new CustomException('Error occurred: ' + ex.getMessage());
        }
    }




/**
 * @description Collects unique ServiceNow sys_id values from the JSON response.
 * @param records List of ServiceNow work item objects from JSON response.
 * @return Set<String> Set of unique sys_id values.
 */
    private static Set<String> collectUniqueIds(List<Object> records) {
        Set<String> uniqueIds = new Set<String>();
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>) recordObj;
            Map<String, Object> sysIds = (Map<String, Object>) record.get('sys_id');
            uniqueIds.add(String.valueOf(sysIds.get('display_value')));
        }
        return uniqueIds;
    }

/**
 * @description Queries existing Bug_Tracking__c records for given sys_id values.
 *              Executes in USER_MODE to enforce CRUD/FLS.
 * @param uniqueIds Set of ServiceNow sys_id values.
 * @return Map<String, Bug_Tracking__c> Map of sys_id to Bug_Tracking__c records.
 */
    private static Map<String, Bug_Tracking__c> loadExistingBugs(Set<String> uniqueIds) {
        Map<String, Bug_Tracking__c> existingBugs = new Map<String, Bug_Tracking__c>();
        List<Bug_Tracking__c> bugList = [ SELECT Id, Unique_Id__c FROM Bug_Tracking__c WHERE Unique_Id__c IN :uniqueIds WITH USER_MODE];
        for (Bug_Tracking__c bug : bugList) {
            existingBugs.put(bug.Unique_Id__c, bug);
        }
        return existingBugs;
    }

/**
 * @description Maps ServiceNow JSON work items to Bug_Tracking__c records for update.
 * @param records List of ServiceNow work item objects from JSON response.
 * @param existingBugs Map of existing Bug_Tracking__c records keyed by sys_id.
 * @return List<Bug_Tracking__c> List of Bug_Tracking__c records ready for update.
 */
    private static List<Bug_Tracking__c> mapServiceNowRecords(
        List<Object> records, 
        Map<String, Bug_Tracking__c> existingBugs
    ) {
        List<Bug_Tracking__c> recordsToUpdate = new List<Bug_Tracking__c>();
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>) recordObj;
            String sysId = getDisplayValue(record, 'sys_id');
            if (String.isNotBlank(sysId) && existingBugs.containsKey(sysId)) {
                Bug_Tracking__c bug = existingBugs.get(sysId);

                 // Collect field values in bulk
            Map<String, Object> fieldValues = new Map<String, Object>{
                'Priority__c'           => getDisplayValue(record, 'priority'),
                'Short_Description__c'  => getDisplayValue(record, 'short_description'),
                'Impact__c'             => getDisplayValue(record, 'impact'),
                'Description__c'        => getDisplayValue(record, 'description'),
                'Status__c'             => getDisplayValue(record, 'incident_state'),
                'Urgency__c'            => getDisplayValue(record, 'urgency'),
                'Assignee__c'           => getDisplayValue(record, 'assigned_to'),
                'Created_By__c'         => getDisplayValue(record, 'sys_created_by'),
                'Created_Date__c'       => getDisplayValue(record, 'sys_created_on'),
                'Configuration_item__c' => getDisplayValue(record, 'cmdb_ci'),
                'Category__c'           => getDisplayValue(record, 'category'),
                'Subcategory__c'        => getDisplayValue(record, 'subcategory'),
                'Last_Modified_Date__c' => getDisplayValue(record, 'sys_updated_on')
            };

            // Apply only accessible fields
            bug = (Bug_Tracking__c) FieldAccessUtil.setAccessibleFields(bug, fieldValues);

            recordsToUpdate.add(bug);
         }
        }
        return recordsToUpdate;
    }

/**
 * @description Safely retrieves the 'display_value' of a nested field in ServiceNow JSON.
 * @param record Map representing a ServiceNow work item.
 * @param fieldName Field name in the ServiceNow JSON object.
 * @return String Value of the field or null if not present.
 */
    private static String getDisplayValue(Map<String, Object> record, String fieldName) {
        if (record.containsKey(fieldName) && record.get(fieldName) != null) {
            Map<String, Object> field = (Map<String, Object>) record.get(fieldName);
            if (field.containsKey('display_value')) {
                return BulkApiCaller.fallbackDash(String.valueOf(field.get('display_value')));
            }
        }
        return null;
    }  

}