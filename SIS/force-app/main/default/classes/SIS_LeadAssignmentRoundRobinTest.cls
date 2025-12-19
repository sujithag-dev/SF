@isTest
public with sharing class SIS_LeadAssignmentRoundRobinTest {
    @testSetup
    public static void setUpData() {
        // Create a test user to assign leads
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Admin' LIMIT 1];
        User testUser = new User();
        testUser.LastName = 'testuser';
        testUser.Alias = 'testuser';
        testUser.Email = 'testuserforroundrobin@example.com';
        testUser.UserName = uniqueUserName;
        testUser.ProfileId = p.Id;
        testUser.TimeZoneSidKey = 'Asia/Singapore';
        testUser.LocaleSidKey = 'en_SG';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.LanguageLocaleKey = 'en_US';
        
        insert testUser;
        
        
        //Create Parent Lead
        Parent_Lead__c pl = new Parent_Lead__c();
        pl.Name = 'TestParentLead1';
        pl.Campus__c = 'SIS';
        pl.Email__c = 'test12345test@gmail.com';
        pl.Mobile_Number_1__c = '4863257895';
        pl.Passport_IC__c = '112233445576';
        pl.Parent_Relationship__c = 'Father';
        insert pl;
        
        //Child Lead with parent lead
        Lead l = new Lead();
        l.LastName = 'testchildLead';
        l.Status = 'New';
        l.Date_of_Birth__c = Date.today()-1;
        l.Parent_Lead__c = pl.Id;
        l.Passport_IC__c = '123122121123';
        l.Nationality__c = 'MY';
        insert l;
        
        Lead le = new Lead();
        le.LastName = 'testchildLeadForNonCitizen';
        le.Status = 'New';
        le.Date_of_Birth__c = Date.today()-5;
        le.Parent_Lead__c = pl.Id;
        le.Passport_IC__c = '123222111123';
        le.Nationality__c = 'IN';
        insert le;
        
        SIS_LeadAssignmentRoundRobinTest.futureMethodForSetUpObjects();
    }
    
    @future
    public static void futureMethodForSetUpObjects(){
        User testUser = [SELECT Id FROM User WHERE LastName = 'testuser' LIMIT 1];
        
        RoundRobinSetting__c rrs = new RoundRobinSetting__c();
        rrs.Name = 'SIS_Lead Assignment For RR';
        rrs.Last_Assigned_Index__c = 5;
        
        insert rrs;
        
    }
    
    @isTest
    public static void assignLead(){
        List<Lead> leadListForMY = [SELECT Id, Nationality__c, FirstName, LastName FROM Lead WHERE LastName = 'testchildLead' LIMIT 1];
        List<Lead> leadListForNonMY = [SELECT Id, Nationality__c, FirstName, LastName FROM Lead WHERE LastName = 'testchildLeadForNonCitizen' LIMIT 1];
        Test.startTest();
        SIS_LeadAssignmentRoundRobin.assignLead(leadListForMY);
        SIS_LeadAssignmentRoundRobin.assignLead(leadListForNonMY);
        Test.stopTest();
    }
}