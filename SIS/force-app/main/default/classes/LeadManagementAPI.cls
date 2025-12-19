@RestResource(urlMapping='/Lead/*')
global class LeadManagementAPI {
    
    public class ParentLeadException extends Exception {}
    public class ChildLeadException extends Exception {}
    public class MyException extends Exception {}
    
    @HttpPost
    global static void createLead() {
        Savepoint sp = Database.setSavepoint();
        
        Map<string,object> resultMsg = new Map<string,object>();
        Map<string,Map<string,object>> resultMap = new Map<string,Map<string,object>>();  
        RestResponse res = RestContext.response;
        System.debug('res---'+ res);
        RestRequest req = RestContext.request;
        
        
        try{
            Id parentLeadId;
            Id parentAccountId;
            Boolean isParentCreated = false;
            String ParentLeadEmail;
            
            if (req == null || req.requestBody == null) {
                throw new MyException('Invalid request: No request body found.');
            }
            
            String requestBody = req.requestBody.toString();
            System.debug('Request Body: ' + requestBody);
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            System.debug('Parsed Request Map: ' + requestMap);
            
            if (!requestMap.containsKey('parentLead') || !requestMap.containsKey('childLead')){
                throw new MyException('Both Parent Lead and Child Lead must be provided together');
            }
            
            
            
            if(requestMap.containsKey('parentLead')){
                String parentLeadJson = JSON.serialize(requestMap.get('parentLead'));
                LeadWrapperContainer.parentLead WrapParent = (LeadWrapperContainer.parentLead) JSON.deserialize(parentLeadJson, LeadWrapperContainer.parentLead.class);
                
                //Required Fields 
                List<String> missingFields = new List<String>();
                if (String.isBlank(WrapParent.parentCampus)) missingFields.add('parentCampus');
                if (String.isBlank(WrapParent.ParentLeadName)) missingFields.add('ParentLeadName');
                if (String.isBlank(WrapParent.parentEmail)) missingFields.add('parentEmail');
                if (String.isBlank(WrapParent.parentMobileNumber1)) missingFields.add('parentMobileNumber1');
                //if (String.isBlank(WrapParent.parentPassportIC)) missingFields.add('parentPassportIC');
                if (String.isBlank(WrapParent.parentRelationship)) missingFields.add('parentRelationship');
                
                
                if (!missingFields.isEmpty()) {
                    throw new ParentLeadException('The required field(s) are missing in the parent lead: ' + String.join(missingFields, ', '));
                }
                
                
                Boolean valueFound = false;
                ParentLeadEmail = WrapParent.parentEmail;
                
                Map<String, String> dateFields = new Map<String, String>();
                if (String.isNotBlank(WrapParent.ParentPassportExpiry)) {
                    dateFields.put('ParentPassportExpiry', WrapParent.ParentPassportExpiry);
                }
                
                if (String.isNotBlank(WrapParent.parentDateofBirth)) {
                    dateFields.put('parentDateofBirth', WrapParent.parentDateofBirth);
                }
                
                for (String fieldName : dateFields.keySet()) {
                    String dateValue = dateFields.get(fieldName);
                    if (String.isNotBlank(dateValue) && !Pattern.matches('^\\d{4}-\\d{1,2}-\\d{1,2}$', dateValue)) {
                        throw new ParentLeadException('Invalid Date Format for ' + fieldName + '. Please enter yyyy-MM-dd format.');
                    }
                }
                
                //MobileNumber Validation
                Map<String, String> phoneFields = new Map<String, String>{
                    'parentMobileNumber1' => WrapParent.parentMobileNumber1,
                        'parentMobileNumber2' => WrapParent.parentMobileNumber2,
                        'parentMobileNumber3' => WrapParent.parentMobileNumber3,
                        'parentPhoneCompany' => WrapParent.parentPhoneCompany
                        };
                            
                            List<String> invalidFields = new List<String>();
                
                for (String fieldName : phoneFields.keySet()) {
                    String value = phoneFields.get(fieldName);
                    if (String.isNotBlank(value) && !Pattern.matches('^\\+?[0-9]{10,12}$', value)) {
                        invalidFields.add(fieldName);
                    }
                }
                
                if (!invalidFields.isEmpty()) {
                    throw new ParentLeadException('Enter a valid number with 10 to 12 digits. ' + String.join(invalidFields, ', '));
                }
                
                
                
                
                if (String.isNotBlank(WrapParent.parentPassportIC)) {
                    
                    String AccountAndContactstatus='';
                    
                    if (!valueFound) {
                        List<Account> accData = [
                            SELECT Id, Name, Parent_NRIC_Passport_No__c, Parent_Relationship_Father_Mother__c, 
                            Parent_Occupation__c, Parent_Contact_Telephone__c, Phone, Parent_Email_Address__c, 
                            Street__c, City__c, State__c, Postcode__c, Country__c
                            FROM Account 
                            WHERE Parent_NRIC_Passport_No__c = :WrapParent.parentPassportIC 
                            LIMIT 1
                        ];
                        
                        if (!accData.isEmpty()) { 
                            Account parentAcc = accData[0];
                            parentAcc.Name = String.isNotBlank(WrapParent.ParentLeadName) ? WrapParent.ParentLeadName : parentAcc.Name;
                            parentAcc.Parent_Relationship_Father_Mother__c = String.isNotBlank(WrapParent.parentRelationship) ? WrapParent.parentRelationship : parentAcc.Parent_Relationship_Father_Mother__c;
                            parentAcc.Parent_Email_Address__c = String.isNotBlank(WrapParent.parentEmail) ? WrapParent.parentEmail : parentAcc.Parent_Email_Address__c;
                            parentAcc.Phone = String.isNotBlank(WrapParent.parentMobileNumber1) ? WrapParent.parentMobileNumber1 : parentAcc.Phone;
                            parentAcc.Street__c = String.isNotBlank(WrapParent.parentStreet) ? WrapParent.parentStreet : parentAcc.Street__c;
                            parentAcc.City__c = String.isNotBlank(WrapParent.parentCity) ? WrapParent.parentCity : parentAcc.City__c;
                            parentAcc.State__c = String.isNotBlank(WrapParent.parentStateProvince) ? WrapParent.parentStateProvince : parentAcc.State__c;
                            parentAcc.Country__c = String.isNotBlank(WrapParent.parentCountry) ? WrapParent.parentCountry : parentAcc.Country__c;
                            parentAcc.Postcode__c = String.isNotBlank(WrapParent.parentPostcode) ? WrapParent.parentPostcode : parentAcc.Postcode__c;
                            
                            update parentAcc;
                            
                            if (String.isNotBlank(WrapParent.parentEmail) || String.isNotBlank(WrapParent.parentMobileNumber1)) {
                                List<Contact> contactData = [
                                    SELECT Id, Household_ID__c, LastName, Relationship__c, NRIC_Passport_No__c, 
                                    Occupation__c, MobilePhone, Email, Primary_Account__c,Company__c,Primary_Contact__c FROM Contact
                                    WHERE NRIC_Passport_No__c = :WrapParent.parentPassportIC 
                                    AND (
                                        (Email = :WrapParent.parentEmail) 
                                        OR 
                                        (MobilePhone = :WrapParent.parentMobileNumber1)
                                    )LIMIT 1];
                                
                                
                                if (!contactData.isEmpty()) { 
                                    Contact contactRecord = contactData[0];
                                    contactRecord.LastName = String.isNotBlank(WrapParent.ParentLeadName) ? WrapParent.ParentLeadName : contactRecord.Name;
                                    contactRecord.Relationship__c = String.isNotBlank(WrapParent.parentRelationship) ? WrapParent.parentRelationship : contactRecord.Relationship__c;
                                    contactRecord.NRIC_Passport_No__c = WrapParent.parentPassportIC;
                                    contactRecord.MobilePhone = String.isNotBlank(WrapParent.parentMobileNumber1) ? WrapParent.parentMobileNumber1 : contactRecord.MobilePhone;
                                    contactRecord.Email = String.isNotBlank(WrapParent.parentEmail) ? WrapParent.parentEmail : contactRecord.Email;
                                    contactRecord.Company__c= String.isNotBlank(WrapParent.parentCompany)?WrapParent.parentCompany:contactRecord.Company__c;
                                    
                                    
                                    update contactRecord; 
                                    System.debug('Contact data updated successfully.');
                                    
                                    AccountAndContactstatus = AccountAndContactstatus+' And Parent Contact ';
                                    WrapParent.contactRecordId = contactRecord.Id;
                                    
                                    
                                }
                                
                            }
                            
                            parentAccountId = parentAcc.Id;
                            valueFound = true;
                            
                            System.debug('Parent Account Data updated successfully.');
                            
                            res.statusCode = 200;
                            WrapParent.ParentLeadStatusMessage = 'Parent Account '+AccountAndContactstatus +'has been updated successfully.';
                            WrapParent.parentAccountRecordId = parentAcc.Id;
                            
                            resultMsg.put('parentBody', WrapParent);
                            resultMap.put('status', resultMsg);
                            
                        }
                    }
                }
                
                
                if (String.isNotBlank(WrapParent.parentEmail) || String.isNotBlank(WrapParent.parentMobileNumber1)) {
                    if (!valueFound) {
                        
                        
                        List<Parent_Lead__c> parentdata = [
                            SELECT Id, Campus__c, Parent_Relationship__c, Email__c, Mobile_Number_1__c, Mobile_Number_2__c, Mobile_Number_3__c,
                            Preferred_Phone_Number__c, Passport_IC__c,Nationality__c, Gender__c, City__c, State_Province__c, Email_Opt_Out__c, 
                            Company__c, Phone_Company__c, Street__c, Country__c, Postcode__c, Passport_Expiry__c, Name,Date_of_Birth__c
                            FROM Parent_Lead__c 
                            WHERE Email__c = :WrapParent.parentEmail OR Mobile_Number_1__c = :WrapParent.parentMobileNumber1
                            LIMIT 1
                        ];
                        
                        if (!parentdata.isEmpty()) {  
                            Parent_Lead__c parentLead = parentdata[0];
                            
                            if (parentLead.Email__c == WrapParent.parentEmail || parentLead.Mobile_Number_1__c == WrapParent.parentMobileNumber1) {
                                parentLead.Campus__c = String.isNotBlank(WrapParent.parentCampus) ? WrapParent.parentCampus : parentLead.Campus__c;
                                parentLead.Parent_Relationship__c = String.isNotBlank(WrapParent.parentRelationship) ? WrapParent.parentRelationship : parentLead.Parent_Relationship__c;
                                parentLead.Name = String.isNotBlank(WrapParent.ParentLeadName) ? WrapParent.ParentLeadName : parentLead.Name;
                                parentLead.Mobile_Number_1__c = String.isNotBlank(WrapParent.parentMobileNumber1) ? WrapParent.parentMobileNumber1 : parentLead.Mobile_Number_1__c;
                                parentLead.Mobile_Number_2__c = String.isNotBlank(WrapParent.parentMobileNumber2) ? WrapParent.parentMobileNumber2 : parentLead.Mobile_Number_2__c;
                                parentLead.Mobile_Number_3__c = String.isNotBlank(WrapParent.parentMobileNumber3) ? WrapParent.parentMobileNumber3 : parentLead.Mobile_Number_3__c;
                                parentLead.Preferred_Phone_Number__c = String.isNotBlank(WrapParent.parentPreferredPhoneNumber) ? WrapParent.parentPreferredPhoneNumber : parentLead.Preferred_Phone_Number__c;
                                //parentLead.Citizenship__c = String.isNotBlank(WrapParent.parentCitizenship) ? WrapParent.parentCitizenship : parentLead.Citizenship__c;
                                parentLead.Gender__c = String.isNotBlank(WrapParent.parentGender) ? WrapParent.parentGender : parentLead.Gender__c;
                                parentLead.City__c = String.isNotBlank(WrapParent.parentCity) ? WrapParent.parentCity : parentLead.City__c;
                                parentLead.State_Province__c = String.isNotBlank(WrapParent.parentStateProvince) ? WrapParent.parentStateProvince : parentLead.State_Province__c;
                                parentLead.Company__c = String.isNotBlank(WrapParent.parentCompany) ? WrapParent.parentCompany : parentLead.Company__c;
                                parentLead.Street__c = String.isNotBlank(WrapParent.parentStreet) ? WrapParent.parentStreet : parentLead.Street__c;
                                parentLead.Country__c = String.isNotBlank(WrapParent.parentCountry) ? WrapParent.parentCountry : parentLead.Country__c;
                                parentLead.Postcode__c = String.isNotBlank(WrapParent.parentPostcode)? WrapParent.parentPostcode : parentLead.Postcode__c;
                                parentLead.Passport_IC__c = String.isNotBlank(WrapParent.parentPassportIC) ? WrapParent.parentPassportIC : parentLead.Passport_IC__c;
                                parentLead.Email__c = String.isNotBlank(WrapParent.parentEmail) ? WrapParent.parentEmail : parentLead.Email__c;
                                parentLead.Date_of_Birth__c = String.isNotBlank(WrapParent.parentDateofBirth) ?Date.valueOf(WrapParent.parentDateofBirth): parentLead.Date_of_Birth__c;
                                parentLead.Passport_Expiry__c = String.isNotBlank(WrapParent.ParentPassportExpiry) ? Date.valueOf(WrapParent.ParentPassportExpiry) : parentLead.Passport_Expiry__c;
                                parentLead.Phone_Company__c = String.isNotBlank(WrapParent.parentPhoneCompany) ? WrapParent.parentPhoneCompany : parentLead.Phone_Company__c;
                                parentLead.Nationality__c =String.isNotBlank(WrapParent.parentNationality) ? WrapParent.parentNationality :parentLead.Nationality__c;
                                update parentLead;
                                
                                parentLeadId = parentLead.Id;   
                                valueFound = true; 
                                
                                System.debug('Parent Lead Data updated successfully.');
                                
                                res.statusCode = 200; 
                                WrapParent.ParentLeadStatusMessage = 'Parent Lead has been updated successfully.';
                                WrapParent.parentLeadRecordId = parentLead.Id;
                                
                                resultMsg.put('parentBody', WrapParent);
                                resultMap.put('status', resultMsg);
                                
                            }
                        }                     
                    }
                }
                if (!valueFound) {
                    Parent_Lead__c parent = new Parent_Lead__c();
                    parent.Campus__c = String.isNotBlank(WrapParent.parentCampus) ? WrapParent.parentCampus : '';
                    parent.Parent_Relationship__c = String.isNotBlank(WrapParent.parentRelationship) ? WrapParent.parentRelationship : '';
                    parent.Name = String.isNotBlank(WrapParent.ParentLeadName) ? WrapParent.ParentLeadName : '';
                    parent.Email__c = String.isNotBlank(WrapParent.parentEmail) ? WrapParent.parentEmail : '';
                    parent.Mobile_Number_1__c = String.isNotBlank(WrapParent.parentMobileNumber1) ? WrapParent.parentMobileNumber1 : '';
                    parent.Mobile_Number_2__c = String.isNotBlank(WrapParent.parentMobileNumber2) ? WrapParent.parentMobileNumber2 : '';
                    parent.Mobile_Number_3__c = String.isNotBlank(WrapParent.parentMobileNumber3) ? WrapParent.parentMobileNumber3 : '';
                    parent.Preferred_Phone_Number__c = String.isNotBlank(WrapParent.parentPreferredPhoneNumber) ? WrapParent.parentPreferredPhoneNumber : 'Mobile Phone 1';
                    parent.Passport_IC__c = String.isNotBlank(WrapParent.parentPassportIC) ? WrapParent.parentPassportIC : '';
                    //parent.Citizenship__c = String.isNotBlank(WrapParent.parentCitizenship) ? WrapParent.parentCitizenship : '';
                    parent.Gender__c = String.isNotBlank(WrapParent.parentGender) ? WrapParent.parentGender : '';
                    parent.City__c = String.isNotBlank(WrapParent.parentCity) ? WrapParent.parentCity : '';
                    parent.State_Province__c = String.isNotBlank(WrapParent.parentStateProvince) ? WrapParent.parentStateProvince : '';
                    parent.Company__c = String.isNotBlank(WrapParent.parentCompany) ? WrapParent.parentCompany : '';
                    parent.Phone_Company__c = String.isNotBlank(WrapParent.parentPhoneCompany) ? WrapParent.parentPhoneCompany : '';
                    parent.Street__c = String.isNotBlank(WrapParent.parentStreet) ? WrapParent.parentStreet : '';
                    parent.Country__c = String.isNotBlank(WrapParent.parentCountry) ? WrapParent.parentCountry : '';
                    parent.Postcode__c =String.isNotBlank(WrapParent.parentPostcode) ? WrapParent.parentPostcode : '';
                    parent.Passport_Expiry__c = String.isNotBlank(WrapParent.ParentPassportExpiry) ? Date.valueOf(WrapParent.ParentPassportExpiry) : null;
                    parent.Date_of_Birth__c = String.isNotBlank(WrapParent.parentDateofBirth) ?Date.valueOf(WrapParent.parentDateofBirth): null;
                    parent.Nationality__c =String.isNotBlank(WrapParent.parentNationality) ? WrapParent.parentNationality :parent.Nationality__c;
                    System.debug('Parent Lead Object: ' + parent);
                    
                    insert parent;
                    isParentCreated = true;
                    parentLeadId = parent.Id;
                    
                    System.debug('New Parent Lead Created Successfully');
                    res.statusCode = 200;
                    WrapParent.ParentLeadStatusMessage = 'New Parent lead created successfully.';
                    WrapParent.parentLeadRecordId = parent.Id;    
                    
                    resultMsg.put('parentBody', WrapParent);
                    resultMap.put('status', resultMsg);
                    
                }
                
                
            }
            
            if(requestMap.containsKey('childLead')){
                
                
                String childLeadJson = JSON.serialize(requestMap.get('childLead'));
                LeadWrapperContainer.childLead WrapChild = (LeadWrapperContainer.childLead) JSON.deserialize(childLeadJson, LeadWrapperContainer.childLead.class);
                
                //Required Fields
                List<String> missingFields = new List<String>();
                if (String.isBlank(WrapChild.childName)) missingFields.add('childName');
                if (String.isBlank(WrapChild.childLeadStatus)) missingFields.add('childLeadStatus');
                if (String.isBlank(WrapChild.childDateofBirth)) missingFields.add('childDateofBirth');
                //if (String.isBlank(WrapChild.childPassportIC)) missingFields.add('childPassportIC');
                if (String.isBlank(WrapChild.childMobilePhone1)) missingFields.add('childMobilePhone1');
                //if (String.isBlank(WrapChild.childEmail)) missingFields.add('childEmail');
                
                if (!missingFields.isEmpty()) {
                    throw new ChildLeadException('The required field(s) are missing in the child lead: ' + String.join(missingFields, ', '));
                }
                
                //Checking Date Format
                Map<String, String> dateFields = new Map<String, String>();
                if (String.isNotBlank(WrapChild.childDateofBirth)) {
                    dateFields.put('childDateofBirth', WrapChild.childDateofBirth);
                }
                
                if (String.isNotBlank(WrapChild.childPassportExpiry)) {
                    dateFields.put('childPassportExpiry', WrapChild.childPassportExpiry);
                }
                
                for (String fieldName : dateFields.keySet()) {
                    String dateValue = dateFields.get(fieldName);
                    if (String.isNotBlank(dateValue) && !Pattern.matches('^\\d{4}-\\d{1,2}-\\d{1,2}$', dateValue)) {
                        throw new ChildLeadException('Invalid Date Format for ' + fieldName + '. Please enter yyyy-MM-dd format.');
                    }
                }
                
                
                //MobileNumber Validation
                Map<String, String> phoneFields = new Map<String, String>{
                    'childMobilePhone1' => WrapChild.childMobilePhone1,
                        'childMobilePhone2' => WrapChild.childMobilePhone2,
                        'childMobilePhone3' => WrapChild.childMobilePhone3
                        };
                            
                            List<String> invalidFields = new List<String>();
                
                for (String fieldName : phoneFields.keySet()) {
                    String value = phoneFields.get(fieldName);
                    if (String.isNotBlank(value) && !Pattern.matches('^\\+?[0-9]{10,12}$', value)) {
                        invalidFields.add(fieldName);
                    }
                }
                
                if (!invalidFields.isEmpty()) {
                    throw new ChildLeadException('Enter a valid number with 10 to 12 digits. ' + String.join(invalidFields, ', '));
                }
                
                
                
                Boolean valueFound = false; 
                List<Programme_Master__c> programData = new List<Programme_Master__c>();
                List<Intake_Master__c> intakeData = new List<Intake_Master__c>();
                
                if (String.isNotBlank(WrapChild.childProgramme)) {
                    System.debug('WrapLead.childProgramme'+WrapChild.childProgramme);
                    programData = [Select Id,Programme_Code__c,Name,Programme_Duration__c,Level_of_Education__c,Is_Offer__c,Campus_Code__c,Campus_Name__c,Campus_Location__c,School_Code__c from Programme_Master__c  where Name =:WrapChild.childProgramme limit 1 ];
                    System.debug('programData'+programData);
                }
                
                if (String.isNotBlank(WrapChild.childIntake)) {
                    System.debug('WrapLead.childIntake'+WrapChild.childIntake);
                    intakeData = [Select Id,Name,EMX_ID__c,Intake_Name__c,Study_Mode__c,CRM_Programme_Intake_ID__c,	Course_Detail_Intake_ID__c,Application_Allowed__c from Intake_Master__c where Name =: WrapChild.childIntake limit 1 ];
                    //intakeData = [Select Id from Intake_Master__c where Intake_Name__c =: WrapChild.childIntake limit 1 ];
                    System.debug('intakeData'+intakeData);
                }
                
                if(isParentCreated){
                    if(!valueFound){  
                        
                        Lead childLead = LeadManagementAPI.childLeadCreate(WrapChild, intakeData, programData, parentAccountId, parentLeadId,ParentLeadEmail);
                        System.debug('Child Lead =>' + childLead);
                        insert childLead;
                        valueFound=true; 
                        System.debug('Child Data is created');
                        
                        res.statusCode = 200;
                        WrapChild.childLeadStatusMessage = 'New Child Lead is Created successfully.';
                        WrapChild.childLeadRecordId = childLead.Id;
                        
                        
                        resultMsg.put('childBody', WrapChild);
                        resultMap.put('status', resultMsg);
                    }
                    
                }
                
                
                
                
                if (String.isNotBlank(WrapChild.childPassportIC)) {
                    if (!valueFound) {
                        List<Student__c> studentData = [
                            SELECT Id, Name, Preferred_Name__c, NRIC_Passport_No__c, Passport_Expiry_Date__c, 
                            Date_of_Birth__c, Nationality__c, Gender__c, 
                            Marital_Status__c, Race__c, Religion__c, Student_Mobile_No__c, 
                            Email_Address__c 
                            FROM Student__c 
                            WHERE NRIC_Passport_No__c = :WrapChild.childPassportIC
                            LIMIT 1
                        ];
                        
                        if (!studentData.isEmpty()) {
                            Student__c student = studentData[0];
                            student.Name = String.isNotBlank(WrapChild.childName) ?WrapChild.childName : student.Name;
                            student.Passport_Expiry_Date__c = String.isNotBlank(WrapChild.childPassportExpiry) ? Date.valueOf(WrapChild.childPassportExpiry):student.Passport_Expiry_Date__c;
                            student.Date_of_Birth__c = String.isNotBlank(WrapChild.childDateofBirth) ?Date.valueOf(WrapChild.childDateofBirth):student.Date_of_Birth__c;
                            student.Nationality__c = String.isNotBlank(WrapChild.childNationality) ? WrapChild.childNationality : student.Nationality__c;
                            //student.Citizenship__c = String.isNotBlank(WrapChild.childCitizenship) ? WrapChild.childCitizenship : student.Citizenship__c;
                            student.Gender__c = String.isNotBlank(WrapChild.childGender) ? WrapChild.childGender : student.Gender__c;
                            student.Student_Mobile_No__c = String.isNotBlank(WrapChild.childMobilePhone1) ? WrapChild.childMobilePhone1 : student.Student_Mobile_No__c;
                            student.Email_Address__c = String.isNotBlank(WrapChild.childEmail) ? WrapChild.childEmail : student.Email_Address__c;
                            
                            if (parentAccountId != null) {
                                student.Parent_Account__c = parentAccountId;
                            }
                            
                            update student;
                            valueFound = true;
                            System.debug('Student Data is Updated');
                            res.statusCode = 200;
                            WrapChild.childLeadStatusMessage = 'Student Record Updated successfully.';
                            WrapChild.studentRecordId = student.Id;
                            resultMsg.put('childBody', WrapChild);
                            resultMap.put('status', resultMsg);
                        }
                    }
                }
                
                if ((String.isNotBlank(WrapChild.childMobilePhone1) && String.isNotBlank(WrapChild.childName) && String.isNotBlank(WrapChild.childDateofBirth)) 
                    || (String.isNotBlank(WrapChild.childEmail) && String.isNotBlank(WrapChild.childName) && String.isNotBlank(WrapChild.childDateofBirth))) {
                        
                        if (!valueFound) {
                            List<Lead> childData = [
                                SELECT LastName, Date_of_Birth__c, Nationality__c, Passport_IC__c, 
                                Passport_Expiry__c, Email, Mobile_Phone_1__c, Mobile_Phone_2__c, Mobile_Phone_3__c, 
                                Preferred_Phone__c, Visa__c, GenderIdentity, Accommodation__c, Bursary__c, Scholarship__c,
                                Intake__c, Programme__c, Status, Lost_reason__c, LeadSource, Rating, Parent_Lead__c, 
                                Parent_Account__c ,Passport_Issue_from__c,Current_School__c,Completed_Grade__c
                                FROM Lead 
                                WHERE ( (Mobile_Phone_1__c != null AND LastName != null AND Date_of_Birth__c != null AND 
                                         Mobile_Phone_1__c = :WrapChild.childMobilePhone1 AND 
                                         LastName = :WrapChild.childName AND
                                         Date_of_Birth__c = :Date.valueOf(WrapChild.childDateofBirth)) 
                                       OR 
                                       (Email != null AND LastName != null AND Date_of_Birth__c != null AND 
                                        Email = :WrapChild.childEmail AND 
                                        LastName = :WrapChild.childName AND
                                        Date_of_Birth__c = :Date.valueOf(WrapChild.childDateofBirth)) )
                                LIMIT 1
                            ];
                            
                            if (!childData.isEmpty()) {
                                
                                if (String.isNotBlank(WrapChild.childLeadStatus) && WrapChild.childLeadStatus != 'LOST' && String.isNotBlank(WrapChild.childLostreason)) {
                                    throw new ChildLeadException('You need to provide childLostreason only if childLeadStatus is "LOST".');
                                }
                                
                                
                                Lead child = childData[0]; 
                                child.LastName = String.isNotBlank(WrapChild.childName) ? WrapChild.childName : child.LastName;
                                child.Date_of_Birth__c = String.isNotBlank(WrapChild.childDateofBirth) ?Date.valueOf(WrapChild.childDateofBirth):child.Date_of_Birth__c;
                                child.Passport_Expiry__c = String.isNotBlank(WrapChild.childPassportExpiry)?Date.valueOf(WrapChild.childPassportExpiry):child.Passport_Expiry__c;
                                child.Nationality__c = String.isNotBlank(WrapChild.childNationality) ? WrapChild.childNationality : child.Nationality__c;
                                //child.Citizenship__c = String.isNotBlank(WrapChild.childCitizenship) ? WrapChild.childCitizenship : child.Citizenship__c;
                                child.Passport_IC__c = String.isNotBlank(WrapChild.childPassportIC) ? WrapChild.childPassportIC : child.Passport_IC__c;
                                child.Email = String.isNotBlank(WrapChild.childEmail) ? WrapChild.childEmail : child.Email;
                                child.Mobile_Phone_1__c = String.isNotBlank(WrapChild.childMobilePhone1) ? WrapChild.childMobilePhone1 : child.Mobile_Phone_1__c;
                                child.Mobile_Phone_2__c = String.isNotBlank(WrapChild.childMobilePhone2) ? WrapChild.childMobilePhone2 : child.Mobile_Phone_2__c;
                                child.Mobile_Phone_3__c = String.isNotBlank(WrapChild.childMobilePhone3) ? WrapChild.childMobilePhone3 : child.Mobile_Phone_3__c;
                                child.Preferred_Phone__c = String.isNotBlank(WrapChild.childPreferredPhone) ? WrapChild.childPreferredPhone : child.Preferred_Phone__c;
                                child.Visa__c = String.isNotBlank(WrapChild.childVisa) ? WrapChild.childVisa : child.Visa__c;
                                child.GenderIdentity = String.isNotBlank(WrapChild.childGender) ? WrapChild.childGender : child.GenderIdentity;
                                child.Accommodation__c = String.isNotBlank(WrapChild.childAccommodation) ? Boolean.valueOf(WrapChild.childAccommodation) : child.Accommodation__c;
                                child.Bursary__c = String.isNotBlank(WrapChild.childBursary) ? Boolean.valueOf(WrapChild.childBursary) : child.Bursary__c;
                                child.Scholarship__c = String.isNotBlank(WrapChild.childScholarship) ? Boolean.valueOf(WrapChild.childScholarship) : child.Scholarship__c;
                                child.Status = String.isNotBlank(WrapChild.childLeadStatus) ? WrapChild.childLeadStatus : child.Status;
                                
                                child.Lost_reason__c = String.isNotBlank(WrapChild.childLostreason) ? WrapChild.childLostreason : child.Lost_reason__c;
                                
                                child.LeadSource = String.isNotBlank(WrapChild.childLeadSource) ? WrapChild.childLeadSource : child.LeadSource;
                                child.Rating = String.isNotBlank(WrapChild.childLeadRating) ? WrapChild.childLeadRating : child.Rating;
                                child.Parent_Lead__c = parentLeadId != null ? parentLeadId : child.Parent_Lead__c;
                                child.Passport_Issue_from__c=String.isNotBlank(WrapChild.childPassportIssuefrom) ?WrapChild.childPassportIssuefrom:child.Passport_Issue_from__c;
                                child.Current_School__c=String.isNotBlank(WrapChild.childCurrentSchool)?WrapChild.childCurrentSchool:child.Current_School__c;
                                child.Completed_Grade__c=String.isNotBlank(WrapChild.childCompletedGrade)?WrapChild.childCompletedGrade:child.Completed_Grade__c;
                                
                                
                                if (programData!= null && !programData.isEmpty()) {
                                    child.Programme__c = programData[0].Id != null ? programData[0].Id : child.Programme__c;
                                }
                                if (intakeData!=null && !intakeData.isEmpty()) {
                                    child.Intake__c = intakeData[0].Id != null ? intakeData[0].Id :  child.Intake__c;
                                }
                                if (parentAccountId != null) {
                                    child.Parent_Account__c = parentAccountId != null ?parentAccountId: child.Parent_Account__c;
                                }
                                
                                
                                
                                update child;
                                valueFound = true;
                                System.debug('Child Lead has been updated successfully.');
                                
                                
                                res.statusCode = 200;
                                WrapChild.childLeadStatusMessage = 'Child Lead has been updated successfully.';
                                WrapChild.childLeadRecordId = child.Id;
                                resultMsg.put('childBody', WrapChild);
                                resultMap.put('status', resultMsg);
                                
                            }
                        }
                    }
                
                
                if (!valueFound) {
                    
                    Lead childLead = LeadManagementAPI.childLeadCreate(WrapChild, intakeData, programData, parentAccountId, parentLeadId,ParentLeadEmail);
                    System.debug('Child Lead =>' + childLead);
                    insert childLead;
                    System.debug('Child Data is created');
                    
                    res.statusCode = 200;
                    WrapChild.childLeadStatusMessage = 'New Child Lead is Created successfully.';
                    WrapChild.childLeadRecordId = childLead.Id;
                    
                    resultMsg.put('childBody', WrapChild);
                    resultMap.put('status', resultMsg);
                    
                    
                }
                String responseBody = JSON.serialize(resultMap);
                res.responseBody = Blob.valueOf(responseBody);
                SISIntegrationLog.createLog(requestBody,responseBody,'Success');
                
            }   
            
        }catch(ParentLeadException e) {
            Database.rollback(sp);
            System.debug('Error: ' + e.getStackTraceString());
            res.statusCode = 400;
            resultMsg.clear(); 
            resultMsg.put('ParentLeadMessage', e.getMessage());
            resultMap.clear(); 
            resultMap.put('status', resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
        }catch(ChildLeadException e) {
            Database.rollback(sp);
            System.debug('Error: ' + e.getStackTraceString());
            res.statusCode = 400;
            resultMsg.clear(); 
            resultMsg.put('ChildLeadMessage', e.getMessage());
            resultMap.clear(); 
            resultMap.put('status', resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
        }
        catch(MyException e) {
            Database.rollback(sp);
            System.debug('Error---'+ e.getStackTraceString());
            res.statusCode = 400;
            resultMsg.clear(); 
            resultMsg.put('message',e.getMessage());
            resultMap.clear(); 
            resultMap.put('status',resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
        }catch (Exception e) {
            Database.rollback(sp); 
            System.debug('Unexpected Error: ' + e.getStackTraceString());
            res.statusCode = 400;
            resultMsg.clear(); 
            if (e.getTypeName() == 'System.DmlException') {
                resultMsg.put('message', string.valueOf(e.getDmlMessage(0)));
            } else {
                resultMsg.put('message', string.valueOf(e.getMessage()));
            }
            resultMap.clear(); 
            resultMap.put('error',resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
        }
        
        
        
        
        
        
        
    }
    
    public static Lead childLeadCreate(LeadWrapperContainer.childLead WrapChild,  List<Intake_Master__c> intakeData, List<Programme_Master__c> programData,Id parentAccountId,Id parentLeadId,String ParentLeadEmail){
        
        if (WrapChild.childLeadStatus != 'NEW') {
            throw new ChildLeadException('Child Lead can only be created when childLeadStatus is NEW. (Current Status: ' + WrapChild.childLeadStatus + ')');
        }
        if(WrapChild.childLeadStatus == 'NEW' && String.isNotBlank(WrapChild.childLostreason)) {
            throw new ChildLeadException('LOST reason should not be provided when the childLeadStatus is NEW.');
        }
        Lead child = new Lead();
        
        
        child.LastName = WrapChild.childName;
        child.Date_of_Birth__c = String.isNotBlank(WrapChild.childDateofBirth) ? Date.valueOf(WrapChild.childDateofBirth) : null;
        child.Passport_Expiry__c = String.isNotBlank(WrapChild.childPassportExpiry) ? Date.valueOf(WrapChild.childPassportExpiry) : null;
        child.Nationality__c = String.isNotBlank(WrapChild.childNationality) ? WrapChild.childNationality : '';
        //child.Citizenship__c = String.isNotBlank(WrapChild.childCitizenship) ? WrapChild.childCitizenship : '';
        child.Passport_IC__c = String.isNotBlank(WrapChild.childPassportIC) ? WrapChild.childPassportIC : '';
        child.Email = String.isNotBlank(WrapChild.childEmail) ? WrapChild.childEmail : ParentLeadEmail;
        System.debug('ParentLeadEmail'+ParentLeadEmail);
        child.Mobile_Phone_1__c = String.isNotBlank(WrapChild.childMobilePhone1) ? WrapChild.childMobilePhone1 : '';
        child.Mobile_Phone_2__c = String.isNotBlank(WrapChild.childMobilePhone2) ? WrapChild.childMobilePhone2 : '';
        child.Mobile_Phone_3__c = String.isNotBlank(WrapChild.childMobilePhone3) ? WrapChild.childMobilePhone3 : '';
        child.Preferred_Phone__c = String.isNotBlank(WrapChild.childPreferredPhone) ? WrapChild.childPreferredPhone : 'Mobile Phone 1';
        child.Passport_Issue_from__c=String.isNotBlank(WrapChild.childPassportIssuefrom) ?WrapChild.childPassportIssuefrom:'';
        child.Current_School__c=String.isNotBlank(WrapChild.childCurrentSchool)?WrapChild.childCurrentSchool:'';
        child.Completed_Grade__c=String.isNotBlank(WrapChild.childCompletedGrade)?WrapChild.childCompletedGrade:'';
        
        if (programData != null && !programData.isEmpty()) {
            child.Programme__c = programData[0].Id;
        } else {
            child.Programme__c = null;
        }
        
        if (intakeData != null && !intakeData.isEmpty()) {
            child.Intake__c = intakeData[0].Id;
        } else {
            child.Intake__c = null;
        }
        
        
        child.Visa__c = String.isNotBlank(WrapChild.childVisa) ? WrapChild.childVisa : '';
        child.GenderIdentity = String.isNotBlank(WrapChild.childGender) ? WrapChild.childGender : '';
        child.Accommodation__c = WrapChild.childAccommodation!=null? Boolean.valueOf(WrapChild.childAccommodation) : false;
        child.Bursary__c = WrapChild.childBursary!=null? Boolean.valueOf(WrapChild.childBursary) : false;
        child.Scholarship__c = WrapChild.childScholarship!=null ? Boolean.valueOf(WrapChild.childScholarship) :false;
        child.Status = WrapChild.childLeadStatus;
        child.Lost_reason__c = String.isNotBlank(WrapChild.childLostreason) ? WrapChild.childLostreason : '';
        child.LeadSource = String.isNotBlank(WrapChild.childLeadSource) ? WrapChild.childLeadSource : '';
        child.Rating = String.isNotBlank(WrapChild.childLeadRating) ? WrapChild.childLeadRating : '';
        child.Parent_Lead__c = parentLeadId != null ? parentLeadId : null;
        
        if (parentAccountId != null) {
            child.Parent_Account__c = parentAccountId;
        }    
        return child;
        
        
    } 
}