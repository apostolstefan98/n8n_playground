public with sharing class EmailMessageTriggerHandler {
    public EmailMessageTriggerHandler() {}

    public void handleAfterInsert(List<EmailMessage> newEmailList) {
        List<Id> emailIdsToProcessList = new List<Id>();

        for (EmailMessage em : newEmailList) {
            if (em.ParentId != null && em.ParentId.getSObjectType() == Case.SObjectType) {
                emailIdsToProcessList.add(em.Id);
            }
        }

        for (Id emailId : emailIdsToProcessList) {
            System.enqueueJob(new N8nCaseEmailQueuable(emailId));
        }
    }
}