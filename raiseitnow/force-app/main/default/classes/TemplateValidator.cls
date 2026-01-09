/**
* @description       : TemplateValidator Class is used to provides validation and DML logic for Service_Template__c objects.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Provides validation and DML logic for Service_Template__c objects.
 */
public with sharing class TemplateValidator {
	/**
     * @description Validates field-level and object-level access, then performs upsert on the service template.
     * @param template The Service_Template__c record to validate and save.
     */
    public static void validateAndUpsertTemplate(Service_Template__c template) {
        validateFieldLevelAccess(template);
        validateObjectAccessAndUpsert(template);
    }

	 /**
     * @description Validates that the user has appropriate field-level access for required fields.
     * @param template The Service_Template__c object whose fields need validation.
     * @throws AdminController.CustomException If access is denied to any critical field.
     */

    private static void validateFieldLevelAccess(Service_Template__c template) {
        Schema.SObjectType objType = Service_Template__c.SObjectType;
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        Set<String> fieldNames = new Set<String>{
            'Service_Name__c', 'Project_Fields__c', 'Project_Name__c',
            'Project_Keys__c', 'User_Lookup__c', 'Username__c'
        };

        Boolean isCreate = (template.Id == null);
        for (String fieldName : fieldNames) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            if (field == null) { continue;}

            Schema.DescribeFieldResult describe = field.getDescribe();
            if ((isCreate && !describe.isCreateable()) || (!isCreate && !describe.isUpdateable())) {
                throw new AdminController.CustomException('No permission to ' + (isCreate ? 'create' : 'update') + ' field: ' + fieldName);
            }
        }
    }
    

    /**
     * @description Performs an upsert on the record after verifying object-level access.
     * @param template The record to be inserted or updated.
     * @throws AdminController.CustomException If user lacks object-level access.
     */

   private static void validateObjectAccessAndUpsert(Service_Template__c template) {

      Boolean isCreate = determineOperationType(template);
 
      Schema.DescribeSObjectResult describe = Service_Template__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);

      if ((isCreate && describe.isCreateable()) || (!isCreate && describe.isUpdateable())) {

          List<SObject> filteredList = Security.stripInaccessible( isCreate ? AccessType.CREATABLE : AccessType.UPDATABLE, new List<SObject>{ template } ).getRecords();
          template = (Service_Template__c) filteredList[0];
          upsert as USER template;
       } else {
           throw new AdminController.CustomException('No permission to ' + (isCreate ? 'create' : 'update') + ' Service_Template__c');
      }
   }

private static Boolean determineOperationType(Service_Template__c template) {
    Boolean isCreate = (template.Id == null);
    
    if (isCreate && template.Project_Name__c != null) {
        Service_Template__c existingTemplate = findExistingTemplate(template.Project_Name__c);
        if (existingTemplate != null) {
            template.Id = existingTemplate.Id;
            isCreate = false; 
        }
    }
    
    return isCreate;
}

private static Service_Template__c findExistingTemplate(String projectName) {
    List<Service_Template__c> existingList = [
        SELECT Id
        FROM Service_Template__c
        WHERE Project_Name__c = :projectName WITH USER_MODE
        LIMIT 1
    ];
    
    return existingList.isEmpty() ? null : existingList[0];
}

}