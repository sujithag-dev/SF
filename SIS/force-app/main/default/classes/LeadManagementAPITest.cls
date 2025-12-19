@IsTest
private class LeadManagementAPITest {
    
    @testSetup
    public static void setUpData(){
        // Create Campus
        List<RecordType> rt = new List<RecordType>();
        rt = [Select Id From RecordType Where DeveloperName = 'Campus_ID' LIMIT 1];
        
        Account account = new Account();
        account.RecordTypeId = rt[0].Id;
        account.Name = 'SISJ';
        insert account;
        
        //Create Parent Lead
        Parent_Lead__c pl = new Parent_Lead__c();
        pl.Name = 'testParentLead';
        pl.Campus__c = 'SIS';
        pl.Email__c = 'parentlead@gmail.com';
        pl.Mobile_Number_1__c = '1234567890';
        insert pl;
        
        //Create Parent Lead for update
        Parent_Lead__c plforUpdate = new Parent_Lead__c();
        plforUpdate.Name = 'testParentLead';
        plforUpdate.Campus__c = 'SIS';
        plforUpdate.Email__c = 'sam07200@gmail.com';
        plforUpdate.Mobile_Number_1__c = '9878093226';
        insert plforUpdate;
        
        //Create Child Lead
        Lead cl = new Lead();
        cl.LastName = 'testchildLead';
        cl.Date_of_Birth__c = date.today()-200;
        cl.Status = 'New';
        cl.Parent_Lead__c = pl.Id;
        insert cl;
        
        //Create Child Lead for update
        Lead clforUpdate = new Lead();
        clforUpdate.LastName = 'Anjali';
        clforUpdate.Date_of_Birth__c = Date.newInstance(2005,04,21);
        clforUpdate.Status = 'New';
        clforUpdate.Email='Anjali07@gmail.com';
        clforUpdate.Parent_Lead__c = plforUpdate.Id;
        clforUpdate.Mobile_Phone_1__c = '9943678161';
        insert clforUpdate;
        
        //Create Account
        Account acc = new Account();
        acc.Name = 'TestName';
        acc.Parent_NRIC_Passport_No__c = '112233445566';
        acc.Parent_Relationship_Father_Mother__c='Mother';
        acc.Parent_Email_Address__c='xyz@gmail.com';
        acc.Phone='60456183447';
        acc.Street__c='xyz';
        acc.City__c='xyz';
        acc.State__c='SYDNEY';
        acc.Country__c='MY';
        acc.Postcode__c='756532';
        insert acc;
        
        //Create Account for update
        Account accupdate = new Account();
        accupdate.Name = 'TestName';
        accupdate.Parent_Email_Address__c='arun1@gmail.com';
        accupdate.Parent_NRIC_Passport_No__c = '637977928989';
        accupdate.Parent_Relationship_Father_Mother__c = 'Mother';
        accupdate.Phone='61456183447';
        accupdate.Street__c='xyz';
        accupdate.City__c='xyz';
        accupdate.State__c='SYDNEY';
        accupdate.Country__c='MY';
        accupdate.Postcode__c='756532';
        insert accupdate;
        
        //Create Contact
        Contact con = new Contact();
        con.Primary_Account__c = acc.Id;
        con.LastName = 'TestConName';
        con.Primary_Contact__c = true;
        con.Email='abc@gmail.com';
        con.MobilePhone='61456183447';
        con.NRIC_Passport_No__c='551133667711';
        insert con;
        
        //Create Contact for update
        Contact conUpdate = new Contact();
        conUpdate.Primary_Account__c = accupdate.Id;
        conUpdate.LastName = 'TestConName';
        conUpdate.NRIC_Passport_No__c = '637977928989';
        conUpdate.Email = 'arun107@gmail.com';
        conUpdate.MobilePhone='8899066550';
        conUpdate.Primary_Contact__c = true;
        insert conUpdate;
        
        //Create Student
        Student__c stud = new Student__c();
        stud.Name = 'TestStudName';
        stud.Parent_Account__c = acc.Id;
        stud.NRIC_Passport_No__c = '994411778855';
        stud.Date_of_Birth__c = Date.today() - 100;
        insert stud;
        
        //Programme Master
        Programme_Master__c pMaster = new Programme_Master__c();
        pMaster.Name = 'TestPMaster';
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
        iMaster.Intake_Number__c = '789456123';
        iMaster.Study_Mode__c = 'Online';
        iMaster.Course_Detail_Intake_ID__c = 123987;
        iMaster.Application_Allowed__c = 'YES';
        iMaster.Programme_Master__c = pMaster.Id;
        insert iMaster;
    }
    
