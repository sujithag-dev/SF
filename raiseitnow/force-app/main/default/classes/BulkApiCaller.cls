/**
* @description       : BulkApiCaller Class is used to trigger batch processes for Jira, Azure, and ServiceNow 
*                      integrations, updating Bug_Tracking__c records via bulk API calls.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description
 * Trigger batch processes for Jira, Azure, and ServiceNow 
 * integrations, updating Bug_Tracking__c records via bulk API calls.
 */
public with sharing class BulkApiCaller {
   /**
     *  @description   Invoked from LWC to trigger the bulk API calls flow.
     *                 Wraps the run() method with @AuraEnabled to allow direct LWC access.
     */
   @AuraEnabled
   public static void runFromLwc() {
      run();
   }
    /**
     * @description Main entry point for bulk API calls.
     *              Triggered from a custom List View button on the Bug_Tracking__c record page,
     *               which invokes a Visualforce page and this Apex method.
     *               Fetches data from Jira, Azure, and ServiceNow,
     *               then updates Bug_Tracking__c records in Salesforce.
     */
    public static void run() {
          Database.executeBatch(new JiraIssuesBatch(), 100); 
          Database.executeBatch(new ServiceNowIssuesBatch(), 100); 
          Database.executeBatch(new AzureIssuesBatch(), 100); 
    }   
    
/**
 * @description Returns the input string or a dash "-" if null or blank.
 * @param input Input string as input.
 * @return String Original value or "-" if blank.
 */
     public static String fallbackDash(String input) {
        return String.isNotBlank(input) ? input : '-';
    }

}