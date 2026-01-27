public with sharing class MFG_ScheduleServiceAppoinmentHandler {

    @InvocableMethod(
        label='Schedule Service Appointments for New Products'
        description='Creates Work Orders and Service Appointments for products created this week'
    )
    public static void scheduleAppointments() {

        try {
            /* -----------------------------------------
             * 1. Fetch Products
             * ----------------------------------------- */
            List<Product2> products = [
                SELECT Id
                FROM Product2
                WHERE CreatedDate = TODAY
            ];
            if (products.isEmpty()) return;

            /* -----------------------------------------
             * 2. Fetch Eligible Accounts
             * ----------------------------------------- */
            Map<Id, Account> accountMap = new Map<Id, Account>(
                [
                    SELECT Id,
                        mfg_Primary_Contact__c,
                        mfg_Service_Territory__c
                    FROM Account
                    WHERE RecordType.DeveloperName = 'mfg_Customer_Account_Recordtype'
                      AND mfg_Service_Territory__c != NULL
                      AND mfg_Primary_Contact__c != NULL
                ]
            );
            system.debug('accountMap: ' + accountMap);
            system.debug('accountMap size: ' + accountMap.size());
            if (accountMap.isEmpty()) return;

            /* -----------------------------------------
             * 3. Create Work Orders
             * Product × Account
             * ----------------------------------------- */
            List<WorkOrder> workOrders = new List<WorkOrder>();

            for (Product2 prod : products) {
                for (Account acc : accountMap.values()) {
                    workOrders.add(new WorkOrder(
                        AccountId      = acc.Id,
                        ContactId      = acc.mfg_Primary_Contact__c,
                        mfg_Product__c = prod.Id,
                        Status         = 'New'
                    ));
                }
            }

            insert workOrders;

            /* -----------------------------------------
             * 4. Fetch Service Territory Members
             * (Territory → Resource)
             * ----------------------------------------- */
            Set<Id> territoryIds = new Set<Id>();
            for (Account acc : accountMap.values()) {
                territoryIds.add(acc.mfg_Service_Territory__c);
            }

            Map<Id, ServiceTerritoryMember> territoryMemberMap = new Map<Id, ServiceTerritoryMember>();
            for (ServiceTerritoryMember stm : [
                SELECT ServiceTerritoryId, ServiceResourceId
                FROM ServiceTerritoryMember
                WHERE ServiceTerritoryId IN :territoryIds
            ]) {
                // keep one resource per territory
                if (!territoryMemberMap.containsKey(stm.ServiceTerritoryId)) {
                    territoryMemberMap.put(stm.ServiceTerritoryId, stm);
                }
            }
            system.debug('territoryMemberMap: ' + territoryMemberMap);
            /* -----------------------------------------
             * 5. Create Service Appointments
             * (Account is derived automatically)
             * ----------------------------------------- */
            List<ServiceAppointment> appointments = new List<ServiceAppointment>();

            DateTime schedStart = DateTime.newInstance(
                Date.today(),
                Time.newInstance(11, 0, 0, 0)
            );

            Integer durationMinutes = 30;

            for (WorkOrder wo : workOrders) {
                DateTime schedEnd = schedStart.addMinutes(durationMinutes);

                appointments.add(new ServiceAppointment(
                    ContactId      = wo.ContactId,
                    ParentRecordId = wo.Id,
                    Duration       = durationMinutes,
                    DurationType   = 'Minutes',
                    Status         = 'Scheduled',
                    SchedStartTime = schedStart,
                    SchedEndTime   = schedEnd,
                    DueDate        = schedEnd.addMinutes(durationMinutes)
                ));
            }

            system.debug('appointments: ' + appointments);
            system.debug('appointments size: ' + appointments.size());
            if (!appointments.isEmpty()) {
                insert appointments;
            }

            /* -----------------------------------------
             * 6. Create Assigned Resources
             * (Driven by WorkOrder → Account → Territory)
             * ----------------------------------------- */
            List<AssignedResource> assignedResources = new List<AssignedResource>();

            for (Integer i = 0; i < appointments.size(); i++) {
                WorkOrder wo = workOrders[i];
                Account acc = accountMap.get(wo.AccountId);

                if (acc != null && territoryMemberMap.containsKey(acc.mfg_Service_Territory__c)) {
                    ServiceTerritoryMember stm =
                        territoryMemberMap.get(acc.mfg_Service_Territory__c);

                    assignedResources.add(new AssignedResource(
                        ServiceAppointmentId = appointments[i].Id,
                        ServiceResourceId    = stm.ServiceResourceId,
                        IsRequiredResource   = true
                    ));
                }
            }

            system.debug('assignedResources: ' + assignedResources);
            system.debug('assignedResources size: ' + assignedResources.size());

            if (!assignedResources.isEmpty()) {
                insert assignedResources;
            }

        } catch (Exception e) {
            System.debug('MFG_ScheduleServiceAppoinmentHandler Error: ' + e.getMessage());
            throw new AuraHandledException(
                'Service Appointment scheduling failed. Please contact your administrator.'
            );
        }
    }
}