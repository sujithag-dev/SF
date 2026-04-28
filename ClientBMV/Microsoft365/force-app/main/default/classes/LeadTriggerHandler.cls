/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : LeadTriggerHandler
 * Author          : Prakash Annadurai
 * Created Date    : Apr 15, 2026
 * Last Modified By: Prakash Annadurai
 * Last Modified On: Apr 17, 2026
 * Description     : Handles Lead conversion and maps custom fields to Opportunity
 *  
 * Change History  :
 *  Date          │   Author            │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 15, 2026  │ Prakash Annadurai   │ Initial version
 *  Apr 17, 2026  │ Prakash Annadurai   │ Added custom field mapping to Opportunity
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class LeadTriggerHandler {

    public static void handleOpportunityCreation(
        List<Lead> newLeads,
        Map<Id, Lead> oldMap
    ) {

        List<Lead> eligibleLeads = new List<Lead>();

        // ── Step 1: Filter Leads
        for (Lead ld : newLeads) {
            Lead oldLead = oldMap.get(ld.Id);

            if (oldLead != null &&
                oldLead.Status != 'Closed - Converted' &&
                ld.Status == 'Closed - Converted' &&
                !ld.IsConverted) {

                eligibleLeads.add(ld);
            }
        }

        if (eligibleLeads.isEmpty()) return;

        // ── Step 2: Collect Company & Emails
        Set<String> companyNames = new Set<String>();
        Set<String> emails       = new Set<String>();

        for (Lead ld : eligibleLeads) {
            if (String.isNotBlank(ld.Company)) companyNames.add(ld.Company.trim());
            if (String.isNotBlank(ld.Email))   emails.add(ld.Email.toLowerCase());
        }

        // ── Step 3: Fetch Existing Accounts
        Map<String, Id> accountMap = new Map<String, Id>();
        for (Account acc : [SELECT Id, Name FROM Account WHERE Name IN :companyNames]) {
            accountMap.put(acc.Name.trim().toLowerCase(), acc.Id);
        }

        // ── Step 4: Fetch Existing Contacts
        Map<String, Id> contactMap = new Map<String, Id>();
        for (Contact con : [SELECT Id, Email FROM Contact WHERE Email IN :emails]) {
            if (con.Email != null) contactMap.put(con.Email.toLowerCase(), con.Id);
        }

        // ── Step 5: Build LeadConvert list
        //    Also keep a map of LeadId → Lead so we can copy fields after conversion
        Map<Id, Lead> leadById = new Map<Id, Lead>();
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();

        for (Lead ld : eligibleLeads) {

            leadById.put(ld.Id, ld); // store for post-conversion mapping

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.Id);
            lc.setConvertedStatus('Closed - Converted');

            // Account
            String accKey = ld.Company != null ? ld.Company.trim().toLowerCase() : null;
            if (accKey != null && accountMap.containsKey(accKey)) {
                lc.setAccountId(accountMap.get(accKey));
            }

            // Contact
            String emailKey = ld.Email != null ? ld.Email.toLowerCase() : null;
            if (emailKey != null && contactMap.containsKey(emailKey)) {
                lc.setContactId(contactMap.get(emailKey));
            }

            // Opportunity
            lc.setDoNotCreateOpportunity(false);
            lc.setOpportunityName(
                String.isNotBlank(ld.Company)
                    ? ld.Company + ' - Opportunity'
                    : 'New Opportunity'
            );

            leadConverts.add(lc);
        }

        // ── Step 6: Convert Leads
        if (leadConverts.isEmpty()) return;

        List<Database.LeadConvertResult> results =
            Database.convertLead(leadConverts, false);

        // ── Step 7: Map custom Lead fields → Opportunity (post-conversion)
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Database.LeadConvertResult res : results) {

            if (res.isSuccess()) {

                System.debug('Converted Lead: ' + res.getLeadId());

                Id oppId = res.getOpportunityId();
                if (oppId == null) continue; // safety check

                Lead sourceLead = leadById.get(res.getLeadId());

                Opportunity opp = new Opportunity(Id = oppId);

                // ── Same API name fields
                opp.Investor_Type__c          = sourceLead.Investor_Type__c;
                opp.AUM_Range__c              = sourceLead.AUM_Range__c;
                opp.Investment_Horizon__c     = sourceLead.Investment_Horizon__c;
                opp.AI_Qualification_Score__c = sourceLead.AI_Qualification_Score__c;
                opp.AI_Qualification_Tier__c  = sourceLead.AI_Qualification_Tier__c;
                opp.Teams_UPN__c              = sourceLead.Teams_UPN__c;

                // ── Different API name fields
                opp.Mexico_Exposure__c        = sourceLead.Mexico_Market_Interest__c;
                opp.Investment_Product__c     = sourceLead.Products_of_Interest__c;

                // ── Lead ID → Lead Source Record lookup
                opp.Lead_Source_Record__c     = sourceLead.Id;

                oppsToUpdate.add(opp);

            } else {
                for (Database.Error err : res.getErrors()) {
                    System.debug('Conversion Error: ' + err.getMessage());
                }
            }
        }

        // ── Step 8: Bulk update Opportunities with mapped fields
        if (!oppsToUpdate.isEmpty()) {
            List<Database.SaveResult> updateResults =
                Database.update(oppsToUpdate, false);

            for (Database.SaveResult sr : updateResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Opp Update Error: ' + err.getMessage());
                    }
                }
            }
        }
    }
}