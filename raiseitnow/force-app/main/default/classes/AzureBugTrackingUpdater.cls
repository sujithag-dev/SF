/**
* @description       : AzureBugTrackingUpdater Class is used to handles updating Bug_Tracking__c records from Azure DevOps work items.
*                      Parses Azure JSON response and updates corresponding records safely.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Handles updating Bug_Tracking__c records from Azure DevOps work items.
 *              Parses Azure JSON response and updates corresponding records safely.
 */
public with sharing class AzureBugTrackingUpdater {
/**
 * @description Maps Azure Work Items from JSON response to Bug_Tracking__c records.
 *              This method parses the Azure API JSON response, maps the fields 
 *              to Salesforce Bug_Tracking__c objects, and performs updates in USER_MODE.
 * @param issues List of Azure bug issue objects.
 */
public static void mapAzureBugToBugTracking(List<Object> issues) {
        if (issues == null || issues.isEmpty()){return;} 

        try {
        
            // Step 1: Collect Unique IDs
            Set<String> uniqueIds = collectAzureUniqueIds(issues);

            // Step 2: Query existing records (User Mode)
            Map<String, Bug_Tracking__c> existingBugs = loadExistingAzureBugs(uniqueIds);

            // Step 3: Map fields
            List<Bug_Tracking__c> recordsToUpdate = buildAzureRecordsToUpdate(issues, existingBugs);

            // Step 4: Update (User Mode)
            if (!recordsToUpdate.isEmpty() && Schema.sObjectType.Bug_Tracking__c.isUpdateable()) {
                Database.update(recordsToUpdate, false, AccessLevel.USER_MODE);
            }

        } catch (Exception e) {
            throw new CustomException('Error occurred: ' + e.getMessage());
        }
    }

   
/**
 * @description Collects unique work item IDs from the Azure JSON response.
 * @param values List of work item objects from Azure JSON response.
 * @return Set<String> Set of unique Azure work item IDs.
 */
    private static Set<String> collectAzureUniqueIds(List<Object> values) {
        Set<String> uniqueIds = new Set<String>();
        for (Object valueObj : values) {
            Map<String, Object> value = (Map<String, Object>) valueObj;
            uniqueIds.add(String.valueOf(value.get('id')));
        }
        return uniqueIds;
    }

 /**
 * @description Queries existing Bug_Tracking__c records for the given Azure work item IDs.
 *              DML and SOQL operations are executed in USER_MODE to enforce CRUD/FLS.
 * @param uniqueIds Set of Azure work item IDs.
 * @return Map<String, Bug_Tracking__c> Map of Azure work item ID to Bug_Tracking__c record.
 */
    private static Map<String, Bug_Tracking__c> loadExistingAzureBugs(Set<String> uniqueIds) {
        Map<String, Bug_Tracking__c> existingBugs = new Map<String, Bug_Tracking__c>();
        for (Bug_Tracking__c bug : [
            SELECT Id, Unique_Id__c FROM Bug_Tracking__c WHERE Unique_Id__c IN :uniqueIds WITH USER_MODE
        ] ) {
            existingBugs.put(bug.Unique_Id__c, bug);
        }
        return existingBugs;
    }

 /**
 * @description Maps Azure JSON work items to Bug_Tracking__c records for update.
 * @param values List of Azure work item objects from JSON response.
 * @param existingBugs Map of existing Bug_Tracking__c records keyed by work item ID.
 * @return List<Bug_Tracking__c> List of Bug_Tracking__c records ready for update.
 */
    private static List<Bug_Tracking__c> buildAzureRecordsToUpdate(
        List<Object> values, 
        Map<String, Bug_Tracking__c> existingBugs
    ) {
        List<Bug_Tracking__c> recordsToUpdate = new List<Bug_Tracking__c>();

        for (Object valueObj : values) {
            Map<String, Object> value = (Map<String, Object>) valueObj;
            String id = String.valueOf(value.get('id'));

            if (!existingBugs.containsKey(id)) {continue;} 

            Bug_Tracking__c bug = existingBugs.get(id);
            Map<String, Object> fields = (Map<String, Object>) value.get('fields');

            mapFieldsToBug(bug, fields, id);

            recordsToUpdate.add(bug);
        }

        return recordsToUpdate;
    }

    /**
 * @description Maps individual fields from Azure JSON to Bug_Tracking__c.
 * @param bug Bug_Tracking__c record to update.
 * @param fields Map of field names and values from Azure JSON.
 * @param id Azure work item ID.
 */
    private static void mapFieldsToBug(Bug_Tracking__c bug, Map<String, Object> fields, String id) {
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Unique_Id__c', id);
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Priority__c', safeGet(fields, 'Microsoft.VSTS.Common.Priority'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Title__c', safeGet(fields, 'System.Title'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Status__c', safeGet(fields, 'System.State'));

    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Description__c',
        normalizeAzureDescription(safeGet(fields, 'System.Description'))
    );

    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Sprint__c', safeGet(fields, 'System.IterationPath'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Created_Date__c', safeGet(fields, 'System.CreatedDate'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Work_Item_Type__c', safeGet(fields, 'System.WorkItemType'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Reason__c', safeGet(fields, 'System.Reason'));

    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Comment__c',
        normalizeAzureDescription(safeGet(fields, 'System.History'))
    );

    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Effort__c', safeGet(fields, 'Microsoft.VSTS.Scheduling.Effort'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Last_Modified_Date__c', safeGet(fields, 'System.ChangedDate'));

    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Assignee__c', safeGetNested(fields, 'System.AssignedTo', 'displayName'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Created_By__c', safeGetNested(fields, 'System.CreatedBy', 'displayName'));
    FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Last_Modified_By__c', safeGetNested(fields, 'System.ChangedBy', 'displayName'));
}


