@isTest
public class SIS_JsonForProgrammeApplicationTest {
    @TestSetup
    public static void setUpDate(){
        // Create Campus
        List<RecordType> rt = new List<RecordType>();
        rt = [Select Id From RecordType Where DeveloperName = 'Campus_ID' LIMIT 1];
        
        Account account = new Account();
        account.RecordTypeId = rt[0].Id;
        account.Name = 'SISJ';
        insert account;
        
        //Create Account
        Account acc = new Account();
        acc.Name = 'testAcc';
        acc.Parent_NRIC_Passport_No__c = '154789654123';
        acc.Parent_Relationship_Father_Mother__c = 'Father';
        acc.Parent_Email_Address__c = 'testacc@gmail.com';
        insert acc;
        
        //Create Contact
        Contact con = new Contact();
        con.LastName = 'testCon';
        con.NRIC_Passport_No__c = '154789654123';
        con.Primary_Account__c = acc.Id;
        con.Email = 'testcon@gmail.com';
        insert con;
        
        //Create Student
        Student__c stud = new Student__c();
        stud.Name = 'testStud';
        stud.NRIC_Passport_No__c = '154578451215';
        stud.Date_of_Birth__c = Date.Today()-500;
        stud.Parent_Account__c = acc.Id;
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
        stud.Acknowledged_Date__c = date.Today()-1;
        stud.Campus_SFID__c = account.Id;
        insert stud;
        
        //Create Programme_Master__c
        Programme_Master__c proMaster = new Programme_Master__c();
        proMaster.Name = 'proName';
        proMaster.Programme_Code__c = 'SIS0012';
        proMaster.Programme_Duration__c = 12;
        proMaster.Level_of_Education__c = 'Primary';
        proMaster.Is_Offer__c = 'Yes';
        proMaster.Campus_SFID__c = account.Id;
        proMaster.Campus_Code__c = '159753';
        proMaster.Campus_Name__c = 'SISKL';
        proMaster.Campus_Location__c = 'Malaysia';
        proMaster.School_Code__c = '156321';
        insert proMaster;
        
        //Create Intake Master
        Intake_Master__c intMaster = new Intake_Master__c();
        intMaster.Intake_Number__c = '789456123';
        intMaster.Study_Mode__c = 'Online';
        intMaster.Course_Detail_Intake_ID__c = 123987;
        intMaster.Application_Allowed__c = 'YES';
        intMaster.Programme_Master__c = proMaster.Id;
        insert intMaster;
        
        //Create Programme_Application__c
        Programme_Application__c progApp = new Programme_Application__c();
        progApp.Offer_Status__c = 'Pending For Approval';
        progApp.Application_Type__c = 'NEW';
        progApp.Conditional_Code__c = 'codeTest';
        progApp.Student__c = stud.Id;
        progApp.Programme_Master__c = proMaster.Id;
        progApp.Intake_Master__c = intMaster.Id;
        insert progApp;
    }
    
    public class SIS_EMXHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('/auth/code')) {
                res.setStatusCode(200);
                res.setBody('{"code": "6626f9dc978f311fb71286bf3cf3251c"}');
            } else if (req.getEndpoint().contains('/auth/token')) {
                res.setStatusCode(200);
                res.setBody('{"access": "7a6cf334f796fa14920c35ee2b3b5f00"}');
            } else if (req.getEndpoint().contains('/crm')) {
                res.setStatusCode(200);
                res.setBody('{"transaction_id": "123456"}');
            }
            
            return res;
        }
    }
    
    @isTest
    public static void createJsonForProgrammeApplicationTest(){
        List<Programme_Application__c> progApp = [SELECT Id FROM Programme_Application__c WHERE Conditional_Code__c = 'codeTest' AND Application_Type__c = 'NEW' LIMIT 1];
        Test.startTest();
        SIS_JsonForProgrammeApplication.createJsonForProgrammeApplication(progApp);
        Test.setMock(HttpCalloutMock.class, new SIS_EMXHttpMock());
        Test.stopTest();
    }
    
    
}