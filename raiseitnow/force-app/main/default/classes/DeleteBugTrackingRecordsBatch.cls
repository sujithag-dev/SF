/**
* @description       : DeleteBugTrackingRecordsBatch class to delete Bug_Tracking__c records older than 6 months
*                      with specific statuses.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Batch class to delete Bug_Tracking__c records older than 6 months
 * with specific statuses.
 */
public class DeleteBugTrackingRecordsBatch implements Database.Batchable<SObject> {

    private final List<String> statusList;

    /**
     * @description Default constructor uses constant status list.
     */
    public DeleteBugTrackingRecordsBatch() {
        this.statusList = Constant.STATUS_LIST;
    }

    /**
     * @description Constructor for testing with mock status list.
     * @param mockStatusList List of status values to filter records
     */
    public DeleteBugTrackingRecordsBatch(List<String> mockStatusList) {
        this.statusList = mockStatusList;
    }

     /**
     * @description Returns a QueryLocator for Bug_Tracking__c records older than 6 months
     * with statuses in the provided list.
     * @param context The batchable context
     * @return Database.QueryLocator for records to process
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        Date sixMonthsAgo = Date.today().addMonths(-6);
        return Database.getQueryLocator([
            SELECT Id
            FROM Bug_Tracking__c
            WHERE CreatedDate <= :sixMonthsAgo
              AND Status__c IN :statusList
        ]);
    }

        /**
     * @description Deletes the batch of Bug_Tracking__c records.
     * @param context The batchable context
     * @param scope List of Bug_Tracking__c records to delete
     */
    public void execute(Database.BatchableContext context, List<Bug_Tracking__c> scope) {
        if (!scope.isEmpty()) {
            Database.delete(scope, false);
        }
    }

    
    /**
     * @description Finish method required by Batchable interface.
     * @param context The batchable context
     */
    public void finish(Database.BatchableContext context) {
        ResultMessage result = new ResultMessage(true, 'DeleteBugTrackingRecordsBatch completed successfully');
        result.payload.add('Job Id: ' + context.getJobId());
        
    }
}