public with sharing class MFG_LeadConversion {

   
    static Map<String, Map<String, MFG_LeadConversionFramework.RTConfig>> config;
    
    public class ServiceResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Object payload;
        @AuraEnabled public Map<Id, String> info;
    }


  
public static ServiceResponse convertLeads(List<Lead> leads) {
    if (leads == null || leads.isEmpty()) {
        System.debug('No leads to convert');
        return null;
    }

    Savepoint sp;
    List<Lead> leadsToConvert = leads;
    System.debug('Lead Records: ' + leadsToConvert);
    
    ServiceResponse res = new ServiceResponse();
    Map<String, Map<String, Object>> leadConversionMap;
    Map<Id, String> infoMessages = new Map<Id, String>();

    try {
        sp = Database.setSavepoint();
        config = MFG_LeadConversionFramework.getRecordTypeConfig();
        System.debug('Record Type Config: ' + config);

        List<Account> accountsToInsert = new List<Account>();
        List<Contact> contactsToInsert = new List<Contact>();
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        Set<String> CinNumbers = new Set<String>();
        Set<String> phoneNumbers = new Set<String>();
        Set<String> Emails = new Set<String>();

        leadConversionMap = new Map<String, Map<String, Object>>();

        for (Lead ld : leadsToConvert) {
            if (String.isNotBlank(ld.mfg_CIN__c)) CinNumbers.add(ld.mfg_CIN__c);
            if (String.isNotBlank(ld.MobilePhone)) phoneNumbers.add(ld.MobilePhone);
            if (String.isNotBlank(ld.Email)) Emails.add(ld.Email);

            Map<String, Object> leadData = new Map<String, Object>{
                'CIN' => ld.mfg_CIN__c,
                'accountToInsert' => null,
                'isNewAccount' => true,
                'isNewContact' => true,
                'ContactToInsert' => null,
                'OpportunityToInsert' => null
            };
            leadConversionMap.put(ld.Id, leadData);
        }
        System.debug('Base Lead Conversion Map: ' + leadConversionMap);

        List<Account> existingAccounts = getAccountsByField('mfg_CIN__c',CinNumbers);

        
        System.debug('Existing Accounts: ' + existingAccounts);

        List<Contact> existingContacts = [
            SELECT Id, FirstName, LastName, Email, Phone, AccountId, Account.mfg_CIN__c,
                   LeadSource, mfg_Communication_Preference__c, MailingStreet, MailingCity,
                   MailingCountryCode, MailingStateCode, MailingPostalCode, 
                   mfg_CreateUser__c, RecordTypeId
            FROM Contact
            WHERE Phone IN :phoneNumbers OR Email IN :Emails
        ];
        System.debug('Existing Contacts (Global): ' + existingContacts);

        Map<String, Account> cinToAccountMap = new Map<String, Account>();
        for (Account acc : existingAccounts) {
            if (String.isNotBlank(acc.mfg_CIN__c)) {
                cinToAccountMap.put(acc.mfg_CIN__c, acc);
            }
        }

        Map<String, Contact> emailToContactMap = new Map<String, Contact>();
        Map<String, Contact> phoneToContactMap = new Map<String, Contact>();
        for (Contact con : existingContacts) {
            if (String.isNotBlank(con.Email)) {
                emailToContactMap.put(con.Email, con);
            }
            if (String.isNotBlank(con.Phone)) {
                phoneToContactMap.put(con.Phone, con);
            }
        }

        for (Lead leadRecord : leadsToConvert) {
            String leadRT;
            if (leadRecord.RecordTypeId != null) {
                leadRT = Schema.SObjectType.Lead.getRecordTypeInfosById()
                    .get(leadRecord.RecordTypeId)
                    .getDeveloperName();
            }

            Account existingAccount = null;
            Contact existingContact = null;

            if (String.isNotBlank(leadRecord.mfg_CIN__c)) {
                existingAccount = cinToAccountMap.get(leadRecord.mfg_CIN__c);
            }

            if (String.isNotBlank(leadRecord.Email) && emailToContactMap.containsKey(leadRecord.Email)) {
                existingContact = emailToContactMap.get(leadRecord.Email);
            } else if (String.isNotBlank(leadRecord.MobilePhone) && phoneToContactMap.containsKey(leadRecord.MobilePhone)) {
                existingContact = phoneToContactMap.get(leadRecord.MobilePhone);
            }

            // SCENARIO 1: Both Account and Contact exist
            if (existingAccount != null && existingContact != null) {
                leadConversionMap.get(leadRecord.Id).put('accountToInsert', existingAccount);
                leadConversionMap.get(leadRecord.Id).put('isNewAccount', false);
                leadConversionMap.get(leadRecord.Id).put('ContactToInsert', existingContact);
                leadConversionMap.get(leadRecord.Id).put('isNewContact', false);

                String info = 'Existing account and contact found. Lead will be linked' +
                    (MFG_LeadConversionFramework.isCreateAllowed(config, leadRT, 'Opportunity')
                        ? ' and an opportunity will be created.'
                        : '.');

                // Create Opportunity if allowed
                if (MFG_LeadConversionFramework.isCreateAllowed(config, leadRT, 'Opportunity')) {
                    Opportunity opp = createOpportunityFromLead(leadRecord, leadRT, config);
                    opp.AccountId = existingAccount.Id;
                    opp.mfg_Primary_Contact__c = existingContact.Id;
                    leadConversionMap.get(leadRecord.Id).put('OpportunityToInsert', opp);
                    opportunitiesToInsert.add(opp);
                    System.debug('Created Opportunity (Existing Account + Contact): ' + opp);
                }

                infoMessages.put(leadRecord.Id, info);
            }
            // SCENARIO 2: Account exists, but Contact is new
            else if (existingAccount != null && existingContact == null) {
                leadConversionMap.get(leadRecord.Id).put('accountToInsert', existingAccount);
                leadConversionMap.get(leadRecord.Id).put('isNewAccount', false);

                Contact newCon = createContactFromLead(leadRecord, leadRT, config);
                newCon.AccountId = existingAccount.Id;
                leadConversionMap.get(leadRecord.Id).put('ContactToInsert', newCon);
                leadConversionMap.get(leadRecord.Id).put('isNewContact', true);
                contactsToInsert.add(newCon);

                String info = 'Existing account found. A new contact will be created' +
                    (MFG_LeadConversionFramework.isCreateAllowed(config, leadRT, 'Opportunity')
                        ? ' and an opportunity will be created.'
                        : '.');

                if (MFG_LeadConversionFramework.isCreateAllowed(config, leadRT, 'Opportunity')) {
                    Opportunity opp = createOpportunityFromLead(leadRecord, leadRT, config);
                    opp.AccountId = existingAccount.Id;
                    opp.Type = 'New Customer';
                    leadConversionMap.get(leadRecord.Id).put('OpportunityToInsert', opp);
                    opportunitiesToInsert.add(opp);
                }

                infoMessages.put(leadRecord.Id, info);
                System.debug('Created Contact + Opportunity for existing Account');
            }
            // SCENARIO 3: Contact exists (with different Account), Account is new.lookup with existing Account and Contact
            else if (existingAccount == null && (existingContact != null && existingContact.AccountId != null)) {
                List<Account> acc = getAccountsByField('Id', existingContact.AccountId);
                System.debug('Existing Contact found with different Account. Using existing Account and Contact' +acc);
                       
                leadConversionMap.get(leadRecord.Id).put('accountToInsert', acc[0]);
                leadConversionMap.get(leadRecord.Id).put('isNewAccount', false);
                leadConversionMap.get(leadRecord.Id).put('ContactToInsert', existingContact);
                leadConversionMap.get(leadRecord.Id).put('isNewContact', false);

                String info = 'Existing account found for this email or phone. ' +
                    'Lead will be linked to the account' +
                    (MFG_LeadConversionFramework.isCreateAllowed(config, leadRT, 'Opportunity')
                        ? ' and an opportunity will be created.'
                        : '.');

                if (MFG_LeadConversionFramework.isCreateAllowed(config, leadRT, 'Opportunity')) {
                    Opportunity opp = createOpportunityFromLead(leadRecord, leadRT, config);
                    opp.AccountId = acc[0].Id;
                    opp.mfg_Primary_Contact__c = existingContact.Id;
                    leadConversionMap.get(leadRecord.Id).put('OpportunityToInsert', opp);
                    opportunitiesToInsert.add(opp);
                }

                infoMessages.put(leadRecord.Id, info);
                System.debug('Using existing Contact and its Account: ' + acc);
            }
            // SCENARIO 4: Both Account and Contact are new
            else {
                Account acc = createAccountFromLead(leadRecord, leadRT, config);
                leadConversionMap.get(leadRecord.Id).put('accountToInsert', acc);
                accountsToInsert.add(acc);

                Contact con = createContactFromLead(leadRecord, leadRT, config);
                con.AccountId = acc.Id;
                leadConversionMap.get(leadRecord.Id).put('ContactToInsert', con);
                contactsToInsert.add(con);

                if (MFG_LeadConversionFramework.isCreateAllowed(config, leadRT, 'Opportunity')) {
                    Opportunity opp = createOpportunityFromLead(leadRecord, leadRT, config);
                    opp.AccountId = acc.Id;
                    opp.Type = 'New Customer';
                    leadConversionMap.get(leadRecord.Id).put('OpportunityToInsert', opp);
                    opportunitiesToInsert.add(opp);
                }
                System.debug('Created new Account + Contact + Opportunity: ' + acc + ', ' + con);
            }
        }

        res.success = true;
        res.message = 'Lead conversion preview is ready. Please review before proceeding.';
        res.payload = leadConversionMap;
        res.info = infoMessages;
        System.debug('Final Lead Conversion Map: ' + leadConversionMap);
        return res;

    } catch (Exception ex) {
        Database.rollback(sp);
        mfg_Log__c err = MFG_Logs.newErrorInstance();
        err.mfg_Error_Message__c = ex.getMessage() + ' (Line ' + ex.getLineNumber() + ')';
        err.mfg_Source_Component__c = 'MFG_LeadConversion.cls';
        err.mfg_Logged_By_Automation__c = 'Apex Class';
        err.mfg_Status__c = 'Failure';
        MFG_Logs.save(err);
        System.debug('Rolled back Lead Conversion due to error: ' + ex.getMessage());
        res.success = false;
        res.message = 'Lead conversion preview could not be completed. Please contact your administrator.';
        res.payload = null;
        res.info = null;
        return res;
    }
}


