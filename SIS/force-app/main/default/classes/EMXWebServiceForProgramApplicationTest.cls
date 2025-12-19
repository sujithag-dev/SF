@isTest
public class EMXWebServiceForProgramApplicationTest {
    @testSetup
    public static void setUpData(){
        // Create Campus
        List<RecordType> rt = new List<RecordType>();
        rt = [Select Id From RecordType Where DeveloperName = 'Campus_ID' LIMIT 1];
        
        Account account = new Account();
        account.RecordTypeId = rt[0].Id;
        account.Name = 'SISJ';
        insert account;
        
        // Parent Account
        Account acc = new Account();
        acc.Name = 'TestName';
        acc.Parent_NRIC_Passport_No__c = '112233445566';
        acc.Parent_Relationship_Father_Mother__c = 'Mother';
        acc.Parent_Email_Address__c = 'xyz@gmail.com';
        acc.Phone = '60456183447';
        acc.Street__c = 'xyz';
        acc.City__c = 'xyz';
        acc.State__c = 'SYDNEY';
        acc.Country__c = 'MY';
        acc.Postcode__c = '756532';
        
        insert acc;
        
        
        // Parent Contact
        Contact con = new Contact();
        con.Primary_Account__c = acc.Id;
        con.LastName = 'TestConName';
        con.Primary_Contact__c = true;
        con.NRIC_Passport_No__c = '0829172';
        con.Email = 'abc@gmail.com';
        con.MobilePhone = '61456183447';
        
        insert con;
        
        
        // Student
        Student__c stud = new Student__c();
        stud.Name = 'TestStudent';
        stud.Parent_Account__c = acc.Id;
        stud.EMX_ID__c = '9874';
        stud.NRIC_Passport_No__c = '789456980765';
        stud.Date_of_Birth__c = Date.today() - 100;
        stud.Primary_Contact__c = con.Id;
        stud.Nationality__c = 'MY';
        stud.Gender__c = 'MALE';
        stud.Marital_Status__c = 'Single';
        stud.Religion__c = 'HINDU';
        stud.State_m__c = 'SELANGOR';
        stud.Country_m__c = 'MY';
        stud.Street_m__c = 'abc street';
        stud.Postcode_m__c = '12345';
        stud.State_p__c = 'SELANGOR';
        stud.Country_p__c = 'MY';
        stud.Street_p__c = 'abc street';
        stud.Postcode_p__c = '12345';
        stud.Race__c = 'OTHERS';
        stud.Lead_Source__c = 'KAKAOTALK';
        stud.Acknowledged_Date__c = Date.today() - 1;
        stud.Campus_SFID__c = account.Id;
        
        insert stud;
        
        
        // Programme Master
        Programme_Master__c pm = new Programme_Master__c();
        pm.EMX_ID__c = '4561';
        pm.Name = 'Testpm';
        pm.Programme_Code__c = '1111';
        pm.Programme_Duration__c = 12;
        pm.Level_of_Education__c = 'Primary';
        pm.Is_Offer__c = 'y';
        pm.Campus_SFID__c = account.Id;
        pm.Campus_Code__c = '8520';
        pm.Campus_Name__c = 'SISKL';
        pm.Campus_Location__c = 'Malaysia';
        pm.School_Code__c = '156321';
        
        insert pm;
        
        // Intake Master
        Intake_Master__c im = new Intake_Master__c();
        im.EMX_ID__c = '7532';
        im.Programme_Master__c = pm.Id;
        im.Intake_Number__c = '789456123';
        im.Study_Mode__c = 'Online';
        im.Course_Detail_Intake_ID__c = 123987;
        im.Application_Allowed__c = 'YES';
        
        insert im;
        
        
        // Programme Application
        Programme_Application__c pa = new Programme_Application__c();
        pa.EMX_ID__c = '1234';
        pa.Offer_Status__c = 'Pending For Approval';
        pa.Student__c = stud.Id;
        pa.Programme_Master__c = pm.Id;
        pa.Intake_Master__c = im.Id;
        pa.Application_Type__c = 'NEW';
        
        insert pa;
        
    }
    
    @isTest
    public static void testUpdateProgramApplication(){
        
        Programme_Application__c pa = [SELECT Id FROM Programme_Application__c LIMIT 1];
        Student__c stud = [SELECT Id FROM Student__c LIMIT 1];
        Programme_Master__c pm = [SELECT Id FROM Programme_Master__c LIMIT 1];
        Intake_Master__c im = [SELECT Id FROM Intake_Master__c LIMIT 1];
        
        
        Map<String, Object> programApplication = new Map<String, Object>();
        programApplication.put('eMXID', '7782');
        programApplication.put('CRMProgramApplicationID', pa.Id);
        programApplication.put('offerStatus', 'Cancelled');
        programApplication.put('conditionalCode', '31d32');
        programApplication.put('offerLetterPrintedDate', '2025-02-15');
        programApplication.put('acceptanceDate', '2025-01-15');
        programApplication.put('immigrationPassType', 'Online');
        programApplication.put('immigrationPassExpiryDate', null);
        programApplication.put('immigrationPassInstitutionName', 'jSP');
        programApplication.put('CRMStudentID', stud.Id);
        programApplication.put('CRMProgrammeMasterID', pm.Id);
        programApplication.put('CRMIntakeMasterID', im.Id);
        
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('programApplication', programApplication);
        
        
        String requestBody = JSON.serialize(requestBodyMap);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        EMXWebServiceForProgramApplication.updateProgramApplication();
        Test.stopTest();
    }
    
