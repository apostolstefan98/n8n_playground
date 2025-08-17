trigger StockAlertEventTrigger on Stock_Alert_Event__e (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        StockAlertEventTriggerHandler.handleAfterInsert(Trigger.new);
    }
}