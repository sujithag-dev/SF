/**
* @description Utility class for logging errors into Error Log.
* Supports Apex, Trigger and Integration error tracking.
*/
public with sharing class MFG_Logs {
 
    /**
     * @description Creates a pre-populated mfg_Log__c instance.
     * @return A new error log record ready for population.
     */
    public static mfg_Log__c newErrorInstance() {
        mfg_Log__c errorLog = new mfg_Log__c();
        errorLog.mfg_Occurred_At__c = System.now();
        errorLog.mfg_User__c = UserInfo.getUserId();
        errorLog.OwnerId = UserInfo.getUserId();
        return errorLog;
    }

        // @AuraEnabled
        // public static void logFromLWC(String message, String componentName) {
        //     mfg_Log__c err = MFG_Logs.newErrorInstance();
        //     err.mfg_Error_Message__c = message;
        //     err.mfg_Source_Component__c = componentName;
        //     err.mfg_Logged_By_Automation__c = 'LWC';
        //     MFG_Logs.save(err);
        // }

 
    /**
     * @description Saves a single error record safely.
     * @param errorLog The mfg_Log__c record to insert.
     */
    public static void save(mfg_Log__c errorLog) {
        if (errorLog == null) {
            return;
        }
        try {
            insert errorLog;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + ex.getMessage());
        }
    }
 
    /**
     * @description Saves multiple error records in bulk (safe for batch/trigger contexts).
     * @param errorLogs List of mfg_Log__c records to insert.
     */
    public static void saveAll(List<mfg_Log__c> errorLogs) {
        if (errorLogs == null || errorLogs.isEmpty()) {
            return;
        }
        try {
            Database.insert(errorLogs, false);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Failed to bulk log errors: ' + ex.getMessage());
        }
    }
}