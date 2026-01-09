/**
* @description       : TicketAttachmentService Class is used to unified attachment service for Jira, Azure DevOps, and ServiceNow systems.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Unified attachment service for Jira, Azure DevOps, and ServiceNow systems.
 */
public class TicketAttachmentService {
	 /**
     * @description Upload Attach Document for Jira Ticket.
     * @param issueIdOrKey The ID or key of the Jira ticket.
     * @param attachments A list of attachments to be uploaded.
     * @return ResultMessage indicating the success of the operation and containing the response from Jira.
     */
    @AuraEnabled
    public static ResultMessage uploadAttachmentJira(String issueIdOrKey, List<WrapperContainer.JiraAttachment> attachments){
        ResultMessage result = new ResultMessage(true, 'Attach Document for Jira Ticket');
        try {
        String boundary  = '----------------------------741e90d31eff';
        Blob bodyBlob = null;
        for (WrapperContainer.JiraAttachment attachment : attachments) { 
            String header;
            String footer;
            String headerEncoded;
            String bodyEncoded;
            String last4Bytes;
            String footerEncoded;

            header = '--' + boundary + '\n' +
                'Content-Disposition: form-data; name="file"; filename="' + attachment.fileName + '";\n' +
                'Content-Type: application/octet-stream';
            footer = '--' + boundary + '--';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
            while (headerEncoded.endsWith('='))
            {
                header += ' ';
                headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
            }
            bodyEncoded = attachment.fileContent; 
            bodyBlob = null;
            last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());

            if (last4Bytes.endsWith('==')) 
            {
                last4Bytes = last4Bytes.substring(0, 2) + '0K';
                bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;   
                footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);
            } else if (last4Bytes.endsWith('=')) 
            {
                last4Bytes = last4Bytes.substring(0, 3) + 'N';
                bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length()-4) + last4Bytes;
                footer = '\n' + footer;
                footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);              
            } else 
            {
                footer = '\r\n' + footer;
                footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);  
            }
            break;
        }
              
             WrapperContainer.AttachmentPostRequest attachPost = new WrapperContainer.AttachmentPostRequest();
             attachPost.setEndpoint = Constant.JIRA_LEGACY + Constant.JIRA_ISSUE_ENDPOINT + issueIdOrKey + Constant.ATTACHMENTS_PATH;
             attachPost.bodyBlob = bodyBlob;
             attachPost.serviceName = Constant.JIRA_SERVICE;
             attachPost.setContentType = 'multipart/form-data; boundary=' + boundary;

             HttpResponse response = ApiUtility.httpPostAttachment(attachPost);       
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                result.payloadMap.put('attachmentResponse' , response.getBody());
            } else {
                result.success = false;
                result.message = 'Jira Ticker Creation Failed due to this error :: ' + response.getStatusCode()+ ' :: ' + response.getBody();
                result.payloadMap.put('eror' , response.getBody());
            }           
         } catch (Exception e) {
             result.success = false;
             result.message = e.getMessage();
         }
        return result;
    }
	 /**
     * @description Uploads attachments to a ServiceNow ticket.
     * @param sysId The ID of the ServiceNow ticket.
     * @param attachments A list of attachments to be uploaded.
     * @return ResultMessage indicating the success of the operation.
     */
    @AuraEnabled
    public static ResultMessage uploadAttachmentServiceNow(String sysId, List<WrapperContainer.JiraAttachment> attachments){
        ResultMessage result = new ResultMessage(true, 'Attach Document for ServiceNow Ticket');
        try {
            String fileName;
            String contentType;
            String setContentType;
            String setEndpoint;
            String header,
            headerEncoded,
            bodyEncoded,
            last4Bytes;
            String serviceName = Constant.SERVICENOW_SERVICE;
            Blob bodyBlob = null;
            for (WrapperContainer.JiraAttachment attachment : attachments) {
                    fileName = attachment.fileName;
                    if(fileName.contains(' ')){ fileName=fileName.replace(' ','_'); }
                    else{ fileName=fileName; }
                    contentType = attachment.type;
                    bodyEncoded =attachment.fileContent;
                    Blob body =null;
                    body= EncodingUtil.base64Decode(attachment.fileContent);
                    headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
                    while (headerEncoded.endsWith('=')){
                            header += ' ';
                            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
                     }
                    bodyBlob = null;
                    last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
                    if (last4Bytes.endsWith('==')) {
                        last4Bytes = last4Bytes.substring(0, 2) + '0K';
                        bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes; 
                        bodyBlob = EncodingUtil.base64Decode( bodyEncoded);
                    } else if (last4Bytes.endsWith('=')) {
                        last4Bytes = last4Bytes.substring(0, 3) + 'N';
                        bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length()-4) + last4Bytes;
                        bodyBlob = EncodingUtil.base64Decode( bodyEncoded);            
                    } else {
                        bodyBlob = EncodingUtil.base64Decode( bodyEncoded);    
                    }
                    break;
                }
            setContentType = contentType;
            setEndpoint = Constant.SERVICE_NOW_LEGACY + Constant.SERVICENOW_ATTACHMENT_FILE_ENDPOINT + sysId + Constant.FILE_NAME_PARAM + fileName;   

             WrapperContainer.AttachmentPostRequest attachPost = new WrapperContainer.AttachmentPostRequest();
             attachPost.setEndpoint = setEndpoint;
             attachPost.bodyBlob = bodyBlob;
             attachPost.serviceName = serviceName;
             attachPost.setContentType = setContentType;
             HttpResponse response = ApiUtility.httpPostAttachment(attachPost);          
    
            processServiceResponse(result, response); 
          } catch (Exception e) {
               handleError(result, e);
          }
        return result;
     }    
   
     private static void processServiceResponse(ResultMessage result, HttpResponse response) {
         if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                result.success = true;
                result.message = 'Servicenow Attachments uploaded successfully' + response.getStatusCode()+ ' :: ' + response.getBody();
                result.payloadMap.put('uploaded' , response.getBody());
            } else {
                result.success = false;
                result.message = 'ServiceNow Ticket Creation Failed due to this error :: ' + response.getStatusCode()+ ' :: ' + response.getBody();
                result.payloadMap.put('eror' , response.getBody());
            }
      }
      
     private static void handleError(ResultMessage result, Exception e) {
         result.success = false;
         result.message = 'An error occurred: ' + e.getMessage();
      }
	/**
     * @description Uploads attachments to an Azure ticket.
     * @param issueIdOrKey The ID or key of the Azure ticket.
     * @param attachments A list of attachments to be uploaded.
     * @param projKey The project key of the Azure ticket.
     * @return ResultMessage indicating the success of the operation.
     */
    @AuraEnabled
    public static ResultMessage uploadAttachmentAzure(String issueIdOrKey, List<WrapperContainer.JiraAttachment> attachments,String projKey){
          ResultMessage result = new ResultMessage(true, 'Attach Document for Azure Ticket');
          String setEndpoint;
          String setContentType;
          String fileName;
          String bodyEncoded; 
          String last4Bytes;
          Blob bodyBlob = null;
          String serviceName = Constant.AZURE_SERVICE;
          try 
             { 
                for (WrapperContainer.JiraAttachment attachment : attachments) {
                      fileName = attachment.fileName;
                      if(fileName.contains(' ')) { fileName=fileName.replace(' ','_'); }  
                      bodyEncoded = attachment.fileContent;
                      Blob body =null;
                      body= EncodingUtil.base64Decode(attachment.fileContent);
                      bodyBlob = null;
                      last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
                      if (last4Bytes.endsWith('==')) {
                               last4Bytes = last4Bytes.substring(0, 2) + '0K';
                               bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;   
                               bodyBlob = EncodingUtil.base64Decode( bodyEncoded);
                          } else if (last4Bytes.endsWith('=')) {
                                      last4Bytes = last4Bytes.substring(0, 3) + 'N';
                                      bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length()-4) + last4Bytes;
                                      bodyBlob = EncodingUtil.base64Decode( bodyEncoded);            
                           } else {
                                    bodyBlob = EncodingUtil.base64Decode( bodyEncoded);                  
                             }
                       break;
                     }
                    setEndpoint = Constant.AZURE_LEGACY + '/' + projKey + Constant.AZURE_ATTACHMENTS_ENDPOINT + issueIdOrKey + Constant.FILE_NAME_PARAMETER + fileName + Constant.API_VERSION_PARAMETER;
                    setContentType = Constant.CONTENT_TYPE_OCTET_STREAM; 
                 
                    WrapperContainer.AttachmentPostRequest attachPost = new WrapperContainer.AttachmentPostRequest();
                    attachPost.setEndpoint = setEndpoint;
                    attachPost.bodyBlob = bodyBlob;
                    attachPost.serviceName = serviceName;
                    attachPost.setContentType = setContentType;
                    HttpResponse response = ApiUtility.httpPostAttachment(attachPost);
                  
                    WrapperContainer.AzureResponseProcessorRequest request = new WrapperContainer.AzureResponseProcessorRequest();
                    request.result = result;
                    request.response = response;
                    request.projKey = projKey;
                    request.issueIdOrKey = issueIdOrKey;
                    processAzureResponse(request);                 
              }catch(Exception e) {
                 handleError(result, e);
               }
           return result;
      }
   
    private static void processAzureResponse(WrapperContainer.AzureResponseProcessorRequest request) {
         request.validate();
         if(request.response.getStatusCode()!= 201) {
               request.result.success = false;
               request.result.message = request.response.getStatusCode()+' '+request.response.getStatus();
            }else {  
               Http finalhttp = new Http();
               HttpRequest  req2=new HttpRequest();
               HttpResponse finalresponse;
               Map<String,object> urlmap = (Map<String,object>) JSON.deserializeUntyped(request.response.getBody());
               String attachurl=(String)urlmap.get('url');
                req2.setHeader(Constant.CONTENT_TYPE,Constant.CONTENT_TYPE_JSON_PATCH);
                req2.setHeader(Constant.CONNECTION,Constant.KEEP_ALIVE);
                req2.setMethod(Constant.HTTP_PATCH);    
                req2.setEndpoint(Constant.AZURE_LEGACY+'/'+ request.projKey + Constant.AZURE_WORKITEMS_BASE_ENDPOINT + request.issueIdOrKey + Constant.API_VERSION_PARAM);
                String finalbody= Constant.JSON_PREFIX + attachurl + '"}}]';
                req2.setBody(finalbody);
                finalresponse = finalhttp.send(req2);
                if(finalresponse.getStatusCode()!= 200) {
                     request.result.success = true;
                     request.result.message = finalresponse.getStatusCode()+' '+finalresponse.getStatus();
                   }else{
                       request.result.success = false;
                       request.result.message = finalresponse.getStatusCode()+' '+finalresponse.getStatus();
                    }
             }
     }
}