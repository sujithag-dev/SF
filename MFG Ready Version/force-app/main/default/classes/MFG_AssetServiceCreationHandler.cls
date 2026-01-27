public class MFG_AssetServiceCreationHandler {
    @InvocableMethod(
        label='Create Asset Services'
        description='Creates Asset Service records for Installed Assets based on Product Service Terms'
    )
    public static void createAssetServices(List<Id> assetIds) {
        system.debug('assetIds: ' + assetIds);

        if (assetIds == null || assetIds.isEmpty()) {
            return;
        }

        try {
            /* ----------------------------
            1. Fetch Assets
            ----------------------------- */
            List<Asset> assets = [
                SELECT Id,
                    Product2Id,
                    InstallDate
                FROM Asset
                WHERE Id IN :assetIds
                  AND Product2Id != NULL
            ];

            if (assets.isEmpty()) {
                return;
            }

            /* ----------------------------
               2. Collect Product Ids
            ----------------------------- */
            Set<Id> productIds = new Set<Id>();
            for (Asset ast : assets) {
                productIds.add(ast.Product2Id);
            }

            /* ----------------------------
            3. Fetch Service Terms
            ----------------------------- */
            List<mfg_Service_Term__c> serviceTerms = [
                SELECT Id,
                    mfg_Covered_Product__c,
                    mfg_Parts_Coverage__c,
                    mfg_Labor_Coverage__c,
                    mfg_Expense_Coverage__c,
                    mfg_Service_Unit__c,
                    mfg_Service_Duration__c,
                    mfg_Standard__c
                FROM mfg_Service_Term__c
                WHERE mfg_Covered_Product__c IN :productIds
                  AND mfg_Active__c = TRUE
            ];

            if (serviceTerms.isEmpty()) {
                return;
            }

            /* ----------------------------
            4. Group Service Terms by Product
            ----------------------------- */
            Map<Id, List<mfg_Service_Term__c>> productToTermsMap =
                new Map<Id, List<mfg_Service_Term__c>>();

            for (mfg_Service_Term__c term : serviceTerms) {
                if (!productToTermsMap.containsKey(term.mfg_Covered_Product__c)) {
                    productToTermsMap.put(
                        term.mfg_Covered_Product__c,
                        new List<mfg_Service_Term__c>()
                    );
                }
                productToTermsMap.get(term.mfg_Covered_Product__c).add(term);
            }

            system.debug('productToTermsMap: ' + productToTermsMap);
            system.debug('productToTermsMap size: ' + productToTermsMap.size());

            /* ----------------------------
               5. Create Asset Services
            ----------------------------- */
            List<mfg_Asset_Service__c> assetServicesToInsert =
                new List<mfg_Asset_Service__c>();

            for (Asset ast : assets) {

                if (!productToTermsMap.containsKey(ast.Product2Id)) {
                    continue;
                }

                for (mfg_Service_Term__c term : productToTermsMap.get(ast.Product2Id)) {

                    Date startDate = ast.InstallDate;
                    Date endDate = calculateEndDate(
                        startDate,
                        term.mfg_Service_Unit__c,
                        term.mfg_Service_Duration__c
                    );
                    system.debug('startDate: ' + startDate + '. endDate: ' + endDate);

                    mfg_Asset_Service__c assetService =
                        new mfg_Asset_Service__c();

                    assetService.mfg_Asset__c = ast.Id;
                    assetService.mfg_Service_Term__c = term.Id;
                    assetService.mfg_Active__c = true;

                    assetService.mfg_Parts_Covered__c = term.mfg_Parts_Coverage__c;
                    assetService.mfg_Labor_Covered__c = term.mfg_Labor_Coverage__c;
                    assetService.mfg_Expenses_Covered__c = term.mfg_Expense_Coverage__c;

                    assetService.mfg_Service_Covered_Unit_Of_Time__c =
                        term.mfg_Service_Unit__c;
                    assetService.mfg_Service_Duration__c =
                        term.mfg_Service_Duration__c;

                    assetService.mfg_Service_Start_Date__c = startDate;
                    assetService.mfg_Service_End_Date__c = endDate;

                    if (term.mfg_Standard__c == true) {
                        assetService.mfg_Service_Type__c = 'Standard';
                    }

                    assetServicesToInsert.add(assetService);
                }
            }

            system.debug(
                'assetServicesToInsert size: ' + assetServicesToInsert.size()
            );
            system.debug('assetServicesToInsert: ' + assetServicesToInsert);

            /* ----------------------------
            6. Insert Asset Services
            ----------------------------- */
            if (!assetServicesToInsert.isEmpty()) {
                insert assetServicesToInsert;
            }

        } catch (Exception ex) {
            System.debug(
                'Error in AssetServiceCreationHandler: ' + ex.getMessage()
            );
        }
    }

    /* ----------------------------
    Date Calculation Helper
    ----------------------------- */
    private static Date calculateEndDate(
        Date startDate,
        String serviceUnit,
        Decimal duration
    ) {
        if (startDate == null || duration == null || duration <= 0) {
            return null;
        }
        Integer dur = Integer.valueOf(duration);

        if (serviceUnit == 'Days') {
            return startDate.addDays(dur);
        }
        if (serviceUnit == 'Weeks') {
            return startDate.addDays(dur * 7);
        }
        if (serviceUnit == 'Months') {
            return startDate.addMonths(dur);
        }
        if (serviceUnit == 'Years') {
            return startDate.addYears(dur);
        }

        return null;
    }
}