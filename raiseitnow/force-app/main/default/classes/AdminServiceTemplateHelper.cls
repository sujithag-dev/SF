/**
* @description       : AdminServiceTemplateHelper class for retrieving service template and project information 
* based on a given service name. Used for admin-related configuration logic.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
* @description AdminServiceTemplateHelper class for retrieving service template and project information 
 * based on a given service name. Used for admin-related configuration logic.
*
*/
public with sharing class AdminServiceTemplateHelper {

    /**
     * @description
     * Retrieves details of service templates based on the specified service name.
     *
     * @param serviceName The name of the service.
     * @return A ResultMessage object containing the templates data.
     */
     @AuraEnabled
    public static ResultMessage getTemplateDetails(String serviceName) {
         ResultMessage result = new ResultMessage(true, 'Get Service Templates');
         try {
              Map<String, String> projectMap = resolveProjects(serviceName);
              List<Service_Template__c> templates = getTemplate(serviceName);
              Map<String, Service_Template__c> templateMap = buildTemplateMap(templates);

              List<Object> templatesDataList = buildTemplateWrappers(projectMap, templateMap);

              result.payloadMap.put('templates', templatesDataList);
            } catch(Exception e) {
                result.success = false;
                result.message = 'Error: ' + e.getMessage();          
             }
        return result;
     }

    private static Map<String, String> resolveProjects(String serviceName) {
       return serviceName == 'ServiceNow' 
               ? new Map<String, String>{ 'Incident' => 'Incident' } 
               : getProjectNames(serviceName);
     }

   private static Map<String, Service_Template__c> buildTemplateMap(List<Service_Template__c> templates) {
         Map<String, Service_Template__c> serviceMap = new Map<String, Service_Template__c>();
        for(Service_Template__c temp : templates) {
              serviceMap.put(temp.Project_Name__c, temp);
         }

     return serviceMap;
  }

  private static List<Object> buildTemplateWrappers(Map<String, String> projectMap, Map<String, Service_Template__c> templateMap) {
      List<Object> wrappers = new List<Object>();
      Integer count = 0;

      for(String projectName : projectMap.keySet()) {
          WrapperContainer.TemplateWrapper wrapper = new WrapperContainer.TemplateWrapper();
          wrapper.projectName = projectName;
          wrapper.projectKey = projectMap.get(projectName);
          wrapper.hadTemplate = templateMap.containsKey(projectName);
          wrapper.uniqueId = String.valueOf(count++);

          if (wrapper.hadTemplate) {
            Service_Template__c template = templateMap.get(projectName);
            wrapper.lookUpId = String.valueOf(template.User_Lookup__c);
            wrapper.userName = String.valueOf(template.Username__c);
            wrapper.createdDate = String.valueOf(template.CreatedDate);
            wrapper.recordId = String.valueOf(template.Id);
            wrapper.fieldsJson = JSON.serialize(template.Project_Fields__c);
          } else {
            wrapper.createdDate = ' - ';
            wrapper.fieldsJson = ' - ';
          }
        wrappers.add(wrapper);
       }
    return wrappers;
  }

    /**
     * @description
     * Retrieves project names and their corresponding IDs based on the specified service.
     *
     * @param serviceName The name of the service.
     * @return A map containing project names as keys and their IDs as values.
     */
     @AuraEnabled
    public static Map<String, String> getProjectNames(String serviceName) {
      try {
            String endpoint = getServiceEndpoint(serviceName);
            HttpResponse response = ApiUtility.sendGetRequest(endpoint);

           if (response.getStatusCode() != 200) {
               throw new CustomException('HTTP request failed with status code: ' + response.getStatusCode());
            }

         return parseProjects(serviceName, response.getBody());
         } catch (Exception e) {
               throw new CustomException('Error occurred: ' + e.getMessage());
          }
     }

   private static String getServiceEndpoint(String serviceName) {
         Map<String, String> serviceEndpoints = new Map<String, String>{
                            Constant.JIRA_SERVICE  => Constant.JIRA_LEGACY + Constant.JIRA_PROJECT_API_ENDPOINT + '/search',
                            Constant.AZURE_SERVICE => Constant.AZURE_LEGACY + Constant.AZURE_PROJECTS_ENDPOINT
                    };

       if (!serviceEndpoints.containsKey(serviceName)) {
               throw new IllegalArgumentException('Invalid service name: ' + serviceName);
        }

       return serviceEndpoints.get(serviceName);
    }
   @TestVisible
   private static Map<String, String> parseProjects(String serviceName, String responseBody) {
        if (Constant.JIRA_SERVICE.equals(serviceName)) {
             return ProjectParser.parseJiraProjects(responseBody);
         } else if (Constant.AZURE_SERVICE.equals(serviceName)) {
            return ProjectParser.parseAzureProjects(responseBody);
       } else {
           throw new CustomException('Unsupported service: ' + serviceName);
       }
     }
     /**
    * @description Retrieves a list of service templates based on the specified service name.
    * @param servName The name of the service.
    * @return A list of Service_Template__c records.
    */
    @AuraEnabled
    public static List<Service_Template__c> getTemplate(String servName) {
        validateServiceName(servName);
        checkObjectAccess();
        return fetchTemplates(servName);
      }

   private static void validateServiceName(String servName) {
        if (String.isBlank(servName)) {
            throw new AuraHandledException('servName parameter cannot be null or blank.');
        }
   }

   private static void checkObjectAccess() {
       if (!Service_Template__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
              throw new AuraHandledException('Service_Template__c object is not accessible.');
        }
    }

/**
 * @description Fetches Service_Template__c records for a given service name.
 *              Uses inline SOQL with bind variable to prevent SOQL injection.
 * @param servName The name of the service to query.
 * @return List of Service_Template__c records matching the service name.
 */
  @TestVisible
private static List<Service_Template__c> fetchTemplates(String servName) {
    if (String.isBlank(servName)) {
        throw new CustomException('Please provide a valid service name.');
    }
    try {
        return [
            SELECT Id, Name, CreatedDate, Username__c, Project_Fields__c,
                   Project_Keys__c, Project_Name__c, Service_Name__c, User_Lookup__c
            FROM Service_Template__c
            WHERE Service_Name__c = :servName
            WITH USER_MODE
        ];
    } catch (Exception e) {
        throw new AuraHandledException('Error occurred while querying: ' + e.getMessage());
    }
}

   

}