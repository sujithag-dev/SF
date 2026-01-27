public with sharing class MFG_AssetDetails {
@AuraEnabled(cacheable = true)
  public static List<Asset> assetList(){
    try {
      return [SELECT Id,Name,Account.Name,Product2.Name,AccountId,Product2Id,Status,mfg_Asset_Number__c,ContactId,ProductCode,mfg_Production_Batch_Unit__c,Quantity,InstallDate,PurchaseDate,UsageEndDate FROM Asset ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}