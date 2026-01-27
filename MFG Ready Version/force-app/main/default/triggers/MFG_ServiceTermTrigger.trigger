trigger MFG_ServiceTermTrigger on Product2 (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        //MFG_ServiceTermHandler.handleNewProducts(Trigger.new); old class
        MFG_ServiceTermController.handleNewProducts(Trigger.new);
    }
}