public with sharing class MFG_ServiceResourceAssignmentHandler {

    // ============================
    // Invocable Method (called from Flow)
    // ============================
    @InvocableMethod(label='Assign Service Resource to Service Appointment'
                    description='Assign Service Resource using Round Robin based on Service Territory')
    public static void assignServiceResources(List<Id> serviceAppointmentIds) {

        System.debug('Invocable Method Started. SA Ids => ' + serviceAppointmentIds);

        if(serviceAppointmentIds == null || serviceAppointmentIds.isEmpty()){
            System.debug('No Service Appointment Ids received. Exiting...');
            return;
        }

        try {
            processAssignments(serviceAppointmentIds);
        }
        catch(Exception e){
            System.debug('Exception in assignServiceResources: ' + e.getMessage());
        }
    }


    // ============================
    // Core Logic Method
    // ============================
    private static void processAssignments(List<Id> serviceAppointmentIds){

        System.debug('processAssignments started');

        // 1. Fetch Service Appointments with Account & Service Territory
        List<ServiceAppointment> saList = [
            SELECT Id, AccountId, Account.mfg_Service_Territory__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ];

        System.debug('Fetched Service Appointments => ' + saList);

        // 2. Collect Service Territory Ids
        Set<Id> serviceTerritoryIds = new Set<Id>();

        for(ServiceAppointment sa : saList){
            if(sa.Account != null && sa.Account.mfg_Service_Territory__c != null){
                serviceTerritoryIds.add(sa.Account.mfg_Service_Territory__c);
            }
        }

        System.debug('Service Territory Ids => ' + serviceTerritoryIds);

        if(serviceTerritoryIds.isEmpty()){
            System.debug('No Service Territories found. Exiting...');
            return;
        }

        // 3. Query Service Territories with Service Resources (child query)
        List<ServiceTerritory> territoryList = [
            SELECT Id, Name, mfg_Next_Resource_Assignment_Index__c,
            (
                SELECT Id, ServiceResource.Id, ServiceResource.Name,
                    EffectiveStartDate, EffectiveEndDate
                FROM ServiceResources
                WHERE ServiceResource.ResourceType = 'T'
                    AND ServiceResource.IsActive = true
                    AND EffectiveStartDate <= TODAY
                    AND (EffectiveEndDate = null OR EffectiveEndDate >= TODAY)
                ORDER BY ServiceResource.Name
            )
            FROM ServiceTerritory
            WHERE IsActive = true
            AND Id IN :serviceTerritoryIds
        ];

        System.debug('Service Territories with Resources => ' + territoryList);

        // Map Territory Id to Territory record
        Map<Id, ServiceTerritory> territoryMap = new Map<Id, ServiceTerritory>();
        for(ServiceTerritory st : territoryList){
            territoryMap.put(st.Id, st);
        }

        // Prepare Assigned Resource records
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();
        List<ServiceTerritory> territoriesToUpdate = new List<ServiceTerritory>();

        // 4. Group Service Appointments by Service Territory
        Map<Id, List<ServiceAppointment>> territoryToSAmap = new Map<Id, List<ServiceAppointment>>();

        for(ServiceAppointment sa : saList){
            if(sa.Account != null && sa.Account.mfg_Service_Territory__c != null){
                Id territoryId = sa.Account.mfg_Service_Territory__c;

                if(!territoryToSAmap.containsKey(territoryId)){
                    territoryToSAmap.put(territoryId, new List<ServiceAppointment>());
                }
                territoryToSAmap.get(territoryId).add(sa);
            }
        }

        System.debug('Territory to Service Appointment Map => ' + territoryToSAmap);

        // 5. Round Robin Assignment per Territory
        for(Id territoryId : territoryToSAmap.keySet()){

            ServiceTerritory territory = territoryMap.get(territoryId);

            if(territory == null){
                System.debug('No Service Territory record found for Id => ' + territoryId);
                continue;
            }

            List<ServiceTerritoryMember> stmList = territory.ServiceResources;

            System.debug('Service Resources for Territory ' + territory.Name + ' => ' + stmList);

            if(stmList == null || stmList.isEmpty()){
                System.debug('No Service Resources available for Territory => ' + territory.Name);
                continue;
            }

            Integer resourceCount = stmList.size();

            Integer index = territory.mfg_Next_Resource_Assignment_Index__c == null ? 0 :
                            Integer.valueOf(territory.mfg_Next_Resource_Assignment_Index__c);

            System.debug('Starting Index for Territory ' + territory.Name + ' => ' + index);

            List<ServiceAppointment> saPerTerritory = territoryToSAmap.get(territoryId);

            for(ServiceAppointment sa : saPerTerritory){

                if(index >= resourceCount){
                    System.debug('Index exceeded resource count. Resetting to 0');
                    index = 0;
                }

                ServiceTerritoryMember stm = stmList[index];
                Id serviceResourceId = stm.ServiceResourceId;

                System.debug('Assigning Service Resource => ' + stm.ServiceResource.Name +
                             ' to Service Appointment => ' + sa.Id);

                AssignedResource ar = new AssignedResource();
                ar.ServiceAppointmentId = sa.Id;
                ar.ServiceResourceId = serviceResourceId;
                ar.IsRequiredResource = true;

                assignedResourceList.add(ar);

                index++; // move to next resource
            }

            // Update next index in territory
            territory.mfg_Next_Resource_Assignment_Index__c = index;
            territoriesToUpdate.add(territory);

            System.debug('Updated Next Index for Territory ' + territory.Name + ' => ' + index);
        }

        // 6. Insert Assigned Resources
        if(!assignedResourceList.isEmpty()){
            insert assignedResourceList;
            System.debug('Inserted Assigned Resources => ' + assignedResourceList);
        }

        // 7. Update Service Territories
        if(!territoriesToUpdate.isEmpty()){
            update territoriesToUpdate;
            System.debug('Updated Service Territories => ' + territoriesToUpdate);
        }

        System.debug('processAssignments completed successfully');
    }

}