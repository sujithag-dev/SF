/**
 * MS365IntegrationHelper
 *
 * Utility class for programmatically publishing Salesforce Platform Events
 * that carry Lead, Opportunity, and Task lifecycle payloads to the
 * Microsoft Teams / Outlook integration layer.
 *
 * Usage (example from a trigger or another class):
 *   MS365IntegrationHelper.publishLeadEvent(lead, 'LEAD_STATUS_CHANGED');
 *   MS365IntegrationHelper.publishOpportunityEvent(opp, 'OPP_CLOSED_WON');
 *   MS365IntegrationHelper.publishTaskEvent(task, 'TASK_OVERDUE');
 *
 * Event types:
 *   Lead        → LEAD_CREATED | LEAD_STATUS_CHANGED | LEAD_REASSIGNED |
 *                  LEAD_CONVERTED | LEAD_SCORE_ALERT | LEAD_AGING_ALERT
 *   Opportunity → OPP_CREATED | OPP_STAGE_CHANGED | OPP_CLOSED_WON |
 *                  OPP_CLOSED_LOST | OPP_NO_ACTIVITY | OPP_AT_RISK | OPP_BIG_DEAL
 *   Task        → TASK_ASSIGNED | TASK_DUE_SOON | TASK_OVERDUE
 */
