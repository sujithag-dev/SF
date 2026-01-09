/**
* @description       : TicketCreationService Class is used to encapsulates the logic for creating tickets in various systems such as
*                      Jira, Azure, and ServiceNow. Dynamically dispatches to the appropriate
*                      creation logic based on the service name.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
* @description
* Encapsulates the logic for creating tickets in various systems such as
* Jira, Azure, and ServiceNow. Dynamically dispatches to the appropriate
* creation logic based on the service name.
*/
public with sharing class TicketCreationService  {
/**
* @description Creates a Jira ticket.
* @param ticketInputs The input data for creating the Jira ticket.
* @return ResultMessage indicating the success of the operation and containing the response from Jira.
*/
    public static ResultMessage createJiraTicket(String ticketInputs) {
        ResultMessage result = new ResultMessage(true, 'Create Jira Ticket'); 
        try {
            WrapperContainer.InputWrapper jiraInput = (WrapperContainer.InputWrapper) JSON.deserialize(ticketInputs, WrapperContainer.InputWrapper.class);
            String requestBody = buildJiraRequestBody(jiraInput);
            HttpResponse response = ApiUtility.httpPostRequest( Constant.JIRA_LEGACY + Constant.JIRA_ISSUE_ENDPOINT, requestBody, Constant.CONTENT_TYPE_JSON_UTF8 );
            if (response.getStatusCode() == 201) {
                handleSuccessfulJiraCreation(response.getBody(), jiraInput, result);
            } 
            else {
                result.success = false;
                result.message = 'Jira Ticket Creation Failed: ' + response.getStatusCode() + ' :: ' + response.getBody();
            }
        } catch (Exception e) {
            result.success = false;
            result.message = e.getMessage();
        }
        return result;
    }
    
    
    private static String buildJiraRequestBody(WrapperContainer.InputWrapper input) {
        Map<String, Object> fields = new Map<String, Object>{'project' => new Map<String, Object>{ 'key' => input.projectKey }};
            for (String key : input.valuesMap.keySet()) {
                Object value = input.valuesMap.get(key);
                if (key == 'summary' || key == 'description') {
                    fields.put(key, value);
                } else if (key == 'reporter' || key == 'assignee') {
                    fields.put(key, new Map<String, Object>{ 'id' => value });
                } else {
                    fields.put(key, new Map<String, Object>{ 'name' => value });
                }
            }
        Map<String, Object> body = new Map<String, Object>{ 'fields' => fields };
            return JSON.serialize(body);
    }
    
    
    private static void handleSuccessfulJiraCreation(String responseBody, WrapperContainer.InputWrapper input, ResultMessage result) {
        WrapperContainer.JiraTicketResponse ticket = (WrapperContainer.JiraTicketResponse) JSON.deserialize(responseBody, WrapperContainer.JiraTicketResponse.class);
        result.message = 'Jira Ticket Created Successfully';
        result.payloadMap.put('JiraTicketCreate', responseBody);
        
        handleAttachments(Constant.JIRA_SERVICE,new WrapperContainer.AttachmentContext(input.templateId, ticket.key, null),result);
        WrapperContainer.TicketRequest request = new WrapperContainer.TicketRequest();
        request.response = responseBody;
        request.templateId = input.templateId;
        request.bugType = 'Jira';
        request.projectName = input.projectName;
        request.description =input.valuesMap.get('description');
        request.priority =input.valuesMap.get('priority');
        request.issuetype=input.valuesMap.get('issuetype');
        request.summary=input.valuesMap.get('summary');
        request.assigneeName=input.assigneeName;
        request.validate();
        Id bugId = TicketRecordService.createTicketRecord(JSON.serialize(request));
        result.payloadMap.put('recordId', bugId);
    }
    
/**
* @description Creates a ServiceNow ticket.
* @param ticketInputs The input data for creating the ServiceNow ticket.
* @return ResultMessage indicating the success of the operation and containing the response from ServiceNow.
*/
    @AuraEnabled
    public static ResultMessage createServiceNowTicket(String ticketInputs) {
        ResultMessage result = new ResultMessage(true, 'Create ServiceNow Ticket');
        try {
            WrapperContainer.InputWrapper serviceNowInput = (WrapperContainer.InputWrapper) JSON.deserialize(ticketInputs, WrapperContainer.InputWrapper.class); 
            String body = buildServiceNowRequestBody(serviceNowInput);
            HttpResponse response = ApiUtility.httpPostRequest(Constant.SERVICE_NOW_LEGACY + Constant.SERVICENOW_INCIDENTS_ENDPOINT, body, Constant.CONTENT_TYPE_JSON_UTF8);
            String jsonData = response.getBody();
            if (response.getStatusCode() == 201) {
                result.message = 'ServiceNow Ticket Created Successfully';                            
                WrapperContainer.ServiceNowTicketResponse sNowResponse = (WrapperContainer.ServiceNowTicketResponse) System.JSON.deserialize(jsonData, WrapperContainer.ServiceNowTicketResponse.class);
                String sysId = sNowResponse.result.sys_id;
                handleAttachments(Constant.SERVICENOW_SERVICE,new WrapperContainer.AttachmentContext(serviceNowInput.templateId, sysId, null),result);
                result.payloadMap.put('ServiceNowTicketCreate', response.getBody());               
                WrapperContainer.TicketRequest request = new WrapperContainer.TicketRequest();
                request.response = response.getBody();
                request.templateId = serviceNowInput.templateId;
                request.bugType ='Service Now';
                request.projectName = serviceNowInput.projectName;
                request.impact=serviceNowInput.valuesMap.get('impact');
                request.urgency=serviceNowInput.valuesMap.get('urgency');
                request.shortDescription=serviceNowInput.valuesMap.get('short_description');
                request.description=serviceNowInput.valuesMap.get('description');
                request.assigneeName=serviceNowInput.assigneeName;
                request.validate();
                Id bugId = TicketRecordService.createTicketRecord(JSON.serialize(request));
                result.payloadMap.put('recordId', bugId);
            } else {
                result.success = false;
                result.message = 'ServiceNow Ticket Creation Failed. Error: ' + response.getBody();
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'An error occurred: ' + e.getMessage();
        }
        return result;
    }
    
    
    private static String buildServiceNowRequestBody(WrapperContainer.InputWrapper serviceNowInput) {
        String body = '{';
        for (String key : serviceNowInput.valuesMap.keySet()) {
            body += '"' + key + '":"' + serviceNowInput.valuesMap.get(key) + '",';
        }
        body += '"' + 'cmdb_ci' + '":"' + serviceNowInput.configItemId + '",';
        body = body.removeEnd(',');
        body += '}';
        return body;
    }
/**
* @description Creates an Azure ticket.
* @param ticketInputs The input data for creating the Azure ticket.
* @return ResultMessage indicating the success of the operation and containing the response from Azure.
*/
    @AuraEnabled
    public static ResultMessage createAzureTicket(String ticketInputs){
        ResultMessage result = new ResultMessage(true, 'Create Azure Ticket');
        try {
            WrapperContainer.InputWrapper azureInput = (WrapperContainer.InputWrapper) JSON.deserialize(ticketInputs, WrapperContainer.InputWrapper.class);
            String projKey = azureInput.projectKey;
            
            
            String body = buildAzureRequestBody(azureInput);   
            
            if(projKey.contains(' ')){
                projKey = projKey.replace(' ','%20');
            }
            String setEndpoint = Constant.AZURE_LEGACY +'/'+ projKey + Constant.AZURE_WORKITEMS_ENDPOINT;
            String setContentType = Constant.CONTENT_TYPE_JSON_PATCH;
            HttpResponse response = ApiUtility.httpPostRequest(setEndpoint, body, setContentType);
            
            if(response.getStatusCode() == 200) {
                result.message = 'Azure Ticket Created Successfully';            
                WrapperContainer.AzureTicketRespose azureResponse = (WrapperContainer.AzureTicketRespose) JSON.deserialize(response.getBody(), WrapperContainer.AzureTicketRespose.class);
                String ids = String.valueOf(azureResponse.id);   
                handleAttachments(Constant.AZURE_SERVICE,new WrapperContainer.AttachmentContext(azureInput.templateId, ids, projKey),result);
                result.payloadMap.put('AzureTicketCreate', response.getBody());
                WrapperContainer.TicketRequest request = new WrapperContainer.TicketRequest();
                request.response = response.getBody();
                request.templateId = azureInput.templateId;
                request.bugType = 'Azure';
                request.projectName = azureInput.projectName;
                request.assigneeName=azureInput.assigneeName;
                request.description=azureInput.valuesMap.get('description');
                request.title=azureInput.valuesMap.get('System.Title');
                request.state=azureInput.valuesMap.get('System.State');
                request.priority=azureInput.valuesMap.get('Priority');
                request.validate();               
                Id bugId = TicketRecordService.createTicketRecord(JSON.serialize(request));
                result.payloadMap.put('recordId', bugId);
            } else {
                result.success = false;
                result.message = 'Azure Ticker Creation Failed due to this error :: ' + response.getBody();
            }               
        } catch (Exception e) {
            result.success = false;
            result.message = 'An error occurred: ' + e.getMessage();
        } 
        return result;
    }
    
    private static String buildAzureRequestBody(WrapperContainer.InputWrapper azureInput) {
        String body = '[';
        for(String key : azureInput.valuesMap.keySet()) { 
            body += '{"op":"add","path":"/fields/'+Key+'","from":null,"value":"'+azureInput.valuesMap.get(key)+'"},';
        }              
        body = body.removeEnd(',');
        body +=']';
        
        return body;
        
    }
       
    private static void handleAttachments(String systemName,WrapperContainer.AttachmentContext ctx,ResultMessage result) {
        ResultMessage attachmentResult = AttachmentManager.getUploadedAttachments(ctx.templateId);
        
        if (attachmentResult.success && 
            attachmentResult.payloadMap != null && 
            attachmentResult.payloadMap.containsKey('jiraAttachments')) {
                
                Integer count = 0;
                for (WrapperContainer.JiraAttachment attachment : 
                     (List<WrapperContainer.JiraAttachment>) attachmentResult.payloadMap.get('jiraAttachments')) {
                         
                         ResultMessage uploadResult;
                         if (systemName == Constant.JIRA_SERVICE) {
                             uploadResult = TicketAttachmentService.uploadAttachmentJira(ctx.recordKey, new List<WrapperContainer.JiraAttachment>{attachment});
                         } else if (systemName == Constant.SERVICENOW_SERVICE) {
                             uploadResult = TicketAttachmentService.uploadAttachmentServiceNow(ctx.recordKey, new List<WrapperContainer.JiraAttachment>{attachment});
                         } else if (systemName == Constant.AZURE_SERVICE) {
                             uploadResult = TicketAttachmentService.uploadAttachmentAzure(ctx.recordKey, new List<WrapperContainer.JiraAttachment>{attachment}, ctx.projectKey);
                         } else {
                             result.success = false;
                             result.message = 'Invalid system name';
                         }
                         result.payloadMap.put('uploadAttachmentResult' + count++, uploadResult);
                     }
            }
    }
    
}