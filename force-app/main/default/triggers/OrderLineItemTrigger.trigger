trigger OrderLineItemTrigger on Order_Line_Item__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        OrderLineItemTriggerHandler.handleAfterInsert(Trigger.new);
    }
}