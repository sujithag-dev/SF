/**
 * @description       : Test class for DeleteBugTrackingRecordsBatch and related scheduled batch.
 *                      Ensures that Bug_Tracking__c records with old statuses are deleted correctly
 *                      and scheduled batch executes without errors.
 * author             : Minuscule Technologies
 * @group             : Integration Tests
 * @last modified on  : 09-10-2025
 * @last modified by  : 
**/
@IsTest
public class DeleteBugTrackingRecordsBatchTest {
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
     * @description Helper method to provide a mock list of closed/resolved statuses for deletion.
     * @return List<String> : List of bug statuses eligible for deletion
     */
    private static List<String> getMockStatusList() {
        return new List<String>{'Closed', 'Resolved'};
    }

    /**
     * @description Test setup method to create sample Bug_Tracking__c records with various types and statuses.
     *              Also sets CreatedDate to 7 months in the past to match deletion criteria.
     */
     @TestSetup
     static void setupTestData() {
        User u = createTestUser();
        System.runAs(u) {
        Date pastDate = Date.today().addMonths(-7);
        List<Bug_Tracking__c> bugs = new List<Bug_Tracking__c>{
            new Bug_Tracking__c(Bug_Type__c='Jira', Status__c='Closed'),
            new Bug_Tracking__c(Bug_Type__c='Azure', Status__c='Resolved'),
            new Bug_Tracking__c(Bug_Type__c='Service Now', Status__c='Closed')
        };
        insert bugs;
        for (Bug_Tracking__c b : [SELECT Id FROM Bug_Tracking__c WHERE Id IN :bugs]) {
            Test.setCreatedDate(b.Id, pastDate);
        }
        insert new Bug_Tracking__c(Bug_Type__c='Jira', Status__c='Open');
    }
}


    /**
     * @description Tests the batch class DeleteBugTrackingRecordsBatch with a mock status list.
     *              Verifies that all eligible Bug_Tracking__c records older than 6 months are deleted.
     */
   @IsTest
    static void testBatchDeleteWithMockStatus() {
        User u = createTestUser();
        System.runAs(u) {
            Test.startTest();
            DeleteBugTrackingRecordsBatch batchJob = new DeleteBugTrackingRecordsBatch(getMockStatusList());
            Database.executeBatch(batchJob, 200);
            Test.stopTest();
            Integer remaining = [SELECT COUNT() FROM Bug_Tracking__c WHERE Status__c IN :getMockStatusList()];
            System.assertEquals(0, remaining, 'All bugs with mock statuses older than 6 months should be deleted');
        }
    }

    /**
     * @description Tests that the scheduled batch scheduleDeleteBugTrackingRecordsBatch executes successfully.
     *              Uses a far future cron expression to simulate scheduled execution.
     */
     @IsTest
    static void testScheduledBatchWithMockStatus() {
        User u = createTestUser();
        System.runAs(u) {
            Test.startTest();   
            scheduleDeleteBugTrackingRecordsBatch schedJob = new scheduleDeleteBugTrackingRecordsBatch();
            System.schedule('Test Scheduled Delete', '0 0 0 1 1 ? 2099', schedJob);
            Test.stopTest();
            System.assert(true, 'Scheduled batch executed without exceptions');
        }
    }