private static List<Account> getAccountsByField(String fieldName,Object fieldValue) {
    if (String.isBlank(fieldName) || fieldValue == null) {
        return new List<Account>();
    }


    Set<String> allowedFields = new Set<String>{ 'Id', 'mfg_CIN__c' };

    if (!allowedFields.contains(fieldName)) {
        return new List<Account>();
    }

    String selectFields =
        'Id, Name, Industry, mfg_Mobile__c, OwnerId, AccountSource, AnnualRevenue, ' +
        'NumberOfEmployees, Website, Phone, mfg_CIN__c, mfg_NumberOfOutlets__c, ' +
        'mfg_Years_in_Business__c, mfg_CompanyContactEmail__c, BillingStreet, ' +
        'BillingCity, BillingState, BillingPostalCode, BillingCountry, ShippingStreet, ' +
        'ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, Rating, ' +
        'mfg_GST_Tax_Registration_Number__c, mfg_Logistics_Support__c, ' +
        'mfg_Inventory_Capacity__c, mfg_CompanyContactRole__c, ' +
        'mfg_PartnerAgreementIssued__c';

    String whereClause;

    if (fieldValue instanceof Set<Object> || fieldValue instanceof List<Object>) {
        whereClause = fieldName + ' IN :fieldValue';
    } else {
        whereClause = fieldName + ' = :fieldValue';
    }

    String soql ='SELECT ' + selectFields +' FROM Account WHERE ' + whereClause;

    return Database.query(soql);
}

   

    private static Account createAccountFromLead(Lead leadRecord,String leadRT, Map<String, Map<String, MFG_LeadConversionFramework.RTConfig>> config) {
        Account acc = new Account();
        MFG_Utility.safeAssign(acc, 'Name', leadRecord.Company);
        MFG_Utility.safeAssign(acc, 'Industry', leadRecord.Industry);
        MFG_Utility.safeAssign(acc, 'mfg_Mobile__c', leadRecord.MobilePhone);
        MFG_Utility.safeAssign(acc, 'OwnerId', leadRecord.OwnerId);
        MFG_Utility.safeAssign(acc, 'AccountSource', leadRecord.LeadSource);
        MFG_Utility.safeAssign(acc, 'AnnualRevenue', leadRecord.AnnualRevenue);
        MFG_Utility.safeAssign(acc, 'NumberOfEmployees', leadRecord.NumberOfEmployees);
        MFG_Utility.safeAssign(acc, 'Website', leadRecord.Website);
        MFG_Utility.safeAssign(acc, 'Phone', leadRecord.Phone);
        MFG_Utility.safeAssign(acc, 'mfg_CIN__c', leadRecord.mfg_CIN__c);
        MFG_Utility.safeAssign(acc, 'mfg_NumberOfOutlets__c', leadRecord.mfg_NumberOfOutlets__c);
        MFG_Utility.safeAssign(acc, 'mfg_Years_in_Business__c', leadRecord.mfg_Years_in_Business__c);
        MFG_Utility.safeAssign(acc, 'mfg_CompanyContactEmail__c', leadRecord.mfg_CompanyContactEmail__c);
        MFG_Utility.safeAssign(acc, 'BillingStreet', leadRecord.Street);
        MFG_Utility.safeAssign(acc, 'BillingCity', leadRecord.City);
        MFG_Utility.safeAssign(acc, 'BillingState', leadRecord.State);
        MFG_Utility.safeAssign(acc, 'BillingPostalCode', leadRecord.PostalCode);
        MFG_Utility.safeAssign(acc, 'BillingCountry', leadRecord.Country);

        if (leadRT == 'mfg_Dealer_Lead_Recordtype') {
            MFG_Utility.safeAssign(acc, 'mfg_CompanyContactRole__c', leadRecord.mfg_CompanyContactRole__c);
            MFG_Utility.safeAssign(acc, 'mfg_PartnerAgreementIssued__c', leadRecord.mfg_PartnerAgreementIssued__c);
        } else if (leadRT == 'mfg_Customer_Lead_Recordtype') {
            MFG_Utility.safeAssign(acc, 'Rating', leadRecord.Rating);
            MFG_Utility.safeAssign(acc, 'mfg_GST_Tax_Registration_Number__c', leadRecord.mfg_GST_Tax_Registration_Number__c);
            MFG_Utility.safeAssign(acc, 'mfg_Logistics_Support__c', leadRecord.mfg_Logistics_Support__c);
            MFG_Utility.safeAssign(acc, 'mfg_Inventory_Capacity__c', leadRecord.mfg_Inventory_Capacity__c);
            MFG_Utility.safeAssign(acc, 'ShippingStreet', leadRecord.Street);
            MFG_Utility.safeAssign(acc, 'ShippingCity', leadRecord.City);
            MFG_Utility.safeAssign(acc, 'ShippingState', leadRecord.State);
            MFG_Utility.safeAssign(acc, 'ShippingPostalCode', leadRecord.PostalCode);
            MFG_Utility.safeAssign(acc, 'ShippingCountry', leadRecord.Country);
        }

        Id accRTId = MFG_LeadConversionFramework.getRecordTypeId(config, leadRT, 'Account');
        if (accRTId != null) acc.RecordTypeId = accRTId;
        return acc;
    }

    private static Contact createContactFromLead(Lead leadRecord,String leadRT, Map<String, Map<String, MFG_LeadConversionFramework.RTConfig>> config) {
        Contact con = new Contact();
        MFG_Utility.safeAssign(con, 'FirstName', leadRecord.FirstName);
        MFG_Utility.safeAssign(con, 'LastName', leadRecord.LastName);
        MFG_Utility.safeAssign(con, 'Email', leadRecord.Email);
        MFG_Utility.safeAssign(con, 'Phone', leadRecord.MobilePhone);
        MFG_Utility.safeAssign(con, 'LeadSource', leadRecord.LeadSource);
        MFG_Utility.safeAssign(con, 'mfg_Communication_Preference__c', leadRecord.mfg_Communication_Preference__c);
        MFG_Utility.safeAssign(con, 'MailingStreet', leadRecord.mfg_Address__Street__s);
        MFG_Utility.safeAssign(con, 'MailingCity', leadRecord.mfg_Address__City__s);
        MFG_Utility.safeAssign(con, 'MailingCountryCode', leadRecord.mfg_Address__CountryCode__s);
        MFG_Utility.safeAssign(con, 'MailingStateCode', leadRecord.mfg_Address__StateCode__s);
        MFG_Utility.safeAssign(con, 'MailingPostalCode', leadRecord.mfg_Address__PostalCode__s);

        if (leadRT == 'mfg_Dealer_Lead_Recordtype') {
            MFG_Utility.safeAssign(con, 'mfg_CreateUser__c', leadRecord.mfg_CreateUser__c);
        }

        Id conRTId = MFG_LeadConversionFramework.getRecordTypeId(config, leadRT, 'Contact');
        if (conRTId != null) con.RecordTypeId = conRTId;
        return con;
    }

    private static Opportunity createOpportunityFromLead(Lead leadRecord,String leadRT, Map<String, Map<String, MFG_LeadConversionFramework.RTConfig>> config) {
        Opportunity opp = new Opportunity();
        MFG_Utility.safeAssign(opp, 'Name', leadRecord.Company);
        MFG_Utility.safeAssign(opp, 'mfg_Product_Family__c', leadRecord.mfg_Product_Family__c);
        MFG_Utility.safeAssign(opp, 'mfg_Product_Subcategory__c', leadRecord.mfg_Product_Subcategory__c);
        MFG_Utility.safeAssign(opp, 'mfg_Expected_Budget__c', leadRecord.mfg_EstimatedBudget__c);
        MFG_Utility.safeAssign(opp, 'mfg_EstimatedQuantity__c', leadRecord.mfg_Quantity__c);
        MFG_Utility.safeAssign(opp, 'mfg_PlanningToBuy__c', leadRecord.mfg_PlanningToBuy__c);
        MFG_Utility.safeAssign(opp, 'mfg_Urgency_Level__c', leadRecord.mfg_Urgency_Level__c);
        MFG_Utility.safeAssign(opp, 'OwnerId', leadRecord.OwnerId);
        MFG_Utility.safeAssign(opp, 'mfg_Key_Requirements_Notes__c', leadRecord.mfg_KeyRequirementsNotes__c);
        MFG_Utility.safeAssign(opp, 'LeadSource', leadRecord.LeadSource);
        opp.StageName = 'Qualification';
        if (leadRecord.mfg_ExpectedPurchaseDate__c != null) {      
            MFG_Utility.safeAssign(opp, 'CloseDate', leadRecord.mfg_ExpectedPurchaseDate__c);
        } else {
            opp.CloseDate = System.today().addDays(30);
        }
        
       

        if (leadRecord.CampaignMembers != null && !leadRecord.CampaignMembers.isEmpty()) {

            System.debug('Campaign Members+++' +leadRecord.CampaignMembers );
            opp.CampaignId = leadRecord.CampaignMembers[0].CampaignId;
            System.debug('Campaign Id+++' +opp.CampaignId );
       }

        Id oppRTId = MFG_LeadConversionFramework.getRecordTypeId(config, leadRT, 'Opportunity');
        if (oppRTId != null) opp.RecordTypeId = oppRTId;

        return opp;
    }

