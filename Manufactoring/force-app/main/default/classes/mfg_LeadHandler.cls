public with sharing class mfg_LeadHandler {
      public static void afterUpdate(List<Lead> newList, List<Lead> oldList) {
        List<Lead> leadsToConvert = new List<Lead>();

        for (Integer i = 0; i < newList.size(); i++) {
            Lead newLead = newList[i];
            Lead oldLead = oldList[i];
           System.debug('oldLead.IsConverted: ' + oldLead.IsConverted + ' newLead.IsConverted: ' + newLead.IsConverted + ' newLead.Status:'+newLead.Status);
            if (!oldLead.IsConverted && !newLead.IsConverted && newLead.Status == 'Converted') {
                leadsToConvert.add(newLead);
            }
        }

        if (!leadsToConvert.isEmpty()) {
             //Map<String, Map<String, Object>> finalConversion =leadConvert(leadsToConvert);
             //System.debug('finalConversion: ' + finalConversion);
        }
      }
      
       @AuraEnabled
      public static Map<String, Map<String, Object>> getLead(List<String> leadIds){
         List<Lead> leadsToConvert = new List<Lead>();
                    List<String> leadFields = new List<String>{
            'Id','RecordTypeId','Company','Industry','MobilePhone','OwnerId',
            'LeadSource','AnnualRevenue','NumberOfEmployees','Website','Phone',
            'mfg_CIN__c','mfg_NumberOfOutlets__c','mfg_Years_in_Business__c',
            'mfg_CompanyContactEmail__c','Street','City','State','PostalCode','Country',
            'mfg_CompanyContactRole__c','mfg_PartnerAgreementIssued__c','Rating',
            'mfg_GST_Tax_Registration_Number__c','mfg_Logistics_Support__c',
            'mfg_Inventory_Capacity__c',
            'FirstName','LastName','Email','mfg_Communication_Preference__c',
            'mfg_Address__Street__s','mfg_Address__City__s','mfg_Address__CountryCode__s',
            'mfg_Address__StateCode__s','mfg_Address__PostalCode__s','mfg_CreateUser__c',
            'mfg_Product_Family__c','mfg_EstimatedBudget__c','mfg_Quantity__c','mfg_Product_Subcategory__c',
            'mfg_PlanningToBuy__c','mfg_Urgency_Level__c','mfg_KeyRequirementsNotes__c',
            'mfg_ExpectedPurchaseDate__c'
            };

            //String query = 'SELECT ' + String.join(leadFields, ',') + ' FROM Lead WHERE Id IN :leadIds';
              String query ='SELECT ' + String.join(leadFields, ',') +
                            ', (SELECT Id, CampaignId FROM CampaignMembers WHERE Campaign.IsActive = true)' +
                            ' FROM Lead WHERE Id IN :leadIds';
            leadsToConvert = Database.query(query);
         if (!leadsToConvert.isEmpty()) {
             Map<String, Map<String, Object>> finalMapping = leadConvert(leadsToConvert);
            return finalMapping;
        }
        return null;

      }

       public static Map<String, Map<String, Object>> leadConvert(List<Lead> leadsToConvert){
           return MFG_LeadConversion.convertLeads(leadsToConvert);

      }
    


}