trigger LeadTrigger on Lead (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.handleOpportunityCreation(
            Trigger.new, Trigger.oldMap
        );
    }
}