    @IsTest
    static void testCreateLead() {
        String pmName = [SELECT Name FROM Programme_Master__c WHERE Name = 'TestPMaster' LIMIT 1].Name;
        String imName = [SELECT Name FROM Intake_Master__c WHERE Intake_Number__c ='789456123' LIMIT 1].Name;
        
        Map<String, Object> parentMap = new Map<String, Object>();
        parentMap.put('parentCampus', 'MGR University');
        parentMap.put('parentRelationship', 'Mother');
        parentMap.put('parentLeadName', 'Samantha');
        parentMap.put('parentEmail', 'samantha@gmail.com');
        parentMap.put('parentDateofBirth', '2001-02-01');
        parentMap.put('parentMobileNumber1', '9189134567');
        parentMap.put('parentMobileNumber2', '9783491465');
        parentMap.put('parentMobileNumber3', '6589044667');
        parentMap.put('parentPreferredPhoneNumber', 'Mobile Phone 1');
        parentMap.put('parentPassportIC', '551133661111');
        //parentMap.put('parentCitizenship', 'Malaysian');
        parentMap.put('parentGender', 'FEMALE');
        parentMap.put('parentCity', 'Chennai');
        parentMap.put('parentStateProvince', 'SYDNEY');
        parentMap.put('parentCompany', 'MGR Company');
        parentMap.put('parentPhoneCompany', '1234222343');
        parentMap.put('parentStreet', 'Karaikal street');
        parentMap.put('parentPostcode', '632607');
        parentMap.put('parentCountry', 'MY');
        parentMap.put('parentPassportExpiry', '2028-02-22');
        parentMap.put('parentNationality','MY');
        
        Map<String, Object> childMap = new Map<String, Object>();
        childMap.put('childName', 'Vetri');
        childMap.put('childDateofBirth', '2005-04-21');
        childMap.put('childNationality', 'AD');
        childMap.put('childCitizenship', 'Malaysian');
        childMap.put('childPassportIC', '345365471234');
        childMap.put('childPassportExpiry', '2089-03-21');
        childMap.put('childEmail', 'Vetri@gmail.com');
        childMap.put('childMobilePhone1', '7128987654');
        childMap.put('childMobilePhone2', '7234563234');
        childMap.put('childMobilePhone3', '8234567895');
        childMap.put('childPreferredPhone', 'Mobile Phone 1');
        childMap.put('childProgramme', pmName);
        childMap.put('childIntake', imName);
        childMap.put('childVisa', 'DEPENDENT (EXPATRIATE/EMPLOYMENT)');
        childMap.put('childGender', 'MALE');
        childMap.put('childAccommodation', 'true');
        childMap.put('childBursary', 'true');
        childMap.put('childScholarship', 'true');
        childMap.put('childLeadStatus', 'NEW');
        childMap.put('childLostreason', '');
        childMap.put('childLeadSource', 'PHONE INQUIRY');
        childMap.put('childLeadRating', 'HOT');
        childMap.put('childPassportIssuefrom', 'MY');
        childMap.put('childCurrentSchool', 'SSC Mandhri Higher Secondary School');
        childMap.put('childCompletedGrade', 'Grade 3 / Year 3');
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('parentLead', parentMap);
        requestBodyMap.put('childLead', childMap);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        LeadManagementAPI.createLead();
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateLeadForUpdate(){
        String pmName = [SELECT Name FROM Programme_Master__c WHERE Name = 'TestPMaster' LIMIT 1].Name;
        String imName = [SELECT Name FROM Intake_Master__c WHERE Intake_Number__c ='789456123' LIMIT 1].Name;
        Map<String, Object> parentMap = new Map<String, Object>();
        parentMap.put('parentCampus', 'MGR University');
        parentMap.put('parentRelationship', 'Mother');
        parentMap.put('parentLeadName', 'Samantha');
        parentMap.put('parentEmail', 'sam07200@gmail.com');
        parentMap.put('parentDateofBirth', '2001-02-01');
        parentMap.put('parentMobileNumber1', '9878093226');
        parentMap.put('parentMobileNumber2', '9783491465');
        parentMap.put('parentMobileNumber3', '6589044667');
        parentMap.put('parentPreferredPhoneNumber', 'Mobile Phone 1');
        parentMap.put('parentPassportIC', '551133667755');
        parentMap.put('parentCitizenship', 'Malaysian');
        parentMap.put('parentGender', 'FEMALE');
        parentMap.put('parentCity', 'Chennai');
        parentMap.put('parentStateProvince', 'SYDNEY');
        parentMap.put('parentCompany', 'MGR Company');
        parentMap.put('parentPhoneCompany', '1234222343');
        parentMap.put('parentStreet', 'Karaikal street');
        parentMap.put('parentPostcode', '632607');
        parentMap.put('parentCountry', 'MY');
        parentMap.put('parentPassportExpiry', '2028-02-22');
        
        Map<String, Object> childMap = new Map<String, Object>();
        childMap.put('childName', 'Anjali');
        childMap.put('childDateofBirth', '2005-04-21');
        childMap.put('childNationality', 'AD');
        childMap.put('childCitizenship', 'Malaysian');
        childMap.put('childPassportIC', '794911166612');
        childMap.put('childPassportExpiry', '2089-03-21');
        childMap.put('childEmail', 'Anjali07@gmail.com');
        childMap.put('childMobilePhone1', '9943678161');
        childMap.put('childMobilePhone2', '7234563234');
        childMap.put('childMobilePhone3', '8234567895');
        childMap.put('childPreferredPhone', 'Mobile Phone 1');
        childMap.put('childProgramme', pmName);
        childMap.put('childIntake', imName);
        childMap.put('childVisa', 'DEPENDENT (EXPATRIATE/EMPLOYMENT)');
        childMap.put('childGender', 'FEMALE');
        childMap.put('childAccommodation', 'true');
        childMap.put('childBursary', 'true');
        childMap.put('childScholarship', 'true');
        childMap.put('childLeadStatus', 'LOST');
        childMap.put('childLostreason', 'UNWILLING TO DISCLOSE');
        childMap.put('childLeadSource', 'PHONE INQUIRY');
        childMap.put('childLeadRating', 'HOT');
        childMap.put('childPassportIssuefrom', 'MY');
        childMap.put('childCurrentSchool', 'SSC Mandhri Higher Secondary School');
        childMap.put('childCompletedGrade', 'Grade 3 / Year 3');
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('parentLead', parentMap);
        requestBodyMap.put('childLead', childMap);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        LeadManagementAPI.createLead();
        Test.stopTest();
    }
    
    @IsTest
    static void updateAccountAndStudent(){
        String pmName = [SELECT Name FROM Programme_Master__c WHERE Name = 'TestPMaster' LIMIT 1].Name;
        String imName = [SELECT Name FROM Intake_Master__c WHERE Intake_Number__c ='789456123' LIMIT 1].Name;
        Map<String, Object> parentMap = new Map<String, Object>();
        parentMap.put('parentCampus', 'MGR University');
        parentMap.put('parentRelationship', 'Mother');
        parentMap.put('parentLeadName', 'Arun');
        parentMap.put('parentEmail', 'arun107@gmail.com');
        parentMap.put('parentDateofBirth', '2002-02-01');
        parentMap.put('parentMobileNumber1', '8899066550');
        parentMap.put('parentMobileNumber2', '9783491465');
        parentMap.put('parentMobileNumber3', '6589044667');
        parentMap.put('parentPreferredPhoneNumber', 'Mobile Phone 1');
        parentMap.put('parentPassportIC', '637977928989');
        parentMap.put('parentCitizenship', 'Malaysian');
        parentMap.put('parentGender', 'FEMALE');
        parentMap.put('parentCity', 'Chennai');
        parentMap.put('parentStateProvince', 'SYDNEY');
        parentMap.put('parentCompany', 'MGR Company');
        parentMap.put('parentPhoneCompany', '1234222343');
        parentMap.put('parentStreet', 'Karaikal street');
        parentMap.put('parentPostcode', '632607');
        parentMap.put('parentCountry', 'MY');
        parentMap.put('parentPassportExpiry', '2028-02-22');
        
        Map<String, Object> childMap = new Map<String, Object>();
        childMap.put('childName', 'Ranjith');
        childMap.put('childDateofBirth', '2009-04-21');
        childMap.put('childNationality', 'AD');
        childMap.put('childCitizenship', 'Malaysian');
        childMap.put('childPassportIC', '994411778855');
        childMap.put('childPassportExpiry', '2089-03-21');
        childMap.put('childEmail', 'ranjith@gmail.com');
        childMap.put('childMobilePhone1', '4876189753');
        childMap.put('childMobilePhone2', '7234563234');
        childMap.put('childMobilePhone3', '8234567895');
        childMap.put('childPreferredPhone', 'Mobile Phone 1');
        childMap.put('childProgramme', pmName);
        childMap.put('childIntake', imName);
        childMap.put('childVisa', 'DEPENDENT (EXPATRIATE/EMPLOYMENT)');
        childMap.put('childGender', 'Male');
        childMap.put('childAccommodation', 'true');
        childMap.put('childBursary', 'true');
        childMap.put('childScholarship', 'true');
        childMap.put('childLeadStatus', 'New');
        childMap.put('childLostreason', '');
        childMap.put('childLeadSource', 'Tawk-to-chat');
        childMap.put('childLeadRating', 'Hot');
        childMap.put('childPassportIssuefrom', 'MY');
        childMap.put('childCurrentSchool', 'SSC Mandhri Higher Secondary School');
        childMap.put('childCompletedGrade', 'Grade 3 / Year 3');
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('parentLead', parentMap);
        requestBodyMap.put('childLead', childMap);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        LeadManagementAPI.createLead();
        Test.stopTest();
    }
    
    @IsTest
    static void missingField(){
        Map<String, Object> parentMap = new Map<String, Object>();
        parentMap.put('parentCampus', '');
        parentMap.put('parentRelationship', 'Mother');
        parentMap.put('parentLeadName', 'Arun');
        parentMap.put('parentEmail', '');
        parentMap.put('parentDateofBirth', '2002-02-01');
        parentMap.put('parentMobileNumber1', '');
        parentMap.put('parentMobileNumber2', '9783491465');
        parentMap.put('parentMobileNumber3', '6589044667');
        parentMap.put('parentPreferredPhoneNumber', 'Mobile Phone 1');
        parentMap.put('parentPassportIC', '');
        
        
        Map<String, Object> childMap = new Map<String, Object>();
        childMap.put('childName', '');
        childMap.put('childDateofBirth', '');
        childMap.put('childNationality', 'AD');
        childMap.put('childPassportIC', '');
        childMap.put('childEmail', '');
        childMap.put('childMobilePhone1', '');
        childMap.put('childPreferredPhone', 'Mobile Phone 1');
        childMap.put('childVisa', 'DEPENDENT (EXPATRIATE/EMPLOYMENT)');
        childMap.put('childGender', 'MALE');
        childMap.put('childLeadStatus', '');
        childMap.put('childLostreason', '');
        childMap.put('childLeadSource', 'Tawk-to-chat');
        childMap.put('childLeadRating', 'Hot');
        
        
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('parentLead', parentMap);
        requestBodyMap.put('childLead', childMap);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        LeadManagementAPI.createLead();
        Test.stopTest();
    }
    @IsTest
    static void missinFieldChild(){
        Map<String, Object> parentMap = new Map<String, Object>();
        parentMap.put('parentCampus', 'SISKL');
        parentMap.put('parentRelationship', 'Mother');
        parentMap.put('parentLeadName', 'abc');
        parentMap.put('parentEmail', 'abc07@gmail.com');
        parentMap.put('parentMobileNumber1', '5346536643');
        
        
        
        Map<String, Object> childMap = new Map<String, Object>();
        childMap.put('childName', '');
        childMap.put('childDateofBirth', '');
        childMap.put('childMobilePhone1', '');
        childMap.put('childLeadStatus', '');
        
        
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('parentLead', parentMap);
        requestBodyMap.put('childLead', childMap);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        LeadManagementAPI.createLead();
        Test.stopTest();
    }
    @IsTest
    static void coverMyException(){
        Map<String, Object> parentMap = new Map<String, Object>();
        parentMap.put('parentCampus', 'SISKL');
        parentMap.put('parentRelationship', 'Mother');
        parentMap.put('parentLeadName', 'abc');
        parentMap.put('parentEmail', 'abc07@gmail.com');
        parentMap.put('parentMobileNumber1', '5346536643');
        
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put('parentLead', parentMap);
        
        String requestBody = JSON.serialize(requestBodyMap);
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = res;
        LeadManagementAPI.createLead();
        Test.stopTest();
    }
}