public class MFG_OrderActivationHandler {

    // Invocable Method (Flow Entry Point)
    @InvocableMethod(
        label='Process Activated Orders'
        description='Allocates inventory and creates production orders for activated orders'
    )
    public static void handleActivatedOrders(List<Id> orderIds) {

        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }

        processActivatedOrders(new Set<Id>(orderIds));
    }

    // Core Business Logic
    public static void processActivatedOrders(Set<Id> orderIds) {

        if (orderIds == null || orderIds.isEmpty()) return;

        try {

            /* =========================
               1. Orders
            ========================== */
            Map<Id, Order> orderMap = new Map<Id, Order>([
                SELECT Id,
                       mfg_Storage_Warehouse__c,
                       mfg_Storage_Warehouse__r.mfg_Warehouse_Linking_Code__c
                FROM Order
                WHERE Id IN :orderIds
            ]);

            /* =========================
               2. Order Products
            ========================== */
            List<OrderItem> orderProducts = [
                SELECT Id, OrderId, Quantity, Product2Id
                FROM OrderItem
                WHERE OrderId IN :orderIds
            ];
            if (orderProducts.isEmpty()) return;

            /* =========================
               3. Collect Data
            ========================== */
            Set<Id> productIds = new Set<Id>();
            Set<Id> storageWarehouseIds = new Set<Id>();
            Set<String> linkingCodes = new Set<String>();

            for (OrderItem op : orderProducts) {
                Order ord = orderMap.get(op.OrderId);
                productIds.add(op.Product2Id);
                storageWarehouseIds.add(ord.mfg_Storage_Warehouse__c);
                linkingCodes.add(ord.mfg_Storage_Warehouse__r.mfg_Warehouse_Linking_Code__c);
            }

            /* =========================
               4. Inventories
            ========================== */
            Map<String, mfg_Inventory__c> inventoryMap = new Map<String, mfg_Inventory__c>();
            Map<Id, Decimal> remainingInventoryQty = new Map<Id, Decimal>();
            Set<Id> inventoryIds = new Set<Id>();

            for (mfg_Inventory__c inv : [
                SELECT Id, mfg_Product__c, mfg_Warehouse__c, mfg_Available_Quantity__c
                FROM mfg_Inventory__c
                WHERE mfg_Product__c IN :productIds
                AND mfg_Warehouse__c IN :storageWarehouseIds
            ]) {
                inventoryMap.put(inv.mfg_Product__c + '-' + inv.mfg_Warehouse__c, inv);
                inventoryIds.add(inv.Id);
                remainingInventoryQty.put(inv.Id, inv.mfg_Available_Quantity__c);
            }

            /* =========================
               5. Production Warehouses
            ========================== */
            Map<String, Id> linkCodeToProductionWh = new Map<String, Id>();
            for (mfg_Warehouse__c wh : [
                SELECT Id, mfg_Warehouse_Linking_Code__c
                FROM mfg_Warehouse__c
                WHERE mfg_Type__c = 'Production'
                AND mfg_Warehouse_Linking_Code__c IN :linkingCodes
            ]) {
                linkCodeToProductionWh.put(wh.mfg_Warehouse_Linking_Code__c, wh.Id);
            }

            /* =========================
               6. Free PBUs by Inventory
            ========================== */
            Map<Id, List<mfg_Production_Batch_Unit__c>> pbuByInventory =
                new Map<Id, List<mfg_Production_Batch_Unit__c>>();

            if (!inventoryIds.isEmpty()) {
                for (mfg_Production_Batch_Unit__c pbu : [
                    SELECT Id, mfg_Inventory__c
                    FROM mfg_Production_Batch_Unit__c
                    WHERE mfg_Order_Product__c = NULL
                    AND mfg_Asset__c = NULL
                    AND mfg_Inventory__c IN :inventoryIds
                ]) {
                    if (!pbuByInventory.containsKey(pbu.mfg_Inventory__c)) {
                        pbuByInventory.put(
                            pbu.mfg_Inventory__c,
                            new List<mfg_Production_Batch_Unit__c>()
                        );
                    }
                    pbuByInventory.get(pbu.mfg_Inventory__c).add(pbu);
                }
            }

            System.debug('inventoryMap' + inventoryMap);
            System.debug('pbuByInventory' + pbuByInventory);
            System.debug('remainingInventoryQty' + remainingInventoryQty);
            System.debug('linkCodeToProductionWh' + linkCodeToProductionWh);
            System.debug('linkingCodes' + linkingCodes);
            System.debug('storageWarehouseIds' + storageWarehouseIds);

            /* =========================
            7. Allocation Logic (FIXED)
            ========================== */
            List<mfg_Production_Batch_Unit__c> pbusToUpdate = new List<mfg_Production_Batch_Unit__c>();
            List<mfg_Production_Order__c> productionOrdersToInsert = new List<mfg_Production_Order__c>();

            for (OrderItem op : orderProducts) {

                Order ord = orderMap.get(op.OrderId);
                Id storageWhId = ord.mfg_Storage_Warehouse__c;
                String linkCode = ord.mfg_Storage_Warehouse__r.mfg_Warehouse_Linking_Code__c;

                String invKey = op.Product2Id + '-' + storageWhId;
                mfg_Inventory__c inv = inventoryMap.get(invKey);

                Decimal requiredQty = op.Quantity;
                Decimal allocQty = 0;

                if (inv != null && remainingInventoryQty.containsKey(inv.Id)) {

                    Decimal remainingQty = remainingInventoryQty.get(inv.Id);
                    Integer freePbuCount = pbuByInventory.containsKey(inv.Id)
                        ? pbuByInventory.get(inv.Id).size()
                        : 0;

                    allocQty = Math.min(
                        requiredQty,
                        Math.min(remainingQty, freePbuCount)
                    );

                    /* ---- Reserve PBUs ---- */
                    if (allocQty > 0) {
                        Integer count = 0;
                        for (mfg_Production_Batch_Unit__c pbu : pbuByInventory.get(inv.Id)) {
                            if (count >= allocQty) break;
                            pbu.mfg_Order_Product__c = op.Id;
                            pbusToUpdate.add(pbu);
                            count++;
                        }

                        // Decrease remaining inventory qty (FIX for Scenario 5)
                        remainingInventoryQty.put(inv.Id, remainingQty - allocQty);
                    }
                }

                /* ---- Production Order for Shortfall ---- */
                Decimal remainingToProduce = requiredQty - allocQty;
                if (remainingToProduce > 0) {
                    productionOrdersToInsert.add(
                        new mfg_Production_Order__c(
                            mfg_Product__c = op.Product2Id,
                            mfg_Quantity_Ordered__c = remainingToProduce,
                            mfg_Order_Product__c = op.Id,
                            mfg_Warehouse__c = linkCodeToProductionWh.get(linkCode)
                        )
                    );
                }
            }

            /* =========================
               8. DML
            ========================== */
            if (!pbusToUpdate.isEmpty()) {
                system.debug('pbusToUpdate size '+ pbusToUpdate.size());
                system.debug('pbusToUpdate ' + pbusToUpdate);
                update pbusToUpdate;
            }

            if (!productionOrdersToInsert.isEmpty()) {
                system.debug('productionOrdersToInsert size '+ productionOrdersToInsert.size());
                system.debug('productionOrdersToInsert ' + productionOrdersToInsert);
                insert productionOrdersToInsert;
            }

        } catch (Exception ex) {
            System.debug('MFG_OrderActivationHandler Error: ' + ex.getMessage());
            throw ex;
        }
    }
}