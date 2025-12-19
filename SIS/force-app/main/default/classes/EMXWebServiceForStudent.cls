@RestResource(urlMapping='/student/*')
global class EMXWebServiceForStudent {
    public class MyException extends Exception {}

    @HttpPatch
    global static void updateStudent(){
        
        Map<string,object> resultMsg = new Map<string,object>();
        Map<string,Map<string,object>> resultMap = new Map<string,Map<string,object>>();
        
        Boolean isUpdate  = false;
        
        RestResponse res = RestContext.response;
        System.debug('res---'+ res);
        
         RestRequest req = RestContext.request;
        
        try{
           // RestRequest req = RestContext.request;
            System.debug('req---'+ req);
            
            if( req != null && req.requestBody != null ){
                string requestBody = req.requestBody.toString();
                System.debug('requestBody---'+ requestBody);
                Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                System.debug('requestMap---'+ requestMap);
                Map<String, Object> studentMap = (Map<String, Object>) requestMap.get('student');
                Object dateOfBirth = studentMap.get('dateOfBirth');
                dateOfBirth = dateOfBirth != null ? dateOfBirth : null;
                studentMap.put('dateOfBirth', dateOfBirth);
                Object passportExpiryDate = studentMap.get('passportExpiryDate');
                passportExpiryDate = passportExpiryDate != null ? passportExpiryDate : null;
                studentMap.put('passportExpiryDate', passportExpiryDate);
                requestMap.put('student', studentMap);
                System.debug('requestMap---'+ requestMap);
                
                String studentJson = JSON.serialize(requestMap.get('student'));
                System.debug('studentJson---'+ studentJson);
                EMXWebServiceWrapper.student student = (EMXWebServiceWrapper.student) JSON.deserialize(studentJson, EMXWebServiceWrapper.student.class);
                System.debug('student---'+ student);

                List<String> missingFields = new List<String>();
                if(String.isBlank(student.name)) missingFields.add('name');
                if(String.isBlank(student.nricOrPassportNo)) missingFields.add('nricOrPassportNo');
                if(String.isBlank(student.dateOfBirth)) missingFields.add('dateOfBirth');
                //if(String.isBlank(student.CRMHouseholdID)) missingFields.add('CRMHouseholdID');

                if(!missingFields.isEmpty()){
                    throw new MyException('The required field(s) are missing for Student: ' + String.join(missingFields, ', '));
                }
                
                Boolean isDOB = String.isNotBlank(student.dateOfBirth) ? checkDateFormat(student.dateOfBirth) : true;
                Boolean isPassExpire = String.isNotBlank(student.passportExpiryDate) ? checkDateFormat(student.passportExpiryDate) : true;
                
                isUpdate = isDOB && isPassExpire;
                System.debug('isUpdate---'+ isUpdate);
                
                if(isUpdate){
                    if(String.isNotBlank(student.CRMStudentID)){
                        /*List<Account> parentAcc = new List<Account>();
                        List<Contact> parentCon = new List<Contact>();
                        if (String.isNotBlank(student.CRMHouseholdID)) {
                            parentAcc = [SELECT Id FROM Account WHERE Id =: student.CRMHouseholdID LIMIT 1];
                            if(parentAcc.isEmpty()){
                                throw new MyException('Record not found for the provided CRMHouseholdID. Please enter a valid CRMHouseholdID');
                            }else{
                                parentCon = [SELECT Id, Primary_Account__c FROM Contact WHERE Primary_Account__c = :student.CRMHouseholdID AND Primary_Contact__c = TRUE LIMIT 1];

                            }
                        }*/
                        
                        List<Student__c> stud = [SELECT Id, Student_SFID__c, Student_UID__c, EMX_ID__c, Name, Preferred_Name__c, NRIC_Passport_No__c, 
                                                 Passport_Expiry_Date__c, Date_of_Birth__c, Nationality__c, Citizenship__c, Gender__c, Marital_Status__c, Race__c, 
                                                 Religion__c, Student_Mobile_No__c, Email_Address__c, Street_m__c, Postcode_m__c, City_m__c, State_m__c, Country_m__c, 
                                                 Contact_Telephone_No_m__c, Street_p__c, Postcode_p__c, City_p__c, State_p__c, Country_p__c, Contact_Telephone_No_p__c, 
                                                 Parent_Account__c, Primary_Contact__c FROM Student__c WHERE Id =: student.CRMStudentID LIMIT 1];
                        if(!stud.isEmpty()){
                            
                            //stud[0].Student_SFID__c = String.isNotBlank(student.studentSFID) ? student.studentSFID : stud[0].Student_SFID__c;
                            stud[0].Student_UID__c = String.isNotBlank(student.studentUID) ? student.studentUID : stud[0].Student_UID__c;
                            stud[0].EMX_ID__c = String.isNotBlank(student.EMXID) ? student.EMXID : stud[0].EMX_ID__c;
                            stud[0].Name = String.isNotBlank(student.name) ? student.name : stud[0].Name;
                            stud[0].Preferred_Name__c = String.isNotBlank(student.preferredName) ? student.preferredName : stud[0].Preferred_Name__c;
                            stud[0].NRIC_Passport_No__c = String.isNotBlank(student.nricOrPassportNo) ? student.nricOrPassportNo : stud[0].NRIC_Passport_No__c;
                            stud[0].Passport_Expiry_Date__c = String.isNotBlank(student.passportExpiryDate) ? Date.valueOf(student.passportExpiryDate) : stud[0].Passport_Expiry_Date__c;
                            stud[0].Date_of_Birth__c = String.isNotBlank(student.dateOfBirth) ? Date.valueOf(student.dateOfBirth) : stud[0].Date_of_Birth__c;
                            stud[0].Nationality__c = String.isNotBlank(student.nationality) ? student.nationality : stud[0].Nationality__c;
                            //stud[0].Citizenship__c = String.isNotBlank(student.citizenship) ? student.citizenship : stud[0].Citizenship__c;
                            stud[0].Gender__c = String.isNotBlank(student.gender) ? student.gender : stud[0].Gender__c;
                            stud[0].Marital_Status__c = String.isNotBlank(student.maritalStatus) ? student.maritalStatus : stud[0].Marital_Status__c;
                            stud[0].Race__c = String.isNotBlank(student.race) ? student.race : stud[0].Race__c;
                            stud[0].Religion__c = String.isNotBlank(student.religion) ? student.religion : stud[0].Religion__c;
                            stud[0].Student_Mobile_No__c = String.isNotBlank(student.studentMobileNo) ? student.studentMobileNo : stud[0].Student_Mobile_No__c;
                            stud[0].Email_Address__c = String.isNotBlank(student.emailAddress) ? student.emailAddress : stud[0].Email_Address__c;
                            stud[0].Street_m__c = String.isNotBlank(student.mailingStreet) ? student.mailingStreet : stud[0].Street_m__c;
                            stud[0].Postcode_m__c = String.isNotBlank(student.mailingPostCode) ? student.mailingPostCode : stud[0].Postcode_m__c;
                            stud[0].City_m__c = String.isNotBlank(student.mailingCity) ? student.mailingCity : stud[0].City_m__c;
                            stud[0].State_m__c = String.isNotBlank(student.mailingState) ? student.mailingState : stud[0].State_m__c;
                            stud[0].Country_m__c = String.isNotBlank(student.mailingCountry) ? student.mailingCountry : stud[0].Country_m__c;
                            stud[0].Contact_Telephone_No_m__c = String.isNotBlank(student.mailingConTelNo) ? student.mailingConTelNo : stud[0].Contact_Telephone_No_m__c;
                            stud[0].Street_p__c = String.isNotBlank(student.permanentStreet) ? student.permanentStreet : stud[0].Street_p__c;
                            stud[0].Postcode_p__c = String.isNotBlank(student.permanentPostCode) ? student.permanentPostCode : stud[0].Postcode_p__c;
                            stud[0].City_p__c = String.isNotBlank(student.permanentCity) ? student.permanentCity : stud[0].City_p__c;
                            stud[0].State_p__c = String.isNotBlank(student.permanentState) ? student.permanentState : stud[0].State_p__c;
                            stud[0].Country_p__c = String.isNotBlank(student.permanentCountry) ? student.permanentCountry : stud[0].Country_p__c;
                            stud[0].Contact_Telephone_No_p__c = String.isNotBlank(student.permanentConTelNo) ? student.permanentConTelNo : stud[0].Contact_Telephone_No_p__c;
                            /*if(!parentAcc.isEmpty()){
                                if(stud[0].Parent_Account__c == parentAcc[0].Id){
                                    stud[0].Parent_Account__c = parentAcc[0].Id;
                                }else{
                                    throw new MyException('The parent account for the student cannot be changed.');
                                }
                            }
                            if(!parentCon.isEmpty()){
                                    stud[0].Primary_Contact__c = parentCon[0].Id != null ? parentCon[0].Id : null;
                            }*/
                            
                            update stud;
                            System.debug('Student with existing Salesforce Id---'+ stud[0].Id);
                            res.statusCode = 200;
                            student.studentStatus = 'Student record updated successfully.';
                            resultMsg.put('body', student);
                            resultMap.put('success',resultMsg);
                            String responseBody = JSON.serialize(resultMap);
                            res.responseBody = Blob.valueOf(responseBody);
                            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Success');
                        }else{
                            throw new MyException('CRMStudentID not have a matching record. Please enter a valid CRMStudentID.');
                        }
                    }else{
                        throw new MyException('CRMStudentID is mandatory to update. Please enter CRMStudentID.');
                    }
                }else{
                    throw new MyException('If dateOfBirth or passportExpiryDate entered, It should be in the format (yyyy-mm-dd).');
                }
            }
            
        }catch(MyException e){
            res.statusCode = 400;
            resultMsg.put('studentStatus',string.valueOf(e.getMessage()));
            resultMap.put('error',resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
            system.debug('res.responseBody---'+res.responseBody.toString());
        }catch(Exception e){
            System.debug('Error---'+ e.getStackTraceString()+ e.getTypeName());
            if (e.getTypeName() == 'System.DmlException') {
                resultMsg.put('studentStatus', string.valueOf(e.getDmlMessage(0)));
            } else {
                resultMsg.put('studentStatus', string.valueOf(e.getMessage()));
            }
            res.statusCode = 400;
            resultMap.put('error', resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
            System.debug('res.responseBody---' + res.responseBody.toString());
        }
        
    }
    
    public static Boolean checkDateFormat(String dateToCheck){
        String datePattern = '^\\d{4}-\\d{2}-\\d{2}$';
        return Pattern.matches(datePattern, dateToCheck);
    }
}