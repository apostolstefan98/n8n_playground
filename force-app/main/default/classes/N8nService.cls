public with sharing class N8nService {
    public N8nService() {}

    public void sendCaseEmailsToN8n(N8nRequestWrapper requestWrapper) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:n8n/webhook/salesforce-case-email');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(requestWrapper));

        Http http = new Http();
        HttpResponse res = http.send(req);
   }
   
   public static void sendStockAlerts(Map<String, Object> payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:n8n/webhook/salesforce-stock-alert');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new CalloutException('Failed to send stock alert to n8n: ' + res.getBody());
        }
   }


    public class N8nRequestWrapper {
        public String caseId;
        public String accountId;
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