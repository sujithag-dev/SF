public without sharing class SISLeadConversionController {
    public class MyException extends Exception {}
    @AuraEnabled
    public static Map<String, Object> getLeadConvertDetails(String recordId){
        Map<String, Object> leadDetails = new Map<String, Object>();
        try{
            System.debug('recordId---'+ recordId);
            List<Parent_Lead__c> parentLead = new List<Parent_Lead__c>();
            List<Account> parentAccount = new List<Account>();
            List<Contact> parentContact = new List<Contact>();
            
            List<Lead> childLead = [SELECT Id, Parent_Lead__c, Parent_Account__c FROM Lead WHERE Id =: recordId LIMIT 1];
            if(!childLead.isEmpty()){
                leadDetails.put('student', childLead[0]);
                if(childLead[0].Parent_Lead__c != null){
                    parentLead = [SELECT Id FROM Parent_Lead__c WHERE Id =: childLead[0].Parent_Lead__c LIMIT 1];
                    if(!parentLead.isEmpty()){
                        leadDetails.put('parentLead', parentLead[0]);
                    }
                }else if(childLead[0].Parent_Account__c != null){
                    parentAccount = [SELECT Id FROM Account WHERE Id =: childLead[0].Parent_Account__c LIMIT 1];
                    if(!parentAccount.isEmpty()){
                        leadDetails.put('parentAccount', parentAccount[0]);
                    }
                    parentContact = [SELECT Id FROM Contact WHERE Primary_Account__c =: childLead[0].Parent_Account__c LIMIT 1];
                    if(!parentContact.isEmpty()){
                        leadDetails.put('parentContact', parentContact[0]);
                    }
                }
                System.debug('leadDetails---'+ leadDetails);
            }
        }catch(Exception e){
            System.debug('Error'+ e);
            leadDetails.put('error', e.getMessage());
        }
        return leadDetails;
    }
    
    @AuraEnabled
    public static Map<String, Object> convertLead(String recordId){
        Savepoint sp = Database.setSavepoint();
        Map<String, Object> result = new Map<String, Object>();
        
        try{
            List<Student__c> duplicateStud = new List<Student__c>();
            Boolean isDuplicateStud = false;
            String currectRecordId = recordId;
            System.debug('currectRecordId---'+ currectRecordId);
            List<Lead> lead = [SELECT Id, Name, Passport_IC__c, Passport_Expiry__c, Date_of_Birth__c, Nationality__c, Citizenship__c, 
                               GenderIdentity, Mobile_Phone_1__c, Email, Parent_Account__c, Parent_Lead__c, LeadSource, Application_For_Admissions_Form__c, Initial_Application_Fee__c,
                               Supporting_Document_Submission__c, Post_Application_Received__c, Is_Duplicate_Student__c, PIC__c FROM Lead WHERE Id =: currectRecordId LIMIT 1];
            
            List<Parent_Lead__c> pLead = new List<Parent_Lead__c>();
            System.debug('lead---'+ lead);
            if(!lead.isEmpty()){
                Lead childLead = lead[0];
                List<String> mandatoryFields = new List<String>();
                if(childLead.Passport_IC__c == null) mandatoryFields.add('Passport IC');
                if(childLead.Application_For_Admissions_Form__c != true) mandatoryFields.add('Application For Admissions Form');
                if(childLead.Initial_Application_Fee__c != true) mandatoryFields.add('Initial Application Fee');
                if(childLead.Supporting_Document_Submission__c != true) mandatoryFields.add('Supporting Document Submission');
                if(childLead.Post_Application_Received__c != true) mandatoryFields.add('Post Application Received');
                
                if(!mandatoryFields.isEmpty()){
                    throw new MyException('Please ensure the following fields has value/checked in child lead before conversion: ' + String.join(mandatoryFields, ', '));
                }
                
                System.debug('l.Parent_Lead__c---'+ lead[0].Parent_Lead__c);
                if(lead[0].Parent_Lead__c != null){
                    pLead = [SELECT Id, Campus__c, Parent_Relationship__c, Name, Email__c, Mobile_Number_1__c, Mobile_Number_2__c, 
                             Mobile_Number_3__c, Preferred_Phone_Number__c, Preferred_Phone_Value__c, Passport_IC__c, Gender__c, 
                             Street__c, City__c, State_Province__c, Postcode__c, Country__c, Email_Opt_Out__c, Company__c, Phone_Company__c  
                             FROM Parent_Lead__c 
                             WHERE Id =: lead[0].Parent_Lead__c LIMIT 1];

                    List<String> mandatoryFieldsForAccAndCon = new List<String>();
                    if(String.isBlank(pLead[0].Passport_IC__c)) mandatoryFieldsForAccAndCon.add('Parent NRIC/Passport No');
                    if(String.isBlank(pLead[0].Parent_Relationship__c)) mandatoryFieldsForAccAndCon.add('Parent Relationship');
                    
                    if(!mandatoryFieldsForAccAndCon.isEmpty()){
                        throw new MyException('Please ensure the following fields has value in parent lead before conversion: ' + String.join(mandatoryFieldsForAccAndCon, ', '));
                    }
                    
                }
                
            }else{
                throw new MyException('No records found.');
            }
            
            duplicateStud = [SELECT Id FROM Student__c WHERE NRIC_Passport_No__c =: lead[0].Passport_IC__c LIMIT 1];
            System.debug('duplicateStud---'+ duplicateStud);
            if(!duplicateStud.isEmpty() && lead[0].Is_Duplicate_Student__c == false){
                lead[0].Is_Duplicate_Student__c = true;
                update lead[0];
                System.debug('Is_Duplicate_Student__c updated in child lead.');
                result.put('warning', 'A Student is already exists with the same Passport/ IC. If you are ok with the duplicate Student, then click the "Convert" button again.');
            }else{
                if(lead[0].Is_Duplicate_Student__c == true){
                    isDuplicateStud = true;
                }
                System.debug('pLead---'+ pLead);
                
                if(!pLead.isEmpty() && pLead.size() > 0){
                    Parent_Lead__c parentLead = pLead[0];
                    Lead childLead = lead[0];
                    
                    Account acc = new Account();
                    acc.Name = String.isNotBlank(parentLead.Name) ? parentLead.Name : acc.Name;
                    acc.Parent_Relationship_Father_Mother__c = String.isNotBlank(parentLead.Parent_Relationship__c) ? parentLead.Parent_Relationship__c : acc.Parent_Relationship_Father_Mother__c;
                    acc.Parent_NRIC_Passport_No__c = String.isNotBlank(parentLead.Passport_IC__c) ? parentLead.Passport_IC__c : acc.Parent_NRIC_Passport_No__c;
                    acc.Parent_Email_Address__c = String.isNotBlank(parentLead.Email__c) ? parentLead.Email__c : acc.Parent_Email_Address__c;
                    acc.Phone = String.isNotBlank(parentLead.Mobile_Number_1__c) ? parentLead.Mobile_Number_1__c : acc.Phone;
                    acc.Street__c = String.isNotBlank(parentLead.Street__c) ? parentLead.Street__c : acc.Street__c;
                    acc.City__c = String.isNotBlank(parentLead.City__c) ? parentLead.City__c : acc.City__c;
                    acc.State__c = String.isNotBlank(parentLead.State_Province__c) ? parentLead.State_Province__c : acc.State__c;
                    acc.Country__c = String.isNotBlank(parentLead.Country__c) ? parentLead.Country__c : acc.Country__c;
                    acc.Postcode__c = String.isNotBlank(parentLead.Postcode__c) ? parentLead.Postcode__c : acc.Postcode__c;
                    
                    insert acc;
                    System.debug('New Account created and acc inserted successfully...' + acc);
                    
                    Contact con = new Contact();
                    con.LastName = String.isNotBlank(parentLead.Name) ? parentLead.Name : con.Name;
                    con.NRIC_Passport_No__c = String.isNotBlank(parentLead.Passport_IC__c) ? parentLead.Passport_IC__c : con.NRIC_Passport_No__c;
                    con.Relationship__c = String.isNotBlank(parentLead.Parent_Relationship__c) ? parentLead.Parent_Relationship__c : con.Relationship__c;
                    con.MobilePhone = String.isNotBlank(parentLead.Mobile_Number_1__c) ? parentLead.Mobile_Number_1__c : con.MobilePhone;
                    con.Email = String.isNotBlank(parentLead.Email__c) ? parentLead.Email__c : con.Email;
                    con.Street__c = String.isNotBlank(parentLead.Street__c) ? parentLead.Street__c : con.Street__c;
                    con.City__c = String.isNotBlank(parentLead.City__c) ? parentLead.City__c : con.City__c;
                    con.State__c = String.isNotBlank(parentLead.State_Province__c) ? parentLead.State_Province__c : con.State__c;
                    con.Country__c = String.isNotBlank(parentLead.Country__c) ? parentLead.Country__c : con.Country__c;
                    con.Postcode__c = String.isNotBlank(parentLead.Postcode__c) ? parentLead.Postcode__c : con.Postcode__c;
                    con.Company__c = String.isNotBlank(parentLead.Company__c) ? parentLead.Company__c : con.Company__c;
                    con.Primary_Account__c = acc.Id != null ? acc.Id : con.Primary_Account__c;
                    con.Primary_Contact__c = true;
                    
                    insert con;
                    System.debug('New Contact created and con inserted successfully...'+ con);
                    
                    Student__c stud = new Student__c();
                    stud.Name = String.isNotBlank(childLead.Name) ? childLead.Name : stud.Name;
                    stud.NRIC_Passport_No__c = String.isNotBlank(childLead.Passport_IC__c) ? childLead.Passport_IC__c : stud.NRIC_Passport_No__c;
                    stud.Passport_Expiry_Date__c = childLead.Passport_Expiry__c != null ? childLead.Passport_Expiry__c : Stud.Passport_Expiry_Date__c;
                    stud.Date_of_Birth__c = childLead.Date_of_Birth__c != null ? childLead.Date_of_Birth__c : Stud.Date_of_Birth__c;
                    stud.Nationality__c = String.isNotBlank(childLead.Nationality__c) ? childLead.Nationality__c : Stud.Nationality__c;
                    //stud.Citizenship__c = String.isNotBlank(childLead.Citizenship__c) ? childLead.Citizenship__c : Stud.Citizenship__c;
                    stud.Gender__c = String.isNotBlank(childLead.GenderIdentity) ? childLead.GenderIdentity : stud.Gender__c;
                    stud.Student_Mobile_No__c = String.isNotBlank(childLead.Mobile_Phone_1__c) ? childLead.Mobile_Phone_1__c : Stud.Student_Mobile_No__c;
                    stud.Email_Address__c = String.isNotBlank(childLead.Email) ? childLead.Email : Stud.Email_Address__c;
                    stud.Lead_Source__c = String.isNotBlank(childLead.LeadSource) ? childLead.LeadSource : Stud.Lead_Source__c;
                    stud.PIC__c = String.isNotBlank(childLead.PIC__c) ? childLead.PIC__c : Stud.PIC__c;
                    stud.Parent_Account__c = acc.Id != null ? acc.Id : stud.Parent_Account__c;
                    stud.Primary_Contact__c = con.Id != null ? con.Id : Stud.Primary_Contact__c;
                    stud.Allow_Duplicate__c = isDuplicateStud;
                    stud.Child_Lead_RecordId__c = childLead.Id;
                    
                    insert stud;
                    System.debug('New Student created and stud inserted successfully...'+ stud);
                    result.put('success', stud.Id);
                    
                    List<Lead> childLeads = [SELECT Id, Parent_Account__c, Parent_Lead__c FROM Lead WHERE Parent_Lead__c =: childLead.Parent_Lead__c AND Id !=: childLead.Id];
                    System.debug('childLeads---'+ childLeads);
                    
                    if(!childLeads.isEmpty()){
                        for(Lead ld: childLeads){
                            ld.Parent_Lead__c = null;
                            ld.Parent_Account__c = acc.Id;
                            update ld;
                            System.debug('Child Lead updated successfully...'+ ld);
                        }
                    }
                    
                    delete parentLead;
                }else if(lead[0].Parent_Account__c != null){
                    Lead childLead = Lead[0];
                    List<Contact> pContact = [SELECT Id FROM Contact WHERE Primary_Account__c =: childLead.Parent_Account__c AND Primary_Contact__c = true LIMIT 1];
                    Student__c stud = new Student__c();
                    stud.Name = String.isNotBlank(childLead.Name) ? childLead.Name : stud.Name;
                    stud.NRIC_Passport_No__c = String.isNotBlank(childLead.Passport_IC__c) ? childLead.Passport_IC__c : stud.NRIC_Passport_No__c;
                    stud.Passport_Expiry_Date__c = childLead.Passport_Expiry__c != null ? childLead.Passport_Expiry__c : Stud.Passport_Expiry_Date__c;
                    stud.Date_of_Birth__c = childLead.Date_of_Birth__c != null ? childLead.Date_of_Birth__c : Stud.Date_of_Birth__c;
                    stud.Nationality__c = String.isNotBlank(childLead.Nationality__c) ? childLead.Nationality__c : Stud.Nationality__c;
                    //stud.Citizenship__c = String.isNotBlank(childLead.Citizenship__c) ? childLead.Citizenship__c : Stud.Citizenship__c;
                    stud.Gender__c = String.isNotBlank(childLead.GenderIdentity) ? childLead.GenderIdentity : stud.Gender__c;
                    stud.Student_Mobile_No__c = String.isNotBlank(childLead.Mobile_Phone_1__c) ? childLead.Mobile_Phone_1__c : Stud.Student_Mobile_No__c;
                    stud.Email_Address__c = String.isNotBlank(childLead.Email) ? childLead.Email : Stud.Email_Address__c;
                    stud.Lead_Source__c = String.isNotBlank(childLead.LeadSource) ? childLead.LeadSource : Stud.Lead_Source__c;
                    stud.PIC__c = String.isNotBlank(childLead.PIC__c) ? childLead.PIC__c : Stud.PIC__c;
                    stud.Parent_Account__c = childLead.Parent_Account__c;
                    stud.Allow_Duplicate__c = isDuplicateStud;
                    stud.Child_Lead_RecordId__c = childLead.Id;
                    if(!pContact.isEmpty()){
                        stud.Primary_Contact__c = pContact[0].Id;
                    } 
                    
                    insert stud;
                    System.debug('New Student created and stud inserted successfully...'+ stud);
                    result.put('success', stud.Id);
                }
            }
            
        }catch(MyException e){
            Database.rollback(sp);
            system.debug('MyException---'+ e.getMessage());
            result.put('error', e.getMessage());
        }catch(Exception e){
            Database.rollback(sp);
            System.debug(e.getMessage());
            if(e.getTypeName() == 'System.DmlException'){
                result.put('error', e.getDmlMessage(0));
            }else{
                result.put('error', e.getMessage());
            }
        }
        return result;
    }
    
    @AuraEnabled
    public static Map<String, Object> handleIsDuplicate(String recordId){
        Map<String, Object> isDuplicateRes = new Map<String, Object>();
        try{
            System.debug('recordId---'+ recordId);
            List<Lead> childLead = [SELECT Id, Is_Duplicate_Student__c FROM Lead WHERE Id =: recordId LIMIT 1];
            if(!childLead.isEmpty() && childLead[0].Is_Duplicate_Student__c == true){
                childLead[0].Is_Duplicate_Student__c = false;
                update childLead;
                isDuplicateRes.put('info', 'No duplicate student record created.');
            }
        }catch(Exception e){
            system.debug('handleIsDuplicate exception---'+ e.getMessage());
            isDuplicateRes.put('error', e.getMessage());
        }
        return isDuplicateRes;
    }
}