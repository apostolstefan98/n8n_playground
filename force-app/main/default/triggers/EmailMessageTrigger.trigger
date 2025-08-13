trigger EmailMessageTrigger on EmailMessage (before insert,after insert) {
    EmailMessageTriggerHandler handler = new EmailMessageTriggerHandler();

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.handleAfterInsert(Trigger.new);
    }
}