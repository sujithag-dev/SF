/**
* @description       : JiraBugTrackingUpdater Class is used to handles updating Bug_Tracking__c records from Jira responses.
*                      Parses the Jira JSON response and updates corresponding records safely.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Handles updating Bug_Tracking__c records from Jira responses.
 *              Parses the Jira JSON response and updates corresponding records safely.
 */
public with sharing class JiraBugTrackingUpdater {
    /**
     * @description Processes a batch of Jira issues and updates Bug_Tracking__c records in bulk.
     *              This method is Queueable-safe and does NOT require @future.
     *
     * @param issues List<Object> - deserialized Jira issues from API response
     */
    public static void updateBugTrackingBatchFromJiraResponse(List<Object> issues) {
        if (issues == null || issues.isEmpty()){ return;}

        try {
            // Step 1: Collect Unique IDs from Jira issues
            Set<String> uniqueIds = collectJiraUniqueIds(issues);

            if (uniqueIds.isEmpty()){return;} 

            // Step 2: Load existing Bug_Tracking__c records (User Mode)
            Map<String, Bug_Tracking__c> existingBugs = loadExistingJiraBugs(uniqueIds);

            if (existingBugs.isEmpty()){return;} 

            // Step 3: Map fields from Jira issues to Bug_Tracking__c records
            List<Bug_Tracking__c> recordsToUpdate = buildJiraRecordsToUpdate(issues, existingBugs);

            // Step 4: Bulk update (User Mode, respects CRUD/FLS)
            if (!recordsToUpdate.isEmpty() && Schema.sObjectType.Bug_Tracking__c.isUpdateable()) {
                Database.update(recordsToUpdate, false, AccessLevel.USER_MODE);
            }

        } catch (Exception e) {
            throw new CustomException('Error occurred: ' + e.getMessage());
        }
    }


 /**
 * @description Collects unique Jira issue keys from the response for querying
 *              existing Bug_Tracking__c records.
 * @param issues List of Jira issues from JSON response.
 * @return Set<String> Set of unique Jira issue keys.
 */
    private static Set<String> collectJiraUniqueIds(List<Object> issues) {
        Set<String> ids = new Set<String>();
        for (Object issueObj : issues) {
            Map<String, Object> issue = (Map<String, Object>) issueObj;
            ids.add((String) issue.get('key'));
        }
        return ids;
    }

/**
 * @description Queries Bug_Tracking__c records matching the provided unique IDs.
 *              Enforces USER_MODE for CRUD/FLS compliance.
 * @param uniqueIds Set of Jira issue keys.
 * @return Map<String, Bug_Tracking__c> Map of unique ID to Bug_Tracking__c record.
 */
    private static Map<String, Bug_Tracking__c> loadExistingJiraBugs(Set<String> uniqueIds) {
        Map<String, Bug_Tracking__c> mapBugs = new Map<String, Bug_Tracking__c>();

    List<Bug_Tracking__c> bugList = [ SELECT Id, Unique_Id__c FROM Bug_Tracking__c WHERE Unique_Id__c IN :uniqueIds WITH USER_MODE];
        for (Bug_Tracking__c bug : bugList ) {
            mapBugs.put(bug.Unique_Id__c, bug);
        }
        return mapBugs;
    }

/**
 * @description Maps Jira issues to Bug_Tracking__c records, preparing them
 *              for DML update.
 * @param issues List of Jira issues from JSON response.
 * @param existingBugs Map of existing Bug_Tracking__c records keyed by Jira issue key.
 * @return List<Bug_Tracking__c> List of updated Bug_Tracking__c records.
 */
    private static List<Bug_Tracking__c> buildJiraRecordsToUpdate(List<Object> issues, Map<String, Bug_Tracking__c> existingBugs) {
        List<Bug_Tracking__c> updates = new List<Bug_Tracking__c>();

        for (Object issueObj : issues) {
            Map<String, Object> issue = (Map<String, Object>) issueObj;
            String key = (String) issue.get('key');

            if (!existingBugs.containsKey(key)) {continue;} 

            Bug_Tracking__c bug = existingBugs.get(key);
            Map<String, Object> fields = (Map<String, Object>) issue.get('fields');

            mapBasicFields(bug, issue, fields);
            mapUserFields(bug, fields);
            mapRichTextFields(bug, fields);

            updates.add(bug);
        }
        return updates;
    }


/**
 * @description Maps basic Jira fields to Bug_Tracking__c.
 * @param bug Bug_Tracking__c record to update.
 * @param issue Single Jira issue object from JSON.
 * @param fields Map of Jira fields for the issue.
 */
    private static void mapBasicFields(Bug_Tracking__c bug, Map<String, Object> issue, Map<String, Object> fields) {

        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Unique_Id__c', (String) issue.get('key'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Key__c', (String) issue.get('id'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Summary__c', safeGetJira(fields, 'summary'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Priority__c', safeGetNestedJira(fields, 'priority', 'name'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Issue_Type__c', safeGetNestedJira(fields, 'issuetype', 'name'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Project__c', safeGetNestedJira(fields, 'project', 'name'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Created_Date__c', safeGetJira(fields, 'created'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Last_Modified_Date__c', safeGetJira(fields, 'lastViewed'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Label__c', extractLabels(fields));
    }

/**
 * @description Maps user-related fields from Jira issue to Bug_Tracking__c.
 * @param bug Bug_Tracking__c record to update.
 * @param fields Map of Jira fields for the issue.
 */
    private static void mapUserFields(Bug_Tracking__c bug, Map<String, Object> fields) {
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Assignee__c', safeGetNestedJira(fields, 'assignee', 'displayName'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Created_By__c', safeGetNestedJira(fields, 'creator', 'displayName'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Reporter__c', safeGetNestedJira(fields, 'reporter', 'displayName'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Status__c', safeGetNestedJira(fields, 'statusCategory', 'name'));
    }

 /**
 * @description Maps rich-text fields like Description and Environment.
 * @param bug Bug_Tracking__c record to update.
 * @param fields Map of Jira fields for the issue.
 */
    private static void mapRichTextFields(Bug_Tracking__c bug, Map<String, Object> fields) {

        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Description__c', extractDescription(fields, 'description'));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Environment__c', extractDescription(fields, 'environment'));
    }

/**
 * @description Extracts and joins Jira labels for a Bug_Tracking__c record.
 * @param fields Map of Jira fields for the issue.
 * @return String Semi-colon separated labels or null.
 */
    @TestVisible
    private static String extractLabels(Map<String, Object> fields) {
        if (fields.containsKey('labels') && fields.get('labels') != null) {
            List<Object> labels = (List<Object>) fields.get('labels');
            List<String> labelStrings = new List<String>();
            for (Object label : labels) {
                labelStrings.add((String) label);
            }
            return BulkApiCaller.fallbackDash(String.join(labelStrings, ';'));
        }
        return null;
    }
/**
 * @description Safely retrieves a string value from a Jira fields map.
 * @param fields Map of Jira fields for the issue.
 * @param key Field key to retrieve.
 * @return String Value or null if not present.
 */
    private static String safeGetJira(Map<String, Object> fields, String key) {
        return (fields.containsKey(key) && fields.get(key) != null)
            ? BulkApiCaller.fallbackDash(String.valueOf(fields.get(key)))
            : null;
    }

/**
 * @description Safely retrieves a nested string value from a Jira fields map.
 * @param fields Map of Jira fields for the issue.
 * @param parentKey Parent key containing nested map.
 * @param childKey Key inside nested map.
 * @return String Value or null if not present.
 */
    private static String safeGetNestedJira(Map<String, Object> fields, String parentKey, String childKey) {
        if (fields.containsKey(parentKey) && fields.get(parentKey) != null) {
            Map<String, Object> nested = (Map<String, Object>) fields.get(parentKey);
            return nested.containsKey(childKey) ? BulkApiCaller.fallbackDash(String.valueOf(nested.get(childKey))) : null;
        }
        return null;
    }

    /**
     * @description Converts a Jira description JSON (doc format) into Salesforce RichText-compatible HTML.
     *
     * @param fields     Map of Jira fields from the API response.
     * @param fieldName  The key (e.g., 'description') that contains the JSON doc structure.
     * @return           HTML string safe to store in RichText fields, or null if not present.
     */
   
    public static String extractDescription(Map<String, Object> fields, String fieldName) {
        if (fields == null || !fields.containsKey(fieldName) || fields.get(fieldName) == null) {
            return null;
        }

        Map<String, Object> richField = (Map<String, Object>) fields.get(fieldName);
        if (!richField.containsKey('content')) {
            return null;
        }

        List<Object> contentList = (List<Object>) richField.get('content');
        String html = '';

        for (Object blockObj : contentList) {
            html += JiraDescriptionParser.processBlockHtml((Map<String, Object>) blockObj);
        }

        return String.isNotBlank(html) ? html : null;
    }

}