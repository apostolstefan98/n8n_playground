public class OrderLineItemTriggerHandler {
    
    public static void handleAfterInsert(List<Order_Line_Item__c> newOrderLineItems) {
        // Only process when order is completed
        Set<Id> orderIds = new Set<Id>();
        for (Order_Line_Item__c oli : newOrderLineItems) {
            orderIds.add(oli.Order__c);
        }
        
        Map<Id, Order__c> ordersMap = new Map<Id, Order__c>([
            SELECT Id, Status__c 
            FROM Order__c 
            WHERE Id IN :orderIds AND Status__c = 'Completed'
        ]);
        
        List<Order_Line_Item__c> completedOrderLineItems = new List<Order_Line_Item__c>();
        for (Order_Line_Item__c oli : newOrderLineItems) {
            if (ordersMap.containsKey(oli.Order__c)) {
                completedOrderLineItems.add(oli);
            }
        }
        
        if (!completedOrderLineItems.isEmpty()) {
            processRecipeBasedInventoryDepletion(completedOrderLineItems);
            updateDailySalesSummary(completedOrderLineItems);
        }
    }
    
    private static void processRecipeBasedInventoryDepletion(List<Order_Line_Item__c> orderLineItems) {
        // Get order line items with product and recipe information
        List<Order_Line_Item__c> itemsWithRecipes = [
            SELECT Id, Product__c, Product__r.Active_Recipe__c, Quantity__c, Order__c, Order__r.Order_Date__c
            FROM Order_Line_Item__c 
            WHERE Id IN :orderLineItems AND Product__r.Active_Recipe__c != null
        ];
        
        if (itemsWithRecipes.isEmpty()) {
            return;
        }
        
        Set<Id> recipeIds = new Set<Id>();
        for (Order_Line_Item__c oli : itemsWithRecipes) {
            recipeIds.add(oli.Product__r.Active_Recipe__c);
        }
        
        // Get recipe items for all recipes
        Map<Id, List<Recipe_Item__c>> recipeItemsMap = new Map<Id, List<Recipe_Item__c>>();
        for (Recipe_Item__c ri : [
            SELECT Id, Recipe__c, Ingredient__c, Quantity__c, Unit_of_Measure__c, Cost__c
            FROM Recipe_Item__c 
            WHERE Recipe__c IN :recipeIds
        ]) {
            if (!recipeItemsMap.containsKey(ri.Recipe__c)) {
                recipeItemsMap.put(ri.Recipe__c, new List<Recipe_Item__c>());
            }
            recipeItemsMap.get(ri.Recipe__c).add(ri);
        }
        
        // Create inventory transactions for recipe consumption
        List<Inventory_Transaction__c> transactionsToCreate = new List<Inventory_Transaction__c>();
        
        for (Order_Line_Item__c oli : itemsWithRecipes) {
            Id recipeId = oli.Product__r.Active_Recipe__c;
            if (recipeItemsMap.containsKey(recipeId)) {
                for (Recipe_Item__c recipeItem : recipeItemsMap.get(recipeId)) {
                    Decimal consumedQuantity = recipeItem.Quantity__c * oli.Quantity__c;
                    
                    Inventory_Transaction__c invTransaction = new Inventory_Transaction__c(
                        Transaction_Type__c = 'Production',
                        Product__c = recipeItem.Ingredient__c,
                        Quantity__c = -consumedQuantity, // Negative for consumption
                        Unit_Cost__c = recipeItem.Cost__c,
                        Transaction_Date__c = DateTime.now(),
                        Order_Line_Item__c = oli.Id,
                        Source_Product__c = oli.Product__c,
                        Notes__c = 'Auto-created from recipe consumption for order line item'
                    );
                    transactionsToCreate.add(invTransaction);
                }
            }
        }
        
        if (!transactionsToCreate.isEmpty()) {
            insert transactionsToCreate;
        }
    }
    
    private static void updateDailySalesSummary(List<Order_Line_Item__c> orderLineItems) {
        // Get order line items with order date
        List<Order_Line_Item__c> itemsWithOrderData = [
            SELECT Id, Product__c, Quantity__c, Unit_Price__c, Line_Total__c, Order__r.Order_Date__c
            FROM Order_Line_Item__c 
            WHERE Id IN :orderLineItems
        ];
        
        // Group by product and date
        Map<String, Daily_Sales_Summary__c> summaryMap = new Map<String, Daily_Sales_Summary__c>();
        
        for (Order_Line_Item__c oli : itemsWithOrderData) {
            String key = oli.Product__c + '_' + oli.Order__r.Order_Date__c;
            
            if (!summaryMap.containsKey(key)) {
                summaryMap.put(key, new Daily_Sales_Summary__c(
                    Product__c = oli.Product__c,
                    Date__c = oli.Order__r.Order_Date__c,
                    Quantity_Sold__c = 0,
                    Total_Revenue__c = 0
                ));
            }
            
            Daily_Sales_Summary__c summary = summaryMap.get(key);
            summary.Quantity_Sold__c += oli.Quantity__c;
            summary.Total_Revenue__c += oli.Line_Total__c;
        }
        
        // Check for existing summaries and update or create new ones
        List<Daily_Sales_Summary__c> existingSummaries = [
            SELECT Id, Product__c, Date__c, Quantity_Sold__c, Total_Revenue__c
            FROM Daily_Sales_Summary__c 
            WHERE Product__c IN :getProductIds(itemsWithOrderData) 
            AND Date__c IN :getOrderDates(itemsWithOrderData)
        ];
        
        Map<String, Daily_Sales_Summary__c> existingSummaryMap = new Map<String, Daily_Sales_Summary__c>();
        for (Daily_Sales_Summary__c existing : existingSummaries) {
            String key = existing.Product__c + '_' + existing.Date__c;
            existingSummaryMap.put(key, existing);
        }
        
        List<Daily_Sales_Summary__c> summariesToUpsert = new List<Daily_Sales_Summary__c>();
        
        for (String key : summaryMap.keySet()) {
            if (existingSummaryMap.containsKey(key)) {
                Daily_Sales_Summary__c existing = existingSummaryMap.get(key);
                Daily_Sales_Summary__c newData = summaryMap.get(key);
                existing.Quantity_Sold__c += newData.Quantity_Sold__c;
                existing.Total_Revenue__c += newData.Total_Revenue__c;
                summariesToUpsert.add(existing);
            } else {
                summariesToUpsert.add(summaryMap.get(key));
            }
        }
        
        if (!summariesToUpsert.isEmpty()) {
            upsert summariesToUpsert;
        }
    }
    
    private static Set<Id> getProductIds(List<Order_Line_Item__c> items) {
        Set<Id> productIds = new Set<Id>();
        for (Order_Line_Item__c item : items) {
            productIds.add(item.Product__c);
        }
        return productIds;
    }
    
    private static Set<Date> getOrderDates(List<Order_Line_Item__c> items) {
        Set<Date> dates = new Set<Date>();
        for (Order_Line_Item__c item : items) {
            dates.add(item.Order__r.Order_Date__c);
        }
        return dates;
    }
}