public class MFG_WorkOrderCreationHandler {

    /* Invocable Method for Flow */
    @InvocableMethod(label='Create Work Orders from Cases'
                     description='Creates Work Orders when Case is Converted and Reason is Demonstration/Installation/Service')
    public static void createWorkOrdersFromFlow(List<Id> caseIds) {

        // System.debug('Invocable Method called with Case Ids: ' + caseIds);

        createWorkOrders(caseIds);
    }


    /* Core Business Logic Method */
    public static void createWorkOrders(List<Id> caseIds) {

        try {

            // System.debug('Entered createWorkOrders method');
            // System.debug('Received Case Ids: ' + caseIds);

            /* Step 1: Query Cases */
            List<Case> caseList = [
                SELECT Id, Status, Reason, AccountId, ContactId, mfg_Preferred_Service_Date_Time__c
                FROM Case
                WHERE Id IN :caseIds
            ];

            // System.debug('Queried Cases: ' + caseList);
            // System.debug('Total Cases fetched: ' + caseList.size());

            /* Step 2: CaseReason → WorkTypeName Map */
            Map<String, String> caseReasonToWorkTypeNameMap = new Map<String, String>{
                'demonstration' => 'Demonstration',
                'installation'  => 'Installation',
                'service'       => 'Service'
            };

            // System.debug('CaseReason to WorkTypeName Map: ' + caseReasonToWorkTypeNameMap);

            /* Step 3: Filter eligible Cases */
            List<Case> eligibleCases = new List<Case>();

            for (Case c : caseList) {

                // System.debug('Processing Case Id: ' + c.Id + ' | Status: ' + c.Status + ' | Reason: ' + c.Reason);

                if (
                    c.Reason != null &&
                    caseReasonToWorkTypeNameMap.containsKey(c.Reason.toLowerCase())
                ) {
                    eligibleCases.add(c);
                    // System.debug('Case is eligible: ' + c.Id);
                } else {
                    System.debug('Case is NOT eligible: ' + c.Id);
                }
            }

            // System.debug('Eligible Cases Count: ' + eligibleCases.size());

            if (eligibleCases.isEmpty()) {
                System.debug('No eligible cases found. Exiting method.');
                return;
            }

            /* Step 4: Query WorkTypes using map values */
            Set<String> workTypeNames = new Set<String>();
            workTypeNames.addAll(caseReasonToWorkTypeNameMap.values());

            // System.debug('WorkType Names to query: ' + workTypeNames);

            Map<String, Id> workTypeNameToIdMap = new Map<String, Id>();

            for (WorkType wt : [
                SELECT Id, Name
                FROM WorkType
                WHERE Name IN :workTypeNames
            ]) {
                workTypeNameToIdMap.put(wt.Name, wt.Id);
                // System.debug('Fetched WorkType => Name: ' + wt.Name + ', Id: ' + wt.Id);
            }

            // System.debug('WorkTypeName to Id Map: ' + workTypeNameToIdMap);

            /* Step 5: Build CaseReason → WorkTypeId Map */
            Map<String, Id> caseReasonToWorkTypeIdMap = new Map<String, Id>();

            for (String caseReason : caseReasonToWorkTypeNameMap.keySet()) {
                String wtName = caseReasonToWorkTypeNameMap.get(caseReason);

                if (workTypeNameToIdMap.containsKey(wtName)) {
                    caseReasonToWorkTypeIdMap.put(caseReason, workTypeNameToIdMap.get(wtName));
                    // System.debug('Mapped CaseReason: ' + caseReason + ' to WorkTypeId: ' + workTypeNameToIdMap.get(wtName));
                }
            }

            // System.debug('Final CaseReason to WorkTypeId Map: ' + caseReasonToWorkTypeIdMap);

            /* Step 6: Create WorkOrders */
            List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();

            for (Case c : eligibleCases) {

                // System.debug('Creating WorkOrder for Case Id: ' + c.Id);

                WorkOrder wo = new WorkOrder();
                wo.AccountId = c.AccountId;
                wo.CaseId = c.Id;
                wo.Status = 'New';
                wo.Priority = 'High';
                wo.mfg_Preferred_Service_Date_Time__c = c.mfg_Preferred_Service_Date_Time__c;

                if (c.ContactId != null) {
                    wo.ContactId = c.ContactId;
                    // System.debug('Assigned ContactId to WorkOrder: ' + c.ContactId);
                } else {
                    System.debug('Case ContactId is null. Skipping Contact assignment.');
                }

                String caseReasonKey = c.Reason.toLowerCase();
                if (caseReasonToWorkTypeIdMap.containsKey(caseReasonKey)) {
                    wo.WorkTypeId = caseReasonToWorkTypeIdMap.get(caseReasonKey);
                    // System.debug('Assigned WorkTypeId: ' + wo.WorkTypeId);
                }

                workOrdersToInsert.add(wo);
            }

            // System.debug('Total WorkOrders to insert: ' + workOrdersToInsert.size());

            if (!workOrdersToInsert.isEmpty()) {
                insert workOrdersToInsert;
                // System.debug('WorkOrders inserted successfully: ' + workOrdersToInsert);
            }

            /* Step 7: Update Case using created WorkOrders */
            List<Case> casesToUpdate = new List<Case>();

            for (WorkOrder wo : workOrdersToInsert) {

                // System.debug('Updating Case for WorkOrder Id: ' + wo.Id + ' | CaseId: ' + wo.CaseId);

                if (wo.CaseId != null) {

                    Case c = new Case();
                    c.Id = wo.CaseId;
                    c.mfg_ConvertedClaimId__c = wo.Id;
                    c.mfg_ConvertedDate__c = Date.today();

                    casesToUpdate.add(c);
                }
            }

            // System.debug('Total Cases to update: ' + casesToUpdate.size());

            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
                // System.debug('Cases updated successfully with WorkOrder Id and Converted Date');
            }

            // System.debug('createWorkOrders method completed successfully.');

        } catch (Exception e) {
            System.debug('Exception in MFG_WorkOrderCreationHandler');
            System.debug('Error Message: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
}