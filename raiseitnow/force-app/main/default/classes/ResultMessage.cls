/**
* @description       : ResultMessage Class is used to handle the results of the all the methods.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 13-06-2024
* last modified by   : 
**/

/**
* @description ResultMessage is used to handle the results of the all the methods.
*
*/
public class ResultMessage {
    /**
     * @description :It Store Boolean output. 
     * @param success    : Boolean
     */ 
    @AuraEnabled
    public Boolean success          {get; set;}

    /**
     * @description :It Store output message values. 
     * @param message    : String
     */
    @AuraEnabled
    public String message           {get; set;}

    /**
     * @description :It Store object list output values. 
     * @param payload    : List<Object> 
     */
    @AuraEnabled
    public List<Object> payload     {get; set;}
   
    /**
     * @description :It Store object Map output values.
     * @param payloadMap : Map<String, Object>
     */
    @AuraEnabled
    public Map<String, Object> payloadMap   {get; set;}

    /** 
     * @description : Constructor of ResultMessage 
     * @param r : Boolean
     * @param m : String
     */
    public ResultMessage(Boolean r, String m) {
        payload = new List<Object>();
        payloadMap = new Map<String, Object>();
        success = r;
        message = m;
    }
}