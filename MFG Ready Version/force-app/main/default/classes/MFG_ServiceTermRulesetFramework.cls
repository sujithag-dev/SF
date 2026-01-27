public without sharing class MFG_ServiceTermRulesetFramework {
    
    public static void createStandardRules(List<mfg_Service_Term__c> serviceTerms) {
        
        if (serviceTerms == null || serviceTerms.isEmpty()) return;
        
        List<mfg_Defect_Code__c> defectCodes = [
            SELECT Id,mfg_Applicable_Products__c,mfg_Defect_Applicability__c FROM mfg_Defect_Code__c
            WHERE mfg_Active__c = true
        ];
        
        List<mfg_Service_Term_RuleSet__c> rulesets =new List<mfg_Service_Term_RuleSet__c>();
        
        for (mfg_Service_Term__c term : serviceTerms) {
            
            for (mfg_Defect_Code__c defect : defectCodes) {                
                
                if (!isScopeMatch(defect, term)) {
                    continue;
                }
                
                rulesets.add(new mfg_Service_Term_RuleSet__c(
                    mfg_Service_Term__c = term.Id,
                    mfg_Defect_Code__c  = defect.Id,
                    mfg_Standard__c     = true,
                    mfg_Coverage_Action__c =defect.mfg_Defect_Applicability__c
                ));
            }
        }
        
        if (!rulesets.isEmpty()) {
            System.debug('before insert rulesets =' +rulesets);
            insert rulesets;
             System.debug('after insert rulesets =' +rulesets);
        }
    }
    
    
    private static Boolean isScopeMatch( mfg_Defect_Code__c defect, mfg_Service_Term__c term) {
      
      
            return emptyOrContains( defect.mfg_Applicable_Products__c, term.mfg_Covered_Product__r.Name);
        

    }
    
    
    private static Boolean emptyOrContains(String values, String target) {
        if (String.isBlank(values)) return true;
        
        for (String v : values.split(';')) {
            if (v.trim().equalsIgnoreCase(target)) {
                return true;
            }
        }
        return false;
    }
}




















/**public without sharing class MFG_ServiceTermRulesetFramework {
    
    public static void createStandardRules(List<mfg_Service_Term__c> serviceTerms) {
        
        if (serviceTerms == null || serviceTerms.isEmpty()) return;
        
        List<mfg_Defect_Code__c> defectCodes = [
            SELECT Id, mfg_Defect_Level__c,mfg_Applicable_Families__c,mfg_Applicable_Subcategories__c,mfg_Applicable_Products__c FROM mfg_Defect_Code__c
            WHERE mfg_Active__c = true
        ];
        
        List<mfg_Service_Term_RuleSet__c> rulesets =new List<mfg_Service_Term_RuleSet__c>();
        
        for (mfg_Service_Term__c term : serviceTerms) {
            
            for (mfg_Defect_Code__c defect : defectCodes) {
                
                if (!multiSelectContains(defect.mfg_Defect_Level__c, term.mfg_Service_Level__c)) {
                    continue;
                }
                
                if (!isScopeMatch(defect, term)) {
                    continue;
                }
                
                rulesets.add(new mfg_Service_Term_RuleSet__c(
                    mfg_Service_Term__c = term.Id,
                    mfg_Defect_Code__c  = defect.Id,
                    mfg_Standard__c     = true
                ));
            }
        }
        
        if (!rulesets.isEmpty()) {
            insert rulesets;
        }
    }
    
    
    private static Boolean isScopeMatch( mfg_Defect_Code__c defect, mfg_Service_Term__c term) {
        
        if (term.mfg_Service_Level__c == 'Family') {
            return emptyOrContains( defect.mfg_Applicable_Families__c, term.mfg_Service_Scope_Value__c);
        }
        
        if (term.mfg_Service_Level__c == 'Subcategory') {
            return emptyOrContains(defect.mfg_Applicable_Subcategories__c,term.mfg_Service_Scope_Value__c );
        }
        
        if (term.mfg_Service_Level__c == 'Product') {
            return emptyOrContains( defect.mfg_Applicable_Products__c, term.mfg_Service_Scope_Value__c);
        }
        
        return false;
    }
    
    private static Boolean multiSelectContains(String values, String target) {
        if (String.isBlank(values) || String.isBlank(target)) return false;
        
        for (String v : values.split(';')) {
            if (v.trim().equalsIgnoreCase(target)) {
                return true;
            }
        }
        return false;
    }
    
    private static Boolean emptyOrContains(String values, String target) {
        if (String.isBlank(values)) return true;
        
        for (String v : values.split(';')) {
            if (v.trim().equalsIgnoreCase(target)) {
                return true;
            }
        }
        return false;
    }
}**/