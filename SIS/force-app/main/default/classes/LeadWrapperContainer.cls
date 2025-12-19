public class LeadWrapperContainer {
    
    public class parentLead{
        public String parentCampus { get; set; }
        public String parentRelationship { get; set; }
        public String ParentLeadName { get; set; }
        public String parentEmail { get; set; }
        public String parentMobileNumber1 { get; set; }
        public String parentMobileNumber2 { get; set; }
        public String parentMobileNumber3 { get; set; }
        public String parentPreferredPhoneNumber { get; set; }
        public String parentPassportIC { get; set; }
        public String parentGender { get; set; }
        public String parentCity { get; set; }
        public String parentStateProvince { get; set; }
        public String parentCompany { get; set; }
        public String parentPhoneCompany { get; set; }
        public String parentStreet { get; set; }
        public String parentCountry { get; set; }
        public String parentPostcode { get; set; }
        public String ParentLeadStatusMessage { get; set; }
        public String ParentPassportExpiry { get; set; }    
        public Id parentAccountRecordId {get; set;} 
        public Id parentLeadRecordId {get; set;}
        public Id contactRecordId {get; set;}
        public String parentDateofBirth {get; set;}
        public String parentNationality {get; set;}
        
        
        
    }
    
    
    public class childLead{
        public String childName { get; set; }
        public String childDateofBirth { get; set; }
        public String childNationality { get; set; }
        //public String childCitizenship { get; set; }
        public String childPassportIC { get; set; }
        public String childPassportExpiry { get; set; }
        public String childEmail { get; set; }
        public String childMobilePhone1 { get; set; }
        public String childMobilePhone2 { get; set; }
        public String childMobilePhone3 { get; set; }
        public String childPreferredPhone { get; set; }
        public String childProgramme {get; set; }
        public String childIntake{get; Set;}    
        public String childVisa { get; set; }
        public String childGender { get; set; }
        public String childAccommodation { get; set; }
        public String childBursary { get; set; }
        public String childScholarship { get; set; }
        public String childLeadStatus {get; set; }  
        public String childLostreason {get; set; } 
        public String childLeadSource {get; set;} 
        public String childLeadRating {get; set;}
        public Id studentRecordId {get; set;}
        public Id childLeadRecordId {get; set;} 
        public String childLeadStatusMessage {get; set;} 
        public String childPassportIssuefrom {get; set;} 
        public String childCurrentSchool {get; set;} 
        public String childCompletedGrade {get; set;}     
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
}