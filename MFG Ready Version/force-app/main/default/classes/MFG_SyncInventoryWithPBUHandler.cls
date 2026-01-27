public class MFG_SyncInventoryWithPBUHandler {

    @InvocableMethod(
        label = 'Sync Inventory with Production Batch Units'
        description = 'Updates Inventory quantities based on Production Batch Unit status and reservation'
    )
    public static void syncInventory(List<Id> pbuIds) {
        system.debug('pbuIds size' + pbuIds.size());
        system.debug('pbuIds: ' + pbuIds);

        if (pbuIds == null || pbuIds.isEmpty()) {
            return;
        }

        try {
            Set<Id> uniquePbuIds = new Set<Id>(pbuIds);
            system.debug('uniquePbuIds size' + uniquePbuIds.size());
            system.debug('uniquePbuIds: ' + uniquePbuIds);

            /* =========================
            1. Fetch PBUs
            ========================== */
            List<mfg_Production_Batch_Unit__c> pbus = [
                SELECT Id,
                    mfg_Inventory__c,
                    mfg_Order_Product__c,
                    mfg_Status__c
                FROM mfg_Production_Batch_Unit__c
                WHERE Id IN :uniquePbuIds
                AND mfg_Inventory__c != NULL
            ];

            if (pbus.isEmpty()) return;

            /* =========================
            2. Collect Inventory Ids
            ========================== */
            Set<Id> inventoryIds = new Set<Id>();
            for (mfg_Production_Batch_Unit__c pbu : pbus) {
                inventoryIds.add(pbu.mfg_Inventory__c);
            }

            /* =========================
            3. Aggregate Quantity On Hand
            ========================== */
            Map<Id, Integer> inventoryToOnHandQty = new Map<Id, Integer>();

            for (AggregateResult ar : [
                SELECT mfg_Inventory__c inventoryId,
                       COUNT(Id) qty
                FROM mfg_Production_Batch_Unit__c
                WHERE mfg_Inventory__c IN :inventoryIds
                AND mfg_Status__c NOT IN ('Delivered', 'Installed')
                GROUP BY mfg_Inventory__c
            ]) {
                inventoryToOnHandQty.put(
                    (Id) ar.get('inventoryId'),
                    (Integer) ar.get('qty')
                );
            }

            system.debug('inventoryToOnHandQty: ' + inventoryToOnHandQty);

            /* =========================
               4. Aggregate Reserved Quantity
            ========================== */
            Map<Id, Integer> inventoryToReservedQty = new Map<Id, Integer>();

            for (AggregateResult ar : [
                SELECT mfg_Inventory__c inventoryId,
                       COUNT(Id) qty
                FROM mfg_Production_Batch_Unit__c
                WHERE mfg_Inventory__c IN :inventoryIds
                AND mfg_Status__c NOT IN ('Delivered', 'Installed')
                AND mfg_Order_Product__c != NULL
                GROUP BY mfg_Inventory__c
            ]) {
                inventoryToReservedQty.put(
                    (Id) ar.get('inventoryId'),
                    (Integer) ar.get('qty')
                );
            }
            system.debug('inventoryToReservedQty: ' + inventoryToReservedQty);

            /* =========================
               5. Update Inventory
            ========================== */
            List<mfg_Inventory__c> inventoriesToUpdate = new List<mfg_Inventory__c>();

            for (Id invId : inventoryIds) {
                inventoriesToUpdate.add(
                    new mfg_Inventory__c(
                        Id = invId,
                        mfg_Quantity_On_Hand__c =
                            inventoryToOnHandQty.containsKey(invId)
                                ? inventoryToOnHandQty.get(invId)
                                : 0,
                        mfg_Reserved_Quantity__c =
                            inventoryToReservedQty.containsKey(invId)
                                ? inventoryToReservedQty.get(invId)
                                : 0
                    )
                );
            }

            system.debug('inventoriesToUpdate: ' + inventoriesToUpdate);
            system.debug('inventoriesToUpdate size: ' + inventoriesToUpdate.size());

            if (!inventoriesToUpdate.isEmpty()) {
                update inventoriesToUpdate;
            }

        } catch (Exception e) {
            System.debug(
                'Error in MFG_SyncInventoryWithPBUHandler: ' +
                e.getMessage()
            );
        }
    }
}