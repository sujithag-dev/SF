trigger MFG_SalesAgreementTrigger on mfg_Sales_Agreement__c (before insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        List<Pricebook2> activePB = [SELECT Id  FROM Pricebook2  WHERE IsActive = true LIMIT 1];

        Id activePBId = (activePB.isEmpty()) ? null : activePB[0].Id;
        
        if (activePBId != null) {
            for (mfg_Sales_Agreement__c sa : Trigger.new) {
                sa.mfg_Price_Book__c = activePBId; 
            }
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {

        Set<Id> changedSAIds = new Set<Id>();

        for (mfg_Sales_Agreement__c newSA : Trigger.new) {
            mfg_Sales_Agreement__c oldSA = Trigger.oldMap.get(newSA.Id);

            if (newSA.mfg_Schedule_Count__c != oldSA.mfg_Schedule_Count__c || 
                newSA.mfg_Activation_Date__c != oldSA.mfg_Activation_Date__c) {

                changedSAIds.add(newSA.Id);
            }
        }

        if (!changedSAIds.isEmpty()) {

            List<mfg_Agreement_Product__c> apList = [
                SELECT Id, mfg_Total_Quantity__c, mfg_Sales_Agreement__c
                FROM mfg_Agreement_Product__c
                WHERE mfg_Sales_Agreement__c IN :changedSAIds
            ];

            if (!apList.isEmpty()) {
                MFG_SalesAgreementHandler.generateSchedulesForAgreementProduct(apList);
            }
        }
    }
}