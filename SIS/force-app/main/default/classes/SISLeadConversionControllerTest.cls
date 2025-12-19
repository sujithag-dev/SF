@isTest
public with sharing class SISLeadConversionControllerTest {
    @testSetup
    public static void setUpData(){
        //Create Parent Lead
        Parent_Lead__c pl = new Parent_Lead__c();
        pl.Name = 'TestParentLead';
        pl.Campus__c = 'SIS';
        pl.Email__c = 'test@gmail.com';
        pl.Mobile_Number_1__c = '1234567890';
        pl.Passport_IC__c = '112233445566';
        pl.Parent_Relationship__c = 'Father';
        insert pl;
        
        //Child Lead with parent lead
        Lead l = new Lead();
        l.LastName = 'testchildLead';
        l.Status = 'new';
        l.Date_of_Birth__c = Date.today()-1;
        l.Parent_Lead__c = pl.Id;
        l.Passport_IC__c = '123123123123';
        l.Application_For_Admissions_Form__c = true;
        l.Initial_Application_Fee__c = true;
        l.Supporting_Document_Submission__c = true;
        l.Post_Application_Received__c = true;
        insert l;
        
        Lead lead = new Lead();
        lead.LastName = 'testchildLead123';
        lead.Status = 'New';
        lead.Date_of_Birth__c = Date.today()-5;
        lead.Parent_Lead__c = pl.Id;
        lead.Passport_IC__c = '123123123125';
        lead.Application_For_Admissions_Form__c = true;
        lead.Initial_Application_Fee__c = true;
        lead.Supporting_Document_Submission__c = true;
        lead.Post_Application_Received__c = true;
        insert lead;
        
        //Create Account
        Account acc = new Account();
        acc.Name = 'TestName';
        acc.Parent_NRIC_Passport_No__c = '112233445566';
        acc.Parent_Relationship_Father_Mother__c = 'Father';
        insert acc;
        
        //Create Contact
        Contact con = new Contact();
        con.Primary_Account__c = acc.Id;
        con.LastName = 'TestConName';
        con.Primary_Contact__c = true;
        con.NRIC_Passport_No__c = '112233445566';
        insert con;
        
        //Child Lead with parent account
        Lead le = new Lead();
        le.LastName = 'testchildLead1';
        le.Status = 'new';
        le.Date_of_Birth__c = Date.today()-1;
        le.Parent_Account__c = acc.Id;
        le.Passport_IC__c = '123123123123';
        le.Application_For_Admissions_Form__c = true;
        le.Initial_Application_Fee__c = true;
        le.Supporting_Document_Submission__c = true;
        le.Post_Application_Received__c = true;
        le.Is_Duplicate_Student__c = true;
        insert le;
        
        //Child Lead for handleIsDuplicate
        
        Lead le1 = new Lead();
        le1.LastName = 'childLeadforDuplicateTrue';
        le1.Status = 'new';
        le1.Date_of_Birth__c = Date.today()-1;
        le1.Parent_Account__c = acc.Id;
        le1.Passport_IC__c = '123123123123';
        le1.Application_For_Admissions_Form__c = true;
        le1.Initial_Application_Fee__c = true;
        le1.Supporting_Document_Submission__c = true;
        le1.Post_Application_Received__c = true;
        le1.Is_Duplicate_Student__c = true;
        insert le1;
        
        Lead le2 = new Lead();
        le2.LastName = 'childLeadforDuplicateFalse';
        le2.Status = 'new';
        le2.Date_of_Birth__c = Date.today()-1;
        le2.Parent_Account__c = acc.Id;
        le2.Passport_IC__c = '123123123123';
        le2.Application_For_Admissions_Form__c = true;
        le2.Initial_Application_Fee__c = true;
        le2.Supporting_Document_Submission__c = true;
        le2.Post_Application_Received__c = true;
        le2.Is_Duplicate_Student__c = true;
        insert le2;
    }
    
    @isTest
    public static void getLeadConvertDetailsAndConvertLeadTest(){
        String leadIdwithPL = [SELECT Id FROM Lead WHERE Name = 'testchildLead' LIMIT 1].Id;
                
        Test.startTest();
        
        Map<String, Object> leadDetailswithPL = SISLeadConversionController.getLeadConvertDetails(leadIdwithPL);
        Map<String, Object> convertDetailswithPL = SISLeadConversionController.convertLead(leadIdwithPL);
        
        Test.stopTest();
    }
    
    @isTest
    public static void getLeadConvertDetailsAndConvertLeadTestForAcc(){
        String leadIdwithPA = [SELECT Id FROM Lead WHERE Name = 'testchildLead1' LIMIT 1].Id;
        String leadIdwithDuplicateTrue = [SELECT Id FROM Lead WHERE Name = 'childLeadforDuplicateTrue' LIMIT 1].Id;
        String leadIdwithDuplicateFalse = [SELECT Id FROM Lead WHERE Name = 'childLeadforDuplicateFalse' LIMIT 1].Id;
        Test.startTest();
        Map<String, Object> leadDetailswithPA = SISLeadConversionController.getLeadConvertDetails(leadIdwithPA);
        Map<String, Object> convertDetailswithPA = SISLeadConversionController.convertLead(leadIdwithPA);
        
        Map<String, Object> handleIsDuplicateTrue = SISLeadConversionController.handleIsDuplicate(leadIdwithDuplicateTrue);
        Map<String, Object> handleIsDuplicateFalse = SISLeadConversionController.handleIsDuplicate(leadIdwithDuplicateFalse);
        Test.stopTest();
    }
    
    
}