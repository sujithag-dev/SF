@RestResource(urlMapping='/ProgramApplication/*')
global class EMXWebServiceForProgramApplication {
    public class MyException extends Exception {}
    
    @HttpPatch
    global static void updateProgramApplication() {
        Map<String, Object> resultMsg = new Map<String, Object>();
        Map<String, Map<String, Object>> resultMap = new Map<String, Map<String, Object>>();
        RestResponse res = RestContext.response;
        RestRequest req = RestContext.request;
        
        try {
            
            if (req == null || req.requestBody == null) {
                throw new MyException('Invalid request: No request body found.');
            }
            
            String requestBody = req.requestBody.toString();
            System.debug('Request Body: ' + requestBody);
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            System.debug('Parsed Request Map: ' + requestMap);
            
            if (!requestMap.containsKey('programApplication')) {
                throw new MyException('Missing "programApplication" in request payload.');
            }
            
            String programJson = JSON.serialize(requestMap.get('programApplication'));
            System.debug('Program JSON: ' + programJson);
            EMXWebServiceWrapper.programApplication WrapProgram = (EMXWebServiceWrapper.programApplication) JSON.deserialize(programJson, EMXWebServiceWrapper.programApplication.class);
            System.debug('WrapProgram: ' + WrapProgram);
            
            
            if (String.isBlank(WrapProgram.CRMProgramApplicationID)) {
                throw new MyException('CRMProgramApplicationID is mandatory to update. Please enter CRMProgramApplicationID.');
            }
            
            
            
            List<String> missingFields = new List<String>();
            if (String.isBlank(WrapProgram.CRMStudentID)) missingFields.add('CRMStudentID');
            if (String.isBlank(WrapProgram.CRMProgrammeMasterID)) missingFields.add('CRMProgrammeMasterID');
            if (String.isBlank(WrapProgram.CRMIntakeMasterID)) missingFields.add('CRMIntakeMasterID');
            
            
            
            
            if (!missingFields.isEmpty()) {
                
                throw new MyException('The required field(s) are missing: ' + String.join(missingFields, ', '));
            }
            
            
            List<Student__c> std = [SELECT Id FROM Student__c WHERE Id = :WrapProgram.CRMStudentID LIMIT 1];
            List<Programme_Master__c> pMaster = [SELECT Id FROM Programme_Master__c WHERE Id = :WrapProgram.CRMProgrammeMasterID LIMIT 1];
            List<Intake_Master__c> iMaster = [SELECT Id, Programme_Master__r.Id 
                                              FROM Intake_Master__c 
                                              WHERE Id = :WrapProgram.CRMIntakeMasterID 
                                              AND Programme_Master__r.Id = :WrapProgram.CRMProgrammeMasterID 
                                              LIMIT 1];
            
            
            List<String> missingRecords = new List<String>();
            if (std.isEmpty()) missingRecords.add('CRMStudentID');
            if (pMaster.isEmpty()) missingRecords.add('CRMProgrammeMasterID');
            if (iMaster.isEmpty()) missingRecords.add('CRMIntakeMasterID');
            
            if (!missingRecords.isEmpty()) {
                String errorMessage = 'No record found with the provided: ' + String.join(missingRecords, ', ');
                if (missingRecords.contains('CRMIntakeMasterID')) {
                    errorMessage +='.  Please ensure that the provided CRMIntakeMasterID is correct and is linked to CRMProgrammeMasterID.';
                } 
                throw new MyException(errorMessage);
            }
            
            Map<String, String> dateFields = new Map<String, String>{
                'offerDate' => WrapProgram.offerDate,
                    'acceptanceDate' => WrapProgram.acceptanceDate,
                    'immigrationPassExpiryDate' => WrapProgram.immigrationPassExpiryDate
                    };
                        
                        
                        for (String fieldName : dateFields.keySet()) {
                            String dateValue = dateFields.get(fieldName);
                            if (String.isNotBlank(dateValue) && !Pattern.matches('^\\d{4}-\\d{1,2}-\\d{1,2}$', dateValue)) {
                                throw new MyException('Invalid Date Format for ' + fieldName + '. Please enter yyyy-MM-dd format.');
                            }
                        }
            
            
            
            
            
            List<Programme_Application__c> applicationData = [SELECT Id,EMX_ID__c, Offer_Status__c, Conditional_Code__c, 
                                                              Offer_Letter_Printed_Date__c, Acceptance_Date__c, 
                                                              Immigration_Pass_Type__c, Immigration_Pass_Expiry_Date__c, 
                                                              Immigration_Pass_Institution_Name__c, Student__c, 
                                                              Programme_Master__c, Intake_Master__c
                                                              FROM Programme_Application__c 
                                                              WHERE Id = :WrapProgram.CRMProgramApplicationID 
                                                              LIMIT 1];
            
            if (applicationData.isEmpty()) {
                throw new MyException('No matching Program Application record found.');
            }
            
            Programme_Application__c application = applicationData[0];
            
            
            application.Offer_Status__c = String.isNotBlank(WrapProgram.offerStatus) ? WrapProgram.offerStatus : application.Offer_Status__c;
            application.EMX_ID__c =String.isNotBlank(WrapProgram.EMXID)?WrapProgram.EMXID : application.EMX_ID__c;
            application.Conditional_Code__c = String.isNotBlank(WrapProgram.conditionalCode) ? WrapProgram.conditionalCode : application.Conditional_Code__c;
            application.Offer_Letter_Printed_Date__c = String.isNotBlank(WrapProgram.offerDate) ? Date.valueOf(WrapProgram.offerDate) : application.Offer_Letter_Printed_Date__c;
            application.Acceptance_Date__c = String.isNotBlank(WrapProgram.acceptanceDate) ? Date.valueOf(WrapProgram.acceptanceDate) : application.Acceptance_Date__c;
            application.Immigration_Pass_Type__c = String.isNotBlank(WrapProgram.immigrationPassType) ? WrapProgram.immigrationPassType : application.Immigration_Pass_Type__c;
            application.Immigration_Pass_Expiry_Date__c = String.isNotBlank(WrapProgram.immigrationPassExpiryDate) ? Date.valueOf(WrapProgram.immigrationPassExpiryDate) : application.Immigration_Pass_Expiry_Date__c;
            application.Immigration_Pass_Institution_Name__c = String.isNotBlank(WrapProgram.immigrationPassInstitutionName) ? WrapProgram.immigrationPassInstitutionName : application.Immigration_Pass_Institution_Name__c;         
            application.Student__c = std[0].Id;
            application.Programme_Master__c = pMaster[0].Id;
            application.Intake_Master__c = iMaster[0].Id;
            
            update application;
            System.debug('Program Application data updated successfully');
            
            res.statusCode = 200;
           // WrapProgram.programApplicationId=application.Id;
            WrapProgram.programApplicationStatus='Program Application record updated successfully.';
            //resultMsg.put('message', 'Program Application record updated successfully.');
            resultMsg.put('body', WrapProgram);
            //resultMsg.put('programId', application.Id);
            resultMap.put('status', resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Success');
            
        } catch (MyException e) {
            System.debug('Error: ' + e.getStackTraceString());
            res.statusCode = 400;
            resultMsg.put('programApplicationStatus', e.getMessage());
            resultMap.put('status', resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
        }catch (Exception e) {
            System.debug('Error---'+ e.getStackTraceString());
            res.statusCode = 400;
            resultMsg.put('programApplicationStatus',string.valueOf(e.getMessage()));
            resultMap.put('status',resultMsg);
            String responseBody = JSON.serialize(resultMap);
            res.responseBody = Blob.valueOf(responseBody);
            SISIntegrationLog.createLog(req.requestBody.toString(),responseBody,'Failure');
        }
        
        //res.responseBody = Blob.valueOf(JSON.serialize(resultMap));
        System.debug('Response Body: ' + res.responseBody.toString());
    }
    
}