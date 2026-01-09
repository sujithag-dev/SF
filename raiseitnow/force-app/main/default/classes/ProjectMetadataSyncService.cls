/**
* @description       : ProjectMetadataSyncService Class is used to synchronize Project_Source_Mapping__mdt custom metadata records
*                      for various source systems (e.g., Jira, Azure, ServiceNow). 
*                      Implements the Metadata.DeployCallback interface to handle deployment results.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Synchronize Project_Source_Mapping__mdt custom metadata records
 *              for various source systems (e.g., Jira, Azure, ServiceNow). 
 *              Implements the Metadata.DeployCallback interface to handle deployment results.
 */
public with sharing class ProjectMetadataSyncService implements Metadata.DeployCallback {
/**
 * @description Synchronizes the Project_Source_Mapping__mdt custom metadata records
 *              for a given service with the provided list of project keys.
 *              If a record exists, it updates it; otherwise, it creates a new record.
 * @param serviceName The name of the source system/service for which metadata needs to be synced.
 * @param projectKeys The list of project keys to associate with the service.
 * @return ResultMessage Indicates success/failure and provides message details.
 */
@AuraEnabled
public static ResultMessage syncMetadataForService(String serviceName, List<String> projectKeys) {
    ResultMessage result = new ResultMessage(true, 'Metadata sync initiated successfully for service');
        
    try {

        if (String.isBlank(serviceName)) {
            throw new AuraHandledException('Service name is required');
          }
        if (projectKeys == null || projectKeys.isEmpty()) {
            throw new AuraHandledException('At least one project key must be selected');
        }

        List<Project_Source_Mapping__mdt> existingRecords = [
            SELECT DeveloperName, Project_Names__c, Source_System__c
            FROM Project_Source_Mapping__mdt
            WHERE Source_System__c = :serviceName WITH USER_MODE
            LIMIT 1
        ];

        String developerName = existingRecords.isEmpty()
            ? serviceName.replaceAll('[^A-Za-z0-9_]', '_')
            : existingRecords[0].DeveloperName;

        String updatedCSV = String.join(projectKeys, ',');
        
        Metadata.CustomMetadata md = new Metadata.CustomMetadata();
        md.fullName = 'Project_Source_Mapping.' + developerName;
        md.label = developerName;

        Metadata.CustomMetadataValue field1 = new Metadata.CustomMetadataValue();
        field1.field = 'Source_System__c';
        field1.value = serviceName;

        Metadata.CustomMetadataValue field2 = new Metadata.CustomMetadataValue();
        field2.field = 'Project_Names__c'; 
        field2.value = updatedCSV;

        md.values.add(field1);
        md.values.add(field2);

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(md);

        Metadata.Operations.enqueueDeployment(container, new ProjectMetadataSyncService());
            
     } catch (Exception e) {
            result.success = false;
            result.message = 'Error syncing metadata for service "' + serviceName + '": ' + e.getMessage();
            
        }

        return result;

}

/**
 * @description Fetches the list of projects associated with a given service name 
 *              from the Project_Source_Mapping__mdt custom metadata type.
 *              This method is cacheable and can be called from Lightning components.
 * @param serviceName The source system name to look up in CMDT.
 * @return List<String> List of project names. Returns empty list if no mapping is found.
 */
@AuraEnabled(cacheable=true)
    public static List<String> getProjectsForService(String serviceName) {
        List<Project_Source_Mapping__mdt> records = [
            SELECT Project_Names__c
            FROM Project_Source_Mapping__mdt
            WHERE Source_System__c = :serviceName WITH USER_MODE
            LIMIT 1 
        ];
        if (!records.isEmpty() && !String.isBlank(records[0].Project_Names__c)) {
            return records[0].Project_Names__c.split(',');
        }
        return new List<String>();
    }

/**
 * @description Callback invoked after a Metadata deployment.
 *              Updates a ResultMessage with success or failure status
 * @param result The deployment result object
 * @param context The deployment context.
 */
 public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        ResultMessage results = new ResultMessage(false, '');
        if (result.status == Metadata.DeployStatus.Succeeded) {
            results.success = true;
            results.message = 'Metadata deployed successfully for service';
            
        } else {
            results.success = false;
            results.message = 'Metadata deployment failed for service: ' + result.errorMessage;
        }
    }
}