public without sharing class MFG_ServiceTermHandler {

    public static void handleNewProducts(List<Product2> newProducts) {
        try {
            if (newProducts == null || newProducts.isEmpty()) {
                return;
            }

            Map<String, mfg_Service_Term__c> productFamily = new Map<String, mfg_Service_Term__c>();
            Map<String, mfg_Service_Term__c> productSubCategory = new Map<String, mfg_Service_Term__c>();
            Map<String, mfg_Service_Term__c> mainProduct = new Map<String, mfg_Service_Term__c>();

            existingServiceTerms(productFamily, productSubCategory, mainProduct);

            List<mfg_Service_Term__c> newServiceTerms = buildServiceTerms(newProducts,productFamily,productSubCategory, mainProduct);

            if (!newServiceTerms.isEmpty()) {
                insert newServiceTerms;
                MFG_ServiceTermRulesetFramework.createStandardRules(newServiceTerms);
            }

            List<mfg_Product_Service_Term__c> newProductMappings = buildProductServiceTerms(newProducts,productFamily,productSubCategory,mainProduct);

            if (!newProductMappings.isEmpty()) {
                insert newProductMappings;
            }
            
        } catch (Exception ex) {
            System.debug('Service Term Error: ' + ex.getMessage());
        }
    }

    private static void existingServiceTerms(Map<String, mfg_Service_Term__c> productFamily,Map<String, mfg_Service_Term__c> productSubCategory,Map<String, mfg_Service_Term__c> mainProduct) {
        for (mfg_Service_Term__c term : [SELECT Id, Name, mfg_Service_Level__c, mfg_Service_Scope_Value__c  FROM mfg_Service_Term__c]) {
            if (term.mfg_Service_Level__c == 'Family') {
                productFamily.put(term.mfg_Service_Scope_Value__c, term);
            } else if (term.mfg_Service_Level__c == 'Subcategory') {
                productSubCategory.put(term.mfg_Service_Scope_Value__c, term);
            } else if (term.mfg_Service_Level__c == 'Product') {
                mainProduct.put(term.mfg_Service_Scope_Value__c, term);
            }
        }
    }

    private static List<mfg_Service_Term__c> buildServiceTerms(List<Product2> newProducts,Map<String, mfg_Service_Term__c> productFamily,Map<String, mfg_Service_Term__c> productSubCategory,Map<String, mfg_Service_Term__c> mainProduct) {
        List<mfg_Service_Term__c> newTerms = new List<mfg_Service_Term__c>();

        for (Product2 product : newProducts) {
            
            if (product.Family != null && !productFamily.containsKey(product.Family)) {
                mfg_Service_Term__c term = new mfg_Service_Term__c(
                    Name                    = product.Family + ' Service Term',
                    mfg_Service_Level__c    = 'Family',
                    mfg_Service_Scope_Value__c = product.Family,
                    mfg_Active__c           = true,
                    mfg_Activation_Date__c  = Date.today(),
                    mfg_Parts_Coverage__c   = 80,
                    mfg_Labor_Coverage__c   = 15,
                    mfg_Expense_Coverage__c = 5,
                    mfg_Service_Unit__c     = 'Months',
                    mfg_Service_Duration__c = 36
                );
                newTerms.add(term);
                productFamily.put(product.Family, term);
            }

            if (product.mfg_Product_Subcategory__c != null && !productSubCategory.containsKey(product.mfg_Product_Subcategory__c)) {

                mfg_Service_Term__c term = new mfg_Service_Term__c(
                    Name                    = product.mfg_Product_Subcategory__c + ' Service Term',
                    mfg_Service_Level__c    = 'Subcategory',
                    mfg_Service_Scope_Value__c = product.mfg_Product_Subcategory__c,
                    mfg_Active__c           = true,
                    mfg_Activation_Date__c  = Date.today(),
                    mfg_Parts_Coverage__c   = 75,
                    mfg_Labor_Coverage__c   = 20,
                    mfg_Expense_Coverage__c = 5,
                    mfg_Service_Unit__c     = 'Months',
                    mfg_Service_Duration__c = 24
                );
                newTerms.add(term);
                productSubCategory.put(product.mfg_Product_Subcategory__c, term);
            }

            if (!mainProduct.containsKey(product.Name)) {
                mfg_Service_Term__c term = new mfg_Service_Term__c(
                    Name                    = product.Name + ' Service Term',
                    mfg_Service_Level__c    = 'Product',
                    mfg_Service_Scope_Value__c = product.Name,
                    mfg_Active__c           = true,
                    mfg_Activation_Date__c  = Date.today(),
                    mfg_Parts_Coverage__c   = 70,
                    mfg_Labor_Coverage__c   = 25,
                    mfg_Expense_Coverage__c = 5,
                    mfg_Service_Unit__c     = 'Months',
                    mfg_Service_Duration__c = 12
                );
                newTerms.add(term);
                mainProduct.put(product.Name, term);
            }
        }
        return newTerms;
    }

    private static List<mfg_Product_Service_Term__c> buildProductServiceTerms(List<Product2> newProducts,Map<String, mfg_Service_Term__c> productFamily,Map<String, mfg_Service_Term__c> productSubCategory,Map<String, mfg_Service_Term__c> mainProduct) {
        List<mfg_Product_Service_Term__c> records = new List<mfg_Product_Service_Term__c>();

        for (Product2 product : newProducts) {

            if (product.Family != null && productFamily.containsKey(product.Family)) {
                records.add(new mfg_Product_Service_Term__c(
                    mfg_Covered_Product__c = product.Id,
                    mfg_Service_Term__c    = productFamily.get(product.Family).Id,
                    mfg_Service_Scope_Value__c = product.Family,
                    mfg_Service_Level__c ='Family'
                ));
            }

            if (product.mfg_Product_Subcategory__c != null && productSubCategory.containsKey(product.mfg_Product_Subcategory__c)) {

                records.add(new mfg_Product_Service_Term__c(
                    mfg_Covered_Product__c = product.Id,
                    mfg_Service_Term__c    = productSubCategory.get(product.mfg_Product_Subcategory__c).Id,
                    mfg_Service_Scope_Value__c = product.mfg_Product_Subcategory__c,
                    mfg_Service_Level__c ='Subcategory'
                ));
            }

            if (mainProduct.containsKey(product.Name)) {
                records.add(new mfg_Product_Service_Term__c(
                    mfg_Covered_Product__c = product.Id,
                    mfg_Service_Term__c    = mainProduct.get(product.Name).Id,
                    mfg_Service_Scope_Value__c = product.Name,
                    mfg_Service_Level__c ='Product'
                ));
            }
        }
        return records;
    }
}