/**
 * @description Safely retrieves a string value from a flat field in Azure JSON.
 * @param fields Map of field names and values from Azure JSON.
 * @param key Field key to retrieve.
 * @return String Value from field or null if missing.
 */
    private static String safeGet(Map<String, Object> fields, String key) {
        return (fields.containsKey(key) && fields.get(key) != null) 
            ? BulkApiCaller.fallbackDash(String.valueOf(fields.get(key))) 
            : null;
    }

/**
 * @description Safely retrieves a string value from a nested field in Azure JSON.
 * @param fields Map of field names and values from Azure JSON.
 * @param parentKey Parent field containing nested object.
 * @param childKey Field key inside nested object.
 * @return String Value from nested field or null if missing.
 */
    private static String safeGetNested(Map<String, Object> fields, String parentKey, String childKey) {
        if (fields.containsKey(parentKey) && fields.get(parentKey) != null) {
            Map<String, Object> nested = (Map<String, Object>) fields.get(parentKey);
            return nested.containsKey(childKey) ? BulkApiCaller.fallbackDash(String.valueOf(nested.get(childKey))) : null;
        }
        return null;
    }


/**
 *@description Normalizes an Azure DevOps HTML description string before storing it in a Salesforce
 *             Rich Text Area field. This ensures consistent rendering by cleaning up special characters,
 *             mentions, and inline styles that may not be fully supported in Salesforce.
 *
 * <p>Transformation rules applied:</p>
 * <ul>
 *   <li>Replaces non-breaking spaces (&nbsp;) with regular spaces.</li>
 *   <li>Converts Azure DevOps `data-vss-mention` attributes to a simpler `data-mention` attribute.</li>
 *   <li>Strips unsupported inline style attributes.</li>
 * </ul>
 *
 * @param rawHtml  The raw HTML string returned from Azure DevOps (may be null or blank).
 * @return         A cleaned and normalized HTML string safe to store in Salesforce RichText fields,
 *                 or null if the input is blank.
 */ 
    @TestVisible
    private static String normalizeAzureDescription(String rawHtml) {
    if (String.isBlank(rawHtml)) 
    {return null;}

    String html = rawHtml;

    // Replace non-breaking spaces
    html = html.replace('&nbsp;', ' ');

    // Fix Azure DevOps mentions (@user links)
    html = html.replace('data-vss-mention=', 'data-mention=');

    // (Optional) Strip unsupported inline styles
    html = html.replaceAll('style=\\"[^"]*\\"', '');

    
    // 🔹 Normalize <img> tags: remove existing width/height and apply standard size
    html = html.replaceAll('width=\\"\\d+\\"', '');
    html = html.replaceAll('height=\\"\\d+\\"', '');
    html = html.replaceAll('<img ', '<img width="172" height="131" ');

    return html;
}

}