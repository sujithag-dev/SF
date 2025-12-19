@isTest
public with sharing class SISProgrammeAndIntakeMasterHandlerTest {
    @testSetup
    public static void setUpData(){
        // Create Campus
        List<RecordType> rt = new List<RecordType>();
        rt = [Select Id From RecordType Where DeveloperName = 'Campus_ID' LIMIT 1];
        
        Account acc = new Account();
        acc.RecordTypeId = rt[0].Id;
        acc.Name = 'SISJ';
        insert acc;
        
        //Programme Master
        Programme_Master__c pMaster = new Programme_Master__c();
        pMaster.Name = 'TesTPM';
        pMaster.Programme_Code__c = '123';
        pMaster.Programme_Duration__c = 12;
        pMaster.Level_of_Education__c = 'Primary';
        pMaster.Is_Offer__c = 'y';
        pMaster.Campus_SFID__c = acc.Id;
        pMaster.Campus_Code__c = 'SIS123';
        pMaster.Campus_Name__c = 'SIS';
        pMaster.Campus_Location__c = 'malaysia';
        pMaster.School_Code__c = 'SIS789';
        insert pMaster;
        
        //Intake Master
        Intake_Master__c iMaster = new Intake_Master__c();
        iMaster.Programme_Master__c = pMaster.Id;
        iMaster.EMX_ID__c = '159159';
        iMaster.Intake_Number__c = '789456123';
        iMaster.Study_Mode__c = 'Online';
        iMaster.Course_Detail_Intake_ID__c = 123987;
        iMaster.Application_Allowed__c = 'YES';
        insert iMaster;
    }
    
    @isTest
    public static void handleProgrammeAndIntakeMasterTestWithoutSFID(){
        Account acc = [Select Id From Account Where RecordType.DeveloperName = 'Campus_ID' LIMIT 1];
            
        Map<String, Object> programmeMaster = new Map<String, Object>();
        programmeMaster.put('CRMProgrammeMasterID', '');
        programmeMaster.put('EMXID', '24680');
        programmeMaster.put('programCode', 'SCISY10');
        programmeMaster.put('programmeName', 'India International after Validate PM');
        programmeMaster.put('programmeDuration', '10');
        programmeMaster.put('levelOfEducation', 'Secondary School');
        programmeMaster.put('isOffer', 'Y');
        programmeMaster.put('CRMCampusID', acc.Id);
        programmeMaster.put('campusCode', 'SISCKL');
        programmeMaster.put('campusName', 'Sunway City International School');
        programmeMaster.put('campusLocation', 'Sunway City');
        programmeMaster.put('schoolCode', 'SCIS');
        programmeMaster.put('schoolName', 'school name');
        programmeMaster.put('departmentName', 'department name');
        programmeMaster.put('departmentCode', 'department code');
        
        Map<String, Object> intakeMasterItem = new Map<String, Object>();
        intakeMasterItem.put('CRMIntakeMasterID', '');
        intakeMasterItem.put('EMXID', '13579');
        intakeMasterItem.put('intakeNumber', '555555');
        intakeMasterItem.put('studyMode', 'Online');
        intakeMasterItem.put('courseDetailIntakeID', '55555');
        intakeMasterItem.put('applicationAllowed', 'YES');
        intakeMasterItem.put('CRMProgrammeMasterID', '');
        
        List<Map<String, Object>> intakeMasterList = new List<Map<String, Object>>();
        intakeMasterList.add(intakeMasterItem);
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('programmeMaster', programmeMaster);
        requestBodyMap.put('intakeMaster', intakeMasterList);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        // Mocking request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        SISProgrammeAndIntakeMasterHandler.handleProgrammeAndIntakeMaster();
        Test.stopTest();
    }
    
    @isTest
    public static void handleProgrammeAndIntakeMasterTestWithSFID(){
        String pm = [SELECT Id FROM Programme_Master__c WHERE Name = 'TesTPM' LIMIT 1].Id;
        String im = [SELECT Id FROM Intake_Master__c WHERE EMX_ID__c = '159159' LIMIT 1].Id;
        Account acc = [Select Id From Account Where RecordType.DeveloperName = 'Campus_ID' LIMIT 1];
        
        Map<String, Object> programmeMaster = new Map<String, Object>();
        programmeMaster.put('CRMProgrammeMasterID', pm);
        programmeMaster.put('EMXID', '24680');
        programmeMaster.put('programCode', 'SCISY10');
        programmeMaster.put('programmeName', 'India International after Validate PM');
        programmeMaster.put('programmeDuration', '10');
        programmeMaster.put('levelOfEducation', 'Secondary School');
        programmeMaster.put('isOffer', 'Y');
        programmeMaster.put('CRMCampusID', acc.Id);
        programmeMaster.put('campusCode', 'SISCKL');
        programmeMaster.put('campusName', 'Sunway City International School');
        programmeMaster.put('campusLocation', 'Sunway City');
        programmeMaster.put('schoolCode', 'SCIS');
        programmeMaster.put('schoolName', 'school name');
        programmeMaster.put('departmentName', 'department name');
        programmeMaster.put('departmentCode', 'department code');
        
        Map<String, Object> intakeMasterItem = new Map<String, Object>();
        intakeMasterItem.put('CRMIntakeMasterID', im);
        intakeMasterItem.put('EMXID', '13579');
        intakeMasterItem.put('intakeNumber', '555555');
        intakeMasterItem.put('studyMode', 'Online');
        intakeMasterItem.put('courseDetailIntakeID', '55555');
        intakeMasterItem.put('applicationAllowed', 'YES');
        intakeMasterItem.put('CRMProgrammeMasterID', pm);
        
        List<Map<String, Object>> intakeMasterList = new List<Map<String, Object>>();
        intakeMasterList.add(intakeMasterItem);
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('programmeMaster', programmeMaster);
        requestBodyMap.put('intakeMaster', intakeMasterList);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        // Mocking request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        SISProgrammeAndIntakeMasterHandler.handleProgrammeAndIntakeMaster();
        Test.stopTest();
    }
    
    
    @isTest
    public static void missingFieldInProgramMaster(){
        String pm = [SELECT Id FROM Programme_Master__c WHERE Name = 'TesTPM' LIMIT 1].Id;
        String im = [SELECT Id FROM Intake_Master__c WHERE EMX_ID__c = '159159' LIMIT 1].Id;
        
        Map<String, Object> programmeMaster = new Map<String, Object>();
        programmeMaster.put('CRMProgrammeMasterID', pm);
        programmeMaster.put('EMXID', '24680');
        programmeMaster.put('programCode', '');
        programmeMaster.put('programmeName', '');
        programmeMaster.put('programmeDuration', '');
        programmeMaster.put('levelOfEducation', '');
        programmeMaster.put('isOffer', '');
        programmeMaster.put('CRMCampusID', '');
        programmeMaster.put('campusCode', '');
        programmeMaster.put('campusName', '');
        programmeMaster.put('campusLocation', 'Sunway City');
        programmeMaster.put('schoolCode', '');
        programmeMaster.put('schoolName', '');
    
        
        Map<String, Object> intakeMasterItem = new Map<String, Object>();
        intakeMasterItem.put('CRMIntakeMasterID', im);
        intakeMasterItem.put('EMXID', '13579');
        intakeMasterItem.put('intakeNumber', '555555');
        intakeMasterItem.put('studyMode', 'Online');
        intakeMasterItem.put('courseDetailIntakeID', '55555');
        intakeMasterItem.put('applicationAllowed', 'YES');
        intakeMasterItem.put('CRMProgrammeMasterID', pm);
        
        List<Map<String, Object>> intakeMasterList = new List<Map<String, Object>>();
        intakeMasterList.add(intakeMasterItem);
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('programmeMaster', programmeMaster);
        requestBodyMap.put('intakeMaster', intakeMasterList);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        // Mocking request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        SISProgrammeAndIntakeMasterHandler.handleProgrammeAndIntakeMaster();
        Test.stopTest();
    }
    
}