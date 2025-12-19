public with sharing class SIS_JsonForProgrammeApplication {
    @InvocableMethod(label='SIS_JsonForProgrammeApplication')
    public static void createJsonForProgrammeApplication(List<Programme_Application__c> progApp){
        String crmJson;
        String progAppId = progApp[0].Id;
        String clientID = System.Label.SIS_clientID;
        System.debug('clientID---'+ clientID);
        String crmMode = 'STUD_WO_PAYMENT';
        System.debug('crmMode---'+ crmMode);
        String orgId = [SELECT Id FROM Organization LIMIT 1].Id;
        String org_Id = orgId.substring(0, 15);
        System.debug('org_Id---'+org_Id);
        // String campusId = 'CAMPUS_SIS_EMS3';
        // System.debug('campusId---'+ campusId);
        
        List<Student__c> stud = new List<Student__c>();
        List<Programme_Master__c> progMaster = new List<Programme_Master__c>();
        List<Intake_Master__c> intakeMaster = new List<Intake_Master__c>();
        List<Programme_Application__c> progApplication = new List<Programme_Application__c>();
        List<Account> parentAcc = new List<Account>();
        List<Contact> parentCon = new List<Contact>();
        
        Map<String, String> constructJson = new Map<String, String>();
        
        
        try{
            constructJson.put('client_id', clientID);
            constructJson.put('CRM_MODE', crmMode);
            constructJson.put('CRM_ORG_ID', org_Id);
            //constructJson.put('CRM_CAMPUS_ID', campusId);
            //constructJson.put('APPLICATION_TYPE', 'New');
            if(!progApp.isEmpty()){
                System.debug('progApp---'+ progApp);
                progApplication = [SELECT Id, Name, EMX_ID__c, CRM_Programme_ID__c, CRM_Student_ID__c, Offer_Status__c, Conditional_Code__c, 
                                   Offer_Letter_Printed_Date__c, Acceptance_Date__c, Student__c, Programme_Master__c, Intake_Master__c, 
                                   Immigration_Pass_Type__c, Immigration_Pass_Institution_Name__c, Immigration_Pass_Expiry_Date__c, 
                                   RecordType.Name, CreatedBy.Name, Application_Type__c, PIC__c FROM Programme_Application__c WHERE Id =: progApp[0].Id LIMIT 1];
                if(!progApplication.isEmpty()){
                    System.debug('progApplication---'+ progApplication);
                    SFWebServiceWrapper progAppWrapper = new SFWebServiceWrapper(progApplication[0]);
                    System.debug('progAppWrapper---'+ progAppWrapper);
                    Map<String, Object> fieldVal = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(progAppWrapper));
                    for (String key : fieldVal.keySet()){
                        if(String.isNotBlank((String)fieldVal.get(key))){
                            constructJson.put(key, (String)fieldVal.get(key));
                        }
                    }
                    
                    if(progApplication[0].Student__c != null){
                        stud = [SELECT Id, Name, NRIC_Passport_No__c, Date_of_Birth__c, Nationality__c, Gender__c, Marital_Status__c, 
                                Race__c, Religion__c, Street_m__c, State_m__c, Postcode_m__c, Country_m__c, City_m__c, 
                                Contact_Telephone_No_m__c, Street_p__c, State_p__c, Postcode_p__c, Country_p__c, City_p__c, 
                                Contact_Telephone_No_p__c, Lead_Source__c, Student_UID__c, Preferred_Name__c, 
                                Passport_Expiry_Date__c, Student_Mobile_No__c, Email_Address__c, CRM_Household_ID__c, Student_SFID__c,
                                Parent_Account__c, Primary_Contact__c, Acknowledged_Date__c, Campus_SFID__c, Emergency_Contact_Name__c, 
                                Emergency_Relationship__c, Emergency_Contact_home__c, Emergency_Contact_Mobile__c, Emergency_Email__c
                                FROM Student__c WHERE Id =: progApplication[0].Student__c LIMIT 1];
                        if(!stud.isEmpty()){
                            System.debug('stud---'+ stud);
                            SFWebServiceWrapper studWrapper = new SFWebServiceWrapper(stud[0]);
                            System.debug('studWrapper---'+ studWrapper);
                            Map<String, Object> fieldValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(studWrapper));
                            for (String key : fieldValues.keySet()){
                                if(String.isNotBlank((String)fieldValues.get(key))){
                                    constructJson.put(key, (String)fieldValues.get(key));
                                }
                            }
                            
                            if(stud[0].Parent_Account__c != null){
                                parentAcc = [SELECT Id, Name, Parent_Relationship_Father_Mother__c, Parent_Contact_Telephone__c, Phone, 
                                             Parent_Email_Address__c, Parent_NRIC_Passport_No__c, Parent_Occupation__c, 
                                             Street__c, State__c, Postcode__c, City__c, Country__c FROM Account 
                                             WHERE Id =: stud[0].Parent_Account__c LIMIT 1];
                                if(!parentAcc.isEmpty()){
                                    System.debug('parentAcc---'+ parentAcc);
                                    SFWebServiceWrapper pAccWrapper = new SFWebServiceWrapper(parentAcc[0]);
                                    System.debug('pAccWrapper---'+ pAccWrapper);
                                    Map<String, Object> accFieldValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(pAccWrapper));
                                    for (String key : accFieldValues.keySet()){
                                        if(String.isNotBlank((String)accFieldValues.get(key))){
                                            constructJson.put(key, (String)accFieldValues.get(key));
                                        }
                                    }
                                    if(stud[0].Primary_Contact__c != null){
                                        parentCon = [SELECT Id, Name, Relationship__c, NRIC_Passport_No__c, Occupation__c, HomePhone, 
                                                     MobilePhone, Email, Street__c, Postcode__c, City__c, State__c, Country__c FROM Contact 
                                                     WHERE Id =: stud[0].Primary_Contact__c LIMIT 1];
                                        if(!parentCon.isEmpty() && parentCon[0].Email != parentAcc[0].Parent_Email_Address__c){
                                            System.debug('parentCon---'+ parentCon);
                                            SFWebServiceWrapper pConWrapper = new SFWebServiceWrapper(parentCon[0]);
                                            System.debug('pConWrapper---'+ pConWrapper);
                                            Map<String, Object> conFieldValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(pConWrapper));
                                            for (String key : conFieldValues.keySet()){
                                                if(String.isNotBlank((String)conFieldValues.get(key))){
                                                    constructJson.put(key, (String)conFieldValues.get(key));
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if(progApplication[0].Programme_Master__c != null){
                        progMaster = [SELECT Id, CRMProgramme_Master_ID__c, Name, Programme_Code__c FROM Programme_Master__c 
                                      WHERE Id =: progApplication[0].Programme_Master__c LIMIT 1];
                        if(!progMaster.isEmpty()){
                            System.debug('progMaster---'+ progMaster);
                            SFWebServiceWrapper progMasterWrapper = new SFWebServiceWrapper(progMaster[0]);
                            System.debug('progMasterWrapper---'+ progMasterWrapper);
                            Map<String, Object> fieldValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(progMasterWrapper));
                            for (String key : fieldValues.keySet()){
                                if(String.isNotBlank((String)fieldValues.get(key))){
                                    constructJson.put(key, (String)fieldValues.get(key));
                                }
                            }
                        }
                    }
                    
                    if(progApplication[0].Intake_Master__c != null){
                        intakeMaster = [SELECT Id, Intake_Number__c, Study_Mode__c FROM Intake_Master__c
                                        WHERE Id =: progApplication[0].Intake_Master__c LIMIT 1];
                        if(!intakeMaster.isEmpty()){
                            System.debug('intakeMaster---'+ intakeMaster);
                            SFWebServiceWrapper intakeMasterWrapper = new SFWebServiceWrapper(intakeMaster[0]);
                            System.debug('intakeMasterWrapper---'+ intakeMasterWrapper);
                            Map<String, Object> fieldValues = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(intakeMasterWrapper));
                            for (String key : fieldValues.keySet()){
                                if(String.isNotBlank((String)fieldValues.get(key))){
                                    constructJson.put(key, (String)fieldValues.get(key));
                                }
                            }
                        }
                    }
                    
                    
                }
                
            }
            
            crmJson = JSON.serialize(constructJson);
            System.debug('crmJson---'+ crmJson);
            SIS_EMXApiCallouts.sendStudentDeatils(crmJson, progAppId, 'Programme Application');
            // if(String.isNotBlank(emxId)){
            //     progApplication[0].EMX_ID__c = emxId;
            //     update progApplication[0];
            // }
            
        }catch (Exception e){
            System.debug('error---'+ e.getMessage()+ 'Line Number---'+ e.getLineNumber());
        }
    }
}