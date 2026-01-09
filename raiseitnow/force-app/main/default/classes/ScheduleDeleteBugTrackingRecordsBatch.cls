/**
* @description       : ScheduleDeleteBugTrackingRecordsBatch Class is used to launches the DeleteBugTrackingRecordsBatch job.
*                      This ensures old bug tracking records are cleaned up on a schedule.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Schedulable class that launches the DeleteBugTrackingRecordsBatch job.
 *              This ensures old bug tracking records are cleaned up on a schedule.
 */
public with sharing class ScheduleDeleteBugTrackingRecordsBatch implements Schedulable {
    /**
     * @description Executes the scheduled job by running the DeleteBugTrackingRecordsBatch.
     * @param sc The system-provided SchedulableContext parameter.
     */
    public void execute(SchedulableContext sc) {
        DeleteBugTrackingRecordsBatch batchJob = new DeleteBugTrackingRecordsBatch();
        Database.executeBatch(batchJob, 200); 
 
    }
}