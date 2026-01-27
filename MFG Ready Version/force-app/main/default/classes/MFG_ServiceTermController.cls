public with sharing class MFG_ServiceTermController {

    private static mfg_Service_Term_Default__mdt defaultConfig;

    public static void handleNewProducts(List<Product2> newProducts) {
        try {
            if (newProducts == null || newProducts.isEmpty()) {
                return;
            }

            defaultConfig = [
                SELECT mfg_Parts_Coverage__c,
                       mfg_Labor_Coverage__c,
                       mfg_Expense_Coverage__c,
                       mfg_Service_Duration__c,
                       mfg_Service_Unit__c
                FROM mfg_Service_Term_Default__mdt
                WHERE DeveloperName = 'mfg_Default_Standard'
                LIMIT 1
            ];

            List<mfg_Service_Term__c> newServiceTerms = buildServiceTerms(newProducts);

            if (!newServiceTerms.isEmpty()) {
                insert newServiceTerms;
                MFG_ServiceTermRulesetFramework.createStandardRules(newServiceTerms);
            }

        } catch (Exception ex) {
            mfg_Log__c err = MFG_Logs.newErrorInstance();
            err.mfg_Error_Message__c = ex.getMessage() + ' (Line ' + ex.getLineNumber() + ')';
            err.mfg_Source_Component__c = 'MFG_ServiceTermController.cls';
            err.mfg_Logged_By_Automation__c = 'Apex Class';
            err.mfg_Status__c = 'Failure';
            MFG_Logs.save(err);
            System.debug('Service Term Error: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
        }
    }

    private static List<mfg_Service_Term__c> buildServiceTerms(List<Product2> newProducts) {

        List<mfg_Service_Term__c> newTerms = new List<mfg_Service_Term__c>();

        for (Product2 product : newProducts) {

            if (product == null || String.isBlank(product.Name)) {
                continue;
            }

            String termName = product.Name + ' Service Term';
            if (termName.length() > 80) {
                termName = product.Name.substring(0, 67) + ' Service Term';
            }

            mfg_Service_Term__c term = new mfg_Service_Term__c(
                Name                    = termName,
                mfg_Covered_Product__c  = product.Id,
                mfg_Active__c           = true,
                mfg_Standard__c         = true,
                mfg_Activation_Date__c  = Date.today(),
                mfg_Parts_Coverage__c   = getPartsCoverage(),
                mfg_Labor_Coverage__c   = getLaborCoverage(),
                mfg_Expense_Coverage__c = getExpenseCoverage(),
                mfg_Service_Unit__c     = getServiceUnit(),
                mfg_Service_Duration__c = getServiceDuration()
            );

            newTerms.add(term);
        }

        return newTerms;
    }

    private static Decimal getPartsCoverage() {
        if (defaultConfig != null && defaultConfig.mfg_Parts_Coverage__c != null) {
            return defaultConfig.mfg_Parts_Coverage__c;
        }
        return null;
    }

    private static Decimal getLaborCoverage() {
        if (defaultConfig != null && defaultConfig.mfg_Labor_Coverage__c != null) {
            return defaultConfig.mfg_Labor_Coverage__c;
        }
        return null;
    }

    private static Decimal getExpenseCoverage() {
        if (defaultConfig != null && defaultConfig.mfg_Expense_Coverage__c != null) {
            return defaultConfig.mfg_Expense_Coverage__c;
        }
        return null;
    }

    private static Decimal getServiceDuration() {
        if (defaultConfig != null && defaultConfig.mfg_Service_Duration__c != null) {
            return defaultConfig.mfg_Service_Duration__c;
        }
        return null;
    }

    private static String getServiceUnit() {
        if (defaultConfig != null && String.isNotBlank(defaultConfig.mfg_Service_Unit__c)) {
            return defaultConfig.mfg_Service_Unit__c;
        }
        return null;
    }
}