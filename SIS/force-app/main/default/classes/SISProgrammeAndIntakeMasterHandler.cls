@RestResource(urlMapping='/programMasters/intakeMasters/*')
global class SISProgrammeAndIntakeMasterHandler {
    public class MyException extends Exception {}
    
    @HttpPost
    global static void handleProgrammeAndIntakeMaster(){
        Savepoint sp = Database.setSavepoint();
        
        Map<string,object> resultMsg = new Map<string,object>();
        Map<string,Map<string,object>> resultMap = new Map<string,Map<string,object>>();
        
        String pmId;
        RestResponse res = RestContext.response;
        System.debug('res---'+ res);
        RestRequest req = RestContext.request;
        try{
            //RestRequest req = RestContext.request;
            System.debug('req---'+ req);
            if( req != null && req.requestBody != null ){
                string requestBody = req.requestBody.toString();
                System.debug('requestBody---'+ requestBody);
                Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                System.debug('requestMap---'+ requestMap);
                
                if(requestMap.containsKey('programmeMaster') && requestMap.containsKey('intakeMaster') && requestMap.size() == 2){
                    String programMasterJson = JSON.serialize(requestMap.get('programmeMaster'));
                    EMXWebServiceWrapper.programMaster programM = (EMXWebServiceWrapper.programMaster) JSON.deserialize(programMasterJson, EMXWebServiceWrapper.programMaster.class);
                    System.debug('programM---'+ programM);
                    
                    if(String.isBlank(programM.CRMProgrammeMasterID) && String.isBlank(programM.EMXID) && String.isBlank(programM.programCode) && String.isBlank(programM.programmeName) && 
                       String.isBlank(programM.programmeDuration) && String.isBlank(programM.levelOfEducation) && String.isBlank(programM.isOffer) && String.isBlank(programM.CRMCampusID) && 
                       String.isBlank(programM.campusCode) && String.isBlank(programM.campusName) && String.isBlank(programM.campusLocation) &&
                       String.isBlank(programM.schoolCode) && String.isBlank(programM.schoolName) && String.isBlank(programM.departmentName) && String.isBlank(programM.departmentCode)){
                           //    System.debug('Program Master has no values. So no need to create or update');
                           //    res.statusCode = 200;
                           //    requestMap.put('programmeMaster',programM);
                           
                           throw new MyException('Please provide the Programme Master details.');
                       }else{
                           List<String> missingFields = new List<String>();
                           //if(String.isBlank(programM.EMXID)) missingFields.add('EMXID');
                           if(String.isBlank(programM.programCode)) missingFields.add('programCode');
                           if(String.isBlank(programM.programmeName)) missingFields.add('programmeName');
                           if(String.isBlank(programM.programmeDuration)) missingFields.add('programmeDuration');
                           if(String.isBlank(programM.levelOfEducation)) missingFields.add('levelOfEducation');
                           if(String.isBlank(programM.isOffer)) missingFields.add('isOffer');
                           if(String.isBlank(programM.CRMCampusID)) missingFields.add('CRMCampusID');
                           if(String.isBlank(programM.campusCode)) missingFields.add('campusCode');
                           if(String.isBlank(programM.campusName)) missingFields.add('campusName');
                           if(String.isBlank(programM.campusLocation)) missingFields.add('campusLocation');
                           if(String.isBlank(programM.schoolCode)) missingFields.add('schoolCode');
                           
                           if(!missingFields.isEmpty()){
                               throw new MyException('The required field(s) are missing for Programme Master: ' + String.join(missingFields, ', '));
                           }
                           
                           List<Account> CRMCampusSFID = new List<Account>();
                           
                           CRMCampusSFID =[SELECT Id,Name FROM Account where id =:programM.CRMCampusID AND RecordType.DeveloperName='Campus_ID' limit 1];
                           System.debug('CRMCampusSFID= '+CRMCampusSFID);
                           
                           List<String> missingRecords = new List<String>();
                           
                           if (CRMCampusSFID.isEmpty()) {  
                               throw new MyException('No record found with the provided:CRMCampusID ');
                           } 
                           
                           if(String.isBlank(programM.CRMProgrammeMasterID)){
                               Programme_Master__c pm = new Programme_Master__c();
                               pm.EMX_ID__c = String.isNotBlank(programM.EMXID) ? programM.EMXID : '';
                               pm.Programme_Code__c = String.isNotBlank(programM.programCode) ? programM.programCode : '';
                               pm.Name = String.isNotBlank(programM.programmeName) ? programM.programmeName : '';
                               pm.Programme_Duration__c = String.isNotBlank(programM.programmeDuration) ? Double.valueOf(programM.programmeDuration) : null;
                               pm.Level_of_Education__c = String.isNotBlank(programM.levelOfEducation) ? programM.levelOfEducation : '';
                               pm.Is_Offer__c = String.isNotBlank(programM.isOffer) ? programM.isOffer : '';
                               pm.Campus_SFID__c =CRMCampusSFID[0].Id!=null ?CRMCampusSFID[0].Id:'';
                               pm.Campus_Code__c = String.isNotBlank(programM.campusCode) ? programM.campusCode : '';
                               pm.Campus_Name__c = String.isNotBlank(programM.campusName) ? programM.campusName : '';
                               pm.Campus_Location__c = String.isNotBlank(programM.campusLocation) ? programM.campusLocation : '';
                               pm.School_Code__c = String.isNotBlank(programM.schoolCode) ? programM.schoolCode : '';
                               pm.School_Name__c = String.isNotBlank(programM.schoolName) ? programM.schoolName : '';
                               pm.Department_Name__c = String.isNotBlank(programM.departmentName) ? programM.departmentName : '';
                               pm.Department_Code__c = String.isNotBlank(programM.departmentCode) ? programM.departmentCode : '';
                               
                               insert pm;
                               System.debug('Program Master without existing SFID Id---'+ pm);
                               pmId = pm.Id;
                               res.statusCode = 200;
                               programM.programmeMasterStatus = 'Program Master record created successfully.';
                               programM.CRMProgrammeMasterID = pm.Id;
                               requestMap.put('programmeMaster',programM);
                           }else{
                               List<Programme_Master__c> existingPM = new List<Programme_Master__c>();
                               existingPM = [SELECT Id, Programme_Code__c, Name, Programme_Duration__c, Level_of_Education__c, Is_Offer__c, Campus_SFID__c, Campus_Code__c, Campus_Name__c, Campus_Location__c, School_Code__c, EMX_ID__c, School_Name__c, Department_Name__c, Department_Code__c  FROM Programme_Master__c WHERE Id =: programM.CRMProgrammeMasterID LIMIT 1];
                               
                               if(!existingPM.isEmpty()){
                                   existingPM[0].EMX_ID__c = String.isNotBlank(programM.EMXID) ? programM.EMXID : existingPM[0].EMX_ID__c;
                                   existingPM[0].Programme_Code__c = String.isNotBlank(programM.programCode) ? programM.programCode : existingPM[0].Programme_Code__c;
                                   existingPM[0].Name = String.isNotBlank(programM.programmeName) ? programM.programmeName : existingPM[0].Name;
                                   existingPM[0].Programme_Duration__c = String.isNotBlank(programM.programmeDuration) ? Double.valueOf(programM.programmeDuration) : existingPM[0].Programme_Duration__c;
                                   existingPM[0].Level_of_Education__c = String.isNotBlank(programM.levelOfEducation) ? programM.levelOfEducation : existingPM[0].Level_of_Education__c;
                                   existingPM[0].Is_Offer__c = String.isNotBlank(programM.isOffer) ? programM.isOffer : existingPM[0].Is_Offer__c;
                                   existingPM[0].Campus_SFID__c =CRMCampusSFID[0].Id != null ? CRMCampusSFID[0].Id:existingPM[0].Campus_SFID__c;
                                   existingPM[0].Campus_Code__c = String.isNotBlank(programM.campusCode) ? programM.campusCode : existingPM[0].Campus_Code__c;
                                   existingPM[0].Campus_Name__c = String.isNotBlank(programM.campusName) ? programM.campusName : existingPM[0].Campus_Name__c;
                                   existingPM[0].Campus_Location__c = String.isNotBlank(programM.campusLocation) ? programM.campusLocation : existingPM[0].Campus_Location__c;
                                   existingPM[0].School_Code__c = String.isNotBlank(programM.schoolCode) ? programM.schoolCode : existingPM[0].School_Code__c;
                                   existingPM[0].School_Name__c = String.isNotBlank(programM.schoolName) ? programM.schoolName : existingPM[0].School_Name__c;
                                   existingPM[0].Department_Name__c = String.isNotBlank(programM.departmentName) ? programM.departmentName : existingPM[0].Department_Name__c;
                                   existingPM[0].Department_Code__c = String.isNotBlank(programM.departmentCode) ? programM.departmentCode : existingPM[0].Department_Code__c;
                                   update existingPM;
                                   System.debug('Program Master with existing CRMProgrammeMasterID Id---'+ existingPM);
                                   res.statusCode = 200;
                                   programM.programmeMasterStatus = 'Program Master record updated successfully.';
                                   programM.CRMProgrammeMasterID = existingPM[0].Id;
                                   requestMap.put('programmeMaster',programM);
                               }else{
                                   System.debug('Program Master with the provided CRMProgrammeMasterID not found.');
                                   throw new MyException('Program Master with the given CRMProgrammeMasterID not found. Please enter a valid CRMProgrammeMasterID.');
                               }
                           }
                       }
                    
                    
                    String intakeMasterJson = JSON.serialize(requestMap.get('intakeMaster'));
                    System.debug('intakeMasterJson----'+ intakeMasterJson);
                    List<Object> intakeList = (List<Object>) JSON.deserializeUntyped(intakeMasterJson);
                    System.debug('Deserialized List: ' + intakeList);
                    List<EMXWebServiceWrapper.intakeMaster> intakeMasterRes = new List<EMXWebServiceWrapper.intakeMaster>();
                    List<Programme_Master__c> allProgMaster = [SELECT Id FROM Programme_Master__c];
                    List<Intake_Master__c> allIntakeMaster = [SELECT Id, EMX_ID__c, Intake_Number__c, Study_Mode__c, Course_Detail_Intake_ID__c, Application_Allowed__c, Programme_Master__c FROM Intake_Master__c];
                    for(Object obj: intakeList){
                        String intakeListJson = JSON.serialize(obj);
                        EMXWebServiceWrapper.intakeMaster intakeOne = (EMXWebServiceWrapper.intakeMaster) JSON.deserialize(intakeListJson, EMXWebServiceWrapper.intakeMaster.class);
                        System.debug('intakeOne---'+ intakeOne.CRMIntakeMasterID);
                        
                        List<Programme_Master__c> existingPM = new List<Programme_Master__c>();
                        if (String.isNotBlank(intakeOne.CRMProgrammeMasterID)){
                            System.debug('intakeOne.CRMProgrammeMasterID---'+ intakeOne.CRMProgrammeMasterID);
                            for (Programme_Master__c pm : allProgMaster) {
                                if (pm.Id == intakeOne.CRMProgrammeMasterID) {
                                    existingPM.add(pm);
                                    break;
                                }
                            }
                            //existingPM = [SELECT Id FROM Programme_Master__c WHERE Id = :intakeOne.CRMProgrammeMasterID LIMIT 1];
                        }
                        
                        if(String.isBlank(intakeOne.CRMIntakeMasterID) && String.isBlank(intakeOne.EMXID) && String.isBlank(intakeOne.intakeNumber) && String.isBlank(intakeOne.studyMode) &&
                           String.isBlank(intakeOne.courseDetailIntakeID) && String.isBlank(intakeOne.applicationAllowed) && String.isBlank(intakeOne.CRMProgrammeMasterID)){
                               System.debug('Intake Master has no values. So no need to create or update');
                               res.statusCode = 200;
                               requestMap.put('intakeMaster',intakeOne);
                           }else{
                               List<String> missingFields = new List<String>();
                               //if(String.isBlank(intakeOne.emxId)) missingFields.add('EMXID');
                               if(String.isBlank(intakeOne.intakeNumber)) missingFields.add('intakeNumber');
                               if(String.isBlank(intakeOne.studyMode)) missingFields.add('studyMode');
                               if(String.isBlank(intakeOne.courseDetailIntakeID)) missingFields.add('courseDetailIntakeID');
                               if(String.isBlank(intakeOne.applicationAllowed)) missingFields.add('applicationAllowed');
                               
                               
                               if(!missingFields.isEmpty()){
                                   throw new MyException('The required field(s) are missing for Intake Master: ' + String.join(missingFields, ', '));
                               }
                               
                               if(String.isBlank(intakeOne.CRMIntakeMasterID)){
                                   Intake_Master__c im = new Intake_Master__c();
                                   im.EMX_ID__c = String.isNotBlank(intakeOne.EMXID) ? intakeOne.EMXID : '';
                                   im.Intake_Number__c = String.isNotBlank(intakeOne.intakeNumber) ? intakeOne.intakeNumber : '';
                                   im.Study_Mode__c = String.isNotBlank(intakeOne.studyMode) ? intakeOne.studyMode : '';
                                   im.Course_Detail_Intake_ID__c = String.isNotBlank(intakeOne.courseDetailIntakeID) ? Double.valueOf(intakeOne.courseDetailIntakeID) : null;
                                   im.Application_Allowed__c = String.isNotBlank(intakeOne.applicationAllowed) ? intakeOne.applicationAllowed : '';
                                   if(!existingPM.isEmpty()){
                                       im.Programme_Master__c = existingPM[0].Id != null ? existingPM[0].Id : null;
                                   }else{
                                       if(String.isNotBlank(pmId)){
                                           im.Programme_Master__c = pmId;
                                           intakeOne.CRMProgrammeMasterID = pmId;
                                       }
                                   }
                                   
                                   insert im;
                                   System.debug('Intake Master without existing CRMIntakeMasterID Id---'+ im);
                                   res.statusCode = 200;
                                   intakeOne.intakeMasterStatus = 'Intake Master record created successfully.';
                                   intakeOne.CRMIntakeMasterID = im.Id;
                                   intakeMasterRes.add(intakeOne);
                                   requestMap.put('intakeMaster',intakeOne);
                               }else{
                                   List<Intake_Master__c> existingIM = new List<Intake_Master__c>();
                                   for (Intake_Master__c im : allIntakeMaster) {
                                       if (im.Id == intakeOne.CRMIntakeMasterID) {
                                           existingIM.add(im);
                                           break; 
                                       }
                                   }
                                   //existingIM = [SELECT Id, EMX_ID__c, Intake_Number__c, Study_Mode__c, Course_Detail_Intake_ID__c, Application_Allowed__c, Programme_Master__c FROM Intake_Master__c WHERE Id =: intakeOne.CRMIntakeMasterID LIMIT 1];
                                   if(!existingIM.isEmpty()){
                                       existingIM[0].EMX_ID__c = String.isNotBlank(intakeOne.EMXID) ? intakeOne.EMXID : existingIM[0].EMX_ID__c; 
                                       existingIM[0].Intake_Number__c = String.isNotBlank(intakeOne.intakeNumber) ? intakeOne.intakeNumber : existingIM[0].Intake_Number__c;
                                       existingIM[0].Study_Mode__c = String.isNotBlank(intakeOne.studyMode) ? intakeOne.studyMode : existingIM[0].Study_Mode__c;
                                       existingIM[0].Course_Detail_Intake_ID__c = String.isNotBlank(intakeOne.courseDetailIntakeID) ? Double.valueOf(intakeOne.courseDetailIntakeID) : existingIM[0].Course_Detail_Intake_ID__c;
                                       existingIM[0].Application_Allowed__c = String.isNotBlank(intakeOne.applicationAllowed) ? intakeOne.applicationAllowed : existingIM[0].Application_Allowed__c;
                                       if(!existingPM.isEmpty()){
                                           existingIM[0].Programme_Master__c = existingPM[0].Id != null ? existingPM[0].Id : existingIM[0].Programme_Master__c;
                                       }
                                       
                                       update existingIM;
                                       System.debug('Intake Master with existing CRMIntakeMasterID---'+ existingIM);
                                       res.statusCode = 200;
                                       intakeOne.intakeMasterStatus = 'Intake Master record updated successfully.';
                                       intakeOne.CRMIntakeMasterID = existingIM[0].Id;
                                       intakeMasterRes.add(intakeOne);
                                       requestMap.put('intakeMaster',intakeOne);
                                   }else{
                                       System.debug('Intake Master with existing CRMIntakeMasterID not found.');
                                       throw new MyException('Intake Master with the given CRMIntakeMasterID not found. Please enter a valid CRMIntakeMasterID.');
                                   }
                               }
                           }
                    }
                    requestMap.put('intakeMaster', intakeMasterRes);
                    System.debug('intakeMasterRes---'+ intakeMasterRes);
                }else{
                    throw new MyException('Please do not make any changes in the JSON body structure. It should contain programmeMaster and intakeMaster.');
                }
                resultMsg.put('body', requestMap);
            }
            resultMap.put('status',resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Success');
            
            
        }catch(MyException e){
            Database.rollback(sp);
            System.debug('Error---'+ e.getStackTraceString()+ e.getTypeName());
            res.statusCode = 400;
            resultMsg.put('message',string.valueOf(e.getMessage()));
            resultMap.put('error',resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
            system.debug('res.responseBody---'+res.responseBody.toString());
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error---'+ e.getMessage());
            System.debug('Error---'+ e.getStackTraceString()+ e.getTypeName());
            res.statusCode = 400;
            resultMsg.put('message',string.valueOf(e.getMessage()));
            resultMap.put('error',resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
        }
    } 
}