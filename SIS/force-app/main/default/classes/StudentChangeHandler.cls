public class StudentChangeHandler {
    public static String clientID = System.Label.SIS_clientID;
    private static String orgId;
    
    private static String getOrgId() {
        if (orgId == null) {
            String fullOrgId = [SELECT Id FROM Organization LIMIT 1].Id;
            orgId=fullOrgId.substring(0, 15);
        }
        return orgId;
    }
    
    public static final Map<String, String> studentFieldMap = new Map<String, String>{
            'Marital_Status__c' => 'MARITAL_STATUS',
            'Religion__c' => 'RELIGION',
            'Street_m__c' => 'RESIDENTIAL_STREET',
            'Postcode_m__c' => 'RESIDENTIAL_POSTCODE',
            'City_m__c' => 'RESIDENTIAL_CITY',
            'State_m__c' => 'RESIDENTIAL_STATE',
            'Country_m__c' => 'RESIDENTIAL_COUNTRY',
            'Contact_Telephone_No_m__c' => 'RESIDENTIAL_TEL_NO',
            'Student_Mobile_No__c' => 'STUDENT_MOBILE_NO',
            'Email_Address__c' => 'E_MAIL',
            'City_p__c' => 'PERMANENT_CITY',
            'Street_p__c' => 'PERMANENT_STREET',
            'Postcode_p__c' => 'PERMANENT_POSTCODE',
            'State_p__c' => 'PERMANENT_STATE',
            'Country_p__c' => 'PERMANENT_COUNTRY',
            'Contact_Telephone_No_p__c' => 'PERMANENT_TEL_NO',
            'Preferred_Name__c' => 'PREFERRED_NAME',
            'Emergency_Contact_Name__c' => 'EMERGENCY_NAME',
            'Emergency_Relationship__c' => 'EMERGENCY_RELATIONSHIP',
            'Emergency_Contact_home__c' => 'EMERGENCY_CONTACT_HOME',
            'Emergency_Contact_Mobile__c' => 'EMERGENCY_CONTACT_MOBILE',
             'Emergency_Email__c' => 'EMERGENCY_EMAIL'   
            };
                
                
                public static final Map<String, String> parentFieldMap = new Map<String, String>{
                    'Name' => 'PARENTS_NAME',
                        'Parent_Relationship_Father_Mother__c' => 'PARENTS_RELATIONSHIP',
                        'Parent_Contact_Telephone__c' => 'PARENTS_RESIDENTIAL_TEL',
                        'Phone' => 'PARENT_MOBILE_NO',
                        'Parent_Email_Address__c' => 'PARENTS_EMAIL',
                        'Parent_NRIC_Passport_No__c' => 'PARENTS_IC_PASSPORT',
                        'Parent_Occupation__c' => 'PARENTS_OCCUPATION',
                        'Street__c' => 'PARENTS_RESIDENTIAL_STREET',
                        'Postcode__c' => 'PARENTS_RESIDENTIAL_POSTCODE',
                        'City__c' => 'PARENTS_RESIDENTIAL_CITY',
                        'State__c' => 'PARENTS_RESIDENTIAL_STATE',
                        'Country__c' => 'PARENTS_RESIDENTIAL_COUNTRY'
                        };
                            
                            public static void processStudentChanges(List<Student__c> newList, Map<Id, Student__c> oldMap) {
                                System.debug('newList---'+ newList + newList.size());
                                List<Programme_Application__c> checkProgApp= new List<Programme_Application__c>();
                                checkProgApp = [SELECT Id FROM Programme_Application__c WHERE Student__c =: newList[0].Id AND EMX_ID__c != null];
                                if(!checkProgApp.isEmpty()){
                                    System.debug('checkProgApp---'+ checkProgApp);
                                    processChanges(newList, oldMap, 'Student__c');
                                }else{
                                    System.debug('No Programme Application found for the Student. So no need to send the details.');
                                }
                            }
    
    
                           public static void processAccountChanges(List<Account> newList, Map<Id, Account> oldMap) {
                                System.debug('newList---'+ newList);
                                processChanges(newList, oldMap, 'Account');
                                // List<Student__c> getStudents = new List<Student__c>();
                                // getStudents = [SELECT Id FROM Student__c WHERE Parent_Account__c =: newList[0].Id];
                                // if(!getStudents.isEmpty()){
                                //     System.debug('getStudents---' + getStudents);
                                //     for(Student__c stud: getStudents){
                                //         List<Programme_Application__c> allProgApp= new List<Programme_Application__c>();
                                //         allProgApp = [SELECT Id, Student__c, EMX_ID__c FROM Programme_Application__c WHERE Student__c =: stud.Id AND EMX_ID__c != null];
                                //         if(!allProgApp.isEmpty()){
                                //             System.debug('allProgApp---'+ allProgApp);
                                //             processChanges(newList, oldMap, 'Account');
                                //         }else{
                                //             System.debug('No Programme Application found for the Student. So no need to send the details.');
                                //         }
                                //     }
                                // }   
                            }
    
    
    
                           private static void processChanges(List<SObject> newList, Map<Id, SObject> oldMap, String objectType) {
                            List<Map<String, Object>> updatedFields = new List<Map<String, Object>>();
        
                                 User currentUser = [SELECT Username, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        
                             if (currentUser.Profile.Name == 'Minimum Access - API Only Integrations') {
                                 System.debug('Skipping for Minimum Access - API Only Integrations profile');
                                  return;
                             }
        
        
        
                           Set<String> systemFieldsToIgnore = new Set<String>{
                               'LastModifiedDate', 'LastModifiedById', 'SystemModstamp', 'CreatedDate', 'CreatedById'
                              };
                    
                    
                    
                    
                    
                    for (SObject newRec : newList) {
                        
                        SObject oldRec = oldMap.get(newRec.Id);  
                        System.debug('oldRec'+oldRec);
                        if (oldRec == null) continue;
                        
                        Map<String, Object> newRecMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(newRec));
                        Map<String, Object> oldRecMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oldRec));
                        System.debug('newRecMap'+newRecMap);
                        System.debug('oldRecMap'+oldRecMap);
                        
                        
                        for (String fieldName : newRecMap.keySet()) {
                            if (systemFieldsToIgnore.contains(fieldName)) continue;
                            
                            Object newVal = newRecMap.get(fieldName);
                            Object oldVal = oldRecMap.get(fieldName);
                            if ((newVal != oldVal) && (newVal == null || oldVal == null || !newVal.equals(oldVal))) {
                                
                                String EmxApiName;
                                if (objectType == 'Student__c' && studentFieldMap.containsKey(fieldName)) {
                                    EmxApiName = studentFieldMap.get(fieldName);
                                }else if (objectType == 'Account' && parentFieldMap.containsKey(fieldName)) {
                                    EmxApiName = parentFieldMap.get(fieldName);
                                }else {
                                    continue;
                                }
                                
                                if (objectType == 'Student__c') {
                                     Student__c studentRec = (Student__c)newRec;
                                    Map<String, Object> updatedJson = new Map<String, Object>{
                                        'client_id' => clientID,
                                            'CRM_MODE' => 'STUD_UPDATE',
                                            'CRM_STUD_ID' => studentRec.Id,
                                            'COLUMN_NAME' => EmxApiName,
                                            'NEW_VALUE' => String.valueOf(newVal),
                                            'CRM_ORG_ID' => getOrgId(),
                                            'CRM_CAMPUS_ID' => studentRec.Campus_SFID__c
                                            };
                                            System.debug('CRM_CAMPUS_ID'+studentRec.Campus_SFID__c);    
                                                updatedFields.add(updatedJson);
                                    
                                    
                                } else if (objectType == 'Account') {
                                    List<Student__c> students = getStudentsFromAccount(newRec.Id);
                                    for (Student__c student : students) {
                                        Map<String, Object> updatedJson = new Map<String, Object>{
                                            'client_id' => clientID,
                                                'CRM_MODE' => 'STUD_UPDATE',
                                                'CRM_STUD_ID' => student.Id,
                                                'COLUMN_NAME' => EmxApiName,
                                                'NEW_VALUE' => String.valueOf(newVal),
                                                'CRM_ORG_ID' => getOrgId(),
                                                'CRM_CAMPUS_ID' => student.Campus_SFID__c
                                                };
                                                    updatedFields.add(updatedJson);
                                       
                                    }
                                }
                                
                            }
                        }
                    }
        
        for (Map<String, Object> stdUpdatedJson : updatedFields) {
            String StudentRecordId;
            System.debug('Json->'+stdUpdatedJson);
            if(stdUpdatedJson.containskey('CRM_STUD_ID')){
                StudentRecordId=String.valueOf(stdUpdatedJson.get('CRM_STUD_ID'));
                System.debug('StudentRecordId'+StudentRecordId);
            }
            String jsonPayload = JSON.serialize(stdUpdatedJson);
            System.debug('Final Payload: ' + jsonPayload);
            try{
                SIS_EMXApiCallouts.sendStudentDeatils(jsonPayload,StudentRecordId,'Student');
            }catch (Exception e) {
                System.debug('Failed to send student details: ' + e.getMessage());
            }
        }
        
    }
    
   private static List<Student__c> getStudentsFromAccount(Id accountId) { 
    //List<Student__c> students = [SELECT Id, Campus_SFID__c FROM Student__c WHERE Parent_Account__c = :accountId];
    List<Student__c> students = [SELECT Id, Campus_SFID__c FROM Student__c WHERE Parent_Account__c = :accountId AND Id IN (SELECT Student__c FROM Programme_Application__c WHERE EMX_ID__c != NULL)];
    if (!students.isEmpty()) {
        return students;
    }
    return new List<Student__c>();
}

}