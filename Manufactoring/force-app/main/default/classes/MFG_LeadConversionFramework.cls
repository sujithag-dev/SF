public with sharing class MFG_LeadConversionFramework {

    /**
     * @description Wrapper to hold RecordType info and creation flag.
     */
    public class RTConfig {
        public String developerName;
        public Id recordTypeId;
        public Boolean isCreate;

        public RTConfig(String developerName, Boolean isCreate) {
            this.developerName = developerName;
            this.isCreate = isCreate;
        }
    }

    /**
     * @description Main configuration map for each Lead Record Type.
     * Key = Lead RecordType DeveloperName
     * Value = Object → RTConfig mapping
     */
    public static Map<String, Map<String, RTConfig>> getRecordTypeConfig() {
        Map<String, Map<String, RTConfig>> config = new Map<String, Map<String, RTConfig>>();

        // Dealer Lead configuration
        config.put('mfg_Dealer_Lead_Recordtype', new Map<String, RTConfig>{
            'Account'     => new RTConfig('mfg_Dealer_Account_Recordtype', true),
            'Contact'     => new RTConfig('mfg_Contact_Recordtype', true),
            'Opportunity' => new RTConfig('mfg_Customer_Opportunity_Recordtype', false)
        });

        // Customer Lead configuration
        config.put('mfg_Customer_Lead_Recordtype', new Map<String, RTConfig>{
            'Account'     => new RTConfig('mfg_Customer_Account_Recordtype', true),
            'Contact'     => new RTConfig('mfg_Contact_Recordtype', true),
            'Opportunity' => new RTConfig('mfg_Customer_Opportunity_Recordtype', true)
        });
        System.debug('configuration map' + config);
        populateRecordTypeIds(config);
        return config;
    }

    /**
     * @description Populate all RecordType IDs dynamically for configured objects.
     */
    public static void populateRecordTypeIds(Map<String, Map<String, RTConfig>> config) {
        if (config == null || config.isEmpty()) return;

        Map<String, Schema.SObjectType> allObjects = Schema.getGlobalDescribe();
		System.debug('allObjects' + allObjects);

        for (String leadRT : config.keySet()) {
            for (String objectName : config.get(leadRT).keySet()) {
                RTConfig rt = config.get(leadRT).get(objectName);
                Schema.SObjectType sObjectType = allObjects.get(objectName);

                if (sObjectType == null) {
                    System.debug('Object not found: ' + objectName);
                    continue;
                }

                Map<String, Schema.RecordTypeInfo> rtInfoMap = sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

                if (rtInfoMap.containsKey(rt.developerName)) {
                    rt.recordTypeId = rtInfoMap.get(rt.developerName).getRecordTypeId();
                } else {
                    System.debug('RecordType not found: ' + rt.developerName + ' on ' + objectName);
                }
            }
        }
    }

    /**
     * @description Get RecordTypeId safely by Lead RT and Object name.
     */
    public static Id getRecordTypeId(Map<String, Map<String, RTConfig>> config, String leadRT, String objectName) {
        if (config == null || !config.containsKey(leadRT)) return null;
        Map<String, RTConfig> objMap = config.get(leadRT);
        if (objMap == null || !objMap.containsKey(objectName)) return null;
        return objMap.get(objectName).recordTypeId;
    }

    /**
     * @description Check if record creation is allowed for this object under a given Lead RT.
     */
    public static Boolean isCreateAllowed(Map<String, Map<String, RTConfig>> config, String leadRT, String objectName) {
        if (config == null || !config.containsKey(leadRT)) return false;
        Map<String, RTConfig> objMap = config.get(leadRT);
        if (objMap == null || !objMap.containsKey(objectName)) return false;
        return objMap.get(objectName).isCreate;
    }
}