@isTest
public class StudentChangeHandlerTest {
    
    
    @testSetup
    public static void setUpData() {
        // Create Campus
        List<RecordType> rt = new List<RecordType>();
        rt = [Select Id From RecordType Where DeveloperName = 'Campus_ID' LIMIT 1];
        
        Account account = new Account();
        account.RecordTypeId = rt[0].Id;
        account.Name = 'SISJ';
        insert account;
        
        Account acc = new Account();
        acc.Name = 'TestName';
        acc.Parent_NRIC_Passport_No__c = '112233445566';
        acc.Parent_Relationship_Father_Mother__c='Mother';
        insert acc;
        
        Student__c std = new Student__c(
            Allow_Duplicate__c = false,
            Name = 'Henry',
            NRIC_Passport_No__c = '487586985487',
            Marital_Status__c='SINGLE',
            Parent_Account__c = acc.Id,
            Date_of_Birth__c = Date.today().addYears(-25),
            Nationality__c = 'MY',
            Gender__c = 'MALE',
            Religion__c = 'HINDU',
            Street_m__c = 'abc street',
            Country_m__c = 'MY',
            Street_p__c = 'abc street',
            Country_p__c = 'MY',
            Acknowledged_Date__c = date.Today()-1,
            Lead_Source__c = 'KAKAOTALK',
            Postcode_m__c = '12345',
            State_m__c = 'SELANGOR',
            State_p__c = 'SELANGOR',
            Postcode_p__c = '12345',
            Race__c = 'OTHERS',
            Campus_SFID__c = account.Id
        );
        insert std;
        
        //Programme Master
        Programme_Master__c pMaster = new Programme_Master__c();
        pMaster.Name = 'TesTPM';
        pMaster.Programme_Code__c = '123';
        pMaster.Programme_Duration__c = 12;
        pMaster.Level_of_Education__c = 'Primary';
        pMaster.Is_Offer__c = 'y';
        pMaster.Campus_SFID__c = account.Id;
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
        
        // Programme Application
        Programme_Application__c pa = new Programme_Application__c();
        pa.EMX_ID__c = '1234';
        pa.Offer_Status__c = 'Pending For Approval';
        pa.Student__c = std.Id;
        pa.Programme_Master__c = pMaster.Id;
        pa.Intake_Master__c = iMaster.Id;
        pa.Application_Type__c = 'NEW';
        
        insert pa;        
        
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
    public static void updateStudentFields() {
        Test.setMock(HttpCalloutMock.class, new SIS_EMXHttpMock());
        Student__c insertedRecord = [
            SELECT Id, Name, Allow_Duplicate__c,Marital_Status__c, Date_of_Birth__c, NRIC_Passport_No__c, CreatedDate, LastModifiedDate, SystemModstamp
            FROM Student__c
            WHERE Name = 'Henry'
            LIMIT 1
        ];
        
        insertedRecord.Marital_Status__c = 'Married';
        
        Test.startTest();
        update insertedRecord;
        StudentChangeHandler.processStudentChanges(
            new List<Student__c>{ insertedRecord },
            new Map<Id, Student__c>{ insertedRecord.Id => insertedRecord }
        );
        Test.stopTest();
        
    }
    
    @isTest
    public static void updatedAccountFields(){
        Test.setMock(HttpCalloutMock.class, new SIS_EMXHttpMock());
        Account insertedAcc = [Select Id,Name,Parent_Relationship_Father_Mother__c,Parent_Contact_Telephone__c ,Phone ,
                               Parent_Email_Address__c,Country__c,State__c,City__c,Postcode__c,Street__c,Parent_NRIC_Passport_No__c from Account where
                               Name = 'TestName' limit 1];
        insertedAcc.Parent_Relationship_Father_Mother__c='Father';
        
        Test.startTest();
        update insertedAcc;
        StudentChangeHandler.processAccountChanges(
            new List<Account>{ insertedAcc },
            new Map<Id, Account>{ insertedAcc.Id => insertedAcc }
        );
        Test.stopTest();
    }
    
    
}