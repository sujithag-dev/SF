public class MFG_InventoryReplenishmentProcessBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return MFG_InventoryReplenishmentProcessHandler.getInventoryQuery();
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        // Cast SObject list to Inventory list
        List<mfg_Inventory__c> inventories = (List<mfg_Inventory__c>) scope;

        MFG_InventoryReplenishmentProcessHandler.processInventories(inventories);
    }

    public void finish(Database.BatchableContext bc) {
        
    }
}