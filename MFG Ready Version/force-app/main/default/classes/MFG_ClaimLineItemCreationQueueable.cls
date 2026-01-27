public without sharing class MFG_ClaimLineItemCreationQueueable
    implements Queueable {

    private List<String> claimIdStrings;

    public MFG_ClaimLineItemCreationQueueable(List<String> claimIdStrings) {
        this.claimIdStrings = claimIdStrings;
    }

    public void execute(QueueableContext context) {

        try {
            /* ----------------------------------------
             * 1. Fetch Cases (TEXT comparison)
             * ---------------------------------------- */
            List<Case> cases = [
                SELECT Id, mfg_ConvertedClaimId__c
                FROM Case
                WHERE mfg_ConvertedClaimId__c IN :claimIdStrings
            ];

            if (cases.isEmpty()) {
                return;
            }

            Map<Id, Id> caseIdToClaimIdMap = new Map<Id, Id>();
            Set<Id> caseIds = new Set<Id>();

            for (Case c : cases) {
                caseIdToClaimIdMap.put(
                    c.Id,
                    (Id) c.mfg_ConvertedClaimId__c
                );
                caseIds.add(c.Id);
            }

            /* ----------------------------------------
             * 2. Fetch Case Line Items
             * ---------------------------------------- */
            List<mfg_Case_Line_Item__c> caseLineItems = [
                SELECT Id,
                       mfg_Case__c,
                       mfg_Asset__c,
                       mfg_Asset__r.Price,
                       mfg_Quantity__c,
                       mfg_Defect_Category__c
                FROM mfg_Case_Line_Item__c
                WHERE mfg_Case__c IN :caseIds
            ];

            if (caseLineItems.isEmpty()) {
                return;
            }

            /* ----------------------------------------
             * 3. Create Claim Line Items
             * ---------------------------------------- */
            List<mfg_Claim_Line_Item__c> claimLineItemsToInsert =
                new List<mfg_Claim_Line_Item__c>();

            for (mfg_Case_Line_Item__c cli : caseLineItems) {

                Id claimId = caseIdToClaimIdMap.get(cli.mfg_Case__c);
                if (claimId == null) continue;

                mfg_Claim_Line_Item__c cliNew =
                    new mfg_Claim_Line_Item__c();

                cliNew.mfg_Claim__c       = claimId;
                cliNew.mfg_Asset__c       = cli.mfg_Asset__c;
                cliNew.mfg_Quantity__c    = cli.mfg_Quantity__c;
                cliNew.mfg_Defect_Type__c = cli.mfg_Defect_Category__c;
                cliNew.mfg_Parts_Costs__c =
                    cli.mfg_Asset__r != null
                        ? cli.mfg_Asset__r.Price
                        : 0;

                claimLineItemsToInsert.add(cliNew);
            }

            if (!claimLineItemsToInsert.isEmpty()) {
                insert claimLineItemsToInsert;
            }

        } catch (Exception ex) {
            System.debug(
                'Error in Claim Line Item Queueable: ' +
                ex.getMessage() +
                ' | Line: ' + ex.getLineNumber()
            );
        }
    }
}