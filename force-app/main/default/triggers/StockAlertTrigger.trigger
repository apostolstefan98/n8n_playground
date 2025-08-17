trigger StockAlertTrigger on Stock_Alert__c (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        StockAlertTriggerHandler.handleAfterInsert(Trigger.new);
    }
}