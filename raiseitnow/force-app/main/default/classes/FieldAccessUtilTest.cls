/**
 * @description       : Test class for FieldAccessUtil utility class.
 *                      Validates safe field setting with FLS (Field-Level Security) checks.
 * author             : Minuscule Technologies
 * @group             : Utility Tests
 * @last modified on  : 09-10-2025
 * @last modified by  : 
**/
@IsTest
private class FieldAccessUtilTest {
     /**
     * @description Creates a test Account record used by multiple test methods.
     */
  @TestSetup
    static void setupTestData() {
        // Create a test user for runAs context
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'stdusr',
            Email = 'stdusr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'stdusr' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        // Insert a test Account
        Account acc = new Account(Name = 'Test Account', Phone = '9999999999');
        insert acc;
    }


     /**
     * @description Tests that valid, createable, and updateable fields are correctly updated.
     */
     @IsTest
    static void testSetAccessibleFieldsValidFields() {
        // Fetch the user and use runAs to satisfy PMD rule
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Account acc = [SELECT Id, Name, Phone FROM Account LIMIT 1];
            Map<String, Object> fieldValues = new Map<String, Object>{
                'Name' => 'Updated Account',
                'Phone' => '1234567890'
            };

            Account updatedAcc = (Account) FieldAccessUtil.setAccessibleFields(acc, fieldValues);

           System.assertEquals('Updated Account',updatedAcc.Name,'Expected Account Name to be updated to "Updated Account"');
           System.assertEquals('1234567890',updatedAcc.Phone,'Expected Account Phone to be updated to "1234567890"');
        }
    }
     
     /**
     * @description Verifies that non-existent fields are ignored safely.
     */
    @IsTest
    static void testSetAccessibleFieldsNonExistentField() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Account acc = [SELECT Id, Name, Phone FROM Account LIMIT 1];
            Map<String, Object> fieldValues = new Map<String, Object>{
                'Non_Existent_Field__c' => 'Some Value',
                'Name' => 'New Name'
            };
            Account updatedAcc = (Account) FieldAccessUtil.setAccessibleFields(acc, fieldValues);
            System.assertEquals('New Name', updatedAcc.Name, 'Expected Name to be updated');
            Boolean hasField = updatedAcc.getSObjectType().getDescribe().fields.getMap().containsKey('Non_Existent_Field__c');
            System.assertEquals(false, hasField, 'Expected non-existent field to not exist on the SObject');
        }
    }

     /**
     * @description Verifies that read-only fields (like Id) are not modified.
     */
    @IsTest
    static void testSetAccessibleFieldsReadOnlyField() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Original Name');
            Map<String, Object> fieldValues = new Map<String, Object>{ 'Id' => '12345', 'Name' => 'Updated Name' };
            Account updatedAcc = (Account) FieldAccessUtil.setAccessibleFields(acc, fieldValues);
            System.assertEquals('Updated Name', updatedAcc.Name, 'Expected Name to be updated');
            System.assertEquals(null, updatedAcc.get('Id'), 'Id should remain null before insert');
        }
    }
    
   /**
     * @description Ensures that when an empty field map is provided, no changes occur.
     */
    @IsTest
    static void testSetAccessibleFieldsEmptyMap() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            Account updatedAcc = (Account) FieldAccessUtil.setAccessibleFields(acc, new Map<String, Object>());
            System.assertEquals(acc.Name, updatedAcc.Name, 'Expected Name to remain unchanged');
        }
    }
    
    /**
     * @description Tests that createable and updateable fields can be modified successfully.
     */
    @IsTest
    static void testSetIfCreateableAndUpdateableValidField() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Before Update');
            FieldAccessUtil.setIfCreateableAndUpdateable(acc, 'Name', 'After Update');
            System.assertEquals('After Update', acc.Name, 'Field should be updated when createable and updateable');
        }
    }

     /**
     * @description Ensures that attempting to set a non-existent field does not affect valid fields.
     */
    @IsTest
    static void testSetIfCreateableAndUpdateableInvalidField() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Before Update');
            FieldAccessUtil.setIfCreateableAndUpdateable(acc, 'Non_Existent_Field__c', 'Some Value');
            System.assertEquals('Before Update', acc.Name, 'Invalid field should not affect other fields');
        }
    }
  
     /**
     * @description Verifies that read-only fields (like Id) are not modified during assignment.
     */
    @IsTest
    static void testSetIfCreateableAndUpdateableReadOnlyField() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Account acc = new Account(Name = 'Before Update');
            FieldAccessUtil.setIfCreateableAndUpdateable(acc, 'Id', '001XXXXXXXXXXXX');
            System.assertEquals(null, acc.Id, 'Id should not be set because it is not createable');
        }
    }
    
    /**
     * @description Tests MIME type detection for PNG files.
     */
   @IsTest
    static void testGetMimeTypePNG() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('sample.png');
            System.assertEquals('image/png', result, 'Expected MIME type for PNG files');
        }
    }

    /**
     * @description Tests MIME type detection for JPG files.
     */
    @IsTest
    static void testGetMimeTypeJPG() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('photo.jpg');
            System.assertEquals('image/jpeg', result, 'Expected MIME type for JPG files');
        }
    }
    /**
     * @description Tests MIME type detection for JPEG files.
     */
   @IsTest
    static void testGetMimeTypeJPEG() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('photo.jpeg');
            System.assertEquals('image/jpeg', result, 'Expected MIME type for JPEG files');
        }
    }

    /**
     * @description Tests MIME type detection for MP4 files.
     */
    @IsTest
    static void testGetMimeTypeMP4() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('video.mp4');
            System.assertEquals('video/mp4', result, 'Expected MIME type for MP4 files');
        }
    }
    /**
     * @description Tests MIME type detection for WEBM files.
     */
    @IsTest
    static void testGetMimeTypeWEBM() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('clip.webm');
            System.assertEquals('video/webm', result, 'Expected MIME type for WEBM files');
        }
    }

    /**
     * @description Tests MIME type detection for PDF files.
     */
   @IsTest
    static void testGetMimeTypePDF() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('document.pdf');
            System.assertEquals('application/pdf', result, 'Expected MIME type for PDF files');
        }
    }

    /**
     * @description Tests default MIME type for unsupported or unknown file extensions.
     */
     @IsTest
    static void testGetMimeTypeUnknownExtension() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('file.xyz');
            System.assertEquals('application/octet-stream', result, 'Expected default MIME type for unknown files');
        }
    }

    /**
     * @description Tests behavior when filename has uppercase extension.
     */
    @IsTest
    static void testGetMimeTypeCaseInsensitive() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            String result = ApiUtility.getMimeType('IMAGE.PNG');
            System.assertEquals('image/png', result, 'MIME type check should be case-insensitive');
        }
    }
    
     /**
     * @description Mock implementation of HttpCalloutMock to simulate API responses.
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        
     /**
     * @description Returns a mock HttpResponse for testing callouts, e.g., httpPostAttachment().
     *
     * @param req HttpRequest The HTTP request sent during the callout. Can be inspected if needed.
     * @return HttpResponse  A mock HttpResponse object with:
     *                       - Status code: 200
     *                       - Header: 'Content-Type' = 'application/json'
     *                       - Body: '{"status":"success"}'
     */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

       /**
     * @description Tests httpPostAttachment() for Jira service with mock callout.
     */
    @IsTest
    static void testHttpPostAttachmentJira() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            WrapperContainer.AttachmentPostRequest request = new WrapperContainer.AttachmentPostRequest();
            request.serviceName = Constant.JIRA_SERVICE;
            request.setEndpoint = 'https://example.atlassian.net/rest/api/2/issue/TEST-1/attachments';
            request.setContentType = 'image/png';
            request.bodyBlob = Blob.valueOf('fakebinarydata');
            Test.startTest();
            HttpResponse response = ApiUtility.httpPostAttachment(request);
            Test.stopTest();
            System.assertNotEquals(null, response, 'Response should not be null');
            System.assertEquals(200, response.getStatusCode(), 'Expected HTTP 200 status');
            System.assert(response.getBody().contains('success'), 'Expected success in response body');
        }
    }

    /**
     * @description Tests httpPostAttachment() for ServiceNow service with mock callout.
     */
   @IsTest
    static void testHttpPostAttachmentServiceNow() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            WrapperContainer.AttachmentPostRequest request = new WrapperContainer.AttachmentPostRequest();
            request.serviceName = Constant.SERVICENOW_SERVICE;
            request.setEndpoint = 'https://instance.service-now.com/api/now/attachment/file';
            request.setContentType = 'image/jpeg';
            request.bodyBlob = Blob.valueOf('anotherbinarydata');
            Test.startTest();
            HttpResponse response = ApiUtility.httpPostAttachment(request);
            Test.stopTest();
            System.assertNotEquals(null, response, 'Response should not be null');
            System.assertEquals(200, response.getStatusCode(), 'Expected 200 response from mock for ServiceNow');
        }
    }

    /**
     * @description Tests httpPostAttachment() for Azure DevOps service with mock callout.
     */
   @IsTest
    static void testHttpPostAttachmentAzure() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            WrapperContainer.AttachmentPostRequest request = new WrapperContainer.AttachmentPostRequest();
            request.serviceName = Constant.AZURE_SERVICE;
            request.setEndpoint = 'https://dev.azure.com/org/project/_apis/wit/attachments';
            request.setContentType = 'application/pdf';
            request.bodyBlob = Blob.valueOf('pdfbinarydata');
            Test.startTest();
            HttpResponse response = ApiUtility.httpPostAttachment(request);
            Test.stopTest();
            System.assertNotEquals(null, response, 'Response should not be null');
            System.assertEquals(200, response.getStatusCode(), 'Expected 200 response from mock for Azure');
        }
    }


    /**
     * @description Tests httpPostAttachment() with an unsupported service name.
     *              Ensures that the method gracefully handles invalid inputs and returns null.
     */
     @IsTest
    static void testHttpPostAttachmentUnsupportedService() {
        User u = [SELECT Id FROM User WHERE Alias = 'stdusr' LIMIT 1];
        System.runAs(u) {
            WrapperContainer.AttachmentPostRequest request = new WrapperContainer.AttachmentPostRequest();
            request.serviceName = 'UNKNOWN_SERVICE';
            request.setEndpoint = 'https://example.com';
            request.setContentType = 'text/plain';
            request.bodyBlob = Blob.valueOf('data');
            HttpResponse response = ApiUtility.httpPostAttachment(request);
            System.assertEquals(null, response, 'Unsupported service should return null');
        }
    }
}