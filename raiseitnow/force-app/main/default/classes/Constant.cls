/**
 * @description       : Constant class is used to store the constan values.
 * author             : Minuscule Technologies 
 * @group             : 
 * @last modified on  : 03-05-2024
 * @last modified by  : 
**/
public with sharing class Constant {
    // Services
    public static final String JIRA_SERVICE = 'Jira';
    public static final String AZURE_SERVICE = 'Azure Devops';
    public static final String SERVICENOW_SERVICE = 'ServiceNow';  
    // headers
    public static final String AUTHORIZATION= 'Authorization'; 
    public static final String CONTENT_TYPE = 'Content-Type';
    public static final String CONTENT_LENGTH = 'Content-Length';
    public static final String CONNECTION = 'Connection';
    public static final String ATLASSIAN_HEADER = 'X-Atlassian-Token';
    public static final String SERVER = 'Server';   
    public static final String BASIC = 'Basic ';
  
    //values
    public static final String NO_CHECK =  'nocheck';
    public static final String KEEP_ALIVE = 'keep-alive';   
    public static final String CONTENT_TYPE_JSON_UTF8 = 'application/json;charset=UTF-8';
    public static final String CONTENT_TYPE_JSON_PATCH = 'application/json-patch+json';
    public static final String CONTENT_TYPE_OCTET_STREAM = 'application/octet-stream';
    public static final String CONTENT_TYPE_JSON = 'application/json';
  

    //http methods
    public static final String HTTP_POST = 'POST';
    public static final String HTTP_PATCH = 'PATCH';
    public static final String HTTP_GET = 'GET';
    public static final String HTTPS_PREFIX = 'https://';
    

   
    public static final String JIRA_USERS_ENDPOINT = '/rest/api/2/users';
    public static final String AZURE_PROJECTS_ENDPOINT = '/_apis/projects?api-version=7.0';
    public static final String SERVICENOW_INCIDENTS_ENDPOINT= '/api/now/table/incident';

    public static final String JIRA_MYSELF_ENDPOINT = '/rest/api/2/myself';
    public static final String AZURE_CONNECTION_DATA_ENDPOINT = '/_apis/ConnectionData';
    public static final String SERVICENOW_USER_INFO_ENDPOINT = '/api/now/table/sys_user?sysparm_query=user_name=admin&sysparm_fields=name,sys_id';    
    public static final String SERVICENOW_USER_INFO = '/api/now/table/sys_user?sysparm_query=user_name=';
    public static final String SERVICENOW_QUERY_PARAMS = '&sysparm_fields=name,sys_id';

    //jira callout 
    public static final String JIRA_ISSUE_ENDPOINT = '/rest/api/2/issue/';
    public static final String ATTACHMENTS_PATH = '/attachments';
    public static final String JIRA_PROJECT_API_ENDPOINT = '/rest/api/2/project';
    public static final String JIRA_ISSUE_CREATE_META_ENDPOINT = '/rest/api/2/issue/createmeta?projectKeys=';
    public static final String JIRA_ISSUE_CREATE_META_PARAMS = '&issuetypeNames=Bug&expand=projects.issuetypes.fields';
   

   //azure callout
    public static final String AZURE_WORKITEMS_ENDPOINT = '/_apis/wit/workitems/$issue?api-version=7.0';   
    public static final String AZURE_ATTACHMENTS_ENDPOINT = '/_apis/wit/attachments/';
    public static final String AZURE_WORKITEMS_BASE_ENDPOINT = '/_apis/wit/workitems/';
    public static final String AZURE_DEVOPS_ISSUE_FIELDS_ENDPOINT = '/_apis/wit/workitemtypes/Issue/fields?$expand=allowedValues&api-version=7.0';
    public static final String AZURE_WORKITEMSBATCH_BASE_ENDPOINT = '/_apis/wit/workitemsbatch';
    public static final String AZURE_WORKITEMSLIST_BASE_ENDPOINT = '_apis/wit/workitems?';

    public static final String FILE_NAME_PARAMETER = '?fileName=';
    public static final String API_VERSION_PARAMETER = '&api-version=7.0';
    public static final String API_VERSION_PARAM = '?api-version=7.0';

    //servicenow callout
    public static final String SERVICENOW_ATTACHMENT_FILE_ENDPOINT = '/api/now/attachment/file?table_name=incident&table_sys_id=';
    public static final String FILE_NAME_PARAM = '&file_name=';
    public static final String SERVICENOW_INCIDENT_META_ENDPOINT = '/api/now/ui/meta/incident';
    public static final String SERVICENOW_DICTIONARY_ENDPOINT = '/api/now/table/sys_dictionary?sysparm_query=name=task^ORname=incident&sysparm_fields';

    //body 
    public static final String JSON_PREFIX = '[{"op":"add","path":"/relations/-","value":{"rel":"AttachedFile","url":"';

    public static final String THUMBNAIL_URL = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB240BY180&versionId=';
    public static final String PNG_BASE_URL = 'data:image/png;base64,';

    //messages  
    public static final String DEFAULT_TEMPLATE = 'No Template found, please contact your salesforce administrator';
    public static final String ERR_RES_FOUND = 'Sorry,You are not Logged in Service Management Tool or No Template Found.Please Contact Your Adminstrator';
    public static final String USER_AUTHENDICATION_ERROR = 'Username is Invalid';
    public static final String ERROR_ADDING_USER_DETAILS = 'Error occured, while adding user details';
    public static final String USER_LOGOUT_SUCCESS_MESSAGE = 'User Logout Successfully';
    public static final String ERROR_NO_USER_TO_LOGOUT = 'Error occurred, No User there to Logout';
    public static final String ERROR_PREFIX = 'Error: ';
    public static final String NO_USER_FOUND = 'No User Found';
    public static final String ERROR_RETRIEVING_USER_DETAILS = 'Error occurred, While retrieving user details';
    public static final String EXCEPTION_PREFIX = 'Exception: ';
    public static final String ERROR_GETTING_PROJECT_LIST = 'Error, while getting the project list from callout';
    public static final String ERROR_GETTING_PROJECT_FIELDS_LIST = 'Error, while getting the project fields list from callout';
    public static final String ERROR_EXCEPTION = 'Error Exception ';
    public static final String ERROR_OCCURRED = 'Error Occured ';
    public static final String ERROR_SERVICE_NULL = 'Error, Service Cannot be Null';
    public static final String STATUS_IN_PROGRESS = 'In-Progress';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String UPDATE_SUCCESS_MESSAGE = 'Update Successfully';
    public static final String NO_DATA_MESSAGE = 'No Data';
    public static final String TEMPLATE_CREATED_SUCCESSFULLY = 'Template Created Successfully';
    public static final String TEMPLATE_CREATED_SUCCESSFULLY_AND_COMPLETED = 'Template Created Successfully, Completed';
    public static final String TEMPLATE_ALREADY_EXISTS = 'Template Already Exists';
    public static final String ERROR_OCCURRED_PREFIX = 'Error occured, ';
    public static final String ERROR_EXCEPTION_PREFIX = 'Error Exception ,';
    public static final String NO_TEMPLATE_EXISTS = 'No Template exists for the requested user';
    public static final String NO_TEMPLATE_FOUND = 'No Template Found';
    public static final String NO_SAVED_TEMPLATE_FOUND = 'No Saved Template found';
    public static final String ERROR_WHILE_DELETING_TEMPLATE = 'Error, while deleting template';




    //status codes
    public static final String EXCEPTIONMESSAGE = 'Exception Message';
    public static final Integer STATUS_CODE_200 = 200;
    public static final Integer STATUS_CODE_201 = 201;
    public static final Integer STATUS_CODE_400 = 400;
    public static final Integer STATUS_CODE_401 = 401;
    public static final Integer STATUS_CODE_404 = 404;
    public static final Integer STATUS_CODE_500 = 500;
   
    //version nyumber
    public static final String ORGVERSION='60.0';

    //named credential
    public static final String JIRA_LEGACY ='callout:RIT_Jira';
    public static final String SERVICE_NOW_LEGACY ='callout:RIT_ServiceNow'; 
    public static final String AZURE_LEGACY ='callout:RIT_Azure';
    public static final String JIRA_NC       = 'RIT_Jira';
    public static final String SERVICENOW_NC = 'RIT_ServiceNow';
    public static final String AZURE_NC      = 'RIT_Azure';
    public static final List<String> LEGACY_LIST = new List<String>{ JIRA_NC, SERVICENOW_NC, AZURE_NC };

    // Integration Map (NC → Service)
    public static final Map<String, String> INTEGRATION_MAP = new Map<String, String>{
    Constant.JIRA_NC       => Constant.JIRA_SERVICE,
    Constant.AZURE_NC      => Constant.AZURE_SERVICE,
    Constant.SERVICENOW_NC => Constant.SERVICENOW_SERVICE
};




    //XML file name
    public static final String CREATE_REMOTE_SITE_BODY_MT = 'CreateRemoteSiteBody_MT';
    public static final String DELETE_REMOTE_SITE_BODY_MT = 'DeleteRemoteSiteBody_MT';
    public static final String CREATE_QUICK_ACTION_BODY_MT = 'CreateQuickActionBody_MT';
    public static final String CREATE_GLOBAL_ACTION_MT = 'CreateGlobalAction_MT';

    //query for getRemoteRecords
    public static final String SELECT_REMOTE_PROXY_QUERY = 'SELECT Id, EndpointUrl, IsActive FROM RemoteProxy WHERE EndpointUrl = \'';

    public static final List<String> JIRA_ALLOWED_FIELDS = new List<String>{'Issue Type','Summary','Priority', 'Description'};
    public static final List<String> SERVICE_NOW_ALLOWED_FIELDS = new List<String>{'Caller', 'Subcategory', 'Short description', 'Description', 'Channel', 'Urgency', 'Category','Impact','Urgency'};
    public static final List<String> AZURE_ALLOWED_FIELDS = new List<String>{'State', 'Title','Description', 'Priority'};


     public static final List<String> STATUS_LIST = new List<String>{'Closed','Canceled','Resolved','Done'};


    // RecordType Names for Bug_Tracking__c
    public static final String BUGTRACKING_RT_JIRA        = 'Jira';
    public static final String BUGTRACKING_RT_AZURE       = 'Azure';
    public static final String BUGTRACKING_RT_SERVICENOW  = 'Service Now';


    

}