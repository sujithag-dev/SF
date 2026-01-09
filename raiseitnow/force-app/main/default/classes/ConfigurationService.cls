/**
* @description       : ConfigurationService Class is used to provides configuration data related to CI (Configuration Item) and user-level integration
*                      with external platforms like ServiceNow & Retrieves the reporter name based on the service.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description
 * Provides configuration data related to CI (Configuration Item) and user-level integration
 * with external platforms like ServiceNow & Retrieves the reporter name based on the service.
 */
public with sharing class ConfigurationService  {
    /**
     * @description Retrieves the list of configuration items.
     * @return ResultMessage containing the configuration item list.
     */
    @AuraEnabled
    public static ResultMessage configuationItemList() {
        String jsonResult;
        String setEndpoint;
        Map<String, String> configUsers = new Map<String, String>();        
        ResultMessage result = new ResultMessage(true, 'Get Configuration Item List'); 
        try {
               setEndpoint =  Constant.SERVICE_NOW_LEGACY + '/api/now/table/cmdb_ci?sysparm_fields=name,sys_id'; 
               HttpResponse response = ApiUtility.sendGetRequest(setEndpoint);
               jsonResult = response.getBody();  
               if(response.getStatusCode() == 200) {                        
                     WrapperContainer.ServiceNowLookupWrapper responseWrapper = (WrapperContainer.ServiceNowLookupWrapper) JSON.deserialize(jsonResult, WrapperContainer.ServiceNowLookupWrapper.class); 
                    if (responseWrapper != null && responseWrapper.result != null) {
                           for(WrapperContainer.ResultItem item : responseWrapper.result) {
                                   configUsers.put( item.sys_id,item.name);
                               }           
                           result.payloadMap.put('configItemList', configUsers);
                        } else {
                           result = new ResultMessage(false, 'Failed to fetch Configuration Item List. Response body is null or does not contain a result list.');
                         }
                  } else {
                       result = new ResultMessage(false, 'Failed to fetch Configuration Item List. Status code: ' + response.getStatusCode());
                   }
           } catch(Exception e) {
                  result.success = false;
                  result.message = e.getMessage();
              }
          return result;
     }
	/**
     * @description Retrieves the reporter name based on the service.
     * @param service The service name ('Jira' or 'ServiceNow').
     * @return ResultMessage containing the reporter name.
     */
    @AuraEnabled
    public static ResultMessage getReporter(String service) {
        ResultMessage result = new ResultMessage(true, 'Get Reporter Name');
        Map<String, String> reporterName = new Map<String, String>(); 
        try {
            String setEndpoint;
            if (service == 'Jira') {
                setEndpoint = Constant.JIRA_LEGACY + Constant.JIRA_MYSELF_ENDPOINT;
            } else if (service == 'ServiceNow') {
                setEndpoint = Constant.SERVICE_NOW_LEGACY + Constant.SERVICENOW_USER_INFO_ENDPOINT;
            } else {
                result.success = false;
                result.payloadMap.put('message', 'Invalid service.');
                return result;
            }
            HttpResponse response = ApiUtility.sendGetRequest(setEndpoint);
            String dataMap = response.getBody();
            Map<String,Object> dataMap2 = (Map<String,Object>) JSON.deserializeUntyped(dataMap);
            if (service == 'Jira') {
                String reporter = String.valueOf(dataMap2.get('displayName'));
                String reporterId = String.valueOf(dataMap2.get('accountId'));
                reporterName.put(reporterId,reporter);
                result.payloadMap.put('reporterName', reporterName);

            } else if (service == 'ServiceNow') {
                List<Object> dataList = (List<Object>) dataMap2.get('result');
                String nowName = '';
                String sysId = '';
                for(object obj:datalist){
                    Map<String,Object> dataMap3 =new Map<String,Object>();
                    dataMap3 =(Map<String,Object>)obj;
                    nowname= (string)dataMap3.get('name');
                    sysId = (string)dataMap3.get('sys_id');
                }
                reporterName.put(sysId,nowname);
                result.payloadMap.put('reporterName', reporterName);
            }
        } catch(Exception e) {
            result.success = false;
            result.payloadMap.put('message', 'Error occurred: ' + e.getMessage());
        }
        return result;
    }
}