/**
* @description       : TicketRecordService Class is used to create and manage Bug_Tracking__c records 
*                      based on responses from external bug tracking systems (Jira, Azure, ServiceNow).
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
* @description Create and manage Bug_Tracking__c records 
*              based on responses from external bug tracking systems (Jira, Azure, ServiceNow).
*/
public with sharing class TicketRecordService  {
    
    // RecordType Ids by Name
    private static Map<String, Id> recordTypeMap = new Map<String, Id>();
    
    
/**
* @description Creates a Bug_Tracking__c record from an external bug tracking system response.
* @param jsonRequest The request JSON containing bug details.
* @return Id of the created Bug_Tracking__c record.
*/
    public static Id createTicketRecord(String jsonRequest) {
        WrapperContainer.TicketRequest request = (WrapperContainer.TicketRequest) JSON.deserialize(jsonRequest, WrapperContainer.TicketRequest.class);
        
        if (!Schema.sObjectType.Bug_Tracking__c.isCreateable()) {
            throw new AuraHandledException('You do not have permission to create Bug_Tracking__c records.');
        }
        
        Map<String, Object> ticketData = TicketRecordHelper.extractTicketData(request.response, request.bugType);
        String ticketDataJSON = JSON.serialize(ticketData);
        TicketRecordHelper.BugDataWrapper wrapper = TicketRecordHelper.createBugDataWrapper(request.bugType, ticketDataJSON);
        
        return insertBugRecord(request, wrapper);
    }
    
/**
* @description Inserts a Bug_Tracking__c record after mapping request data.
* @param request The request wrapper containing bug details.
* @param wrapper Processed bug data wrapper.
* @return Id of the inserted Bug_Tracking__c record.
*/
    private static Id insertBugRecord(WrapperContainer.TicketRequest request,TicketRecordHelper.BugDataWrapper wrapper) {
        Bug_Tracking__c bug = new Bug_Tracking__c();
        
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Service_Template__c', request.templateId);
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Unique_Id__c', TicketRecordHelper.getUniqueId(request.bugType, wrapper));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Project__c', TicketRecordHelper.getProjectName(request.bugType, request.projectName, wrapper));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Key__c', TicketRecordHelper.getKey(request.bugType, wrapper));
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Bug_Type__c', request.bugType);
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Description__c', request.description);
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Assignee__c', request.assigneeName);
        
        TimeZone tz               = UserInfo.getTimeZone();
        Datetime dtIST            = System.now().addMinutes(tz.getOffset(System.now()) / (60 * 1000));
        String formattedDT = dtIST.format('EEE, MMM d, yyyy, h:mm a', 'Asia/Kolkata');
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Created_Date__c', formattedDT);
        FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Last_Modified_Date__c', formattedDT);
        
        applyBugTypeMappings(request, bug);

        
        
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE,new List<Bug_Tracking__c>{ bug } );
        
        List<Bug_Tracking__c> filteredBugs = (List<Bug_Tracking__c>) decision.getRecords();
        
        if (!filteredBugs.isEmpty()) {
            insert filteredBugs;
            return filteredBugs[0].Id;
        }
        return null;
    
    }
    
    /**
     * @description Applies bug-type specific field mappings.
     * @param request The request wrapper.
     * @param bug The Bug_Tracking__c record to populate.
     */
    private static void applyBugTypeMappings(WrapperContainer.TicketRequest request, Bug_Tracking__c bug) {
        if (request.bugType == 'Jira') {
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Priority__c', request.priority);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Issue_Type__c', request.issuetype);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Summary__c', request.summary);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'RecordTypeId', getRecordTypeId('Jira'));
        } else if (request.bugType == 'Azure') {
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Title__c', request.title);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Priority__c', request.priority);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Status__c', request.state);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'RecordTypeId', getRecordTypeId('Azure'));
        } else if (request.bugType == 'Service Now') {
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Impact__c', request.impact);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Urgency__c', request.urgency);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'Short_Description__c', request.shortDescription);
            FieldAccessUtil.setIfCreateableAndUpdateable(bug, 'RecordTypeId', getRecordTypeId('Service Now'));
        }
    }
    
/**
* @description Returns the RecordTypeId for Bug_Tracking__c given a RecordType name.  
* @param recordTypeName The developer name of the RecordType.
* @return Id of the RecordType, or null if not found or name is blank.
*/
    private static Id getRecordTypeId(String recordTypeName) {
        if (String.isBlank(recordTypeName)){
            return null;
        }
        
        if (!recordTypeMap.containsKey(recordTypeName)) {
            for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE Name IN ('Jira', 'Azure', 'Service Now') WITH SECURITY_ENFORCED]) {
                recordTypeMap.put(rt.Name, rt.Id);
            }
        }
        return recordTypeMap.get(recordTypeName);
    }
    
}