public class BMVLeadAIParser {

    // Inner class to hold parsed values
    public class AIResult {
        @InvocableVariable(label='AI Score' required=false)
        public Decimal aiScore;
        
        @InvocableVariable(label='AI Tier' required=false)
        public String aiTier;
        
        @InvocableVariable(label='AI Summary' required=false)
        public String aiSummary;
        
        @InvocableVariable(label='AI Action' required=false)
        public String aiAction;
        
        @InvocableVariable(label='AI Reason' required=false)
        public String aiReason;
    }

    // Input class
    public class AIRequest {
        @InvocableVariable(label='Raw Response' required=true)
        public String rawResponse;
    }

    // Main invocable method called from Flow
    @InvocableMethod(label='Parse BMV AI Response' 
                     description='Parses Prompt Builder response into fields')
    public static List<AIResult> parseResponse(
        List<AIRequest> requests
    ) {
        List<AIResult> results = new List<AIResult>();
        
        for(AIRequest req : requests) {
            AIResult result = new AIResult();
            String response = req.rawResponse;
            
            if(String.isBlank(response)) {
                result.aiScore   = 0;
                result.aiTier    = 'Not Scored';
                result.aiSummary = 'No response received';
                result.aiAction  = 'Review manually';
                result.aiReason  = 'N/A';
                results.add(result);
                continue;
            }

            // Extract SCORE
            result.aiScore = extractScore(response);
            
            // Extract TIER
            result.aiTier = extractValue(
                response, 'TIER:', 
                new List<String>{'SUMMARY:', 'ACTION:', 'REASON:'}
            );
            
            // Extract SUMMARY
            result.aiSummary = extractValue(
                response, 'SUMMARY:', 
                new List<String>{'ACTION:', 'REASON:'}
            );
            
            // Extract ACTION
            result.aiAction = extractValue(
                response, 'ACTION:', 
                new List<String>{'REASON:'}
            );
            
            // Extract REASON
            result.aiReason = extractValueToEnd(
                response, 'REASON:'
            );
            
            // Default values if parsing failed
            if(result.aiTier == null || result.aiTier == '') {
                result.aiTier = 'Not Scored';
            }
            if(result.aiSummary == null || result.aiSummary == '') {
                result.aiSummary = response;
            }
            if(result.aiAction == null || result.aiAction == '') {
                result.aiAction = 'Review manually';
            }
            if(result.aiReason == null || result.aiReason == '') {
                result.aiReason = 'N/A';
            }
            
            results.add(result);
        }
        
        return results;
    }

    // Extract numeric score
    private static Decimal extractScore(String response) {
        try {
            Integer scoreIdx = response.indexOf('SCORE:');
            if(scoreIdx == -1) return 0;
            
            // Get text after SCORE:
            String afterScore = response.substring(
                scoreIdx + 6
            ).trim();
            
            // Extract digits
            String digits = '';
            for(Integer i = 0; i < afterScore.length(); i++) {
                String c = afterScore.substring(i, i+1);
                if(c.isNumeric()) {
                    digits += c;
                } else if(digits.length() > 0) {
                    break;
                }
            }
            
            if(String.isNotBlank(digits)) {
                return Decimal.valueOf(digits);
            }
            return 0;
        } catch(Exception e) {
            return 0;
        }
    }

    // Extract value between keyword and next keyword
    private static String extractValue(
        String response, 
        String keyword,
        List<String> nextKeywords
    ) {
        try {
            Integer keyIdx = response.indexOf(keyword);
            if(keyIdx == -1) return null;
            
            // Start after keyword
            Integer startIdx = keyIdx + keyword.length();
            String afterKey = response.substring(startIdx).trim();
            
            // Find earliest next keyword
            Integer endIdx = afterKey.length();
            for(String nextKey : nextKeywords) {
                Integer nextIdx = afterKey.indexOf(nextKey);
                if(nextIdx != -1 && nextIdx < endIdx) {
                    endIdx = nextIdx;
                }
            }
            
            return afterKey.substring(0, endIdx).trim();
        } catch(Exception e) {
            return null;
        }
    }

    // Extract value from keyword to end of string
    private static String extractValueToEnd(
        String response, 
        String keyword
    ) {
        try {
            Integer keyIdx = response.indexOf(keyword);
            if(keyIdx == -1) return 'N/A';
            
            String value = response.substring(
                keyIdx + keyword.length()
            ).trim();
            
            return String.isBlank(value) ? 'N/A' : value;
        } catch(Exception e) {
            return 'N/A';
        }
    }
}