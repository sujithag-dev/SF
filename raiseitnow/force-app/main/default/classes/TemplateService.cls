/**
* @description       : TemplateService Class is used to provides service template-related operations for retrieving ticket templates.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description  Provides service template-related operations for retrieving ticket templates.
 * 
 */
public with sharing class TemplateService  {
	
    /**
     * @description Test-visible variable used for mocking connection results in test contexts.
     */
    @TestVisible
    static ResultMessage testConnectionResult;
    
    /**
      * @description Retrieves details of templates.
      * @return ResultMessage indicating the success of the operation and containing template details. 
     */
    @AuraEnabled
    public static ResultMessage getTemplateDetails() {
        ResultMessage result = new ResultMessage(true, 'Get Template Details');
        ResultMessage connectionResult;
        if (Test.isRunningTest() && testConnectionResult != null) {
            connectionResult = testConnectionResult;
        } else {
            connectionResult = AdminController.getRaiseItNowConnections();
        }
        
        if(connectionResult != null && connectionResult.payloadMap != null && connectionResult.payloadMap.containsKey('connectionNames')) {
            List<String> connections = (List<String>)connectionResult.payloadMap.get('connectionNames');
            try {
                List<Service_Template__c> templates = new List<Service_Template__C>();
                List<WrapperContainer.TemplateWrapper> templateWrappers = new List<WrapperContainer.TemplateWrapper>();
                if(Service_Template__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()){
                    templates = (List<Service_Template__c>) Database.query('SELECT Id,Username__c,Name,CreatedDate,User_Lookup__c, Project_Fields__c, Project_Keys__c, Project_Name__c, Service_Name__c FROM Service_Template__c WHERE Service_Name__c =: connections WITH USER_MODE');

                    for(Service_Template__c template : templates) {
                        WrapperContainer.TemplateWrapper templateWrapper = new WrapperContainer.TemplateWrapper();
                        templateWrapper.recordId = template.Id;
                        templateWrapper.projectName = template.Project_Name__c;
                        templateWrapper.projectKey = template.Project_Keys__c;
                        templateWrapper.servName = template.Service_Name__c;
                        templateWrapper.createdDate = '' + template.CreatedDate;
                        templateWrapper.fieldsJson = template.Project_Fields__c;
                        templateWrapper.lookUpId = template.User_Lookup__c;
                        templateWrapper.userName = template.Username__c;
                        templateWrappers.add(templateWrapper);
                    }
                    result.payloadMap.put('templates', templateWrappers);
                }else{
                    result.success = false;
                    result.message = 'Error During Get Template Details';
                }
            } catch (Exception e) {
                result.success = false;
                result.message = e.getMessage();
            }
        } else {
            result.payloadMap.put('templates', new List<Service_Template__C>());
        }
        return result;
    }

}