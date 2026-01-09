/**
* @description       : Test class for AdminController, ProjectFieldService, and ExternalUserIntegrationService.
*                      Ensures coverage for HTTP callouts, exception handling, and response validation.
* @author            : Minuscule Technologies
* @last modified on  : 10-10-2025
* @last modified by  :
*/
/**
* @description Test class for AdminController and related service/handler classes.
* This test class covers  ProjectFieldService,ExternalUserIntegrationService.
*
*/
@isTest
public class ServiceIntegrationHandlerTest {
    
    /**
* @description Reusable messages for assertions to improve readability and maintain PMD compliance.
* MSG_RESULT_NOT_NULL       : Used when verifying that a returned object or result is not null.
* MSG_EXPECT_SUCCESS_TRUE   : Used when expecting a ResultMessage.success field to be true.
* MSG_EXPECT_SUCCESS_FALSE  : Used when expecting a ResultMessage.success field to be false.
* MSG_EXPECT_ERROR_MESSAGE  : Used when asserting that an error message is returned or not null.
*/
    private static final String MSG_RESULT_NOT_NULL = 'Result should not be null';
    private static final String MSG_EXPECT_SUCCESS_TRUE = 'Expected success to be true';
    private static final String MSG_EXPECT_SUCCESS_FALSE = 'Expected success to be false';
    private static final String MSG_EXPECT_ERROR_MESSAGE = 'Expected an error message';
    
    
    /**
* @description Creates a test User record used by multiple test methods.
* @return User The newly created test User record.
*/
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser' + System.currentTimeMillis() + '@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }
    
    /**
* @description Creates a reusable HTTP callout mock instance for test methods.
*              Helps reduce duplication when mocking HTTP responses.
* @param body The response body to return from the mock callout.
* @param statusMsg The HTTP status message to simulate.
* @param statusCode The HTTP status code to simulate.
* @return An instance of HttpCalloutMock that can be passed to Test.setMock().
*/
    private static HttpCalloutMock makeMock(String body, String statusMsg, Integer statusCode) {
        return new Mock_AdminController(body, statusMsg, statusCode);
    }
    
    
    /**
* @description Mock implementation for HTTP callouts used across many tests.
*/
    public class Mock_AdminController implements HttpCalloutMock {  
        private String body;
        private String statusMsg;
        private Integer statusCode;
        private Boolean throwException = false;
        
        /**
* @description Constructor for Mock_AdminController that initializes a mock HTTP response.
* @param body The response body to return from the mock callout.
* @param statusMsg The HTTP status message to simulate.
* @param statusCode The HTTP status code to simulate.
*/
        public Mock_AdminController(String body, String statusMsg, Integer statusCode) {
            this.body = body;
            this.statusMsg = statusMsg;
            this.statusCode = statusCode;
        }
        
        /**
* @description Sets whether this mock should throw an exception when called.
* @param flag Boolean value indicating if the mock should throw an exception.
*             Set to true to simulate a callout failure, false to allow normal response.
* @return Mock_AdminController Returns the current instance for method chaining.
*/  
        public Mock_AdminController setThrowException(Boolean flag) {
            this.throwException = flag;
            return this;
        }
        
        
        
        /**
* @description Enables exception throwing for the mock instance.
*/
        public void enableException() {
            this.throwException = true;
        }
        
        /**
* @description Generates a mock HTTP response for testing callouts.
* @param req The HTTP request object being mocked (not used in this implementation).
* @return HttpResponse The simulated HTTP response based on the initialized fields.
* @throws CalloutException if throwException is true to simulate failure.
*/
        public HTTPResponse respond(HTTPRequest req) {
            if (throwException) {
                throw new CalloutException('Simulated callout failure');
            }
            HttpResponse res = new HttpResponse();
            if (this.statusCode != null) {
                res.setStatusCode(this.statusCode);
            }
            if (this.body != null) {
                res.setBody(this.body);
            }
            if (this.statusMsg != null) {
                res.setStatus(this.statusMsg);
            }
            res.setHeader('Content-Type', Constant.CONTENT_TYPE_JSON_UTF8);
            return res;
        }          
    }
    
    /**
* @description Test positive scenarios for ProjectFieldService.projFieldsList() with Jira, Azure, and ServiceNow services.
*/
    @isTest
    static void testProjFieldsListPositive() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, makeMock('{"someJiraField": "value"}','OK',200));
            ResultMessage resultJira = ProjectFieldService.projFieldsList('projKey', Constant.JIRA_SERVICE);
            
            Test.setMock(HttpCalloutMock.class, makeMock('{"someAzureField": "value"}','OK',200));
            ResultMessage resultAzure = ProjectFieldService.projFieldsList('projKey', Constant.AZURE_SERVICE);
            
            Test.setMock(HttpCalloutMock.class, makeMock('{"someServiceNowField": "value"}','OK',200));
            ResultMessage resultServiceNow = ProjectFieldService.projFieldsList('projKey', Constant.SERVICENOW_SERVICE);
            Test.stopTest();
            
            System.assert(resultJira.success, MSG_EXPECT_SUCCESS_TRUE);
            System.assert(resultAzure.success, MSG_EXPECT_SUCCESS_TRUE);
            System.assert(resultServiceNow.success, MSG_EXPECT_SUCCESS_TRUE);
        }
    }
    
    /**
* @description Test negative scenarios for ProjectFieldService.projFieldsList() with invalid inputs.
*/
    @isTest
    static void testProjFieldsListNegative() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, makeMock('{"someField": "value"}','Bad Request',400));
            
            Test.startTest();
            ResultMessage resultInvalid  = ProjectFieldService.projFieldsList('projKey', 'InvalidService');  
            ResultMessage resultInvalid2 = ProjectFieldService.projFieldsList(null, Constant.JIRA_SERVICE);
            ResultMessage resultInvalid3 = ProjectFieldService.projFieldsList('', Constant.SERVICENOW_SERVICE);  
            Test.stopTest();
            
            System.assert(!resultInvalid.success, MSG_EXPECT_SUCCESS_FALSE);
            System.assert(!resultInvalid2.success, MSG_EXPECT_SUCCESS_FALSE);
            System.assert(!resultInvalid3.success, MSG_EXPECT_SUCCESS_FALSE);
        }
    }
    
    /**
* @description Test exception handling in ProjectFieldService.projFieldsList() when callout throws an error.
*/
    @isTest
    static void testProjFieldsListCatchBlock() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Mock_AdminController mock = new Mock_AdminController('', 'Internal Server Error', 500);
            mock.enableException();
            Test.setMock(HttpCalloutMock.class, mock);
            
            Test.startTest();
            ResultMessage result = ProjectFieldService.projFieldsList('TEST_KEY', 'Jira');
            Test.stopTest();
            
            System.assert(!result.success, MSG_EXPECT_SUCCESS_FALSE);
            System.assertNotEquals(null, result.message, MSG_EXPECT_ERROR_MESSAGE);
        }
    }
    
    /**
* @description Test success scenario for fetching Jira users list.
*/
    @isTest
    static void testGetJiraUsersList() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String mockResponse = '[{"name":"User1","email":"user1@example.com"},{"name":"User2","email":"user2@example.com"}]';    
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'OK',200));
            
            Test.startTest();
            ResultMessage result = ExternalUserIntegrationService.getJiraUsersList();
            Test.stopTest();
            
            System.assert(result.success, MSG_EXPECT_SUCCESS_TRUE);
        }
    }
    
    /**
* @description Test failure scenario for getJiraUsersList() when API returns an error.
*/
    @isTest
    static void testGetJiraUsersListError() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, makeMock('','Bad Request',404));
            
            Test.startTest();
            ResultMessage result = ExternalUserIntegrationService.getJiraUsersList();
            Test.stopTest();
            System.assert(!result.success, MSG_EXPECT_SUCCESS_FALSE);
        }
    }
    
    /**
* @description Test handling for Jira user list API non-200 response scenario.
*/
    @isTest
    static void testGetJiraUsersListException() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String mockResponse = '[{"name":"User1","email":"user1@example.com"}]';    
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'Bad Request',404));
            
            Test.startTest();
            ResultMessage result = ExternalUserIntegrationService.getJiraUsersList();
            Test.stopTest();
            System.assert(!result.success, MSG_EXPECT_SUCCESS_FALSE);
            System.assertEquals('Failed to fetch Jira users. Status code: 404', result.message, 'Expected error message to indicate failure');
        }
    }
    
    
    /**
* @description Test ServiceNow lookup API success scenario.
*/
    @isTest
    static void testServiceNowLookupSuccess() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String mockResponse = '{"result":[{"sys_id":"assigned_to_sys_id","name":"assigned_to_name"}]}';    
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'OK',200));
            
            Test.startTest();      
            ResultMessage result1 = ExternalUserIntegrationService.serviceNowLookup('assigned_to');
            Test.stopTest();
            System.assertNotEquals(null, result1, MSG_RESULT_NOT_NULL);
            System.assert(result1.success, MSG_EXPECT_SUCCESS_TRUE);
        }
    }
    
    /**
* @description Test ServiceNow lookup API failure or invalid input scenario.
*/
    @isTest
    static void testServiceNowLookupFail() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String mockResponse = '';      
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'Bad Request',400));
            
            Test.startTest();    
            try {
                ResultMessage result = ExternalUserIntegrationService.serviceNowLookup('');
                System.assert(!result.success, MSG_EXPECT_SUCCESS_FALSE);
            }
            catch (Exception e) {
                System.assertEquals('Invalid fieldName: ', e.getMessage(), 'Incorrect exception message');
            }
            Test.stopTest();
        }
    }
    
    /**
* @description Test Azure Teams API success scenario.
*/
    @isTest
    static void testGetAzureTeamsSuccess() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String projectId = '737d18ca-bff9-4b7f-ba8b-429d33ea3cee';
            String mockResponse = '{"id":"'+projectId+'","name":"Azure Issue Template Team"}';
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'OK',200));
            Test.startTest();
            ResultMessage result = ExternalUserIntegrationService.getAzureTeams(projectId);
            Test.stopTest();
            System.assertNotEquals(null, result, MSG_RESULT_NOT_NULL);
            System.assert((result.success == true) || (result.message != null), 'Either success=true or an explanatory message expected');
        }
    }
    
    /**
* @description Test Azure Teams API when projectId is null.
*/
    @isTest
    static void testGetAzureTeamsNoProject() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String projectId = null;
            String mockResponse = '{"value":[]}';
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'Bad Request',500));
            Test.startTest();
            try {
                ResultMessage teamMembers = ExternalUserIntegrationService.getAzureTeams(projectId);
                System.assertNotEquals(null, teamMembers, 'Expected non-null result for null projectId');
                System.assertEquals('Project ID is null.', teamMembers.message, 'Expected error message to indicate failure');
            } catch (Exception e) {
                System.assertEquals('No Projects found or response is invalid.', e.getMessage(), 'Incorrect exception message');
            }
            Test.stopTest();
        }
    }
    
    /**
* @description Test Azure Teams API when no teams found.
*/
    @isTest
    static void testGetAzureTeamsNoTeams() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String projectId = 'sampleProjectId';
            String mockResponse = '{"value":[]}';
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'Bad Request',500));
            Test.startTest();
            try {
                ResultMessage teamMembers = ExternalUserIntegrationService.getAzureTeams(projectId);
                System.assertNotEquals(null, teamMembers, 'Expected result object even when no teams exist');
            } catch (Exception e) {
                System.assertEquals('No teams found or response is invalid.', e.getMessage(), 'Incorrect exception message');
            }
            Test.stopTest();
        }
    }
    
    /**
* @description Test Azure Team Members API success scenario.
*/
    @isTest
    static void testGetAzureTeamMembersSuccess() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String mockResponse = '{"value":[{"identity":{"displayName":"User 1","uniqueName":"user1@example.com"}},{"identity":{"displayName":"User 2","uniqueName":"user2@example.com"}}]}';
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'OK',200));      
            
            Test.startTest();
            List<String> teamId = new List<String>{'teamId1', 'teamId2'};
                Map<String,String> result = ExternalUserIntegrationService.getAzureTeamMembers(teamId,'projectId');
            Test.stopTest();
            System.assertNotEquals(null, result, 'Expected result to be not null');
            System.assert(result.size() > 0, 'Expected at least one team member mapping returned');
        }
    }
    
    /**
* @description Test Azure Team Members API failure scenario.
*/
    @isTest
    static void testGetAzureTeamMembersFailure() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            String mockResponse = '{"value":[{"identity":{"displayName":"User 1","uniqueName":"user1@example.com"}}]}';
            Test.setMock(HttpCalloutMock.class, makeMock(mockResponse,'Bad Request',500));  
            
            Test.startTest();
            try {
                List<String> teamId = new List<String>{};
                    Map<String,String> result = ExternalUserIntegrationService.getAzureTeamMembers(teamId,'projectId');
                System.assertNotEquals(null, result, 'Expected result not to be null even for bad response');
            }
            catch (Exception e) {
                System.assertEquals('Failed to fetch team members for team ID: team1. Status code: 500', e.getMessage(), 'Incorrect exception message');
            }
            Test.stopTest();
        }
    }
    
    /**
* @description Verifies that ExternalUserIntegrationService.getAzureTeamMembers()
*              handles HTTP callout exceptions gracefully and returns or throws as expected.
*/
    @isTest
    static void testGetAzureTeamMembersException() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            Mock_AdminController mock = new Mock_AdminController('', 'Bad Request', 500).setThrowException(true);
            Test.setMock(HttpCalloutMock.class, mock);
            
            Map<String, String> result;
            Test.startTest();
            try {
                List<String> teamId = new List<String>{ 'team1', 'team2' };
                    result = ExternalUserIntegrationService.getAzureTeamMembers(teamId, 'projectId');
                System.assertNotEquals(null, result, 'Expected result not to be null');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Expected a meaningful exception message');
            }
            Test.stopTest();
        }
    }
    
    /**
* @description Validates that the Identity wrapper correctly stores
*                displayName and uniqueName values.
*/
    @isTest
    static void testIdentitySuccess() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            WrapperContainer.Identity identity = new WrapperContainer.Identity();
            identity.displayName = 'Test User';
            identity.uniqueName = 'test@example.com';
            
            System.assertEquals('Test User', identity.displayName, 'Display name should match');
            System.assertEquals('test@example.com', identity.uniqueName, 'Unique name should match');
        }
    }
    
    /**
* @description
* Tests the internal structure of Incidentwrapper to ensure that
* columns and their associated choices are properly mapped in the result object.
*/
    @isTest
    static void testIncidentWrapperStructure() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            WrapperContainer.Choice choice = new WrapperContainer.Choice();
            choice.label = 'High Priority';
            choice.value = 'high';
            choice.name = 'HIGH';
            choice.reference = true;
            
            WrapperContainer.Column column = new WrapperContainer.Column();
            column.filterable = true;
            column.label = 'Priority';
            column.mandatory = true;
            column.defaults = 'Normal';
            column.readOnly = false;
            column.name = 'priority';
            column.columnType = 'choice';
            column.choices = new List<WrapperContainer.Choice>{ choice };
                
                WrapperContainer.Result result = new WrapperContainer.Result();
            result.columns = new Map<String, WrapperContainer.Column>{
                'priority' => column
                    };
                        
                        WrapperContainer.Incidentwrapper incidentWrapper = new WrapperContainer.Incidentwrapper();
            incidentWrapper.result = result;
            
            System.assertNotEquals(null, incidentWrapper.result, 'Incident wrapper result should not be null');
            System.assertEquals(1, incidentWrapper.result.columns.size(), 'Expected single column in incident wrapper result');
            
            WrapperContainer.Column testColumn = incidentWrapper.result.columns.get('priority');
            System.assertEquals('Priority', testColumn.label, 'Column label mismatch');
            System.assertEquals('choice', testColumn.columnType, 'Column type mismatch');
            System.assertEquals(1, testColumn.choices.size(), 'Choices size mismatch');
            
            WrapperContainer.Choice testChoice = testColumn.choices[0];
            System.assertEquals('High Priority', testChoice.label, 'Choice label mismatch');
            System.assertEquals('high', testChoice.value, 'Choice value mismatch');
            System.assertEquals(true, testChoice.reference, 'Choice reference flag mismatch');
        }
    }
    
    /**
* @description
* Tests the structure of AzureWrapper and FieldDetails inside WrapperContainer.
* Ensures all assigned values and list contents are preserved correctly.
*/
    @isTest
    static void testAzureWrapperStructure() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            WrapperContainer.FieldDetails field = new WrapperContainer.FieldDetails();
            field.defaultValue = 'Open';
            field.allowedValues = new List<String>{ 'Open', 'In Progress', 'Closed' };
                field.helpText = 'Status of the work item';
            field.alwaysRequired = true;
            field.referenceName = 'System.State';
            field.name = 'State';
            
            WrapperContainer.AzureWrapper azureWrapper = new WrapperContainer.AzureWrapper();
            azureWrapper.count = 1;
            azureWrapper.value = new List<WrapperContainer.FieldDetails>{ field };
                
                System.assertEquals(1, azureWrapper.count, 'Azure wrapper count mismatch');
            System.assertNotEquals(null, azureWrapper.value, 'Azure wrapper value must not be null');
            System.assertEquals(1, azureWrapper.value.size(), 'Azure wrapper value size mismatch');
            
            WrapperContainer.FieldDetails testField = azureWrapper.value[0];
            System.assertEquals('Open', testField.defaultValue, 'Field default value mismatch');
            System.assertEquals('State', testField.name, 'Field name mismatch');
            System.assertEquals('System.State', testField.referenceName, 'Field reference name mismatch');
            System.assertEquals(true, testField.alwaysRequired, 'Field required flag mismatch');
            System.assertEquals(3, testField.allowedValues.size(), 'Allowed values size mismatch');
            System.assertEquals('Status of the work item', testField.helpText, 'Field helpText mismatch');
        }
    }
    
    /**
* @description
* Validates that TicketRequest.validate() throws the correct exception when
* required fields like templateId or response are missing.
*/
    @isTest
    static void testValidateMissingFields() {
        User testUser = createTestUser();
        System.runAs(testUser) {
            WrapperContainer.TicketRequest missingTemplate = new WrapperContainer.TicketRequest();
            missingTemplate.response = '{"status":"ok"}';
            
            try {
                missingTemplate.validate();
                System.assert(false, 'Expected exception for missing templateId');
            } catch (IllegalArgumentException e) {
                System.assertEquals(
                    'templateId and response are required',
                    e.getMessage(),
                    'Validate missing fields exception message mismatch'
                );
            }
        }
    }
    
}