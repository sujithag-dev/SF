@isTest
public with sharing class EMXWebServiceForStudentTest {
    @testSetup
    public static void setUpData(){
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
        
        //Create Student
        Student__c stud = new Student__c();
        stud.Name = 'TestStudName';
        stud.Parent_Account__c = acc.Id;
        stud.NRIC_Passport_No__c = '123789';
        stud.Date_of_Birth__c = Date.today() - 100;
        insert stud;
    }
    
    @isTest
    public static void updateStudentTest(){
        String accId = [SELECT Id FROM Account WHERE Name = 'TestName' LIMIT 1].Id;
        String conId = [SELECT Id FROM Contact WHERE Name = 'TestConName' LIMIT 1].Id;
        String studId = [SELECT Id FROM Student__c WHERE Name = 'TestStudName' LIMIT 1].Id;
        
        Map<String, Object> studentMap = new Map<String, Object>();
        studentMap.put('CRMStudentID', studId);
        studentMap.put('studentUID', 'abcd1234');
        studentMap.put('EMXID', 'abcdef123456');
        studentMap.put('name', 'Sanjai');
        studentMap.put('preferredName', 'Sanjai B');
        studentMap.put('nricOrPassportNo', '123456789012');
        studentMap.put('passportExpiryDate', '2026-03-26');
        studentMap.put('dateOfBirth', '2001-03-26');
        studentMap.put('nationality', 'IN');
        studentMap.put('citizenship', 'Malaysian');
        studentMap.put('gender', 'Male');
        studentMap.put('maritalStatus', 'Single');
        studentMap.put('race', 'Others');
        studentMap.put('religion', 'Hindu');
        studentMap.put('studentMobileNo', '9988776655');
        studentMap.put('emailAddress', 'sanjai@gmail.com');
        studentMap.put('mailingStreet', 'abc street');
        studentMap.put('mailingPostCode', '636636');
        studentMap.put('mailingCity', 'Malaysia');
        studentMap.put('mailingState', 'SELANGOR');
        studentMap.put('mailingCountry', 'MY');
        studentMap.put('mailingConTelNo', '3366554488');
        studentMap.put('permanentStreet', 'abc street');
        studentMap.put('permanentPostCode', '636636');
        studentMap.put('permanentCity', 'Malaysia');
        studentMap.put('permanentState', 'SELANGOR');
        studentMap.put('permanentCountry', 'MY');
        studentMap.put('permanentConTelNo', '3366554488');
        studentMap.put('CRMHouseholdID', accId);
        
        // Create outer map
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('student', studentMap);
        
        // Serialize the full map
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        // Mocking request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        EMXWebServiceForStudent.updateStudent();
        
        Test.stopTest();
    }
    
    @isTest
    public static void coverException(){
        String accId = [SELECT Id FROM Account WHERE Name = 'TestName' LIMIT 1].Id;
        String conId = [SELECT Id FROM Contact WHERE Name = 'TestConName' LIMIT 1].Id;
        String studId = [SELECT Id FROM Student__c WHERE Name = 'TestStudName' LIMIT 1].Id;
        
        Map<String, Object> studentMap = new Map<String, Object>(); 
        studentMap.put('name', 'Sanjai');
        studentMap.put('nricOrPassportNo', '123456789012');
        studentMap.put('dateOfBirth', '2001-03-26');
        
        // Create outer map
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('student', studentMap);
        
        // Serialize the full map
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        // Mocking request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        EMXWebServiceForStudent.updateStudent();
        
        Test.stopTest();
    }
   
}