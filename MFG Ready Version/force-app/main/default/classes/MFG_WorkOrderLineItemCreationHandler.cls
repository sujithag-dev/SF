public with sharing class MFG_WorkOrderLineItemCreationHandler {

    /*========================================
      Invocable Method (Called from Flow)
    ========================================*/
    @InvocableMethod(label='Create Work Order Line Items from Case Line Items')
    public static void createWorkOrderLineItems(List<Id> workOrderIds) {

        System.debug('Invocable Method Started');
        System.debug('WorkOrder Ids from Flow: ' + workOrderIds);

        if (workOrderIds == null || workOrderIds.isEmpty()) {
            System.debug('No WorkOrder Ids received. Exiting...');
            return;
        }

        try {
            processWorkOrderLineItems(workOrderIds);
        } catch (Exception e) {
            System.debug('Exception in Invocable Method: ' + e.getMessage());
        }
    }


    /*========================================
      Core Logic Method
    ========================================*/
    private static void processWorkOrderLineItems(List<Id> workOrderIds) {

        System.debug('Core Logic Method Started');

        // Step 1: Query Work Orders with Case
        List<WorkOrder> workOrders = [
            SELECT Id, CaseId
            FROM WorkOrder
            WHERE Id IN :workOrderIds
            AND CaseId != null
        ];

        System.debug('Queried WorkOrders: ' + workOrders);

        if (workOrders.isEmpty()) {
            System.debug('No WorkOrders with Case found. Exiting...');
            return;
        }

        // Collect Case Ids
        Set<Id> caseIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            caseIds.add(wo.CaseId);
        }

        System.debug('Collected Case Ids: ' + caseIds);

        // Step 2: Query Case Line Items
        List<mfg_Case_Line_Item__c> caseLineItems = [
            SELECT Id, mfg_Case__c, mfg_Asset__c
            FROM mfg_Case_Line_Item__c
            WHERE mfg_Case__c IN :caseIds
        ];

        System.debug('Case Line Items found: ' + caseLineItems.size());

        if (caseLineItems.isEmpty()) {
            System.debug('No Case Line Items found. Exiting...');
            return;
        }

        // Map CaseId → Case Line Items
        Map<Id, List<mfg_Case_Line_Item__c>> caseToLineItemMap = new Map<Id, List<mfg_Case_Line_Item__c>>();

        for (mfg_Case_Line_Item__c cli : caseLineItems) {
            if (!caseToLineItemMap.containsKey(cli.mfg_Case__c)) {
                caseToLineItemMap.put(cli.mfg_Case__c, new List<mfg_Case_Line_Item__c>());
            }
            caseToLineItemMap.get(cli.mfg_Case__c).add(cli);
        }

        System.debug('Case to Line Item Map: ' + caseToLineItemMap);

        // Step 3: Create Work Order Line Items
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();

        for (WorkOrder wo : workOrders) {

            if (!caseToLineItemMap.containsKey(wo.CaseId)) {
                continue;
            }

            for (mfg_Case_Line_Item__c cli : caseToLineItemMap.get(wo.CaseId)) {

                WorkOrderLineItem woli = new WorkOrderLineItem();
                woli.WorkOrderId = wo.Id;
                woli.AssetId     = cli.mfg_Asset__c;

                woliList.add(woli);

                System.debug('Prepared WOLI for WorkOrder: ' + wo.Id +
                            ' with Asset: ' + cli.mfg_Asset__c);
            }
        }

        // Step 4: Insert Work Order Line Items
        if (!woliList.isEmpty()) {
            try {
                insert woliList;
                System.debug('Successfully inserted WorkOrderLineItems: ' + woliList.size());
            } catch (Exception e) {
                System.debug('Error inserting WorkOrderLineItems: ' + e.getMessage());
            }
        } else {
            System.debug('No WorkOrderLineItems to insert.');
        }
    }
}