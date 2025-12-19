public with sharing class SFWebServiceWrapper {

    //Student Fields
    public String STUDENT_UID {get;set;}
    public String FULL_NAME {get;set;}
    public String LAST_NAME {get;set;}
    public String FIRST_NAME {get;set;}
    public String IC_PASSPORT {get;set;}
    public String PASSPORT_EXPIRY_DATE {get;set;}
    public String DATE_OF_BIRTH {get;set;}
    public String NATIONALITY {get;set;}
    public String GENDER {get;set;}
    public String MARITAL_STATUS {get;set;}
    public String RACE {get;set;}
    public String RELIGION {get;set;}
    public String RESIDENTIAL_STREET {get;set;}
    public String RESIDENTIAL_POSTCODE {get;set;}
    public String RESIDENTIAL_CITY {get;set;}
    public String RESIDENTIAL_STATE {get;set;}
    public String RESIDENTIAL_COUNTRY {get;set;}
    public String RESIDENTIAL_TEL_NO {get;set;}
    public String STUDENT_MOBILE_NO {get;set;}
    public String E_MAIL {get;set;}
    public String PERMANENT_STREET  {get;set;}
    public String PERMANENT_POSTCODE {get;set;}
    public String PERMANENT_CITY {get;set;}
    public String PERMANENT_STATE {get;set;}
    public String PERMANENT_COUNTRY {get;set;}
    public String PERMANENT_TEL_NO {get;set;}
    public String LEAD_SOURCE {get;set;}
    public String PARENT_ACKNOWLEDGED_DATE {get;set;}
    public String PREFERRED_NAME {get;set;}
    public String CRM_HOUSEHOLD_ID {get;set;}
    public String CRM_STUD_ID {get;set;}
    public String CRM_CAMPUS_ID {get;set;}
    public String EMERGENCY_NAME {get;set;}
    public String EMERGENCY_RELATIONSHIP {get;set;}
    public String EMERGENCY_CONTACT_HOME {get;set;}
    public String EMERGENCY_CONTACT_MOBILE {get;set;}
    public String EMERGENCY_EMAIL {get;set;}
     
    //Programme Master Fields
    public String PROGRAMME {get;set;}

    //Intake Master Fields
    public String INTAKE_NUMBER {get;set;}
    public String STUDY_MODE {get;set;}

    //Programme Application Fields
    public String STATUS {get;set;}
    public String CREATED_BY {get;set;}
    public String IMM_PASS_TYPE {get;set;}
    public String IMM_PASS_EXPIRY_DATE {get;set;}
    public String IMM_PASS_INSTITUTION_NAME {get;set;}
    public String APPLICATION_TYPE {get;set;}
    public String CRM_PROG_ID {get;set;}
    

    //Parent Account Fields
    public String PARENTS_NAME {get;set;}
    public String PARENTS_RELATIONSHIP {get;set;}
    public String PARENTS_RESIDENTIAL_TEL {get;set;}
    public String PARENT_MOBILE_NO {get;set;}
    public String PARENTS_EMAIL {get;set;}
    public String PARENTS_IC_PASSPORT {get;set;}
    public String PARENTS_OCCUPATION {get;set;}
    public String PARENTS_RESIDENTIAL_STREET {get;set;}
    public String PARENTS_RESIDENTIAL_POSTCODE {get;set;}
    public String PARENTS_RESIDENTIAL_CITY {get;set;}
    public String PARENTS_RESIDENTIAL_STATE {get;set;}
    public String PARENTS_RESIDENTIAL_COUNTRY {get;set;}
    public String PARENT_ACKNOWLEDGED_NAME {get;set;}
    public String PARENT_ACKNOWLEDGED_ICP {get;set;}

    //Parent Contact Fields
    public String PARENTS2_NAME {get;set;}
    public String PARENTS2_RELATIONSHIP {get;set;}
    public String PARENTS2_IC_PASSPORT {get;set;}
    public String PARENTS2_OCCUPATION {get;set;}
    public String PARENTS2_RESIDENTIAL_TEL {get;set;}
    public String PARENTS2_MOBILE_NO {get;set;}
    public String PARENTS2_EMAIL {get;set;}
    public String PARENTS2_RESIDENTIAL_POSTCODE {get;set;}
    public String PARENTS2_RESIDENTIAL_CITY {get;set;}
    public String PARENTS2_RESIDENTIAL_STATE {get;set;}
    public String PARENTS2_RESIDENTIAL_COUNTRY {get;set;}
    public String PARENTS2_RESIDENTIAL_STREET {get;set;}


    
    

    public SFWebServiceWrapper(Student__c stud){
        this.STUDENT_UID = stud.Student_UID__c;
        this.FULL_NAME = stud.Name;
        this.LAST_NAME = stud.Name;
        this.FIRST_NAME = stud.Name;
        this.IC_PASSPORT = stud.NRIC_Passport_No__c;
        this.PASSPORT_EXPIRY_DATE = stud.Passport_Expiry_Date__c != null ? formatDate(stud.Passport_Expiry_Date__c) : null;
        this.DATE_OF_BIRTH = stud.Date_of_Birth__c != null ? formatDate(stud.Date_of_Birth__c) : null;
        this.NATIONALITY = stud.Nationality__c;
        this.GENDER = stud.Gender__c;
        this.MARITAL_STATUS = stud.Marital_Status__c;
        this.RACE = stud.Race__c;
        this.RELIGION = stud.Religion__c;
        this.RESIDENTIAL_STREET = stud.Street_m__c;
        this.RESIDENTIAL_POSTCODE = stud.Postcode_m__c;
        this.RESIDENTIAL_CITY = stud.City_m__c;
        this.RESIDENTIAL_STATE = stud.State_m__c;
        this.RESIDENTIAL_COUNTRY = stud.Country_m__c;
        this.RESIDENTIAL_TEL_NO = stud.Contact_Telephone_No_m__c;
        this.STUDENT_MOBILE_NO = stud.Student_Mobile_No__c;
        this.E_MAIL = stud.Email_Address__c;
        this.PERMANENT_STREET = stud.Street_p__c;
        this.PERMANENT_POSTCODE = stud.Postcode_p__c;
        this.PERMANENT_CITY = stud.City_p__c;
        this.PERMANENT_STATE = stud.State_p__c;
        this.PERMANENT_COUNTRY = stud.Country_p__c;
        this.PERMANENT_TEL_NO = stud.Contact_Telephone_No_p__c;
        this.LEAD_SOURCE = stud.Lead_Source__c;
        this.PARENT_ACKNOWLEDGED_DATE = stud.Acknowledged_Date__c != null ? formatDate(stud.Acknowledged_Date__c) : null;
        this.PREFERRED_NAME = stud.Preferred_Name__c;
        this.CRM_HOUSEHOLD_ID = stud.CRM_Household_ID__c;
        this.CRM_STUD_ID = stud.Student_SFID__c;
        this.CRM_CAMPUS_ID = stud.Campus_SFID__c;
        this.EMERGENCY_NAME = stud.Emergency_Contact_Name__c;
        this.EMERGENCY_RELATIONSHIP = stud.Emergency_Relationship__c;
        this.EMERGENCY_CONTACT_HOME = stud.Emergency_Contact_home__c;
        this.EMERGENCY_CONTACT_MOBILE = stud.Emergency_Contact_Mobile__c;
        this.EMERGENCY_EMAIL = stud.Emergency_Email__c;
    }

    public SFWebServiceWrapper(Programme_Master__c progMaster){
        this.PROGRAMME = progMaster.Programme_Code__c;
       
    }

    public SFWebServiceWrapper(Intake_Master__c intakeMaster){
        this.INTAKE_NUMBER = intakeMaster.Intake_Number__c;
        this.STUDY_MODE = intakeMaster.Study_Mode__c;
    }

    public SFWebServiceWrapper(Programme_Application__c progApp){
        this.STATUS = progApp.Offer_Status__c;
        this.CREATED_BY = progApp.PIC__c;
        this.IMM_PASS_TYPE = progApp.Immigration_Pass_Type__c;
        this.IMM_PASS_EXPIRY_DATE = progApp.Immigration_Pass_Expiry_Date__c != null ? formatDate(progApp.Immigration_Pass_Expiry_Date__c) : null;
        this.IMM_PASS_INSTITUTION_NAME = progApp.Immigration_Pass_Institution_Name__c;
        this.APPLICATION_TYPE = progApp.Application_Type__c;
        this.CRM_PROG_ID = progApp.CRM_Programme_ID__c;
    }

    public SFWebServiceWrapper(Account pAcc){
        this.PARENTS_NAME = pAcc.Name;
        this.PARENTS_RELATIONSHIP = pAcc.Parent_Relationship_Father_Mother__c;
        this.PARENTS_RESIDENTIAL_TEL = pAcc.Parent_Contact_Telephone__c;
        this.PARENT_MOBILE_NO = pAcc.Phone;
        this.PARENTS_EMAIL = pAcc.Parent_Email_Address__c;
        this.PARENTS_IC_PASSPORT = pAcc.Parent_NRIC_Passport_No__c;
        this.PARENTS_OCCUPATION = pAcc.Parent_Occupation__c;
        this.PARENTS_RESIDENTIAL_STREET = pAcc.Street__c;
        this.PARENTS_RESIDENTIAL_POSTCODE = pAcc.Postcode__c;
        this.PARENTS_RESIDENTIAL_CITY = pAcc.City__c;
        this.PARENTS_RESIDENTIAL_STATE = pAcc.State__c;
        this.PARENTS_RESIDENTIAL_COUNTRY = pAcc.Country__c;
        this.PARENT_ACKNOWLEDGED_NAME = pAcc.Name;
        this.PARENT_ACKNOWLEDGED_ICP = pAcc.Parent_NRIC_Passport_No__c;
    }

    public SFWebServiceWrapper(Contact pCon){
        this.PARENTS2_NAME = pCon.Name;
        this.PARENTS2_RELATIONSHIP = pCon.Relationship__c;
        this.PARENTS2_IC_PASSPORT = pCon.NRIC_Passport_No__c;
        this.PARENTS2_OCCUPATION = pCon.Occupation__c;
        this.PARENTS2_RESIDENTIAL_TEL = pCon.HomePhone;
        this.PARENTS2_MOBILE_NO = pCon.MobilePhone;
        this.PARENTS2_EMAIL = pCon.Email;
        this.PARENTS2_RESIDENTIAL_CITY = pCon.City__c;
        this.PARENTS2_RESIDENTIAL_COUNTRY = pCon.Country__c;
        this.PARENTS2_RESIDENTIAL_POSTCODE = pCon.Postcode__c;
        this.PARENTS2_RESIDENTIAL_STATE = pCon.State__c;
        this.PARENTS2_RESIDENTIAL_STREET = pCon.Street__c;
    }

    
    
    private String formatDate(Date inputDate) {

        // Create an array of month abbreviations
        List<String> monthAbbr = new List<String>{
            'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
            'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
        };

        String formattedDate = String.format(
            '{0}-{1}-{2}',
            new List<String>{
                inputDate.day() < 10 ? '0' + String.valueOf(inputDate.day()) : String.valueOf(inputDate.day()),
                monthAbbr[inputDate.month() - 1],
                String.valueOf(inputDate.year())
            }
        );
        return formattedDate;
    }
}