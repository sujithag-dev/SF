/**
* @description       : JiraIssuesBatch Class is used to fetches Jira issues in batches and updates Salesforce Bug Tracking records.
*                      Processes 100 records per API call and supports stateful batch processing.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @class JiraIssuesBatch
 * @implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts
 * @description Fetches Jira issues in batches and updates Salesforce Bug Tracking records.
 *              Processes 100 records per API call and supports stateful batch processing.
 */
public with sharing class JiraIssuesBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

  /** 
   * @description Stores the Base64-encoded list of Jira fields used in API requests. 
   */
    private String encodedFields;
  /**
   * @description Accumulates Jira issues retrieved during batch execution.
   */
    public List<Object> issues = new List<Object>();
    /**
     * @description Stores batch execution status and messages.
     */
    private ResultMessage resultMsg;

    /**
     * @constructor JiraIssuesBatch
     * @description Encodes common Jira fields for batch API calls.
     */
    public JiraIssuesBatch() {
        String fields = 'creator,created,project,issuetype,reporter,assignee,statusCategory,priority,labels,environment,summary,description,lastViewed';
        this.encodedFields = EncodingUtil.urlEncode(fields, 'UTF-8');
        this.resultMsg = new ResultMessage(true, 'Jira batch processing started');
    }

    /**
     * @method start
     * @param bc Database.BatchableContext
     * @return Database.QueryLocator
     * @description Queries all Bug_Tracking__c records with Jira issue keys.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Unique_Id__c, Key__c
            FROM Bug_Tracking__c
            WHERE Unique_Id__c != null AND Bug_Type__c = 'Jira'
        ]);
    }

    /**
     * @method execute
     * @param bc Database.BatchableContext
     * @param scope List<Bug_Tracking__c>
     * @description Processes a batch of Bug_Tracking__c records:
     *              1. Builds Jira issue key list
     *              2. Calls Jira REST API
     *              3. Updates Bug_Tracking__c via helper class
     */
    public void execute(Database.BatchableContext bc, List<Bug_Tracking__c> scope) {
        try {
            List<String> issueKeys = buildIssueKeys(scope);
            List<String> issueIds  = buildIssueIds(scope);

            if (issueKeys.isEmpty()) { return;} 

            String endpoint = buildEndpoint(issueKeys, issueIds);
            HttpResponse response = ApiUtility.sendGetRequest(endpoint);

            if (response != null && response.getStatusCode() == 200) {
                List<Object> batchData = parseJiraResponse(response);
                if (!batchData.isEmpty()) {
                    issues.addAll(batchData);
                }
            }else{
                 resultMsg.success = false;
                 resultMsg.message = 'Error in JiraBatchProcessor';
            }

            JiraBugTrackingUpdater.updateBugTrackingBatchFromJiraResponse(issues);

        } catch (Exception ex) {
             resultMsg.success = false;
             resultMsg.message = 'Error in JiraBatchProcessor: ' + ex.getMessage();
        }
    }

    /**
     * @method finish
     * @param bc Database.BatchableContext
     * @description Finalization logic after batch completes.
     */
    public void finish(Database.BatchableContext bc) {
        if (resultMsg.success) {
                resultMsg.message = 'Jira batch completed successfully but no issues were processed. Job ID: ' + bc.getJobId();
            } else {
                resultMsg.message = 'Jira batch completed successfully. Total issues processed. Job ID: ' + bc.getJobId();
            }
    }

    // ---------------- Helper Methods ----------------

    private List<String> buildIssueKeys(List<Bug_Tracking__c> scope) {
        List<String> keys = new List<String>();
        for (Bug_Tracking__c bug : scope) {
            if (bug.Unique_Id__c != null) {keys.add(bug.Unique_Id__c.trim());} 
        }
        return keys;
    }

    private List<String> buildIssueIds(List<Bug_Tracking__c> scope) {
        List<String> ids = new List<String>();
        for (Bug_Tracking__c bug : scope) {
            if (bug.Key__c != null) {ids.add(bug.Key__c.trim());} 
        }
        return ids;
    }

    private String buildEndpoint(List<String> keys, List<String> ids) {
        String jql = 'key in (' + String.join(keys, ',') + ')';
        String reconcileIssues = 'reconcileIssues in (' + String.join(ids, ',') + ')';
        return Constant.JIRA_LEGACY + '/rest/api/3/search/jql' +
               '?jql=' + EncodingUtil.urlEncode(jql, 'UTF-8') +
               '&maxResults=100' +
               '&fields=' + encodedFields +
               '&expand=changelog&' + EncodingUtil.urlEncode(reconcileIssues, 'UTF-8');
    }

    private List<Object> parseJiraResponse(HttpResponse response) {
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> batchData = (List<Object>) jsonResponse.get('issues');
        return batchData != null ? batchData : new List<Object>();
    }
}