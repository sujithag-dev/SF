public with sharing class MFG_Utility {
   
     
 public static void safeAssign(SObject target, String fieldName, Object value) {
    try {
        if (value == null) return;

        Map<String, Schema.SObjectField> fieldMap = target.getSObjectType().getDescribe().fields.getMap();
        System.debug('fieldMap' + fieldMap );
        if (!fieldMap.containsKey(fieldName)) {
            System.debug('Field not found: ' + fieldName);
            return;
        }

        Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
        System.debug('fieldDesc' + fieldDesc );
        Schema.DisplayType fieldType = fieldDesc.getType();
        System.debug('fieldType' + fieldType);
        
        Object finalValue = null;
        Boolean shouldAssign = false;

        switch on fieldType {
            when String, TextArea, Email, Phone, Url, Picklist {
                String strVal = String.valueOf(value).trim();
                if (String.isNotBlank(strVal)) {
                    finalValue = strVal;
                    shouldAssign = true;
                }
            }

            when Date {
                if (value instanceof Date) {
                    finalValue = value;
                    shouldAssign = true;
                } else if (value instanceof String && String.isNotBlank((String)value)) {
                    finalValue = tryParseDate((String)value);
                    shouldAssign = finalValue != null;
                }
            }

            when Datetime {
                if (value instanceof Datetime) {
                    finalValue = value;
                    shouldAssign = true;
                } else if (value instanceof String && String.isNotBlank((String)value)) {
                    finalValue = tryParseDatetime((String)value);
                    shouldAssign = finalValue != null;
                }
            }

            when Boolean {
                if (value instanceof Boolean) {
                    finalValue = value;
                    shouldAssign = true;
                } else if (value instanceof String) {
                    String boolStr = ((String)value).toLowerCase().trim();
                    if (boolStr == 'true' || boolStr == '1' || boolStr == 'yes') {
                        finalValue = true;
                        shouldAssign = true;
                    } else if (boolStr == 'false' || boolStr == '0' || boolStr == 'no') {
                        finalValue = false;
                        shouldAssign = true;
                    }
                }
            }

            when Currency, Double, Percent, Integer {
                if (value instanceof Decimal || value instanceof Integer || value instanceof Double) {
                    finalValue = value;
                    shouldAssign = true;
                } else if (value instanceof String && String.isNotBlank((String)value)) {
                    try {
                        finalValue = Decimal.valueOf(((String)value).replaceAll('[^0-9.-]', ''));
                        shouldAssign = true;
                    } catch (Exception ex) {
                        System.debug('Invalid number: ' + value);
                    }
                }
            }

            when Reference, Id {
                if (value instanceof String) {
                    try {
                        finalValue = (Id)value;
                        shouldAssign = true;
                    } catch (Exception ex) {
                        System.debug('Invalid ID: ' + value);
                    }
                } else if (value instanceof Id) {
                    finalValue = value;
                    shouldAssign = true;
                }
            }

            when else {
                finalValue = value;
                shouldAssign = true;
            }
        }

        if (shouldAssign) {
            target.put(fieldName, finalValue);
        }
    } catch (Exception e) {
        System.debug('Error in safeAssign: ' + e.getMessage());
    }
}

public static Date tryParseDate(String dateStr) {
    try {
        return Date.valueOf(dateStr);
    } catch (Exception ex) {
        System.debug('Unable to parse date: ' + dateStr);
        return null;
    }
}

public static Datetime tryParseDatetime(String datetimeStr) {
    try {
        return Datetime.valueOf(datetimeStr);
    } catch (Exception ex) {
        try {
            return Datetime.valueOfGmt(datetimeStr.replace('T', ' ').replace('Z', ''));
        } catch (Exception ex2) {
            return null;
        }
    }
}
}