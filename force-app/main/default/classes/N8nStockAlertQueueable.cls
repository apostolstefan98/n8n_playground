public class N8nStockAlertQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<String> alertIds;
    
    public N8nStockAlertQueueable(Set<String> alertIds) {
        this.alertIds = alertIds;
    }
    
    public void execute(QueueableContext context) {
        try {
            List<Stock_Alert__c> alerts = queryAlertDetails();
            if (!alerts.isEmpty()) {
                Map<String, List<Stock_Alert__c>> alertsByVendor = groupAlertsByVendor(alerts);
                sendAlertsToN8n(alertsByVendor);
                updateSlackMessageSent(alerts);
            }
        } catch (Exception e) {
            System.debug('Error in N8nStockAlertQueueable: ' + e.getMessage());
        }
    }
    
    private List<Stock_Alert__c> queryAlertDetails() {
        return [
            SELECT Id, Product__c, Product__r.Name, Product__r.Primary_Vendor__c, Product__r.Primary_Vendor__r.Name,
                   Alert_Type__c, Current_Stock_Level__c, Reorder_Point__c, Days_Until_Stockout__c,
                   Product__r.Reorder_Quantity__c, Product__r.Cost__c, Product__r.Days_Until_Stockout__c
            FROM Stock_Alert__c 
            WHERE Id IN :alertIds
        ];
    }
    
    private Map<String, List<Stock_Alert__c>> groupAlertsByVendor(List<Stock_Alert__c> alerts) {
        Map<String, List<Stock_Alert__c>> alertsByVendor = new Map<String, List<Stock_Alert__c>>();
        
        for (Stock_Alert__c alert : alerts) {
            String vendorId = alert.Product__r.Primary_Vendor__c;
            if (!alertsByVendor.containsKey(vendorId)) {
                alertsByVendor.put(vendorId, new List<Stock_Alert__c>());
            }
            alertsByVendor.get(vendorId).add(alert);
        }
        
        return alertsByVendor;
    }
    
    private void sendAlertsToN8n(Map<String, List<Stock_Alert__c>> alertsByVendor) {
        for (String vendorId : alertsByVendor.keySet()) {
            List<Stock_Alert__c> vendorAlerts = alertsByVendor.get(vendorId);
            
            Map<String, Object> vendorInfo = new Map<String, Object>();
            if (vendorId != null && vendorAlerts[0].Product__r.Primary_Vendor__r != null) {
                vendorInfo.put('id', vendorId);
                vendorInfo.put('name', vendorAlerts[0].Product__r.Primary_Vendor__r.Name);
            } else {
                vendorInfo.put('id', 'NO_VENDOR');
                vendorInfo.put('name', 'No Vendor Assigned');
            }
            
            Map<String, Object> payload = new Map<String, Object>{
                'vendor' => vendorInfo,
                'alerts' => buildAlertPayload(vendorAlerts),
                'timestamp' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
            };
            
            N8nService.sendStockAlerts(payload);
        }
    }
    
    private List<Map<String, Object>> buildAlertPayload(List<Stock_Alert__c> alerts) {
        List<Map<String, Object>> alertPayload = new List<Map<String, Object>>();
        
        for (Stock_Alert__c alert : alerts) {
            alertPayload.add(new Map<String, Object>{
                'alertId' => alert.Id,
                'product' => new Map<String, Object>{
                    'id' => alert.Product__c,
                    'name' => alert.Product__r.Name
                },
                'alertType' => alert.Alert_Type__c,
                'currentStock' => alert.Current_Stock_Level__c,
                'reorderPoint' => alert.Reorder_Point__c,
                'daysUntilStockout' => alert.Product__r.Days_Until_Stockout__c,
                'suggestedOrderQuantity' => alert.Product__r.Reorder_Quantity__c,
                'estimatedCost' => alert.Product__r.Reorder_Quantity__c * alert.Product__r.Cost__c
            });
        }
        
        return alertPayload;
    }
    
    private void updateSlackMessageSent(List<Stock_Alert__c> alerts) {
        for (Stock_Alert__c alert : alerts) {
            alert.Slack_Message_Sent__c = true;
        }
        update alerts;
    }
}