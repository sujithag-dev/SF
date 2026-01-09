/**
* @description       : ServiceTemplateHandler Class is used to handles CRUD operations for Service_Template__c objects.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Handles CRUD operations for Service_Template__c objects.
 */
public with sharing class ServiceTemplateHandler {
	 /**
     * @description Deletes a Service_Template__c record if the user has delete access.
     * @param templateId The Id of the Service_Template__c record to delete.
     * @return A ResultMessage indicating whether the deletion was successful.
     */
    @AuraEnabled
    public static ResultMessage deleteTemplate(Id templateId) {
        ResultMessage result = new ResultMessage(true, 'Delete Template');
        try {
            if (!Service_Template__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
                throw new AdminController.CustomException('You do not have permission to delete Service_Template__c');
            }
            delete new Service_Template__c(Id = templateId);
            result.payloadMap.put('message', 'Service Template deleted successfully');
        } catch (Exception e) {
            result.success = false;
            result.payloadMap.put('message', 'Unexpected error occurred while deleting Service Template.');
        }
        return result;
    }


 /**
 * @description Deletes service templates by name.
 *
 * @param templateName The name of the template to delete.
 * @return A ResultMessage indicating whether the deletion was successful.
 */   
@AuraEnabled
public static ResultMessage deleteTemplates(String templateName) {
    ResultMessage result = new ResultMessage(true, 'Delete Template');
    try {
        if (!Service_Template__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
            throw new AdminController.CustomException(
                'You do not have permission to delete Service_Template__c'
            );
        }

        List<Service_Template__c> templateRecords = [
            SELECT Id, Project_Name__c, Service_Name__c
            FROM Service_Template__c
            WHERE Service_Name__c = :templateName
        ];

        if (!templateRecords.isEmpty()) {
            delete templateRecords;

            result.payloadMap.put(
                'message',
                templateRecords.size() + 
                ' Service Template(s) deleted successfully for Service "' + templateName + '"'
            );
        } else {
            result.success = false;
            result.payloadMap.put(
                'message',
                'No Service Templates found for Service "' + templateName + '"'
            );
        }

    } catch (Exception e) {
        result.success = false;
        result.payloadMap.put(
            'message',
            'Unexpected error occurred while deleting Service Templates: ' + e.getMessage()
        );
    }
    return result;
}


	 /**
     * @description Saves or updates a Service_Template__c record using data from a JSON string.
     * @param jsonString A serialized TemplateWrapper object with service template data.
     * @return A ResultMessage indicating the success or failure of the save operation.
     */
    @AuraEnabled
    public static ResultMessage saveTemplateData(String jsonString) {
        ResultMessage result = new ResultMessage(true, 'Save Template');
        try {
            WrapperContainer.TemplateWrapper template = (WrapperContainer.TemplateWrapper)
                JSON.deserialize(jsonString, WrapperContainer.TemplateWrapper.class);

            Service_Template__c servTemp = new Service_Template__c();

            FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Service_Name__c', template.servName);
            FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Project_Fields__c', template.fieldsJson);
            FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Project_Name__c', template.projectName);
            FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Project_Keys__c', template.projectKey);
            FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'User_Lookup__c', template.lookUpId);
            FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Username__c', template.userName);

            if (template.recordId != null && Schema.SObjectType.Service_Template__c.fields.Id.isAccessible()) {
                servTemp.Id = template.recordId;
            }

            TemplateValidator.validateAndUpsertTemplate(servTemp);
            result.payloadMap.put('message', 'Service Template Saved successfully');
        } catch (Exception e) {
            result.success = false;
            result.payloadMap.put('message', 'Unexpected error occurred while saving Service Template.');
            result.payloadMap.put('status', e.getMessage());
        }
        return result;
    }

/**
 * @description Saves multiple service templates from a list of JSON strings.
 *
 * @param jsonRecordsList List of JSON strings representing service templates.
 * @return ResultMessage Contains success status and messages for processed records.
 */
@AuraEnabled
public static ResultMessage saveMultipleTemplateDataSimple(List<String> jsonRecordsList) {
    ResultMessage result = new ResultMessage(true, 'Save Multiple Templates');
    
    try {
        Integer successCount = 0;
        List<String> errorMessages = new List<String>();
        
        for (String jsonString : jsonRecordsList) {
            try {
                WrapperContainer.TemplateWrapper template = (WrapperContainer.TemplateWrapper)
                    JSON.deserialize(jsonString, WrapperContainer.TemplateWrapper.class);

                Service_Template__c servTemp = new Service_Template__c();
                
                FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Service_Name__c', template.servName);
                FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Project_Fields__c', template.fieldsJson);
                FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Project_Name__c', template.projectName);
                FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Project_Keys__c', template.projectKey);
                FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'User_Lookup__c', template.lookUpId);
                FieldAccessUtil.setIfCreateableAndUpdateable(servTemp, 'Username__c', template.userName);

                if (template.recordId != null && Schema.SObjectType.Service_Template__c.fields.Id.isAccessible()) {
                    servTemp.Id = template.recordId;
                }

                TemplateValidator.validateAndUpsertTemplate(servTemp);
                successCount++;
                
            } catch (Exception individualError) {
                String projectInfo = '';
                try {
                    WrapperContainer.TemplateWrapper tempTemplate = (WrapperContainer.TemplateWrapper)
                        JSON.deserialize(jsonString, WrapperContainer.TemplateWrapper.class);
                    projectInfo = ' for project: ' + tempTemplate.projectName;
                } catch (Exception parseError) {
                    projectInfo = ' (unable to parse project info)';
                }
                
                errorMessages.add('Error saving template' + projectInfo + ': ' + individualError.getMessage());
            }
        }
        
        if (successCount > 0) {
            result.payloadMap.putAll(buildSuccessPayload(successCount, errorMessages));
        } else {
            result.success = false;
            result.payloadMap.put('message', 'No templates were saved successfully');
            result.payloadMap.put('errors', errorMessages);
        }
        
    } catch (Exception e) {
        result.success = false;
        result.payloadMap.put('message', 'Unexpected error occurred while saving multiple Service Templates');
        result.payloadMap.put('status', e.getMessage());
    }
    
    return result;
}

    /**
     * @description Builds a payload map summarizing the result of saving Service Template records.
     *
     * @param successCount The number of templates saved successfully (Integer).
     * @param errorMessages List<String> of error messages for partial failures (use an empty list if none).
     * @return Map<String, Object> Map containing 'message' (String), 'successCount' (Integer), and
     *                              optionally 'partialErrors' (List<String>).
     */
    private static Map<String, Object> buildSuccessPayload(Integer successCount, List<String> errorMessages) {
        Map<String, Object> payload = new Map<String, Object>();

        String message;
        if (successCount == 1) {
            message = 'Service Template Saved successfully';
        } else {
            message = String.valueOf(successCount) + ' Service Templates saved successfully';
        }

        if (!errorMessages.isEmpty()) {
            message += ' with ' + String.valueOf(errorMessages.size()) + ' errors';
            payload.put('partialErrors', errorMessages);
        }

        payload.put('message', message);
        payload.put('successCount', successCount);

        return payload;
    }


}