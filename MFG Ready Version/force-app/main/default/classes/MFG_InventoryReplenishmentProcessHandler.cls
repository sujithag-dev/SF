public class MFG_InventoryReplenishmentProcessHandler {

    /* ================= CONSTANTS ================= */
    private static final String WAREHOUSE_TYPE_PRODUCTION = 'Production';
    private static final String PRIORITY_MEDIUM = 'Medium';
    private static final String STATUS_PLANNED = 'Planned';

    /* ================= INVENTORY QUERY ================= */
    public static Database.QueryLocator getInventoryQuery() {
        return Database.getQueryLocator([
            SELECT Id,
                mfg_Product__c,
                mfg_Warehouse__r.mfg_Warehouse_Linking_Code__c,mfg_Last_Forecast_Date__c,
                mfg_Available_Quantity__c,mfg_Reorder_Point_Units__c,mfg_Next_Forecast_Date__c 
            FROM mfg_Inventory__c
            WHERE mfg_Inventory_Below_Safety_Level__c = true
            AND mfg_Product__c != NULL
            AND mfg_Warehouse__r.mfg_Warehouse_Linking_Code__c != NULL
            AND (mfg_Next_Forecast_Date__c <= TODAY OR mfg_Last_Forecast_Date__c = NULL)
        ]);

    }

    /* ================= MAIN PROCESS ================= */
    public static void processInventories(List<mfg_Inventory__c> inventories) {

        if (inventories.isEmpty()) return;

        try {

            /* Collect linking codes */
            Set<String> linkingCodes = new Set<String>();
            for (mfg_Inventory__c inv : inventories) {
                if (inv.mfg_Warehouse__r != null) {
                    linkingCodes.add(
                        inv.mfg_Warehouse__r.mfg_Warehouse_Linking_Code__c
                    );
                }
            }

            /* Fetch production warehouses */
            Map<String, Id> productionWarehouseMap = new Map<String, Id>();
            if (!linkingCodes.isEmpty()) {
                for (mfg_Warehouse__c warehouse : [
                    SELECT Id, mfg_Warehouse_Linking_Code__c
                    FROM mfg_Warehouse__c
                    WHERE mfg_Warehouse_Linking_Code__c IN :linkingCodes
                    AND mfg_Type__c = :WAREHOUSE_TYPE_PRODUCTION
                    AND mfg_Is_Active__c = true
                ]) {
                    productionWarehouseMap.put(
                        warehouse.mfg_Warehouse_Linking_Code__c,
                        warehouse.Id
                    );
                }
            }

            /* Create production orders and update inventories */
            List<mfg_Production_Order__c> productionOrdersToInsert = new List<mfg_Production_Order__c>();
            List<mfg_Inventory__c> inventoriesToUpdate = new List<mfg_Inventory__c>();

            for (mfg_Inventory__c inv : inventories) {

                try {

                    if (inv.mfg_Warehouse__r == null) continue;

                    String linkingCode = inv.mfg_Warehouse__r.mfg_Warehouse_Linking_Code__c;

                    Id productionWarehouseId = productionWarehouseMap.get(linkingCode);

                    if (productionWarehouseId == null) continue;

                    Integer quantityToProduce = calculateQuantity(
                                                    inv.mfg_Reorder_Point_Units__c,
                                                    inv.mfg_Available_Quantity__c
                                                );

                    if (quantityToProduce <= 0) continue;

                    productionOrdersToInsert.add(
                        new mfg_Production_Order__c(
                            mfg_Product__c = inv.mfg_Product__c,
                            mfg_Warehouse__c = productionWarehouseId,
                            mfg_Quantity_Ordered__c = quantityToProduce,
                            mfg_Estimated_Start__c = Date.today(),
                            mfg_Priority__c = PRIORITY_MEDIUM,
                            mfg_Status__c = STATUS_PLANNED
                        )
                    );

                    inventoriesToUpdate.add(
                        new mfg_Inventory__c(
                            Id = inv.Id,
                            mfg_Last_Forecast_Date__c = Date.today() 
                        )
                    );


                } catch (Exception recordEx) {
                    // Skip this inventory and continue
                    System.debug(
                        LoggingLevel.ERROR,
                        'Inventory processing failed: ' + inv.Id +
                        ' | ' + recordEx.getMessage()
                    );
                }
            }

            /* Insert production orders */
            if (!productionOrdersToInsert.isEmpty()) {
                insert productionOrdersToInsert;
            }

            /* Update inventories */
            if (!inventoriesToUpdate.isEmpty()) {
                update inventoriesToUpdate;
            }

        } catch (Exception batchEx) {
            // Protect batch chunk from failure
            System.debug(
                LoggingLevel.ERROR,
                'Batch execution failed: ' + batchEx.getMessage()
            );
        }
    }

    /* ================= HELPER ================= */
    private static Integer calculateQuantity(
        Decimal reorderPoint,
        Decimal availableQty
    ) {
        Integer reorder = reorderPoint != null ? Integer.valueOf(reorderPoint) : 0;

        Integer available = availableQty != null ? Integer.valueOf(availableQty) : 0;

        Integer quantity = reorder - available;
        return quantity > 0 ? quantity : 0;
    }
}