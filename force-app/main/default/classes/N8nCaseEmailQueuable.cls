public class N8nCaseEmailQueuable implements Queueable, Database.AllowsCallouts {
    private Id emailId;

    public N8nCaseEmailQueuable(Id emailId) {
        this.emailId = emailId;
    }

    public void execute(QueueableContext context) {
        N8nService.N8nRequestWrapper payload = buildPayload(emailId);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:n8n/webhook/salesforce-case-email');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('n8n response: ' + res.getBody());
    }

    private N8nService.N8nRequestWrapper buildPayload(Id emailId) {
        EmailMessage em = [SELECT FromAddress, ParentId, Incoming FROM EmailMessage WHERE Id = :emailId LIMIT 1];
        Case caseItem = [SELECT Id, CaseNumber, Description, AccountId FROM Case WHERE Id = :em.ParentId LIMIT 1];

        List<EmailMessage> recentEmails = [SELECT Subject, TextBody, CreatedDate, FromAddress,Incoming FROM EmailMessage WHERE ParentId = :caseItem.Id ORDER BY CreatedDate DESC LIMIT 5];

        N8nService.N8nRequestWrapper wrapper = new N8nService.N8nRequestWrapper();
        wrapper.caseId = caseItem.Id;
        wrapper.accountId = caseItem.AccountId;
        wrapper.caseNumber = caseItem.CaseNumber;
        wrapper.description = caseItem.Description;
        wrapper.emails = new List<N8nService.EmailData>();

        for (EmailMessage msg : recentEmails) {
            N8nService.EmailData emailData = new N8nService.EmailData();
            emailData.subject = msg.Subject;
            emailData.body = msg.TextBody;
            emailData.createdDate = String.valueOf(msg.CreatedDate);
            emailData.isFromCustomer = msg.Incoming;
            wrapper.emails.add(emailData);
        }

        return wrapper;
    }
}