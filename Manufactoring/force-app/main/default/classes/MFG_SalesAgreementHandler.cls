/**
* @File Name : MFG_SalesAgreementHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 24, 2025 |   | Initial Version
**/

public class MFG_SalesAgreementHandler {

    @InvocableMethod(label='Create Sales Agreement Automatically')
    public static List<SalesAgreementResult> createSalesAgreement(List<SalesAgreementInput> inputList) {

        List<SalesAgreementResult> results = new List<SalesAgreementResult>();

        try {

            Set<Id> inputIds = new Set<Id>();
            Map<Id, SalesAgreementInput> inputMap = new Map<Id, SalesAgreementInput>();

            for (SalesAgreementInput inp : inputList) {
                inputIds.add(inp.recordId);
                inputMap.put(inp.recordId, inp);
            }

            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [SELECT Id, Name, AccountId, Pricebook2Id,mfg_Synced_Order__c, mfg_Initiate_Sales_Agreement__c  FROM Opportunity WHERE Id IN :inputIds]
            );
			
            Map<Id, Account> accMap = new Map<Id, Account>(
                [ SELECT Id, Name,mfg_Initiate_Sales_Agreement__c FROM Account WHERE Id IN :inputIds ]);


            for (Id recId : inputIds) {

                SalesAgreementInput userInput = inputMap.get(recId);
                mfg_Sales_Agreement__c salesAgreement =  new mfg_Sales_Agreement__c();
               
                if (oppMap.containsKey(recId)) {
                    salesAgreement = createFromOpportunity(oppMap.get(recId), userInput);
                    System.debug('SalesAgreement Created From Opportunity: ' + salesAgreement);
                } else if (accMap.containsKey(recId)) {
                    salesAgreement = createFromAccount(accMap.get(recId), userInput);
                    System.debug('SalesAgreement Created From Account: ' + salesAgreement);
                } else {
                    continue;
                }

                SalesAgreementResult res = new SalesAgreementResult();
                res.salesAgreementId = salesAgreement.Id;
                res.salesAgreementName = salesAgreement.Name;
                
                results.add(res);
                System.debug('SalesAgreementResult Sucess Result ' + results);
            }
        }
        catch (Exception ex) {
            mfg_Log__c err = MFG_Logs.newErrorInstance();
            err.mfg_Error_Message__c = ex.getMessage() + ' (Line ' + ex.getLineNumber() + ')';
            err.mfg_Source_Component__c = 'MFG_SalesAgreementHandler.cls';
            err.mfg_Logged_By_Automation__c = 'Apex Class';
            err.mfg_Status__c = 'Failure';
            MFG_Logs.save(err);
            
            
            SalesAgreementResult res = new SalesAgreementResult();
            res.errorMessage ='Error creating Sales Agreement: ' + ex.getMessage();
            results.add(res);
            
            System.debug('Error creating Sales Agreement: ' + ex.getMessage());
            
        }

