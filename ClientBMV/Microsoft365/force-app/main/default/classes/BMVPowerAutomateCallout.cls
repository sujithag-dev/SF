public class BMVPowerAutomateCallout {

    public class CalloutRequest {
        @InvocableVariable(
            label='Opportunity Id'
            required=true
        )
        public String opportunityId;

        @InvocableVariable(
            label='Opportunity Name'
        )
        public String opportunityName;

        @InvocableVariable(
            label='Stage Name'
        )
        public String stageName;

        @InvocableVariable(
            label='Close Date'
        )
        public String closeDate;

        @InvocableVariable(
            label='Days No Activity'
        )
        public String daysNoActivity;

        @InvocableVariable(
            label='Investor Type'
        )
        public String investorType;

        @InvocableVariable(
            label='AUM Range'
        )
        public String aumRange;

        @InvocableVariable(
            label='Owner Name'
        )
        public String ownerName;

        @InvocableVariable(
            label='Owner Email'
        )
        public String ownerEmail;

        @InvocableVariable(
            label='Risk Level'
        )
        public String riskLevel;

        @InvocableVariable(
            label='Risk Reason'
        )
        public String riskReason;

        @InvocableVariable(
            label='Next Action'
        )
        public String nextAction;

        @InvocableVariable(
            label='Urgency'
        )
        public String urgency;

        @InvocableVariable(
            label='Personal Message'
        )
        public String personalMessage;
    }

    public class CalloutResult {
        @InvocableVariable(
            label='Is Success'
        )
        public Boolean isSuccess;
    }

    @InvocableMethod(
        label='Send Risk Alert to Power Automate'
        description='Sends opportunity risk alert async'
    )
    public static List<CalloutResult> sendAlert(
        List<CalloutRequest> requests
    ) {
        List<CalloutResult> results =
            new List<CalloutResult>();

        for(CalloutRequest req : requests) {
            CalloutResult result =
                new CalloutResult();
            try {
                String body = buildRequestBody(req);

                sendAlertAsync(body);

                result.isSuccess = true;

            } catch(Exception e) {
                result.isSuccess = false;
                System.debug(
                    'Error queuing PA callout: '
                    + e.getMessage()
                );
            }
            results.add(result);
        }
        return results;
    }

    @future(callout=true)
    public static void sendAlertAsync(
        String requestBody
    ) {
        try {
            HttpRequest httpReq =
                new HttpRequest();
            httpReq.setEndpoint(
                'callout:Power_Automate_Risk_Alert' +
                '/powerautomate/automations/direct/' +
                'workflows/' +
                '14a199ead048416fa871014bb9d31b27/' +
                'triggers/manual/paths/invoke' +
                '?api-version=1' +
                '&sp=%2Ftriggers%2Fmanual%2Frun' +
                '&sv=1.0' +
                '&sig=EvTyE9F-r62asDk9Zran7jS4VFZoaXrPAMlMuQN9mg0'
            );
            httpReq.setMethod('POST');
            httpReq.setHeader(
                'Content-Type',
                'application/json'
            );
            httpReq.setBody(requestBody);
            httpReq.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(httpReq);

            System.debug(
                'PA Response: ' +
                res.getStatusCode() +
                ' ' + res.getBody()
            );

        } catch(Exception e) {
            System.debug(
                'PA Async Callout Error: '
                + e.getMessage()
            );
        }
    }

    private static String buildRequestBody(
        CalloutRequest req
    ) {
        Map<String, Object> body =
            new Map<String, Object>();

        body.put('opportunityId',
            req.opportunityId != null ?
            req.opportunityId : '');
        body.put('opportunityName',
            req.opportunityName != null ?
            req.opportunityName : '');
        body.put('stageName',
            req.stageName != null ?
            req.stageName : '');
        body.put('closeDate',
            req.closeDate != null ?
            String.valueOf(req.closeDate) : '');
        body.put('daysNoActivity',
            req.daysNoActivity != null ?
            req.daysNoActivity : '0');
        body.put('investorType',
            req.investorType != null ?
            req.investorType : '');
        body.put('aumRange',
            req.aumRange != null ?
            req.aumRange : '');
        body.put('ownerName',
            req.ownerName != null ?
            req.ownerName : '');
        body.put('ownerEmail',
            req.ownerEmail != null ?
            req.ownerEmail : '');
        body.put('riskLevel',
            req.riskLevel != null ?
            req.riskLevel : '');
        body.put('riskReason',
            req.riskReason != null ?
            req.riskReason : '');
        body.put('nextAction',
            req.nextAction != null ?
            req.nextAction : '');
        body.put('urgency',
            req.urgency != null ?
            req.urgency : '');
        body.put('personalMessage',
            req.personalMessage != null ?
            req.personalMessage : '');
        body.put('sfRecordUrl',
            'https://orgfarm-325dfbb8d0-dev-ed' +
            '.develop.lightning.force.com' +
            '/lightning/r/Opportunity/' +
            (req.opportunityId != null ?
            req.opportunityId : '') + '/view'
        );

        return JSON.serialize(body);
    }
}