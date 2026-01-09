/**
* @description       : AttachmentManager Class is used to manages file retrieval and deletion operations across attachments
*                      uploaded for different ticketing systems.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/                          
/**
 * @description
 * Manages file retrieval and deletion operations across attachments
 * uploaded for different ticketing systems.
 */
public with sharing class AttachmentManager  {
/**
 * @description Retrieves the size of a ContentDocument in bytes.
 * @param docId The Id of the ContentDocument.
 * @return The size of the document in bytes. Returns 0 if the document is not found.
 */
@AuraEnabled
public static Integer getDocumentSize(String docId) {
    List<ContentDocument> documentList = [
        SELECT Id, ContentSize
        FROM ContentDocument
        WHERE Id = :docId
        WITH SECURITY_ENFORCED
    ];

    if (!documentList.isEmpty()) {
        return Integer.valueOf(documentList[0].ContentSize); 
    }
    return 0;
}

	/**
     * @description Get Uploaded Attachments.
     * @param recordId The ID of the record for which attachments are being retrieved.
     * @return ResultMessage indicating the success of the operation and containing the retrieved attachments.
     */
    @AuraEnabled
    public static ResultMessage getUploadedAttachments(String recordId) {
        ResultMessage result = new ResultMessage(true, 'Get Uploaded Attachments');
        try {
              if (!isAccessible(ContentDocumentLink.SObjectType)) {
                    return accessDenied(result, 'ContentDocumentLink');
                }
              List<Id> contentDocumentIds = fetchContentDocumentIds(recordId);
              if (!isAccessible(Service_Template__c.SObjectType)) {
                    return accessDenied(result, 'Service_Template__c');
               }
              String projectName = fetchProjectName(recordId);
              if (!isAccessible(ContentVersion.SObjectType)) {
                    return accessDenied(result, 'ContentVersion');
               }
              List<ContentVersion> contentVersions = fetchContentVersions(contentDocumentIds, projectName);
              List<WrapperContainer.JiraAttachment> jiraAttachments = new List<WrapperContainer.JiraAttachment>();
              for (ContentVersion cv : contentVersions) {
                            jiraAttachments.add(new WrapperContainer.JiraAttachment(cv));
                }
              result.payloadMap.put('thumbnailURL', Constant.THUMBNAIL_URL);
              result.payloadMap.put('jiraAttachments', jiraAttachments);
              result.payloadMap.put('pngBaseUrl', Constant.PNG_BASE_URL);
            } catch (Exception e) {
                result.success = false;
                result.message = e.getMessage();
             }
        return result;
     }
    private static Boolean isAccessible(Schema.SObjectType sObjectType) {
          return sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible();
     }
    @TestVisible
    private static ResultMessage accessDenied(ResultMessage result, String objectName) {
        result.success = false;
        result.message = 'You don\'t have read access to the ' + objectName + '.';
        return result;
     }

    private static List<Id> fetchContentDocumentIds(String recordId) {
        List<Id> contentDocumentIds = new List<Id>();
        for (ContentDocumentLink cdl : [ SELECT ContentDocumentId  FROM ContentDocumentLink  WHERE LinkedEntityId = :recordId  WITH USER_MODE ]) {
                  contentDocumentIds.add(cdl.ContentDocumentId);
          }
        return contentDocumentIds;
     }
    @TestVisible
    private static String fetchProjectName(String recordId) {
          for (Service_Template__c template : [ SELECT Project_Name__c  FROM Service_Template__c  WHERE Id = :recordId  WITH USER_MODE ]) {
                     if (template.Project_Name__c != null) {
                           return '%' + template.Project_Name__c.trim() + '%';
                      }
            }
         return '';
     }

 @TestVisible
    private static List<ContentVersion> fetchContentVersions(List<Id> contentDocumentIds, String projectName) {
   
    List<ContentVersion> results;

    if (contentDocumentIds != null && !contentDocumentIds.isEmpty() && String.isBlank(projectName)) {
        results = [
            SELECT ContentBodyId, VersionNumber, Title, Description, ReasonForChange, Id,
                   ContentDocumentId, PathOnClient, CreatedDate, LastModifiedDate, FileType,
                   VersionData, ContentSize, FileExtension, FirstPublishLocationId
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
            WITH USER_MODE
            ORDER BY CreatedDate
        ];
    }
   
    else if ((contentDocumentIds == null || contentDocumentIds.isEmpty()) && !String.isBlank(projectName)) {
        results = [
            SELECT ContentBodyId, VersionNumber, Title, Description, ReasonForChange, Id,
                   ContentDocumentId, PathOnClient, CreatedDate, LastModifiedDate, FileType,
                   VersionData, ContentSize, FileExtension, FirstPublishLocationId
            FROM ContentVersion
            WHERE ReasonForChange LIKE :projectName
            WITH USER_MODE
            ORDER BY CreatedDate
        ];
    }
   
    else {
        results = [
            SELECT ContentBodyId, VersionNumber, Title, Description, ReasonForChange, Id,
                   ContentDocumentId, PathOnClient, CreatedDate, LastModifiedDate, FileType,
                   VersionData, ContentSize, FileExtension, FirstPublishLocationId
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
               OR ReasonForChange LIKE :projectName
            WITH USER_MODE
            ORDER BY CreatedDate
        ];
    }

    return results;
}

	  /**
     * @description Deletes attachments.
     * @param contentDocumentIds The IDs of the content documents to be deleted.
     * @return ResultMessage indicating the success of the operation.
     */
@AuraEnabled
public static ResultMessage deleteAttachment(List<Id> contentDocumentIds) {
    ResultMessage result = new ResultMessage(true, 'Delete Attachment');
    try {
        if (!contentDocumentIds.isEmpty() && ContentDocument.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
            List<ContentDocument> docsToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
          if (!docsToDelete.isEmpty()) {
                delete docsToDelete;
            }
        }
    } catch (Exception e) {       
        result.success = false;
        result.message = e.getMessage();
    }    
    result.payloadMap.put('message', 'Attachments deleted successfully');
    return result;
}

}