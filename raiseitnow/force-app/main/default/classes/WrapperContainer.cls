/**
* @description       : WrapperContainer is a utility class designed to handle responses from various methods.
* author             : Minuscule Technologies
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description  WrapperContainer is used to handle the response of the all the methods.
 */
public with sharing class WrapperContainer {  
/**
 * @description Wrapper class for ticket creation parameters. Encapsulates all data needed to create a service ticket in an external system.
 */
    public class TicketRequest {

    /**
     * @description Raw response body from the external API call
    */
    public String response = ''; 
    /**
     * @description ID of the template to use for ticket creation
    */
    public String templateId = ''; 
    /**
     * @description Type of ticket being created
    */
    public String bugType = 'General'; 
    /**
     * @description Name of the project this ticket belongs to
    */
    public String description ='';
    /**
     * @description Name of the project 
    */
    public String projectName = ''; 

    /*@description Name of the Assignee 
    */
    public String assigneeName=''; 
    /**
     * @description Priority of ticket being created
    */
    public String priority='';
    /**
     * @description issuetype of the ticket
    */
    public String issuetype ='';
    /**
     * @description summary of the ticket being created
    */
    public String summary='';
    

    /**
     * @shortdescription of the ticket being created
    */
    public String shortDescription='';
    /**
     * @description urgency of the ticket being created
    */
    public String urgency='';
    /**
     * @description impact of the ticket being created
    */
    public String impact ='';
    /**
     * @description state of the ticket being created
    */
    public String state='';
    /**
     * @description Title of the ticket being created
    */
    public String title='';
    
     /**
     * @description Validates required fields before processing
     * @throws IllegalArgumentException when missing required fields
     */
    public void validate() {
        if (String.isBlank(templateId) || String.isBlank(response)) {
            throw new IllegalArgumentException('templateId and response are required');
        }
    }
    }

    /**
 * @description Encapsulates all parameters needed for processing Azure responses
 */
public class AzureResponseProcessorRequest {
    /**
     * @description Result message container from the processing pipeline
    */
        @AuraEnabled public ResultMessage result { get; set; }
    /**
     * @description HTTP response object from Azure DevOps API call
     */
        @AuraEnabled public HttpResponse response { get; set; }
    /**
     * @description Project key identifier
     */
        @AuraEnabled public String projKey { get; set; }
    /**
     * @description  Issue identifier or key
     */
        @AuraEnabled public String issueIdOrKey { get; set; }

    /**
     * @description Validates required fields before processing
     * @throws IllegalArgumentException if validation fails
     */
    public void validate() {
        if (result == null || response == null) {
            throw new IllegalArgumentException('Result and Response cannot be null');
        }
        if (String.isBlank(projKey)) {
            throw new IllegalArgumentException('Project key is required');
        }
    }
}

/**
 * @description AttachmentContext class holding systemName, templateId, recordKey, projectKey info for handling ticket attachments across Jira, ServiceNow, and Azure.
 */
public class AttachmentContext {


    /** @description Template Id associated with the ticket creation. */
    public Id templateId { get; set; }

    /** @description Identifier of the created record in the external system (issue key, sysId, work item id). */
    public String recordKey { get; set; }

    /** @description Project key or identifier, primarily used for Azure. */
    public String projectKey { get; set; }

    /**
     * @description Constructor initializing all fields for attachment handling context.
     * @param templateId Template Id used for ticket creation.
     * @param recordKey External system record identifier.
     * @param projectKey External system project identifier (used mainly for Azure).
     */
    public AttachmentContext(Id templateId, String recordKey, String projectKey) {
        this.templateId = templateId;
        this.recordKey = recordKey;
        this.projectKey = projectKey;
    }
}



/**
 * @description Encapsulates all parameters required for HTTP POST requests with file attachments to external services. Provides validation and structured data handling.
 */
public class AttachmentPostRequest {
    /**
 * @description The complete API endpoint URL for the external service
 * @required
 */
@AuraEnabled public String setEndpoint { get; set; }

/**
 * @description Binary attachment data to be posted
 * @required
 */
@AuraEnabled public Blob bodyBlob { get; set; }

/**
 * @description Identifier for the target external service (e.g., 'AzureBlobStorage')
 */
@AuraEnabled public String serviceName { get; set; }

/**
 * @description MIME type of the attachment (e.g., 'application/pdf')
 * @required
 */
@AuraEnabled public String setContentType { get; set; }

}


/**
 * @description Represents a project in a system.
 */
public class Project {
    /**
    * @description
    * The unique key or identifier of the project.
    */
    @AuraEnabled public String key { get; set; }
    /**
     * @description
     * The human-readable name of the project.
     */
    @AuraEnabled public String name { get; set; }
}


    /**
 * @description Represents wrapper for incidents in a system.
 */
public class Incidentwrapper {
    /**
     * @description
     * The result object containing the incident data (e.g., list of incidents, metadata).
     */
    @AuraEnabled public Result result {get; set;}
}


/**
 * @description Represents result details in a system.
 */
public class Result  {
        /**
         * @description
        * A map of column keys to Column objects representing the structure or schema of the data.
        * Useful for dynamically rendering or processing table-like results.
        */
    @AuraEnabled public Map<String, Column> columns { get; set; }
}


/**
 * @description Represents column details in a system.
 */     
public class Column {
        /**
         * @description
         * Indicates whether the column is filterable in the UI or query logic.
         */
    @AuraEnabled public Boolean filterable { get; set; }
        /**
         * @description
         * The display label for the column (e.g., 'Status', 'Priority').
         */
    @AuraEnabled public String label { get; set; }
        /**
         * @description
         * Indicates whether the column is required (i.e., must have a value).
         */
    @AuraEnabled public Boolean mandatory { get; set; }
        /**
         * @description
         *  The default value for the column, if any.
         */
    @AuraEnabled public String defaults { get; set; }
        /**
         * @description
         * Indicates whether the column is read-only (i.e., not editable).
         */
    @AuraEnabled public Boolean readOnly { get; set; }
        /**
         * @description
         * The API or system name of the column (e.g., 'status', 'priority_code').
         */
    @AuraEnabled public String name { get; set; }
        /**
         * @description
         * The data type of the column (e.g., 'string', 'boolean', 'choice').
         */
    @AuraEnabled public String columnType { get; set; }
        /**
         * @description
         *  A list of available choices for the column, used when the columnType is of a selectable type (e.g., dropdown).
         */
    @AuraEnabled public List<Choice> choices { get; set; }
}


    /**
 * @description Represents choice details in a system.
 */
public class Choice {
    /**
     * @description
     * The user-facing label for the choice (e.g., 'High Priority', 'Open').
     */
    @AuraEnabled public String label { get; set; }
    /**
     * @description
     * The underlying value associated with the choice (e.g., 'high', 'open').
     */
    @AuraEnabled public String value { get; set; }
        /**
     * @description
     * The internal or reference name for the choice, if different from value.
     */
    @AuraEnabled public String name { get; set; }
    /**
     * @description
     * Indicates whether this choice is a reference to another object or record.
     */
    @AuraEnabled public boolean reference {get; set;}
}


/**
 * @description Represents Azure wrapper details in a system.
 */    
public class AzureWrapper {
    
    /**
    * @description
    * The number of records returned in the response (e.g., number of fields or items).
    */
    @AuraEnabled public Integer count { get; set; }
    /**
    * @description
    * A list of field details retrieved from Azure DevOps, typically representing
    * metadata or configuration of work item fields.
    */
    @AuraEnabled public List<FieldDetails> value { get; set; }
} 


/**
 * @description Represents field details for Azure integration in a system.
 */
public class FieldDetails {
    /**
     * @description
     * The default value assigned to the field, if any.
     */
    @AuraEnabled public String defaultValue { get; set; }
    /**
     * @description
     * A list of allowed values for the field, commonly used for dropdowns or picklists.
     */
    @AuraEnabled public List<String> allowedValues { get; set; }
    /**
     * @description
     * Help text or description for the field, often shown as a tooltip in the UI.
     */
    @AuraEnabled public String helpText { get; set; }
    /**
     * @description
     * Indicates whether this field is always required when creating or updating a record.
     */
    @AuraEnabled public Boolean alwaysRequired { get; set; }
    /**
     * @description
     * The system-level reference name used internally in Azure DevOps APIs.
     */
    @AuraEnabled public String referenceName { get; set; }
    /**
    * @description
    * The human-readable display name of the field (e.g., 'Priority', 'Assigned To').
    */
    @AuraEnabled public String name { get; set; }

}


/**
 * @description Represents user details in a system.
 */
public class UserWrapper {
    /**
     * @description
     * The URL to the user’s own profile or API reference (e.g., self-link from Jira).
     */
    @AuraEnabled public String self;
    /**
    * @description
    * The unique account ID of the user, typically platform-specific (e.g., Jira Account ID).
    */
    @AuraEnabled public String accountId;
    /**
     * @description
     * The type of account (e.g., 'atlassian', 'service', 'app').
     */
    @AuraEnabled public String accountType;
    /**
     * @description
     * The user’s email address.
     */
    @AuraEnabled public String emailAddress;
    /**
     * @description
     * The full display name of the user (e.g., 'Jane Doe').
     */
    @AuraEnabled public String displayName;
    /**
     * @description
    * Indicates whether the user's account is currently active.
    */
    @AuraEnabled public Boolean active;
    /**
 * @description
 * The locale or language preference of the user (e.g., 'en-US').
 */
    @AuraEnabled public String locale;
}


    /**
 * @description Represents ServiceNow lookup wrapper in a system.
 */
public class ServiceNowLookupWrapper {
/**
 * @description
 * A list of result items returned from the ServiceNow lookup API.
 */
    public List<ResultItem> result;
}


/**
 * @description Represents result item details in a system.
 */
public class ResultItem {
/**
 * @description
 * The unique system ID of the item in ServiceNow (e.g., a sys_id for a user or group).
 */    
    @SuppressWarnings('PMD.FieldNamingConventions') // Required to match ServiceNow JSON key exactly
    public String sys_id;
    /**
 * @description
 * The display name of the item (e.g., user name, group name, or CI name).
 */
    public String name;
}


/**
* @description Represents team information wrapper in a system.
*/
public class TeamInfoWrapper{
/**
 * @description
 * A list of Azure DevOps teams associated with the query or project.
 */
    public List<TeamInfo> value;
    /**
 * @description
 * The total number of teams returned in the response.
 */
    public Integer count;
}


    /**
 * @description Represents team information details in a system.
 */
public class TeamInfo {
/**
 * @description
 * The unique identifier of the team.
 */
    public String id;
/**
 * @description
 * The display name of the team.
 */
    public String name;
/**
 * @description
 * The API URL for the team resource.
 */
    public String url;
/**
 * @description
 * A brief description of the team, if available.
 */
    public String description;
/**
 * @description
 * The identity URL associated with the team (e.g., for avatars or permissions).
 */
    public String identityUrl;
/**
 * @description
 * The name of the Azure DevOps project this team belongs to.
 */
    public String projectName;
/**
 * @description
 * The unique identifier of the project this team is part of.
 */
    public String projectId;
}


/**
 * @description Represents identity wrapper in a system.
 */
public class IdentityWrapper {

/**
 * @description
 * The identity details for the user or group.
 */
    public Identity identity { get; set; }
}


/**
 * @description Represents identity response in a system.
 */
public class IdentityResponse {
/**
 * @description
 * A list of identity wrappers representing individual users or groups.
 */
    public List<IdentityWrapper> value { get; set; }
//    public Integer count { get; set; }
}


/**
 * @description Represents identity details in a system.
 */
public class Identity {
/**
 * @description
 * The full display name of the identity (e.g., 'John Doe').
 */
    public String displayName { get; set; }
/**
 * @description
 * The unique system-level name or email of the identity.
 */
    public String uniqueName { get; set; }
} 

/**
 * @description Wrapper Class for the template details.
 */
public class TemplateWrapper {
/**
 * @description
 * A unique identifier for the template, often used for cross-system reference.
 */
    @AuraEnabled public String uniqueId;
/**
 * @description
 * The Salesforce record ID associated with the template (e.g., Service_Template__c Id).
 */
    @AuraEnabled public String recordId;
/**
 * @description
 * The name of the project where the template applies (e.g.,Service Now, Azure or Jira project name).
 */
    @AuraEnabled public String projectName;
/**
 * @description
 * The key or short code of the project.
 */
    @AuraEnabled public String projectKey;
/**
 * @description
 * The name of the integrated service this template belongs to (e.g., "Jira", "Azure", "ServiceNow").
 */
    @AuraEnabled public String servName;
/**
 * @description
 * Indicates whether the template has already been created or linked.
 */
    @AuraEnabled public Boolean hadTemplate;
/**
 * @description
 * The creation date of the template as a formatted string.
 */
    @AuraEnabled public String createdDate;
/**
 * @description
 * JSON string containing field-value mappings or configurations used for the template.
 */
    @AuraEnabled public String fieldsJson;
/**
 * @description
 * Lookup ID associated with an external entity, if applicable.
 */
    @AuraEnabled public String lookUpId;
/**
 * @description
 * The user name of the person who created or is using the template.
 */
    @AuraEnabled public String userName;
    @AuraEnabled public String recordTypeName;
    
}


/**
 * @description Represents input for the ticket creation.
 */
public class InputWrapper {
    
/**
 * @description
 * The ID of the selected template used for ticket creation.
 */
    public String templateId;
/**
 * @description
 * The key or short code of the target project (e.g., Jira project key).
 */
    public String projectKey;
/**
 * @description
 * The name of the target project where the ticket should be created.
 */
    public String projectName;
/**
 * @description
 * A map of field names to user-provided values used to populate the ticket fields.
 */
    public Map<String, String> valuesMap;
/**
 * @description
 * The user or entity to assign the ticket to (e.g., a username or ID).
 */
    public String assigneeName;
/**
 * @description
 * The configuration item ID, typically used in ServiceNow integrations for CMDB references.
 */
    public String configItemId;

    
    
}


/**
 * @description Represents attachment details for the ticket creation.
 */
// used for test instantiation
@SuppressWarnings('PMD.EmptyStatementBlock')
public class JiraAttachment {
/**
 * @description
 * The ID of the `ContentVersion` record in Salesforce.
 */
    @AuraEnabled public String contentVersionId;
/**
 * @description
 * The name of the file (without extension).
 */
    @AuraEnabled public String fileName;
/**
 * @description
 * The full name or display name of the file.
 */
    @AuraEnabled public String name;
/**
 * @description
 * The base64-encoded file content used for API upload.
 */
    @AuraEnabled public String fileContent;
/**
 * @description
 * The file type or extension (e.g., "png", "pdf").
 */
    @AuraEnabled public String type;
/**
 * @description
 * The ID of the associated `ContentDocument` (used for linking).
 */
    @AuraEnabled public Id documentId;
/**
 * @description
 * The URL used to retrieve or preview the file thumbnail.
 */
    @AuraEnabled public String url;



    @AuraEnabled public Integer contentFileSize;

/**
 * @description
 * Default constructor.
 */
    public JiraAttachment(){
        
    }
    /**
     * @description Constructor
     * @param cv  The `ContentVersion` record containing file metadata and binary data.
     */
    public JiraAttachment(ContentVersion cv) {
        this.contentFileSize = cv.ContentSize;
        this.contentVersionId = cv.Id;
        this.fileName = cv.Title;
        if(cv.VersionData != null){
            this.fileContent = EncodingUtil.base64Encode(cv.VersionData);
        }
        this.type = cv.FileExtension;
        this.documentId = cv.contentDocumentId;
        this.name = cv.Title;
        this.url = Constant.THUMBNAIL_URL + cv.Id;
    }
}


/**
 * @description Handle the response value after the jira ticket creation.
 */
public class JiraTicketResponse {
/**
 * @description
 * The unique key of the created Jira ticket (e.g., "PROJ-123").
 */
    public String key {get; set;}
/**
 * @description
 * The name or key of the project to which the ticket belongs.
 */
    public String project {get; set;}
/**
 * @description
 * The unique Id of the created Jira ticket (e.g., "12345").
 */
    public String id {get;set;}
    
}


/**
 * @description Handle the response value after the serviceNow ticket creation.
 */
public class ServiceNowTicketResponse{
/**
 * @description This class encapsulates the `result` field which contains the unique system identifier (`sys_id`)
 * of the newly created incident or task in ServiceNow.
 */
    public ServiceNowResult result { get; set; }

}


/**
 * @description Handle the response value after the azure ticket creation.
 */
public class AzureTicketRespose {
    /**
     * @description
    * The unique id of the created Azure ticket (e.g., "23").
    */
    public Integer id {get; set;}
}


/**
 * @description Handle the response value after the serviceNow ticket creation.
 */
public class ServiceNowResult {
/**
 * @description  the `sys_id`, which uniquely identifies the created record
 * in the ServiceNow system.
 */
    @SuppressWarnings('PMD.PropertyNamingConventions') // Required for exact JSON key mapping
    public String sys_id { get; set; }
/**
     * @description The `task_effective_number`, which is an auto-number generated
     *              after the record is created in the ServiceNow system.
     */  
@SuppressWarnings('PMD.PropertyNamingConventions') // Required for exact JSON key mapping
    public String task_effective_number { get; set; }
    
}


/**
 * @description Utility class responsible for handling API calls to Azure DevOps to retrieve ticket details(id and project)
 */
public class AzureGetAPIData {
    /**
     * @description
    * The unique id of the created Azure ticket (e.g., "23").
    */
    public Integer id {get; set;}
/**
 * @description
 * The name or key of the project to which the ticket belongs.
 */
    public String project {get; set;}
}

}