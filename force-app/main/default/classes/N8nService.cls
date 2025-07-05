public with sharing class N8nService {
    public N8nService() {}

    public void sendCaseEmailsToN8n(N8nRequestWrapper requestWrapper) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:n8n/...');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(requestWrapper));

        Http http = new Http();
        HttpResponse res = http.send(req);
   }


    public class N8nRequestWrapper {
        public String caseId;
        public String caseNumber;
        public String description;
        public List<EmailData> emails;
    }

    public class EmailData {
        public String subject;
        public String body;
        public String createdDate;
        public Boolean isFromCustomer;
    }
}