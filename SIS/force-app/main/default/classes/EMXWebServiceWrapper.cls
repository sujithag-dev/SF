public class EMXWebServiceWrapper {
    public class intakeMaster{
        public String CRMIntakeMasterID {get; set;}
        public String EMXID {get; set;}
        public String intakeNumber {get; set;}
        public String studyMode {get; set;}
        public String courseDetailIntakeID {get; set;}
        public String applicationAllowed {get; set;}
        public String CRMProgrammeMasterID {get; set;}
        public String intakeMasterStatus { get; set; }
    }
    
    public class programMaster{
        public String CRMProgrammeMasterID {get; set;}
        public String EMXID {get; set;}
        public String programCode {get; set;}
        public String programmeName {get; set;}
        public String programmeDuration {get; set;}
        public String levelOfEducation {get; set;}
        public String isOffer {get; set;}
        public String CRMCampusID {get; set;}
        public String campusCode {get; set;}
        public String campusName {get; set;}
        public String campusLocation {get; set;}
        public String schoolCode {get; set;}
        public String schoolName {get; set;}
        public String departmentName {get; set;}
        public String departmentCode {get; set;}
        public String programmeMasterStatus { get; set; }
    }
    
    public class student{
        public String CRMStudentID { get; set; }
        public String studentUID { get; set; }
        public String EMXID { get; set; }
        public String name { get; set; }
        public String preferredName { get; set; }
        public String nricOrPassportNo { get; set; }
        public String passportExpiryDate { get; set; }
        public String dateOfBirth { get; set; }
        public String nationality { get; set; }
        public String gender { get; set; }
        public String maritalStatus { get; set; }
        public String race { get; set; }
        public String religion { get; set; }
        public String studentMobileNo { get; set; }
        public String emailAddress { get; set; }
        public String mailingStreet { get; set; }
        public String mailingPostCode { get; set; }
        public String mailingCity { get; set; }
        public String mailingState { get; set; }
        public String mailingCountry { get; set; }
        public String mailingConTelNo { get; set; }
        public String permanentStreet { get; set; }
        public String permanentPostCode { get; set; }
        public String permanentCity { get; set; }
        public String permanentState { get; set; }
        public String permanentCountry { get; set; }
        public String permanentConTelNo { get; set; }
        public String CRMHouseholdID { get; set; }
        public String studentStatus { get; set; }
    }

    
    public class programApplication{
        public String CRMprogramApplicationID { get; set; }
        public String EMXID { get; set; }
        public String offerStatus { get; set; }
        public String conditionalCode { get; set; }
        public String offerDate { get; set; } 
        public String acceptanceDate { get; set; }
        public String immigrationPassType { get; set; }
        public String immigrationPassExpiryDate { get; set; }
        public String immigrationPassInstitutionName { get; set; }
        public String CRMStudentID { get; set; }
        public String CRMProgrammeMasterID { get; set; }
        public String CRMIntakeMasterID { get; set; }
        //public Id programApplicationId {get; set;}
        public String programApplicationStatus {get; set;}
        
    }
}