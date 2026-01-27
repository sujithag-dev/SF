public with sharing class MFG_ServiceAppointmentCreationHandler {

    /*=============================
    Invocable Method (Flow calls this)
    =============================*/
    @InvocableMethod(label='Create Service Appointments from Work Orders')
    public static void createServiceAppointments(List<Id> workOrderIds) {
        try {
            if (workOrderIds == null || workOrderIds.isEmpty()) {
                return;
            }

            createServiceAppointmentsLogic(workOrderIds);

        } catch (Exception e) {
            System.debug('Error in Invocable Method: ' + e.getMessage());
        }
    }


    /*=============================
    Core Business Logic Method
    =============================*/
    private static void createServiceAppointmentsLogic(List<Id> workOrderIds) {
        system.debug('workOrderIds: '+ workOrderIds);

        try {
            // 1. Fetch Work Orders
            List<WorkOrder> woList = [
                SELECT Id, ContactId, WorkTypeId, mfg_Preferred_Service_Date_Time__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ];

            Set<Id> workTypeIds = new Set<Id>();
            for (WorkOrder wo : woList) {
                if (wo.WorkTypeId != null) {
                    workTypeIds.add(wo.WorkTypeId);
                }
            }

            // 2. Fetch Work Types
            Map<Id, WorkType> wtMap = new Map<Id, WorkType>([
                SELECT Id,
                    EstimatedDuration,
                    DurationType,
                    BlockTimeBeforeAppointment,
                    BlockTimeBeforeUnit,
                    BlockTimeAfterAppointment,
                    BlockTimeAfterUnit,
                    TimeframeEnd,
                    TimeFrameEndUnit
                FROM WorkType
                WHERE Id IN :workTypeIds
            ]);
            system.debug('wtMap: '+ wtMap);


            List<ServiceAppointment> saList = new List<ServiceAppointment>();

            // 3. Create Service Appointments
            for (WorkOrder wo : woList) {

                if (wo.WorkTypeId == null || wo.mfg_Preferred_Service_Date_Time__c == null) {
                    continue;
                }

                WorkType wt = wtMap.get(wo.WorkTypeId);

                if (wt == null) continue;

                Datetime schedStart = wo.mfg_Preferred_Service_Date_Time__c;

                Datetime arrivalWindowStart = addTime(
                    schedStart,
                    wt.BlockTimeBeforeAppointment,
                    wt.BlockTimeBeforeUnit
                );

                Datetime schedEnd = addTime(
                    schedStart,
                    wt.EstimatedDuration,
                    wt.DurationType
                );

                Datetime arrivalWindowEnd = addTime(
                    schedEnd,
                    wt.BlockTimeAfterAppointment,
                    wt.BlockTimeAfterUnit
                );

                Datetime dueDate = addTime(
                    schedStart,
                    wt.TimeframeEnd,
                    wt.TimeFrameEndUnit
                );

                ServiceAppointment sa = new ServiceAppointment();
                sa.ParentRecordId = wo.Id;
                sa.WorkTypeId = wt.Id;
                sa.ContactId = wo.ContactId;

                sa.SchedStartTime = schedStart;
                sa.ArrivalWindowStartTime = arrivalWindowStart;
                sa.SchedEndTime = schedEnd;
                sa.ArrivalWindowEndTime = arrivalWindowEnd;

                sa.Duration = wt.EstimatedDuration;
                sa.DurationType = wt.DurationType;

                sa.EarliestStartTime = arrivalWindowStart;
                sa.DueDate = dueDate;

                saList.add(sa);
            }

            system.debug('saList: '+ saList);
            // 4. Insert Service Appointments
            if (!saList.isEmpty()) {
                insert saList;
            }

        } catch (Exception e) {
            System.debug('Error in Core Logic: ' + e.getMessage());
        }
    }


    /*=============================
    Utility Method for DateTime Calculation
    =============================*/
    private static Datetime addTime(Datetime baseTime, Decimal value, String unit) {

        if (baseTime == null || value == null || unit == null) {
            return baseTime;
        }

        Integer val = value.intValue();

        if (unit == 'Minutes') {
            return baseTime.addMinutes(val);
        }
        else if (unit == 'Hours') {
            return baseTime.addHours(val);
        }
        else if (unit == 'Days') {
            return baseTime.addDays(val);
        }

        return baseTime;
    }

}