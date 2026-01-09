/**
* @description       : FieldAccessUtil Class is used to safely set field values on SObjects with FLS checks.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description Utility class to safely set field values on SObjects with FLS checks.
 */
public with sharing class FieldAccessUtil {
	/**
     * @description Sets the field value on an SObject only if both createable and updateable.
     * @param record The SObject record.
     * @param fieldName The name of the field to set.
     * @param value The value to assign to the field.
     */
    public static void setIfCreateableAndUpdateable(SObject record, String fieldName, Object value) {
        SObjectField field = record.getSObjectType().getDescribe().fields.getMap().get(fieldName);
        if (field != null) {
            DescribeFieldResult describe = field.getDescribe();
            if (describe.isCreateable() && describe.isUpdateable()) {
                record.put(fieldName, value);
            }
        }
    }

     /**
     * @description Sets multiple field values on an SObject only if the fields
     *              are both createable and updateable according to FLS.
     * @param record The SObject instance to modify.
     * @param fieldValues Map of field API names to values.
     * @return The updated SObject with only accessible fields modified.
     */
    public static SObject setAccessibleFields(SObject record, Map<String, Object> fieldValues) {
    Map<String, SObjectField> fieldMap = record.getSObjectType().getDescribe().fields.getMap();
    for (String fieldName : fieldValues.keySet()) {
        SObjectField field = fieldMap.get(fieldName);
        if (field == null) {
            continue;
        }
        DescribeFieldResult describe = field.getDescribe();
        if (!(describe.isCreateable() && describe.isUpdateable())) {
            continue;
        }
        record.put(fieldName, fieldValues.get(fieldName));
    }
    return record;
}

}