@AuraEnabled
public static ServiceResponse saveRecords(String convertedMap) {
     Map<String, Map<String, Object>> leadConversionMap;
     ServiceResponse res = new ServiceResponse();
      Savepoint sp;

    try {
        sp = Database.setSavepoint(); 
     
        if (String.isBlank(convertedMap)) {
        throw new AuraHandledException('leadConversionMap is empty.');
        }
        Map<String, Object> outerMap = (Map<String, Object>) JSON.deserializeUntyped(convertedMap);
        leadConversionMap = new Map<String, Map<String, Object>>();



        for (String leadId : outerMap.keySet()) {

            Map<String, Object> leadData = (Map<String, Object>) outerMap.get(leadId);


            if (leadData.containsKey('accountToInsert') && leadData.get('accountToInsert') != null) {

                Object accObj = leadData.get('accountToInsert');

                if (accObj instanceof Map<String, Object>) {
                    Map<String, Object> accMap = (Map<String, Object>) accObj;              
                    accMap.remove('Contacts');
                    accMap.remove('contacts'); 
                    Account acc = (Account) JSON.deserialize(JSON.serialize(accMap), Account.class);
                    leadData.put('accountToInsert', acc);
                }
            }

        
            if (leadData.containsKey('ContactToInsert') && leadData.get('ContactToInsert') != null) {

                Object conObj = leadData.get('ContactToInsert');

                if (conObj instanceof Map<String, Object>) {
                    Contact con = (Contact) JSON.deserialize(JSON.serialize(conObj), Contact.class);
                    leadData.put('ContactToInsert', con);
                }
            }

            
            if (leadData.containsKey('OpportunityToInsert') && leadData.get('OpportunityToInsert') != null) {

                Object oppObj = leadData.get('OpportunityToInsert');

                if (oppObj instanceof Map<String, Object>) {
                    Opportunity opp = (Opportunity) JSON.deserialize(JSON.serialize(oppObj), Opportunity.class);
                    leadData.put('OpportunityToInsert', opp);
                }
            }

            leadConversionMap.put(leadId, leadData);
        }

        System.debug('leadConversionMap: ' + leadConversionMap);


        List<Account> accountsToInsert = new List<Account>();
        List<Contact> contactsToInsert = new List<Contact>();
        List<Opportunity> oppsToInsert = new List<Opportunity>();

        for (String leadId : leadConversionMap.keySet()) {
            Map<String, Object> leadData = leadConversionMap.get(leadId);
            Account acc = (Account) leadData.get('accountToInsert');
            Boolean isNewAcc = (Boolean) leadData.get('isNewAccount');
            Boolean isNewContact = (Boolean) leadData.get('isNewContact');
            Contact con = (Contact) leadData.get('ContactToInsert');
            Opportunity opp = (Opportunity) leadData.get('OpportunityToInsert');

            if (acc != null && isNewAcc == true) accountsToInsert.add(acc);
            if (con != null && (isNewContact == null || isNewContact == true)) contactsToInsert.add(con);
            if (opp != null) oppsToInsert.add(opp);
        }

        System.debug('Accounts to insert: ' + accountsToInsert.size());
        System.debug('Contacts to insert: ' + contactsToInsert.size());
        System.debug('Opportunities to insert: ' + oppsToInsert.size());

        if (!accountsToInsert.isEmpty()) {
            insert accountsToInsert;
            System.debug('Inserted Accounts: ' + accountsToInsert);
        }

        Map<String, Id> cinToAccountIdMap = new Map<String, Id>();
        for (Account acc : accountsToInsert) {
            if (String.isNotBlank(acc.mfg_CIN__c)) {
                cinToAccountIdMap.put(acc.mfg_CIN__c, acc.Id);
            }
        }

        // Update references in the existing leadConversionMap
        for (String leadId : leadConversionMap.keySet()) {
            Map<String, Object> leadData = leadConversionMap.get(leadId);
            Account acc = (Account) leadData.get('accountToInsert');
            Contact con = (Contact) leadData.get('ContactToInsert');
            Opportunity opp = (Opportunity) leadData.get('OpportunityToInsert');

            Id accId = (acc != null && acc.Id != null) ? acc.Id : cinToAccountIdMap.get((String)leadData.get('CIN'));

            //Re-assign updated Account ID
            if (acc != null && accId != null) {
                acc.Id = accId;
                leadData.put('accountToInsert', acc);
            }

            // Assign AccountId to Contact & Opportunity
            if (con != null && accId != null && con.AccountId == null) {
                con.AccountId = accId;
            }
            if (opp != null && accId != null && opp.AccountId == null) {
                opp.AccountId = accId;
            }
        }

        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
            System.debug('Inserted Contacts: ' + contactsToInsert);
        }

        for (String leadId : leadConversionMap.keySet()) {
            Map<String, Object> leadData = leadConversionMap.get(leadId);
            Account acc = (Account) leadData.get('accountToInsert');
            Contact con = (Contact) leadData.get('ContactToInsert');
            Opportunity opp = (Opportunity) leadData.get('OpportunityToInsert');
            if (con != null && con.Id != null) {
                leadData.put('ContactToInsert', con);
                 
                if (opp != null) {
                    opp.mfg_Primary_Contact__c = con.Id; 
                }
                
            }
        }


        if (!oppsToInsert.isEmpty()) {
            insert oppsToInsert;
            System.debug(' Inserted Opportunities: ' + oppsToInsert);
        }

        // Update Opportunity Ids in map
        for (String leadId : leadConversionMap.keySet()) {
            Map<String, Object> leadData = leadConversionMap.get(leadId);
            Opportunity opp = (Opportunity) leadData.get('OpportunityToInsert');
            if (opp != null && opp.Id != null) {
                leadData.put('OpportunityToInsert', opp);
            }
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        for (String leadId : leadConversionMap.keySet()) {
            Map<String, Object> leadData = leadConversionMap.get(leadId);
            Account acc = (Account) leadData.get('accountToInsert');
            Contact con = (Contact) leadData.get('ContactToInsert');
            Opportunity opp = (Opportunity) leadData.get('OpportunityToInsert');

            Lead ld = new Lead();
            ld.Id =leadId;
            ld.Status ='Converted';
            ld.mfg_IsConverted__c=true;
            ld.mfg_ConvertedAccountId__c = acc.Id;
            ld.mfg_ConvertedContactId__c = con.Id;
           if (opp != null && opp.Id != null) {
            ld.mfg_ConvertedOpportunityId__c = opp.Id;
           }
            ld.mfg_ConvertedDate__c =System.today();    
            leadsToUpdate.add(ld);
            }

            if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
            System.debug('Updated Leads to Converted status: ' + leadsToUpdate);
        }
        
        res.success = true;
        res.message = 'Lead converted successfully';
        res.payload = leadConversionMap;
        System.debug('Updated Lead Conversion Map: ' + leadConversionMap);

        return res;

    } catch (Exception ex) {
        Database.rollback(sp);
        mfg_Log__c err = MFG_Logs.newErrorInstance();
        err.mfg_Error_Message__c = ex.getMessage() + ' (Line ' + ex.getLineNumber() + ')';
        err.mfg_Source_Component__c = 'MFG_LeadConversion.saveRecords';
        err.mfg_Logged_By_Automation__c = 'Apex Class';
        err.mfg_Status__c = 'Failure';
        MFG_Logs.save(err);
        System.debug('Rollback due to DML Error: ' + ex.getMessage());
        res.success = false;
        res.message = 'Lead Conversion Failed: ' + ex.getMessage();
        res.payload = null;
        return res;
    }

}

}