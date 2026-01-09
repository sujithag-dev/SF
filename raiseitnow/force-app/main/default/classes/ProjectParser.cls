/**
* @description       : ProjectParser Class is used to parse Jira and Azure DevOps projects.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Utility class to parse Jira and Azure DevOps projects.
 */

public with sharing class ProjectParser  {


	 /**
     * @description Parses Jira project response JSON into a map of <ProjectName, ProjectKey>.
     * @param responseBody JSON string returned from Jira API.
     * @return Map of project name to project key.
     */
	public static Map<String, String> parseJiraProjects(String responseBody) {
    Map<String, String> mapProj = new Map<String, String>();

    try {
        List<WrapperContainer.Project> projects = extractProjects(responseBody);

        for (WrapperContainer.Project proj : projects) {
            if (projectHasBugIssueType(proj.key)) {
                mapProj.put(proj.name, proj.key);
            }
        }
    } catch (Exception e) {
        throw new CustomException('Error parsing Jira projects:: ' + e.getMessage());
    }

    return mapProj;
}
private static List<WrapperContainer.Project> extractProjects(String responseBody) {
    Map<String, Object> responseMap =
        (Map<String, Object>) JSON.deserializeUntyped(responseBody);

    List<Object> values = (List<Object>) responseMap.get('values');
    if (values == null) {
        return new List<WrapperContainer.Project>();
    }

    String valuesJson = JSON.serialize(values);
    return (List<WrapperContainer.Project>)
        JSON.deserialize(valuesJson, List<WrapperContainer.Project>.class);
}
private static Boolean projectHasBugIssueType(String projectKey) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:RIT_Jira/rest/api/3/project/' + projectKey + '/statuses');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(60000);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            return false;
        }

        List<Object> issueTypeStatuses =
            (List<Object>) JSON.deserializeUntyped(res.getBody());

        for (Object issueTypeStatusObj : issueTypeStatuses) {
            Map<String, Object> issueTypeStatus =
                (Map<String, Object>) issueTypeStatusObj;
            String issueTypeName = (String) issueTypeStatus.get('name');

            if ('Bug'.equalsIgnoreCase(issueTypeName)) {
                return true; 
            }
        }
    } catch (Exception e) {
        throw new CustomException('Error checking Bug issue type for project :' + e.getMessage());
    }

    return false;
}


/**
 * @description Parses Azure DevOps project response JSON into a map of <ProjectName, ProjectId>.
 * @param responseBody JSON string returned from Azure DevOps API (contains "value" array of projects).
 * @return Map where the key is the project name and the value is the project id.
 */
  public static Map<String, String> parseAzureProjects(String responseBody) {
       Map<String, String> mapProj = new Map<String, String>();
       Map<String, Object> azureDataList = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
       List<Object> resValue = (List<Object>) azureDataList.get('value');

       for (Object obj : resValue) {
           Map<String, Object> mapResult = (Map<String, Object>) obj;
           String projectName = (String) mapResult.get('name');
           String projectId = (String) mapResult.get('id');
           mapProj.put(projectName, projectId);
        }
       return mapProj;
   }

	
}