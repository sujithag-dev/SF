/**
* @description       : Apiutiility Class is used to send http request and get response
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/

/**
* @description  Apiutiility is used to send http request and get response
*
*/
public class ApiUtility { 
    /**
    * @description Sends an HTTP GET request to the specified endpoint.
    * @param setEndpoint The URL endpoint to which the GET request should be sent.
    * @return The HttpResponse object containing the server's response to the GET request.
    */    
    public static HttpResponse sendGetRequest(String setEndpoint) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(setEndpoint);
            req.setMethod(Constant.HTTP_GET);
            Http http = new Http();
            HttpResponse response = http.send(req);
            return response;
        } catch (Exception e) {
            return null;        
        }
    }
    
    /**
    * @description Sends an HTTP POST request to the specified endpoint with the given body and content type.
    * @param setEndpoint The URL endpoint to which the POST request should be sent.
    * @param body The body content to be sent in the POST request.
    * @param setContentType The content type of the body, e.g., "application/json".
    * @return The HttpResponse object containing the server's response to the POST request.
    */ 
    public static HttpResponse httpPostRequest(String setEndpoint, String body, String setContentType) {
        try {
            HttpRequest request = new HttpRequest();
            Http http = new Http();
            request.setMethod(Constant.HTTP_POST);
            request.setEndpoint(setEndpoint);
            request.setHeader(Constant.CONTENT_TYPE, setContentType);
            request.setBody(body);
            HttpResponse response = http.send(request);
            return response;
        } catch (Exception e) {
            return null; 
        }
    }
    
    /**
    * @description Sends an HTTP POST request to the specified endpoint with a Blob body and specific headers for different services.
    * @param attachPost An instance of AttachmentPostWrapper that contains:
    *     - setEndpoint The URL endpoint to which the POST request should be sent.
    *     - bodyBlob The Blob content to be sent in the POST request.
    *     - serviceName The name of the service (e.g., Jira, ServiceNow, Azure) to determine specific headers.
    *     - setContentType The content type of the body, e.g., "application/json".
    * @return The HttpResponse object containing the server's response to the POST request.
    */ 
    public static HttpResponse httpPostAttachment(WrapperContainer.AttachmentPostRequest attachPost) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            Integer contentLength = attachPost.bodyBlob.size();
            
            if (attachPost.serviceName.equals(Constant.JIRA_SERVICE)) {
                req.setHeader(Constant.ATLASSIAN_HEADER, Constant.NO_CHECK);
                req.setHeader(Constant.CONTENT_TYPE,attachPost.setContentType);
            } else if (attachPost.serviceName.equals(Constant.SERVICENOW_SERVICE)) {
                req.setHeader(Constant.SERVER, Constant.SERVICENOW_SERVICE);
                req.setHeader(Constant.CONTENT_TYPE,getMimeType(attachPost.setContentType));
            } else if (attachPost.serviceName.equals(Constant.AZURE_SERVICE)) {
                req.setHeader(Constant.CONTENT_LENGTH, String.valueOf(contentLength));
                req.setHeader(Constant.CONTENT_TYPE,getMimeType(attachPost.setContentType) );
            } else {
                throw new IllegalArgumentException('Unsupported service name');
            }
            req.setHeader(Constant.CONNECTION, Constant.KEEP_ALIVE);
            req.setMethod(Constant.HTTP_POST);
            req.setEndpoint(attachPost.setEndpoint);
            req.setBodyAsBlob(attachPost.bodyBlob);
            req.setTimeout(120000);
            HttpResponse response = http.send(req);
            return response;
        } catch (Exception e) {
            return null; 
        }
    }

/**
 * @description Returns the MIME type based on the provided file extension.
 *
 * @param fileName The file extension (e.g., 'pdf', 'png', 'txt') for which the MIME type is to be determined.
 * @return A string representing the corresponding MIME type (e.g., 'application/pdf', 'image/png').
 *         Returns ('application/octet-stream') if the extension is unrecognized or null.
 */
public static String getMimeType(String fileName) {
    if (fileName.endsWithIgnoreCase('png')){return 'image/png';} 
    if (fileName.endsWithIgnoreCase('jpg') || fileName.endsWithIgnoreCase('jpeg')){ return 'image/jpeg';}
    if (fileName.endsWithIgnoreCase('mp4')){return 'video/mp4';} 
    if (fileName.endsWithIgnoreCase('webm')){return 'video/webm';} 
    if (fileName.endsWithIgnoreCase('pdf')){return 'application/pdf';} 
    return 'application/octet-stream'; 
}


}