public class SIS_LeadAssignmentRoundRobin {
    @InvocableMethod(label='SIS_LeadAssignmentRoundRobin')
    public static void assignLead(List<Lead> lead){
        try{
            Lead leadToUpdate = lead[0];
            if(leadToUpdate.Nationality__c == 'MY' || String.isBlank(leadToUpdate.Nationality__c)){
                SIS_LeadAssignmentRoundRobin.assignLeadsByNationality(leadToUpdate, 'MY');
            }else{
                SIS_LeadAssignmentRoundRobin.assignLeadsByNationality(leadToUpdate, 'OTHERS');
            }
        }catch(Exception e){
            //Database.rollback(sp);
            System.debug('Error---'+ e.getMessage());
            System.debug('Error---'+ e.getStackTraceString());
        }
    }
    
    
    public static void assignLeadsByNationality(Lead lead, String nationality){
        Integer lastAssignedIndex;
        Integer userCount;
        String leadFullName;
        List<CustomNotificationType> customNotification = new List<CustomNotificationType>();
        List<RoundRobinSetting__c> roundRobinIndex = new List<RoundRobinSetting__c>();
        List<Group> groupName = new List<Group>();
        List<GroupMember> groupMembers = new List<GroupMember>();
        List<User> userToAssign = new List<User>();
        try{
            if(Test.isRunningTest()){
                roundRobinIndex = [Select Id, Last_Assigned_Index__c From RoundRobinSetting__c Where Name = 'SIS_Lead Assignment For RR' Limit 1];
                if(nationality == 'MY'){
                    groupName = [select Id from Group Where DeveloperName = 'SIS_Lead_Assignment_Queue' Limit 1];
                }else if(nationality == 'OTHERS'){
                    groupName = [select Id from Group Where DeveloperName = 'SIS_Queue_For_International_Students' Limit 1];
                }
            }else{
                if(nationality == 'MY'){
                    roundRobinIndex = [Select Id, Last_Assigned_Index__c, Last_Assigned_User_Name__c From RoundRobinSetting__c Where Name = 'SIS_Lead Assignment For Malaysian Students' Limit 1];
                    groupName = [select Id from Group Where DeveloperName = 'SIS_Lead_Assignment_Queue' Limit 1];
                }else if(nationality == 'OTHERS'){
                    roundRobinIndex = [Select Id, Last_Assigned_Index__c, Last_Assigned_User_Name__c From RoundRobinSetting__c Where Name = 'SIS_Lead Assignment For International Students' Limit 1];
                    groupName = [select Id from Group Where DeveloperName = 'SIS_Queue_For_International_Students' Limit 1];
                }
            }
            System.debug('roundRobinIndex---'+ roundRobinIndex);
            System.debug('groupName---'+ groupName);
            customNotification = [SELECT Id FROM CustomNotificationType WHERE DeveloperName	= 'SIS_Notification_To_Lead_Owner_For_Round_Robin' LIMIT 1];
            System.debug('customNotification---'+ customNotification);
            if(!roundRobinIndex.isEmpty()){
                lastAssignedIndex = Integer.valueOf(roundRobinIndex[0].Last_Assigned_Index__c);
                System.debug('lastAssignedIndex---'+ lastAssignedIndex);
            }
            if(!groupName.isEmpty()){
                groupMembers = [Select Id, UserOrGroup.Id From GroupMember where GroupId =: groupName[0].Id];
                System.debug('groupMembers---'+ groupMembers);
                if(!groupMembers.isEmpty()){
                    userCount = groupMembers.size();
                    System.debug('userCount---'+ userCount);
                    if(userCount > 0){
                        lastAssignedIndex = lastAssignedIndex + 1;
                        System.debug('lastAssignedIndex after update---'+ lastAssignedIndex);
                        if(lastAssignedIndex > userCount){
                            lastAssignedIndex = 1;
                            System.debug('lastAssignedIndex after reset---'+ lastAssignedIndex);
                        }
                        //get user to assign
                        userToAssign = [SELECT Id, Name FROM User WHERE Id = :groupMembers[lastAssignedIndex - 1].UserOrGroup.Id];
                        System.debug('userToAssign---'+ userToAssign);
                        //Lead To Update
                        Lead leadToUpdate = lead;
                        leadToUpdate.OwnerId = userToAssign[0].Id;
                        update leadToUpdate;
                        System.debug('leadToUpdate---'+ leadToUpdate);
                        System.debug('leadToUpdate.Name---'+leadToUpdate.LastName);
                        
                        leadFullName = (leadToUpdate.FirstName != null ? leadToUpdate.FirstName + ' ' : '') + leadToUpdate.LastName;
                        System.debug('leadFullName---'+ leadFullName);
                        
                        // Create a new custom notification
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('New Lead Alert!');
                        notification.setBody('🎯 You\'ve been assigned a new lead!\n' +'👤 Name: ' + leadFullName + '\n' );
                        notification.setNotificationTypeId(customNotification[0].Id);
                        notification.setTargetId(leadToUpdate.Id);
                        
                        notification.send(new Set<String>{userToAssign[0].Id});
                        System.debug('Notification sent!!');
                        
                        //Update Last Assigned Index in RoundRobinSetting__c
                        RoundRobinSetting__c rrs = roundRobinIndex[0];
                        rrs.Last_Assigned_Index__c = lastAssignedIndex;
                        rrs.Last_Assigned_User_Name__c = userToAssign[0].Name;
                        update rrs;
                        System.debug('rrs after update---'+ rrs);
                    }
                }
            }
        }catch(Exception e){
            //Database.rollback(sp);
            System.debug('Error---'+ e.getMessage());
            System.debug('Error---'+ e.getStackTraceString());
        }
    }
}