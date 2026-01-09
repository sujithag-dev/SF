/**
* @description       : TicketRecordHelper Class is used for parsing and extracting ticket response data
*                      based on different bug tracking systems (Jira, Azure, ServiceNow).
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Helper class for parsing and extracting ticket response data
 * based on different bug tracking systems (Jira, Azure, ServiceNow).
 */
public with sharing class TicketRecordHelper  {
	/**
     * @description Extracts relevant fields from the given ticket response string
     *              based on the bug type.
     * @param response The JSON string response received from the external system.
     * @param bugType The type of bug tracker (e.g., 'Jira', 'Azure', 'Service Now').
     * @return A map containing ticket metadata to be used for record creation.
     */
	 public  static Map<String, Object> extractTicketData(String response, String bugType) {
       Map<String, Object> initialRes = (Map<String, Object>) JSON.deserializeUntyped(response);
       Map<String, Object> ticketData = new Map<String, Object>();  
       switch on bugType {
           when 'Jira' {
                 extractJiraData(initialRes, ticketData);
            }
           when 'Azure' {
                 extractAzureData(initialRes, ticketData);
            }
           when 'Service Now' {
                 extractServiceNowData(initialRes, ticketData);
            }
        }
       return ticketData;
    }

	 /**
     * @description Extracts Jira-specific ticket fields like 'key'.
     * @param initialRes Parsed response map.
     * @param ticketData The result map to populate.
     */
	  private static void extractJiraData(Map<String, Object> initialRes, Map<String, Object> ticketData) {
         if (initialRes.containsKey('key')) {  ticketData.put('key', initialRes.get('key')); }
		 if (initialRes.containsKey('id')) {  ticketData.put('id', initialRes.get('id')); }
    }
	/**
     * @description Extracts Azure-specific ticket fields like 'id' and 'project'.
     * @param initialRes Parsed response map.
     * @param ticketData The result map to populate.
     */
	 private static void extractAzureData(Map<String, Object> initialRes, Map<String, Object> ticketData) {
        if (initialRes.containsKey('id')) { ticketData.put('id', initialRes.get('id')); }  
        if (initialRes.containsKey('fields')) {
              Map<String, Object> fields = (Map<String, Object>) initialRes.get('fields');
             
              ticketData.put('project', fields.get('System.TeamProject'));
            }
    }
	/**
     * @description Extracts ServiceNow-specific fields like 'result'.
     * @param initialRes Parsed response map.
     * @param ticketData The result map to populate.
     */
	 private static void extractServiceNowData(Map<String, Object> initialRes, Map<String, Object> ticketData) {
        if (initialRes.containsKey('result')) {  ticketData.put('result', initialRes.get('result')); }
    }
	 /**
     * @description Converts the parsed ticket data to the appropriate wrapper object
     *              depending on the bug type.
     * @param bugType The type of ticketing system.
     * @param ticketDataJSON Serialized ticket data.
     * @return A BugDataWrapper instance holding system-specific deserialized objects.
     */
	 public  static BugDataWrapper createBugDataWrapper(String bugType, String ticketDataJSON) {
        BugDataWrapper wrapper = new BugDataWrapper();  
        switch on bugType {
           when 'Jira' {
                  wrapper.jiraData = ticketDataJSON != null  ? (WrapperContainer.JiraTicketResponse) JSON.deserialize(ticketDataJSON, WrapperContainer.JiraTicketResponse.class) : new WrapperContainer.JiraTicketResponse();
            }
           when 'Azure' {
                  wrapper.azureData = ticketDataJSON != null ? (WrapperContainer.AzureGetAPIData) JSON.deserialize(ticketDataJSON, WrapperContainer.AzureGetAPIData.class) : new WrapperContainer.AzureGetAPIData();
            }
           when 'Service Now' {
                  wrapper.serviceData = ticketDataJSON != null ? (WrapperContainer.ServiceNowTicketResponse) JSON.deserialize(ticketDataJSON, WrapperContainer.ServiceNowTicketResponse.class) : new WrapperContainer.ServiceNowTicketResponse();
            }
         }  
       return wrapper;
    }
	/**
     * @description Determines the unique ID of the ticket based on bug type and wrapper.
     * @param bugType The bug tracking system name.
     * @param wrapper A wrapper holding deserialized data.
     * @return The unique identifier (e.g., Jira key, ServiceNow sys_id).
     */
	 public  static String getUniqueId(String bugType, BugDataWrapper wrapper) {
       switch on bugType {
            when 'Jira' { return wrapper.jiraData.key;  }
            when 'Service Now' {  return wrapper.serviceData.result.sys_id; }
            when 'Azure' { return String.valueOf(wrapper.azureData.id); }
            when else { return null; }
         }
    }
	 /**
     * @description Determines the project name from the bug system and wrapper.
     * @param bugType The bug tracking system name.
     * @param projectName The provided project name (fallback).
     * @param wrapper A wrapper holding deserialized data.
     * @return The actual project name to store in the record.
     */
	  public  static String getProjectName(String bugType, String projectName, BugDataWrapper wrapper) {
        switch on bugType {
             when 'Jira', 'Service Now' { return projectName; }
             when 'Azure' { return wrapper.azureData.project; }
             when else { return null; }
         }
    }
	
     /**
     * @description Determines the key/id to store in Bug_Tracking__c.
     * @param bugType The bug tracking system name.
     * @param wrapper Wrapper containing deserialized response data.
     * @return The key/id value.
     */
	public  static String getKey(String bugType,BugDataWrapper wrapper) {
        switch on bugType {
             when 'Jira' { return wrapper.jiraData.id; }
             when 'Service Now'{return wrapper.serviceData.result.task_effective_number;}
             when else { return null; }
         }
    }
	/**
     * @description Wrapper class holding ticket response models for Jira, Azure, and ServiceNow.
     */
	 public  class BugDataWrapper {
        public WrapperContainer.JiraTicketResponse jiraData;
        public WrapperContainer.AzureGetAPIData azureData;
        public WrapperContainer.ServiceNowTicketResponse serviceData;
    }

}