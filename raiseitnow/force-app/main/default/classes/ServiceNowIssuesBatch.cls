/**
* @description       : ServiceNowIssuesBatch Class is used to perform batch processing for fetching and updating 
*                      ServiceNow incident records into Bug_Tracking__c. It makes callouts to the ServiceNow API, 
*                      parses the response, and updates Salesforce data accordingly.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description  Perform batch processing for fetching and updating 
 *               ServiceNow incident records into Bug_Tracking__c. It makes callouts to the ServiceNow API, 
 *               parses the response, and updates Salesforce data accordingly.
 */
public with sharing class ServiceNowIssuesBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
   /**
    * @description Holds issues fetched from ServiceNow API.
    */
    public List<Object> issues = new List<Object>();
   /**
    * @description Stores batch execution status and messages.
    */
    private ResultMessage resultMsg;

    /**
     * @description Constructor initializes ResultMessage with default success message.
     */
	public ServiceNowIssuesBatch() {
        this.resultMsg = new ResultMessage(true, 'ServiceNow batch processing started');
    }

    /**
     * @description Defines the query to fetch ServiceNow bug records to process in batch.
     * @param bc Batchable context
     * @return QueryLocator returning Bug_Tracking__c records with ServiceNow type.
     */
	public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Unique_Id__c
            FROM Bug_Tracking__c
            WHERE Unique_Id__c != null AND Bug_Type__c = 'Service Now'
        ]);
    }

    /**
     * @description Executes batch logic for each scope of records.
     *              Fetches data from ServiceNow API and updates Bug_Tracking__c records.
     * @param bc Batchable context
     * @param scope List of Bug_Tracking__c records to process.
     */
	 public void execute(Database.BatchableContext bc, List<Bug_Tracking__c> scope) {
        try {
            List<String> allSysIds = buildSysIds(scope);

            if (allSysIds.isEmpty()) { return;} 

            String endpoint = buildEndpoint(allSysIds);

            HttpResponse response = ApiUtility.sendGetRequest(endpoint);

            if (response != null && response.getStatusCode() == 200) {
                List<Object> batchData = parseServiceNowResponse(response);
                if (!batchData.isEmpty()) {
                    issues.addAll(batchData);
                }
            }else{
                 resultMsg.success = false;
                 resultMsg.message = 'Error in ServiceNowBatchProcessor';
            }
            ServiceNowBugTrackingUpdater.updateBugTrackingBatchFromServiceNowResponse(issues);
        } catch (Exception ex) {
             resultMsg.success = false;
             resultMsg.message = 'Error in ServiceNowBatchProcessor: ' + ex.getMessage();
        }
    }

    /**
     * @description Called after all batch executions complete.
     *              Logs final result message and job ID.
     * @param bc Batchable context
     */
	public void finish(Database.BatchableContext bc) {
        if (resultMsg.success) {
                resultMsg.message = 'ServiceNow batch completed successfully but no issues were processed. Job ID: ' + bc.getJobId();
            } else {
                resultMsg.message = 'ServiceNow batch completed successfully. Total issues processed. Job ID: ' + bc.getJobId();
            }
    }

    /**
     * @description Builds list of sys_ids from Bug_Tracking__c scope records.
     * @param scope List of Bug_Tracking__c records
     * @return List of sys_id strings
     */
	private List<String> buildSysIds(List<Bug_Tracking__c> scope) {
        List<String> sysIds = new List<String>();
        for (Bug_Tracking__c bug : scope) {
            if (bug.Unique_Id__c != null) {sysIds.add(bug.Unique_Id__c.trim());} 
        }
        return sysIds;
    }

    /**
     * @description Builds the ServiceNow API endpoint URL using provided sys_ids.
     * @param allSysIds List of sys_ids to query from ServiceNow
     * @return Constructed API endpoint string
     */
	 private String buildEndpoint(List<String> allSysIds) {
		String joinedIds = String.join(allSysIds, ',');

		return  Constant.SERVICE_NOW_LEGACY
                    + '/api/now/table/incident'
                    + '?sysparm_query=sys_idIN' + joinedIds
                    + '&sysparm_limit=100'
                    + '&sysparm_display_value=all'
                    + '&sysparm_fields=' + String.join(new List<String>{
                            'sys_id','sys_created_by','sys_created_on','sys_class_name','cmdb_ci',
                            'category','assigned_to','incident_state','priority',
                            'urgency','impact','subcategory','description',
                            'short_description','sys_updated_on'
                            }, ',');                  
    }

    /**
     * @description Parses ServiceNow API JSON response to extract result list.
     * @param response HttpResponse from ServiceNow API
     * @return List of issue records from ServiceNow API response
     */
	private List<Object> parseServiceNowResponse(HttpResponse response) {
		Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> records = (List<Object>) root.get('result');
		return records != null ? records : new List<Object>(); 
    }
}