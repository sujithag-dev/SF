trigger mfg_LeadTrigger on Lead (after update) {

    if (Label.mfg_Activate_ApexTrigger != 'true' && Label.mfg_Activate != 'true') {
        return;
    }

    if(Trigger.isAfter) { 
        if(Trigger.isUpdate) {
            mfg_LeadHandler.afterUpdate(Trigger.new, Trigger.old);
        }       
    }

}