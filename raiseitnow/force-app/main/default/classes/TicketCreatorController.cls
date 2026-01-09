/**
* @description       : TicketCreatorController Class is used to create the tickets with the services.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 13-06-2024
* last modified by   : 
**/
/**
* @description TicketCreatorController is used to create the tickets with the services.
*
 */ 
public with sharing class TicketCreatorController {

    /**
      * @description Retrieves details of templates.
      * @return ResultMessage indicating the success of the operation and containing template details. 
     */
    @AuraEnabled
    public static ResultMessage getTemplateDetails() {
       return TemplateService.getTemplateDetails();
    }
   
    /**
     * @description Get Uploaded Attachments.
     * @param recordId The ID of the record for which attachments are being retrieved.
     * @return ResultMessage indicating the success of the operation and containing the retrieved attachments.
     */
    @AuraEnabled
    public static ResultMessage getUploadedAttachments(String recordId) {
          return AttachmentManager.getUploadedAttachments( recordId);
     }
    

    /**
     * @description Deletes attachments.
     * @param contentDocumentIds The IDs of the content documents to be deleted.
     * @return ResultMessage indicating the success of the operation.
     */
    @AuraEnabled
    public static ResultMessage deleteAttachment(List<Id> contentDocumentIds) {
       return AttachmentManager.deleteAttachment( contentDocumentIds);
    }
    /**
     * @description Creates a Jira ticket.
     * @param ticketInputs The input data for creating the Jira ticket.
     * @return ResultMessage indicating the success of the operation and containing the response from Jira.
     */
    @AuraEnabled
    public static ResultMessage createJiraTicket(String ticketInputs) {
         return TicketCreationService.createJiraTicket(ticketInputs);
     }
   
   
    /**
     * @description Creates a ServiceNow ticket.
     * @param ticketInputs The input data for creating the ServiceNow ticket.
     * @return ResultMessage indicating the success of the operation and containing the response from ServiceNow.
     */
    @AuraEnabled
    public static ResultMessage createServiceNowTicket(String ticketInputs) {
        return TicketCreationService.createServiceNowTicket(ticketInputs);
     }
   
   
    /**
     * @description Creates an Azure ticket.
     * @param ticketInputs The input data for creating the Azure ticket.
     * @return ResultMessage indicating the success of the operation and containing the response from Azure.
     */
    @AuraEnabled
    public static ResultMessage createAzureTicket(String ticketInputs){
         return TicketCreationService.createAzureTicket(ticketInputs);
    }
   
    /**
     * @description Retrieves the list of configuration items.
     * @return ResultMessage containing the configuration item list.
     */
    @AuraEnabled
    public static ResultMessage configuationItemList() {
       return ConfigurationService.configuationItemList();
     }
    /**
     * @description Retrieves the reporter name based on the service.
     * @param service The service name ('Jira' or 'ServiceNow').
     * @return ResultMessage containing the reporter name.
     */
    @AuraEnabled
    public static ResultMessage getReporter(String service) {
        return ConfigurationService.getReporter(service);
    }    
   
}