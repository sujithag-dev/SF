public class BMVOpptyRiskParser {

    public class RiskResult {
        @InvocableVariable(label='Risk Level')
        public String riskLevel;

        @InvocableVariable(label='Risk Reason')
        public String riskReason;

        @InvocableVariable(label='Next Action')
        public String nextAction;

        @InvocableVariable(label='Urgency')
        public String urgency;

        @InvocableVariable(label='Personal Message')
        public String personalMessage;
    }

    public class RiskRequest {
        @InvocableVariable(
            label='Raw Response'
            required=true
        )
        public String rawResponse;
    }

    @InvocableMethod(
        label='Parse Opportunity Risk Response'
        description='Parses Agentforce risk analysis response'
    )
    public static List<RiskResult> parseResponse(
        List<RiskRequest> requests
    ) {
        List<RiskResult> results =
            new List<RiskResult>();

        for(RiskRequest req : requests) {
            RiskResult result = new RiskResult();
            String r = req.rawResponse;

            if(String.isBlank(r)) {
                result.riskLevel      = 'Unknown';
                result.riskReason     = 'Could not analyze';
                result.nextAction     = 'Review manually';
                result.urgency        = 'This Week';
                result.personalMessage= 'Please review this opportunity manually.';
                results.add(result);
                continue;
            }

            result.riskLevel = extractValue(
                r, 'RISK_LEVEL:',
                new List<String>{
                    'RISK_REASON:',
                    'NEXT_ACTION:',
                    'URGENCY:',
                    'PERSONAL_MESSAGE:'
                }
            );
            result.riskReason = extractValue(
                r, 'RISK_REASON:',
                new List<String>{
                    'NEXT_ACTION:',
                    'URGENCY:',
                    'PERSONAL_MESSAGE:'
                }
            );
            result.nextAction = extractValue(
                r, 'NEXT_ACTION:',
                new List<String>{
                    'URGENCY:',
                    'PERSONAL_MESSAGE:'
                }
            );
            result.urgency = extractValue(
                r, 'URGENCY:',
                new List<String>{
                    'PERSONAL_MESSAGE:'
                }
            );
            result.personalMessage = extractToEnd(
                r, 'PERSONAL_MESSAGE:'
            );

            if(String.isBlank(result.riskLevel))
                result.riskLevel = 'Medium';
            if(String.isBlank(result.riskReason))
                result.riskReason = 'No recent activity detected';
            if(String.isBlank(result.nextAction))
                result.nextAction = 'Review and contact investor';
            if(String.isBlank(result.urgency))
                result.urgency = 'This Week';
            if(String.isBlank(result.personalMessage))
                result.personalMessage =
                    'Please review this opportunity and take action.';

            results.add(result);
        }
        return results;
    }

    private static String extractValue(
        String response,
        String keyword,
        List<String> nextKeywords
    ) {
        try {
            Integer keyIdx = response.indexOf(keyword);
            if(keyIdx == -1) return '';

            Integer startIdx = keyIdx + keyword.length();
            String afterKey = response
                .substring(startIdx).trim();

            Integer endIdx = afterKey.length();
            for(String nextKey : nextKeywords) {
                Integer nextIdx = afterKey.indexOf(nextKey);
                if(nextIdx != -1 && nextIdx < endIdx) {
                    endIdx = nextIdx;
                }
            }
            return afterKey.substring(0, endIdx).trim();
        } catch(Exception e) {
            return '';
        }
    }

    private static String extractToEnd(
        String response,
        String keyword
    ) {
        try {
            Integer keyIdx = response.indexOf(keyword);
            if(keyIdx == -1) return '';
            return response
                .substring(keyIdx + keyword.length())
                .trim();
        } catch(Exception e) {
            return '';
        }
    }
}