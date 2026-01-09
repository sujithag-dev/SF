/**
* @description       : AzureIssuesBatch Class is used to perform batch processing for fetching and updating 
*                      Azure work items into Bug_Tracking__c records. It uses callouts to Azure DevOps APIs, 
*                      parses responses, and updates Salesforce accordingly.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description  Batch implementation for fetching and updating Azure work items 
 *               into Bug_Tracking__c records. Uses callouts to Azure DevOps APIs,
 *               parses responses, and updates Salesforce accordingly.
 */
public with sharing class AzureIssuesBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
      /**
     * @description Accumulates Azure work items retrieved during batch execution.
     */
	public List<Object> issues = new List<Object>();
     /**
     * @description Stores batch execution status and messages.
     */
    private ResultMessage resultMsg;

    
    /**
     * @description Initializes the batch with a default success message.
     */
	public AzureIssuesBatch() {
        this.resultMsg = new ResultMessage(true, 'Azure batch processing started');
    }

     /**
     * @description Defines the scope of records for batch execution.
     *              Retrieves Bug_Tracking__c records where Bug_Type__c = 'Azure'
     *              and Unique_Id__c is not null.
     * @param bc Batch context.
     * @return QueryLocator to iterate Bug_Tracking__c records.
     */
	 public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Unique_Id__c
            FROM Bug_Tracking__c
            WHERE Unique_Id__c != null AND Bug_Type__c = 'Azure'
        ]);
    }

    
    /**
     * @description Processes each batch scope of Bug_Tracking__c records.
     *              - Extracts Azure work item IDs.
     *              - Builds request body for Azure API.
     *              - Performs callout to Azure DevOps batch endpoint.
     *              - Parses response and maps work items to Bug_Tracking__c.
     * @param bc Batch context.
     * @param scope List of Bug_Tracking__c records in this batch chunk.
     */
	public void execute(Database.BatchableContext bc, List<Bug_Tracking__c> scope) {
        try {

			List<Integer> workItemIds = buildIssueIds(scope);

            if (workItemIds.isEmpty()) { return;} 

			List<Object> batchIds = convertToObjects(workItemIds);

			if (batchIds.isEmpty()) { return;}

			String endpoint = Constant.AZURE_LEGACY + '/_apis/wit/workitemsbatch?api-version=7.1-preview.1';
            String body = buildAzureBody(batchIds);

			HttpResponse response = ApiUtility.httpPostRequest(endpoint, body, Constant.CONTENT_TYPE_JSON);

            if (response != null && response.getStatusCode() == 200) {
                List<Object> batchData = parseAzureResponse(response);
                if (!batchData.isEmpty()) {
                    issues.addAll(batchData);
                }
            }else{
                 resultMsg.success = false;
                 resultMsg.message = 'Error in AzureBatchProcessor';
            }

            AzureBugTrackingUpdater.mapAzureBugToBugTracking(issues);

        } catch (Exception ex) {
             resultMsg.success = false;
             resultMsg.message = 'Error in AzureBatchProcessor: ' + ex.getMessage();
        }
    }

     /**
     * @description Finalizes batch execution.
     *              Updates result message with success/failure details and job ID.
     * @param bc Batch context.
     */
	 public void finish(Database.BatchableContext bc) {
        if (resultMsg.success) {
                resultMsg.message = 'Azure batch completed successfully but no issues were processed. Job ID: ' + bc.getJobId();
            } else {
                resultMsg.message = 'Azure batch completed successfully. Total issues processed. Job ID: ' + bc.getJobId();
            }
    }


     /**
     * @description Extracts Azure work item IDs from Bug_Tracking__c scope.
     * @param scope List of Bug_Tracking__c records.
     * @return List of Integer IDs.
     */
	 private List<Integer> buildIssueIds(List<Bug_Tracking__c> scope) {
        List<Integer> ids = new List<Integer>();
        for (Bug_Tracking__c bug : scope) {
            if (bug.Unique_Id__c != null) {ids.add(Integer.valueOf(bug.Unique_Id__c));} 
        }
        return ids;
    }

     /**
     * @description Converts a list of work item IDs to a list of Objects for serialization.
     * @param workItemIds List of work item IDs.
     * @return List<Object> containing work item IDs.
     */
    @TestVisible
	private static List<Object> convertToObjects(List<Integer> workItemIds) {
          if (workItemIds == null || workItemIds.isEmpty()) {
                 return new List<Object>();
           }
 
         List<Object> batchIds = new List<Object>();
         for (Integer id : workItemIds) {
                batchIds.add(id);
          }

         return batchIds;
  }

   /**
     * @description Parses the Azure API response to extract work items.
     * @param response HttpResponse returned from Azure API.
     * @return List<Object> representing Azure work items.
     */
   private List<Object> parseAzureResponse(HttpResponse response) {
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> batchData = (List<Object>) jsonResponse.get('value');
        return batchData != null ? batchData : new List<Object>();
    }


     /**
     * @description Builds the JSON request body for Azure DevOps work item batch API.
     * @param batchIds List of work item IDs to include in the request.
     * @return String containing serialized JSON body.
     */
	private String buildAzureBody(List<Object> batchIds) {

       Map<String, Object> body = new Map<String, Object>{
            'ids' => batchIds,
            'fields' => new List<String>{
                'System.Title',
                'System.CreatedBy',
                'System.CreatedDate',
                'System.TeamProject',
                'System.IterationPath',
                'System.WorkItemType',
                'System.AssignedTo',
                'System.State',
                'System.Reason',
                'Microsoft.VSTS.Common.Priority',
                'Microsoft.VSTS.Scheduling.Effort',
                'System.History',
                'System.Description',
                'System.ChangedDate',
                'System.ChangedBy'
            }
        };

        String jsonBody = JSON.serialize(body);
		return jsonBody;
    }

}