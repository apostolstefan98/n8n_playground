public class StockAlertTriggerHandler {
    
    public static void handleAfterInsert(List<Stock_Alert__c> newAlerts) {
        publishStockAlertEvents(newAlerts);
    }
    
    private static void publishStockAlertEvents(List<Stock_Alert__c> newAlerts) {
        // Query alerts with related Product and Vendor information
        List<Stock_Alert__c> alertsWithDetails = [
            SELECT Id, Product__c, Product__r.Name, Product__r.Primary_Vendor__c, 
                   Product__r.Primary_Vendor__r.Name, Alert_Type__c, Current_Stock_Level__c
            FROM Stock_Alert__c 
            WHERE Id IN :newAlerts
        ];
        
        List<Stock_Alert_Event__e> events = new List<Stock_Alert_Event__e>();
        
        for (Stock_Alert__c alert : alertsWithDetails) {
            Stock_Alert_Event__e event = new Stock_Alert_Event__e(
                Alert_Id__c = alert.Id,
                Product_Id__c = alert.Product__c,
                Product_Name__c = alert.Product__r.Name,
                Alert_Type__c = alert.Alert_Type__c,
                Current_Stock_Level__c = alert.Current_Stock_Level__c,
                Vendor_Id__c = alert.Product__r.Primary_Vendor__c,
                Vendor_Name__c = alert.Product__r.Primary_Vendor__r?.Name
            );
            events.add(event);
        }
        
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
}