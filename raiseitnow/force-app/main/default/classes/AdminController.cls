/**
* @description       : AdminController Class is used to integrate with the services.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   :  
**/
/**
 * @description Acts as the top-level Apex controller to route service template and connection requests.
 *              Also provides utility methods, such as retrieving the currently logged-in user's name.
 */
public with sharing class AdminController {

    /**
     * @description Retrieves available RaiseItNow connections from Named Credentials.
     * @return A ResultMessage object containing NamedCredential records and connection names.
     */
    @AuraEnabled 
    public static ResultMessage getRaiseItNowConnections() {
        return ConnectionHandler.getRaiseItNowConnections();    
    }

    /**
     * @description Verifies the connection status of a specified RaiseItNow service.
     * @param serviceName The name of the service (e.g., Jira, ServiceNow, Azure).
     * @return A ResultMessage indicating whether the service connection is active.
     */
    @AuraEnabled 
    public static ResultMessage getRaiseItNowConnectionStatus(String serviceName) {
        return ConnectionHandler.getRaiseItNowConnectionStatus(serviceName);
    }

    /**
     * @description Deletes a service template record by its ID after checking access permissions.
     * @param templateId The Id of the Service_Template__c record to delete.
     * @return A ResultMessage indicating the success or failure of the deletion.
     */
    @AuraEnabled 
    public static ResultMessage deleteTemplate(Id templateId) {
        return ServiceTemplateHandler.deleteTemplate(templateId);
    }

    /**
     * @description Saves or updates a service template based on the provided JSON input.
     * @param jsonString A JSON string containing the template data.
     * @return A ResultMessage indicating whether the template was saved successfully.
     */
    @AuraEnabled 
    public static ResultMessage saveTemplateData(String jsonString) {
        return ServiceTemplateHandler.saveTemplateData(jsonString);
    }

    /**
     * @description Custom exception used for controlled errors in admin operations.
     */
    public class CustomException extends Exception {}

  
    /**
     * @description Returns the username of the currently logged-in user.
     *
     * @return {String} The username of the running user as defined in the User record.
     *
     */
     @AuraEnabled(cacheable=true)
     public static String getCurrentUserName() {
            return UserInfo.getUserName();
     }



}