    /**
     * @description Mock class for Jira project status callout returning projects with "Bug" issue type.
     */
    private class JiraProjectStatusMock implements HttpCalloutMock {
       /**
       * @description Mocks a successful response containing a "Bug" issue type.
       * @param req The simulated HTTP request.
       * @return HttpResponse The mock response.
       */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"name":"Bug"},{"name":"Task"}]');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    /**
     * @description Mock class for Jira project status callout returning projects without "Bug" issue type.
     */
    private class JiraProjectStatusNoBugMock implements HttpCalloutMock {
        /**
        * @description Mocks a successful response without any "Bug" issue type.
        * @param req The simulated HTTP request.
        * @return HttpResponse The mock response.
        */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"name":"Task"},{"name":"Story"}]');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    /**
     * @description Mock class for Jira project status callout returning HTTP 500 error.
     */
    private class JiraProjectStatusErrorMock implements HttpCalloutMock {
       /**
       * @description Mocks an HTTP 500 Internal Server Error response.
       * @param req The simulated HTTP request.
       * @return HttpResponse The mock error response.
       */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500); 
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    /**
     * @description Validates that parseJiraProjects includes only projects with Bug issue type.
     */
   @IsTest
    static void testParseJiraProjectsWithBug() {
        User u = createTestUser();
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new JiraProjectStatusMock());
            String jiraJson = '{ "values": [ { "key": "PROJ1", "name": "Project One" } ] }';
            Test.startTest(); 
            Map<String, String> result = ProjectParser.parseJiraProjects(jiraJson);
            Test.stopTest();
            System.assertEquals(1, result.size(), 'Project should be included since it has Bug issue type');
            System.assertEquals('PROJ1', result.get('Project One'), 'Project key should match');
        }
    }

    /**
     * @description Validates that parseJiraProjects excludes projects without Bug issue type.
     */
   @IsTest
    static void testParseJiraProjectsWithoutBug() {
        User u = createTestUser();
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new JiraProjectStatusNoBugMock());
            String jiraJson = '{ "values": [ { "key": "PROJ3", "name": "Project Three" } ] }';
            Test.startTest();  
            Map<String, String> result = ProjectParser.parseJiraProjects(jiraJson);
            Test.stopTest();
            System.assertEquals(0, result.size(), 'Project should be excluded since no Bug issue type exists');
        }
    }

    /**
     * @description Ensures parseJiraProjects returns empty map for empty values array.
     */
   @IsTest
    static void testParseJiraProjectsEmptyValues() {
        User u = createTestUser();
        System.runAs(u) {
            String jiraJson = '{ "values": [] }';
            Map<String, String> result = ProjectParser.parseJiraProjects(jiraJson);
           System.assertEquals(0, result.size(), 'Empty values array should return empty map');
        }
    }
    /**
     * @description Ensures parseJiraProjects handles HTTP 500 error responses gracefully.
     */
  @IsTest
    static void testParseJiraProjectsWithCalloutError() {
        User u = createTestUser();
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new JiraProjectStatusErrorMock());
            String jiraJson = '{ "values": [ { "key": "PROJ_ERROR", "name": "Error Project" } ] }';
            Test.startTest();
            Map<String, String> result = ProjectParser.parseJiraProjects(jiraJson);
            Test.stopTest();
           System.assertEquals(0, result.size(), 'Project should be excluded due to callout error');
        }
    }
    /**
     * @description Ensures parseJiraProjects handles JSON without "values" key safely.
     */
     @IsTest
    static void testParseJiraProjectsWithEmptyValues() {
        User u = createTestUser();
        System.runAs(u) {
            String jiraJson = '{ "foo": "bar" }';
            Test.startTest();
            Map<String, String> result = ProjectParser.parseJiraProjects(jiraJson);
            Test.stopTest();
            System.assertEquals(0, result.size(), 'Should return empty map when "values" key is missing');
        }
    }
    /**
     * @description Ensures parseAzureProjects correctly parses Azure project JSON.
     */
      @IsTest
    static void testParseAzureProjects() {
        User u = createTestUser();
        System.runAs(u) {
            String azureJson = '{"value":[{"id":"123","name":"AzureProj1"},{"id":"456","name":"AzureProj2"}]}';
            Map<String, String> result = ProjectParser.parseAzureProjects(azureJson);
            System.assertEquals(2, result.size(), 'Azure projects count should be 2');
            System.assertEquals('123', result.get('AzureProj1'), 'AzureProj1 should have ID 123');
            System.assertEquals('456', result.get('AzureProj2'), 'AzureProj2 should have ID 456');
        }
    }

    /**
     * @description Ensures parseAzureProjects returns empty map for empty value array.
     */
     @IsTest
    static void testParseAzureProjectsEmpty() {
        User u = createTestUser();
        System.runAs(u) {
            String azureJson = '{"value":[]}';
            Map<String, String> result = ProjectParser.parseAzureProjects(azureJson);
            System.assertEquals(0, result.size(), 'Empty value array should return empty map');
        }
    }
    /**
     * @description Tests that invalid Jira JSON throws CustomException.
     */
     @IsTest
    static void testParseJiraProjectsInvalidJson() {
        User u = createTestUser();
        System.runAs(u) {
            String invalidJson = 'invalid json';
            try {
                ProjectParser.parseJiraProjects(invalidJson);
                System.assert(false, 'Expected exception for invalid JSON');
            } catch (CustomException e) {
                System.assert(e.getMessage().contains('Error parsing Jira projects'), 'CustomException should be thrown');
            }
        }
    }
    
     /**
     * @description Tests that a simple paragraph block is converted to <p> HTML correctly.
     */
   @IsTest
    static void testProcessParagraphBlock() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> block = new Map<String, Object>{
                'type' => 'paragraph',
                'content' => new List<Object>{
                    new Map<String, Object>{ 'type' => 'text', 'text' => 'Hello World' }
                }
            };
            String html = JiraDescriptionParser.processBlockHtml(block);
            System.assertEquals('<p>Hello World</p>', html, 'Paragraph block should render correctly');
        }
    }

    
    /**
     * @description Tests that a bullet list block is converted to <ul><li> HTML correctly.
     */
   @IsTest
    static void testProcessBulletListBlock() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> block = new Map<String, Object>{
                'type' => 'bulletList',
                'content' => new List<Object>{
                    new Map<String, Object>{ 'type' => 'paragraph', 'content' => new List<Object>{
                        new Map<String, Object>{ 'type' => 'text', 'text' => 'Item 1' }
                    }},
                    new Map<String, Object>{ 'type' => 'paragraph', 'content' => new List<Object>{
                        new Map<String, Object>{ 'type' => 'text', 'text' => 'Item 2' }
                    }}
                }
            };
            String html = JiraDescriptionParser.processBlockHtml(block);
            System.assertEquals('<ul><li>Item 1</li><li>Item 2</li></ul>', html, 'Bullet list should render correctly');
        }
    }

    
    /**
     * @description Tests that an ordered list block is converted to <ol><li> HTML correctly.
     */
    @IsTest
    static void testProcessOrderedListBlock() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> block = new Map<String, Object>{
                'type' => 'orderedList',
                'content' => new List<Object>{
                    new Map<String, Object>{ 'type' => 'paragraph', 'content' => new List<Object>{
                        new Map<String, Object>{ 'type' => 'text', 'text' => 'Step 1' }
                    }},
                    new Map<String, Object>{ 'type' => 'paragraph', 'content' => new List<Object>{
                        new Map<String, Object>{ 'type' => 'text', 'text' => 'Step 2' }
                    }}
                }
            };
            String html = JiraDescriptionParser.processBlockHtml(block);
            System.assertEquals('<ol><li>Step 1</li><li>Step 2</li></ol>', html, 'Ordered list should render correctly');
        }
    }

      /**
     * @description Tests that a code block is rendered as <pre><code> HTML correctly.
     */
     @IsTest
    static void testProcessCodeBlock() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> block = new Map<String, Object>{
                'type' => 'codeBlock',
                'content' => new List<Object>{
                    new Map<String, Object>{ 'type' => 'text', 'text' => 'System.debug(\'Hello\');' }
                }
            };
            String html = JiraDescriptionParser.processBlockHtml(block);
            System.assertEquals('<pre><code>System.debug(\'Hello\');</code></pre>', html, 'Code block should render correctly');
        }
    }

     /**
     * @description Tests that a mediaSingle block is rendered with fallback text for media correctly.
     */
    @IsTest
    static void testProcessMediaSingleBlock() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> block = new Map<String, Object>{
                'type' => 'mediaSingle',
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'media',
                        'attrs' => new Map<String, Object>{ 'alt' => 'Image 1' }
                    }
                }
            };
            String html = JiraDescriptionParser.processBlockHtml(block);
            System.assertEquals('<p>[Media: Image 1]</p>', html, 'MediaSingle block should render correctly');
        }
    }

    /**
     * @description Tests that an unsupported block type falls back to rendering plain text correctly.
     */
   @IsTest
    static void testProcessFallbackBlock() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> block = new Map<String, Object>{
                'type' => 'unsupportedBlock',
                'content' => new List<Object>{
                    new Map<String, Object>{ 'type' => 'text', 'text' => 'Fallback text' }
                }
            };
            String html = JiraDescriptionParser.processBlockHtml(block);
            System.assertEquals('Fallback text', html, 'Fallback block should render content as plain text');
        }
    }


   /**
     * @description Tests rendering of inline marks (bold, italic), hard breaks, mentions, emoji, and links.
     * Ensures combined inline formatting is handled correctly within a paragraph block.
     */
   @IsTest
    static void testInlineMarksAndSpecials() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> block = new Map<String, Object>{
                'type' => 'paragraph',
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'text',
                        'text' => 'BoldText',
                        'marks' => new List<Object>{ new Map<String, Object>{ 'type' => 'strong' } }
                    },
                    new Map<String, Object>{
                        'type' => 'text',
                        'text' => 'ItalicText',
                        'marks' => new List<Object>{ new Map<String, Object>{ 'type' => 'em' } }
                    },
                    new Map<String, Object>{ 'type' => 'hardBreak' },
                    new Map<String, Object>{
                        'type' => 'mention',
                        'attrs' => new Map<String, Object>{ 'text' => '@User' }
                    },
                    new Map<String, Object>{
                        'type' => 'emoji',
                        'attrs' => new Map<String, Object>{ 'text' => '😊' }
                    },
                    new Map<String, Object>{
                        'type' => 'link',
                        'text' => 'Google',
                        'attrs' => new Map<String, Object>{ 'href' => 'https://google.com' }
                    }
                }
            };
            String html = JiraDescriptionParser.processBlockHtml(block);
            String expected = '<p><b>BoldText</b><i>ItalicText</i><br/>@User😊<a href="https://google.com">Google</a></p>';
            System.assertEquals(expected, html, 'Inline marks, mentions, emoji, and links should render correctly');
        }
    }

    /**
     * @description Tests that passing null or an empty block to processBlockHtml() returns an empty string.
     */
     @IsTest
    static void testEmptyBlockOrNull() {
        User u = createTestUser();
        System.runAs(u) {
            System.assertEquals('', JiraDescriptionParser.processBlockHtml(null), 'Null block should return empty string');
            System.assertEquals('', JiraDescriptionParser.processBlockHtml(new Map<String,Object>()), 'Empty block should return empty string');
        }
    }

    /**
     * @description Tests advanced inline handling, including:
     *                  - Fallback rendering of unsupported nested content
     *                  - TextColor mark rendering with <span> and inline style
     *                  - Link block fallback when 'text' property is missing, using 'href' as link text
     */
    @IsTest
    static void testInlineItemFallbackTextColorAndLinkWithoutText() {
        User u = createTestUser();
        System.runAs(u) {
            Map<String, Object> nestedBlock = new Map<String, Object>{
                'content' => new List<Object>{
                    new Map<String, Object>{ 'type' => 'text', 'text' => 'Nested' }
                }
            };
            String fallbackHtml = JiraDescriptionParser.processBlockHtml(new Map<String, Object>{
                'type' => 'unsupportedBlock',
                'content' => new List<Object>{ nestedBlock }
            });
            System.assertEquals('Nested', fallbackHtml, 'Fallback block should render nested content');

            Map<String, Object> blockWithColor = new Map<String, Object>{
                'type' => 'paragraph',
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'text',
                        'text' => 'ColoredText',
                        'marks' => new List<Object>{ new Map<String, Object>{
                            'type' => 'textColor',
                            'attrs' => new Map<String, Object>{ 'color' => 'red' }
                        }}
                    }
                }
            };
            String colorHtml = JiraDescriptionParser.processBlockHtml(blockWithColor);
            System.assertEquals('<p><span style="color:red">ColoredText</span></p>', colorHtml, 'TextColor mark should render span with style');

            Map<String, Object> blockWithLink = new Map<String, Object>{
                'type' => 'paragraph',
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'link',
                        'attrs' => new Map<String, Object>{ 'href' => 'https://example.com' }
                    }
                }
            };
            String linkHtml = JiraDescriptionParser.processBlockHtml(blockWithLink);
            System.assertEquals('<p><a href="https://example.com">https://example.com</a></p>', linkHtml, 'Link without text should use href as link text');
        }
    }
}