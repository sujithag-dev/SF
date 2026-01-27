public without sharing class MFG_ClaimLineItemCreationHandler {

    @InvocableMethod(label='Create Claim Line Items from Case Line Items')
    public static void enqueueClaimLineItemJob(List<Id> claimIds) {

        if (claimIds == null || claimIds.isEmpty()) {
            return;
        }

        // Convert Ids to String (Case field is TEXT)
        List<String> claimIdStrings = new List<String>();
        for (Id claimId : claimIds) {
            claimIdStrings.add(String.valueOf(claimId));
        }

        System.enqueueJob(
            new MFG_ClaimLineItemCreationQueueable(claimIdStrings)
        );
    }
}