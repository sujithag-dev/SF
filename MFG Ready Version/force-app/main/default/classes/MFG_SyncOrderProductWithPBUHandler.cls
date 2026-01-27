public class MFG_SyncOrderProductWithPBUHandler {
    @InvocableMethod(
        label = 'Sync Order Product with Production Batch Units'
        description = 'Updates reserved quantity count on Order Products based on Production Batch Units'
    )
    public static void syncReservedQuantity(List<Id> orderItemIds) {

        if (orderItemIds == null || orderItemIds.isEmpty()) {
            return;
        }

        try {
            Set<Id> uniqueOrderItemIds = new Set<Id>(orderItemIds);

            if (uniqueOrderItemIds.isEmpty()) {
                return;
            }
            system.debug('uniqueOrderItemIds size: ' + uniqueOrderItemIds.size());
            system.debug('uniqueOrderItemIds: ' + uniqueOrderItemIds);

            /* STEP 3: Aggregate PBU count per OrderItem */
            Map<Id, Integer> orderItemToCountMap = new Map<Id, Integer>();

            for (AggregateResult ar : [
                SELECT mfg_Order_Product__c orderItemId, COUNT(Id) pbuCount
                FROM mfg_Production_Batch_Unit__c
                WHERE mfg_Order_Product__c IN :uniqueOrderItemIds
                GROUP BY mfg_Order_Product__c
            ]) {
                orderItemToCountMap.put(
                    (Id) ar.get('orderItemId'),
                    (Integer) ar.get('pbuCount')
                );
            }

            /* STEP 4: Update OrderItem reserved quantity */
            List<OrderItem> orderItemsToUpdate = new List<OrderItem>();

            for (Id orderItemId : orderItemToCountMap.keySet()) {
                orderItemsToUpdate.add(new OrderItem(
                    Id = orderItemId,
                    mfg_Quantity_Reserved__c = orderItemToCountMap.get(orderItemId)
                ));
            }
            system.debug('orderItemsToUpdate size: ' + orderItemsToUpdate.size());
            if (!orderItemsToUpdate.isEmpty()) {
                system.debug('orderItemsToUpdate: ' + orderItemsToUpdate);
                update orderItemsToUpdate;
            }

        } catch (Exception e) {
            System.debug(
                'Error in MFG_SyncOrderProductWithProductionBatchUnitHandler: ' +
                e.getMessage()
            );
        }
    }

}