        return results;
    }


    public class SalesAgreementInput {
        @InvocableVariable(required=true)
        public Id recordId;

        @InvocableVariable(required=true)
        public String scheduleFrequency;

        @InvocableVariable(required=true)
        public Date activationDate;

        @InvocableVariable(required=true)
        public Integer scheduleCount;
    }

    public class SalesAgreementResult {
        @InvocableVariable
        public Id salesAgreementId;
        
        @InvocableVariable
        public String salesAgreementName;
        
        @InvocableVariable
        public String errorMessage;
        
        
    }


    private static mfg_Sales_Agreement__c  createFromOpportunity(Opportunity opp, SalesAgreementInput inp) {

        if (!opp.mfg_Initiate_Sales_Agreement__c || opp.mfg_Synced_Order__c == null) {
            return null;
        }

        mfg_Sales_Agreement__c sa = new mfg_Sales_Agreement__c(
            Name = opp.Name + ' - Sales Agreement',
            mfg_Account__c = opp.AccountId,
            mfg_Price_Book__c = opp.Pricebook2Id,
            mfg_Order__c = opp.mfg_Synced_Order__c,
            mfg_Opportunity__c = opp.Id,
            mfg_Status__c = 'Draft',
            mfg_Schedule_Frequency__c = inp.scheduleFrequency,
            mfg_Activation_Date__c = inp.activationDate,
            mfg_Schedule_Count__c = inp.scheduleCount
        );
        
        if(sa != null){
          insert sa;
        }

        List<OrderItem> orderItems = [
            SELECT Id, Product2Id, UnitPrice, ListPrice, Quantity FROM OrderItem  WHERE OrderId = :opp.mfg_Synced_Order__c
        ];

        List<mfg_Agreement_Product__c> apList = new List<mfg_Agreement_Product__c>();

        for (OrderItem item : orderItems) {
            apList.add(
                new mfg_Agreement_Product__c(
                    mfg_Sales_Agreement__c = sa.Id,
                    mfg_Product__c = item.Product2Id,
                    mfg_Sales_Price__c = item.UnitPrice,
                    mfg_List_Price__c = item.ListPrice,
                    mfg_Total_Quantity__c = item.Quantity
                )
            );
        }

        if (!apList.isEmpty()) {
            insert apList;
            generateSchedulesForAgreementProduct(apList);
        }

        return sa;
    }


    private static mfg_Sales_Agreement__c createFromAccount(Account acc, SalesAgreementInput inp) {
        
         if (!acc.mfg_Initiate_Sales_Agreement__c) {
            return null;
         }

        mfg_Sales_Agreement__c sa = new mfg_Sales_Agreement__c(
            Name = acc.Name + ' - Sales Agreement',
            mfg_Account__c = acc.Id,
            mfg_Status__c = 'Draft',
            mfg_Schedule_Frequency__c = inp.scheduleFrequency,
            mfg_Activation_Date__c = inp.activationDate,
            mfg_Schedule_Count__c = inp.scheduleCount
        );
        
        if(sa != null){
           insert sa;
        }    
        return sa;
    }


    public static void generateSchedulesForAgreementProduct(List<mfg_Agreement_Product__c> apList) {

        if (apList == null || apList.isEmpty()) {
            return;
        }   


        Set<Id> saIds = new Set<Id>();
        Set<Id> apIds = new Set<Id>();

        for (mfg_Agreement_Product__c ap : apList) {
            if (ap.mfg_Sales_Agreement__c != null) saIds.add(ap.mfg_Sales_Agreement__c);
            if (ap.Id != null) apIds.add(ap.Id);
        }

        if (saIds.isEmpty()){ 
            return;}


        Map<Id, mfg_Sales_Agreement__c> saMap = new Map<Id, mfg_Sales_Agreement__c>(
            [  SELECT Id, mfg_Schedule_Frequency__c, mfg_Schedule_Count__c, mfg_Activation_Date__c
                FROM mfg_Sales_Agreement__c
                WHERE Id IN :saIds
            ]
        );

        List<mfg_Agreement_Product_Schedule__c> oldSchedules =
            [
                SELECT Id
                FROM mfg_Agreement_Product_Schedule__c
                WHERE mfg_Agreement_Product__c IN :apIds
            ];

        if (!oldSchedules.isEmpty()) {
            delete oldSchedules;
        }

        List<mfg_Agreement_Product_Schedule__c> newSchedules = new List<mfg_Agreement_Product_Schedule__c>();


        for (mfg_Agreement_Product__c ap : apList) {

            mfg_Sales_Agreement__c sa = saMap.get(ap.mfg_Sales_Agreement__c);
            if (sa == null) continue;

            if (sa.mfg_Schedule_Count__c == null || sa.mfg_Schedule_Count__c <= 0) continue;
            if (sa.mfg_Activation_Date__c == null) continue;
            if (ap.mfg_Total_Quantity__c == null || ap.mfg_Total_Quantity__c <= 0) continue;
			
            Integer scheduleCount = Integer.valueOf(sa.mfg_Schedule_Count__c);
            Integer totalQty = Integer.valueOf(ap.mfg_Total_Quantity__c);
            Integer count = scheduleCount;

            Integer baseQty = totalQty / count;
            Integer remainder = Math.mod(totalQty, count);

            Date activation = sa.mfg_Activation_Date__c;
            String freq = sa.mfg_Schedule_Frequency__c;

            for (Integer period = 1; period <= count; period++) {

                Integer qtyThisPeriod = (period <= remainder) ? baseQty + 1 : baseQty;

                Date startDate = getStartDate(freq, activation, period);
                Date endDate = getEndDate(freq, startDate);

                Datetime dt = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
                String periodLabel = dt.format('MMM d, yyyy');

                newSchedules.add(
                    new mfg_Agreement_Product_Schedule__c(
                        mfg_Agreement_Product__c = ap.Id,
                        mfg_Schedule_Start_Date__c = startDate,
                        mfg_Schedule_End_Date__c = endDate,
                        mfg_Planned_Quantity__c = qtyThisPeriod,
                        mfg_Period_Label__c = periodLabel,
                        mfg_Status__c = 'In Progress'
                    )
                );
            }
        }

        if (!newSchedules.isEmpty()) {
            insert newSchedules;
        }
    }

    private static Date getStartDate(String freq, Date activation, Integer period) {
        if (freq == 'Daily') return activation.addDays(period - 1);
        if (freq == 'Weekly') return activation.addDays((period - 1) * 7);
        if (freq == 'Monthly') return activation.addMonths(period - 1);
        if (freq == 'Quarterly') return activation.addMonths((period - 1) * 3);
        if (freq == 'Yearly') return activation.addYears(period - 1);
        return activation;
    }

    private static Date getEndDate(String freq, Date startDate) {
        if (freq == 'Daily') return startDate;
        if (freq == 'Weekly') return startDate.addDays(6);
        if (freq == 'Monthly') return startDate.addMonths(1).addDays(-1);
        if (freq == 'Quarterly') return startDate.addMonths(3).addDays(-1);
        if (freq == 'Yearly') return startDate.addYears(1).addDays(-1);
        return startDate;
    }

}