    @isTest
    public static void testUpdateProgramApplicationWithWrongIMId(){
        
        Programme_Application__c pa = [SELECT Id FROM Programme_Application__c LIMIT 1];
        Student__c stud = [SELECT Id FROM Student__c LIMIT 1];
        Programme_Master__c pm = [SELECT Id FROM Programme_Master__c LIMIT 1];
        Intake_Master__c im = [SELECT Id FROM Intake_Master__c LIMIT 1];
        
        
        Map<String, Object> programApplication = new Map<String, Object>();
        programApplication.put('eMXID', '7782');
        programApplication.put('CRMProgramApplicationID', pa.Id);
        programApplication.put('offerStatus', 'Cancelled');
        programApplication.put('conditionalCode', '31d32');
        programApplication.put('offerLetterPrintedDate', '2025-02-15');
        programApplication.put('acceptanceDate', '2025-01-15');
        programApplication.put('immigrationPassType', 'Online');
        programApplication.put('immigrationPassExpiryDate', null);
        programApplication.put('immigrationPassInstitutionName', 'jSP');
        programApplication.put('CRMStudentID', stud.Id);
        programApplication.put('CRMProgrammeMasterID', pm.Id);
        programApplication.put('CRMIntakeMasterID', 'X' + String.valueOf(pm.Id).substring(1));
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('programApplication', programApplication);
        
        
        String requestBody = JSON.serialize(requestBodyMap);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        EMXWebServiceForProgramApplication.updateProgramApplication();
        Test.stopTest();
    }
    
    @isTest
    public static void testMissingFieldsProgramApplication(){
        
        Programme_Application__c pa = [SELECT Id FROM Programme_Application__c LIMIT 1];
        Student__c stud = [SELECT Id FROM Student__c LIMIT 1];
        Programme_Master__c pm = [SELECT Id FROM Programme_Master__c LIMIT 1];
        Intake_Master__c im = [SELECT Id FROM Intake_Master__c LIMIT 1];
        
        
        Map<String, Object> programApplication = new Map<String, Object>();
        programApplication.put('eMXID', '7782');
        programApplication.put('CRMProgramApplicationID', pa.Id);
        programApplication.put('offerStatus', 'Cancelled');
        programApplication.put('conditionalCode', '31d32');
        programApplication.put('offerLetterPrintedDate', '2025-02-15');
        programApplication.put('acceptanceDate', '2025-01-15');
        programApplication.put('immigrationPassType', 'Online');
        programApplication.put('immigrationPassExpiryDate', null);
        programApplication.put('immigrationPassInstitutionName', 'jSP');
        programApplication.put('CRMStudentID', '');
        programApplication.put('CRMProgrammeMasterID', pm.Id);
        programApplication.put('CRMIntakeMasterID', '');
        
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('programApplication', programApplication);
        
        
        String requestBody = JSON.serialize(requestBodyMap);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        EMXWebServiceForProgramApplication.updateProgramApplication();
        Test.stopTest();    
    }
    
    @isTest
    public static void testMissingIntakeFieldsProgramApplication(){
        
        Student__c stud = [SELECT Id FROM Student__c LIMIT 1];
        Programme_Master__c pm = [SELECT Id FROM Programme_Master__c LIMIT 1];
        
        Map<String, Object> programApplication = new Map<String, Object>();
        programApplication.put('eMXID', '7782');
        programApplication.put('CRMProgramApplicationID', '');
        programApplication.put('offerStatus', 'Cancelled');
        programApplication.put('conditionalCode', '31d32');
        programApplication.put('offerLetterPrintedDate', '2025-02-15');
        programApplication.put('acceptanceDate', '2025-01-15');
        programApplication.put('immigrationPassType', 'Online');
        programApplication.put('immigrationPassExpiryDate', null);
        programApplication.put('immigrationPassInstitutionName', 'jSP');
        programApplication.put('CRMStudentID', stud.Id);
        programApplication.put('CRMProgrammeMasterID', pm.Id);
        programApplication.put('CRMIntakeMasterID', '');
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('programApplication', programApplication);
        
        String requestBody = JSON.serialize(requestBodyMap);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        EMXWebServiceForProgramApplication.updateProgramApplication();
        Test.stopTest();    
    }
    
    
}