public with sharing class MS365IntegrationHelper {

    // ─────────────────────────────────────────────────────────────────────────
    // Custom exception for surfacing publish errors upstream
    // ─────────────────────────────────────────────────────────────────────────
    public class MS365IntegrationException extends Exception {}

    // ─────────────────────────────────────────────────────────────────────────
    // LEAD EVENT
    // Accepts a Lead SObject already queried with all required fields.
    // Required fields on the lead parameter:
    //   Id, Name, Company, Email, Phone, Status, LeadSource, Rating,
    //   Lead_Score__c, OwnerId, IsConverted, ConvertedOpportunityId
    // ─────────────────────────────────────────────────────────────────────────
    public static void publishLeadEvent(Lead lead, String eventType) {
        if (lead == null || String.isBlank(eventType)) {
            throw new MS365IntegrationException('publishLeadEvent: lead and eventType are required.');
        }

        Lead_Lifecycle_Event__e evt = new Lead_Lifecycle_Event__e();
        evt.Lead_Id__c            = lead.Id;
        evt.Lead_Name__c          = lead.Name;
        evt.Company__c            = lead.Company;
        evt.Email__c              = lead.Email;
        evt.Phone__c              = lead.Phone;
        evt.Status__c             = lead.Status;
        evt.Lead_Source__c        = lead.LeadSource;
        evt.Rating__c             = lead.Rating;
        evt.Lead_Score__c         = lead.Lead_Score__c;
        evt.Event_Type__c         = eventType;
        evt.SF_Record_URL__c      = getSFRecordURL(lead.Id);

        // Owner enrichment
        if (lead.OwnerId != null) {
            User owner = queryUser(lead.OwnerId);
            if (owner != null) {
                evt.Owner_Name__c  = owner.Name;
                evt.Owner_Email__c = owner.Email;
                evt.Owner_UPN__c   = owner.Teams_UPN__c;
            }
        }

        // Conversion enrichment
        if (lead.IsConverted && lead.ConvertedOpportunityId != null) {
            evt.Converted_Opp_Id__c = lead.ConvertedOpportunityId;
            List<Opportunity> opps = [
                SELECT Name FROM Opportunity
                WHERE Id = :lead.ConvertedOpportunityId
                LIMIT 1
            ];
            if (!opps.isEmpty()) {
                evt.Converted_Opp_Name__c = opps[0].Name;
            }
        }

        publishAndValidate(evt);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // OPPORTUNITY EVENT
    // Required fields on the opp parameter:
    //   Id, Name, AccountId, StageName, Amount, CloseDate, Probability,
    //   Deal_Size_Category__c, Close_Reason__c, OwnerId
    // ─────────────────────────────────────────────────────────────────────────
    public static void publishOpportunityEvent(Opportunity opp, String eventType) {
        if (opp == null || String.isBlank(eventType)) {
            throw new MS365IntegrationException('publishOpportunityEvent: opp and eventType are required.');
        }

        Opportunity_Lifecycle_Event__e evt = new Opportunity_Lifecycle_Event__e();
        evt.Opportunity_Id__c     = opp.Id;
        evt.Opportunity_Name__c   = opp.Name;
        evt.Event_Type__c         = eventType;
        evt.New_Stage__c          = opp.StageName;
        evt.Amount__c             = opp.Amount;
        evt.Close_Date__c         = getFormattedDate(opp.CloseDate);
        evt.Probability__c        = opp.Probability;
        evt.Deal_Size_Category__c = opp.Deal_Size_Category__c;
        evt.Close_Reason__c       = opp.Close_Reason__c;
        evt.SF_Record_URL__c      = getSFRecordURL(opp.Id);

        // Account name
        if (opp.AccountId != null) {
            List<Account> accs = [SELECT Name FROM Account WHERE Id = :opp.AccountId LIMIT 1];
            if (!accs.isEmpty()) {
                evt.Account_Name__c = accs[0].Name;
            }
        }

        // Owner enrichment
        if (opp.OwnerId != null) {
            User owner = queryUser(opp.OwnerId);
            if (owner != null) {
                evt.Owner_Name__c  = owner.Name;
                evt.Owner_Email__c = owner.Email;
                evt.Owner_UPN__c   = owner.Teams_UPN__c;
            }
        }

        publishAndValidate(evt);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TASK EVENT
    // Required fields on the task parameter:
    //   Id, Subject, ActivityDate, Priority, Status, OwnerId, WhatId
    // ─────────────────────────────────────────────────────────────────────────
    public static void publishTaskEvent(Task task, String eventType) {
        if (task == null || String.isBlank(eventType)) {
            throw new MS365IntegrationException('publishTaskEvent: task and eventType are required.');
        }

        Task_Alert_Event__e evt = new Task_Alert_Event__e();
        evt.Task_Id__c       = task.Id;
        evt.Subject__c       = task.Subject;
        evt.Due_Date__c      = getFormattedDate(task.ActivityDate);
        evt.Priority__c      = task.Priority;
        evt.Status__c        = task.Status;
        evt.Event_Type__c    = eventType;
        evt.SF_Record_URL__c = getSFRecordURL(task.Id);

        // Related-to record
        if (task.WhatId != null) {
            evt.Related_To_URL__c = getSFRecordURL(task.WhatId);
            // Attempt polymorphic name resolution (Opportunity or Lead or Account)
            String relatedName = resolvePolymorphicName(task.WhatId);
            evt.Related_To_Name__c = relatedName;
        }

        // Assigned-to enrichment
        if (task.OwnerId != null) {
            User assignee = queryUser(task.OwnerId);
            if (assignee != null) {
                evt.Assigned_To_Name__c  = assignee.Name;
                evt.Assigned_To_Email__c = assignee.Email;
                evt.Assigned_To_UPN__c   = assignee.Teams_UPN__c;
            }
        }

        publishAndValidate(evt);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // BULK LEAD EVENT — publish multiple lead events in one EventBus call
    // ─────────────────────────────────────────────────────────────────────────
    public static void publishLeadEvents(List<Lead> leads, String eventType) {
        if (leads == null || leads.isEmpty() || String.isBlank(eventType)) {
            return;
        }

        List<Lead_Lifecycle_Event__e> evts = new List<Lead_Lifecycle_Event__e>();
        Set<Id> ownerIds = new Set<Id>();
        for (Lead l : leads) {
            if (l.OwnerId != null) ownerIds.add(l.OwnerId);
        }

        Map<Id, User> ownerMap = new Map<Id, User>(
            [SELECT Id, Name, Email, Teams_UPN__c FROM User WHERE Id IN :ownerIds]
        );

        for (Lead l : leads) {
            Lead_Lifecycle_Event__e evt = new Lead_Lifecycle_Event__e();
            evt.Lead_Id__c       = l.Id;
            evt.Lead_Name__c     = l.Name;
            evt.Company__c       = l.Company;
            evt.Email__c         = l.Email;
            evt.Status__c        = l.Status;
            evt.Lead_Score__c    = l.Lead_Score__c;
            evt.Event_Type__c    = eventType;
            evt.SF_Record_URL__c = getSFRecordURL(l.Id);
            if (l.OwnerId != null && ownerMap.containsKey(l.OwnerId)) {
                User owner = ownerMap.get(l.OwnerId);
                evt.Owner_Name__c  = owner.Name;
                evt.Owner_Email__c = owner.Email;
                evt.Owner_UPN__c   = owner.Teams_UPN__c;
            }
            evts.add(evt);
        }

        List<Database.SaveResult> results = EventBus.publish(evts);
        validateBulkPublish(results);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPER — getFormattedDate
    // Returns ISO-8601 date string (YYYY-MM-DD) or empty string if null.
    // ─────────────────────────────────────────────────────────────────────────
    public static String getFormattedDate(Date d) {
        if (d == null) {
            return '';
        }
        return String.valueOf(d);  // Apex returns YYYY-MM-DD for Date
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPER — getSFRecordURL
    // Builds an absolute Salesforce record URL using the SF_ORG_BASE_URL label.
    // ─────────────────────────────────────────────────────────────────────────
    public static String getSFRecordURL(String recordId) {
        if (String.isBlank(recordId)) {
            return '';
        }
        String baseUrl = Label.SF_ORG_BASE_URL;
        return baseUrl + '/' + recordId;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPER — getOwnerUPN
    // Returns the Teams_UPN__c for a given User Id, or empty string if not set.
    // ─────────────────────────────────────────────────────────────────────────
    public static String getOwnerUPN(Id ownerId) {
        if (ownerId == null) {
            return '';
        }
        User u = queryUser(ownerId);
        return (u != null && !String.isBlank(u.Teams_UPN__c)) ? u.Teams_UPN__c : '';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIVATE — Single-record user query (Id + Name + Email + Teams_UPN__c)
    // ─────────────────────────────────────────────────────────────────────────
    private static User queryUser(Id userId) {
        List<User> users = [
            SELECT Id, Name, Email, Teams_UPN__c
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
        return users.isEmpty() ? null : users[0];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIVATE — Publish a single SObject platform event and validate
    // ─────────────────────────────────────────────────────────────────────────
    private static void publishAndValidate(SObject evt) {
        Database.SaveResult result = EventBus.publish(evt);
        if (!result.isSuccess()) {
            List<String> errors = new List<String>();
            for (Database.Error err : result.getErrors()) {
                errors.add(err.getMessage());
            }
            throw new MS365IntegrationException(
                'Platform event publish failed: ' + String.join(errors, '; ')
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIVATE — Validate results from bulk EventBus.publish
    // ─────────────────────────────────────────────────────────────────────────
    private static void validateBulkPublish(List<Database.SaveResult> results) {
        List<String> errors = new List<String>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errors.add('Record ' + i + ': ' + err.getMessage());
                }
            }
        }
        if (!errors.isEmpty()) {
            throw new MS365IntegrationException(
                'Bulk platform event publish failed: ' + String.join(errors, '; ')
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIVATE — Resolve polymorphic WhatId to a record Name
    // Attempts Opportunity → Account → Lead → Case in order.
    // Returns empty string if no match is found.
    // ─────────────────────────────────────────────────────────────────────────
    private static String resolvePolymorphicName(Id whatId) {
        if (whatId == null) return '';

        String objType = whatId.getSObjectType().getDescribe().getName();

        if (objType == 'Opportunity') {
            List<Opportunity> recs = [SELECT Name FROM Opportunity WHERE Id = :whatId LIMIT 1];
            return recs.isEmpty() ? '' : recs[0].Name;
        } else if (objType == 'Account') {
            List<Account> recs = [SELECT Name FROM Account WHERE Id = :whatId LIMIT 1];
            return recs.isEmpty() ? '' : recs[0].Name;
        } else if (objType == 'Lead') {
            List<Lead> recs = [SELECT Name FROM Lead WHERE Id = :whatId LIMIT 1];
            return recs.isEmpty() ? '' : recs[0].Name;
        } else if (objType == 'Case') {
            List<Case> recs = [SELECT Subject FROM Case WHERE Id = :whatId LIMIT 1];
            return recs.isEmpty() ? '' : recs[0].Subject;
        }

        return '';
    }
}
