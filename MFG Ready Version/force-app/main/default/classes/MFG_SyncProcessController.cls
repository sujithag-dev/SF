public class MFG_SyncProcessController {
    @InvocableMethod(label='Run Inventory Replenishment Batch')
    public static void runInventoryReplenishmentProcessBatch() {
        Database.executeBatch(
            new MFG_InventoryReplenishmentProcessBatch(),
            200
        );
    }

}