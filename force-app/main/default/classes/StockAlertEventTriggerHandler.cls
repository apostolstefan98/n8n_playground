public class StockAlertEventTriggerHandler {
    
    public static void handleAfterInsert(List<Stock_Alert_Event__e> events) {
        Set<String> alertIds = new Set<String>();
        
        for (Stock_Alert_Event__e event : events) {
            if (String.isNotBlank(event.Alert_Id__c)) {
                alertIds.add(event.Alert_Id__c);
            }
        }
        
        if (!alertIds.isEmpty()) {
            System.enqueueJob(new N8nStockAlertQueueable(alertIds));
        }
    }
}