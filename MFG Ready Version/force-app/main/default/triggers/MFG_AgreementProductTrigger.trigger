trigger MFG_AgreementProductTrigger on mfg_Agreement_Product__c (before insert, before update,after insert, after update) {
    if(Trigger.isBefore){
        Set<Id> productIds = new Set<Id>();

        for(mfg_Agreement_Product__c ap : Trigger.new){
            if(ap.mfg_Product__c != null){
                productIds.add(ap.mfg_Product__c);
            }
        }

        if(!productIds.isEmpty()){
            Map<Id, Product2> productMap = new Map<Id, Product2>(
                [SELECT Id, Name FROM Product2 WHERE Id IN :productIds]
            );
            
            Map<Id, Decimal> productToPrice = new Map<Id, Decimal>();

            for (PricebookEntry pbe : [ SELECT Product2Id, UnitPrice FROM PricebookEntry WHERE Product2Id IN :productIds AND IsActive = true
                AND Pricebook2.IsActive = true
            ]) {
                productToPrice.put(pbe.Product2Id, pbe.UnitPrice);
            }

            for(mfg_Agreement_Product__c ap : Trigger.new){
                if(ap.mfg_Product__c != null){
                    ap.Name = productMap.get(ap.mfg_Product__c).Name;
                }
                
                if (productToPrice.containsKey(ap.mfg_Product__c)) {
                    ap.mfg_List_Price__c = productToPrice.get(ap.mfg_Product__c);
                }
            }
        }
    }

    List<mfg_Agreement_Product__c> apToProcess = new List<mfg_Agreement_Product__c>();

    if(Trigger.isAfter){

        if(Trigger.isInsert){
            apToProcess.addAll(Trigger.new);
        }

        if(Trigger.isUpdate){
            for(mfg_Agreement_Product__c newAP : Trigger.new){
                mfg_Agreement_Product__c oldAP = Trigger.oldMap.get(newAP.Id);

                if(newAP.mfg_Total_Quantity__c != oldAP.mfg_Total_Quantity__c){
                    apToProcess.add(newAP);
                }
            }
        }

        if(!apToProcess.isEmpty()){
            MFG_SalesAgreementHandler.generateSchedulesForAgreementProduct(apToProcess);
        }
    }
}