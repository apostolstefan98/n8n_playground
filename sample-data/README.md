# Coffee Shop Sample Data

This directory contains CSV files with sample data for the coffee shop Salesforce data model.

## Files Created

1. **Account.csv** - 7 vendor records (Coffee, Pastry, Dairy, Packaging suppliers)
2. **Product2.csv** - 13 product records (Coffee beans, beverages, pastries, raw materials, packaging)
3. **Batch__c.csv** - 9 batch records with production dates and quantities
4. **Daily_Sales_Summary__c.csv** - 20 daily sales records across different products and weather conditions
5. **Inventory_Transaction__c.csv** - 20 inventory movement records (receipts, sales, production, waste)
6. **Purchase_Order__c.csv** - 7 purchase order records in various statuses
7. **Purchase_Order_Line__c.csv** - 14 purchase order line items
8. **Recipe__c.csv** - 7 recipe records for beverages and food items
9. **Recipe_Item__c.csv** - 20 recipe ingredient records showing recipe compositions
10. **Stock_Alert__c.csv** - 7 stock alert records for various inventory conditions

## Upload Process Using Salesforce CLI

### Prerequisites
1. Ensure you have the Salesforce CLI installed: `sf --version`
2. Authenticate to your org: `sf org login web`
3. Verify your org connection: `sf org display`

### Step 1: Create Custom Objects First
Before uploading data, ensure all custom objects are deployed:
```bash
sf project deploy start --source-dir force-app/main/default/objects
```

### Step 2: Upload Data in Dependency Order

**Upload in this specific order to respect lookup relationships:**

```bash
# 1. Standard Objects (Account, Product2)
sf data import tree --plan sample-data/Account.csv --target-org your-org-alias
sf data import tree --plan sample-data/Product2.csv --target-org your-org-alias

# 2. Independent Custom Objects
sf data import tree --plan sample-data/Batch__c.csv --target-org your-org-alias
sf data import tree --plan sample-data/Recipe__c.csv --target-org your-org-alias
sf data import tree --plan sample-data/Purchase_Order__c.csv --target-org your-org-alias

# 3. Dependent Objects
sf data import tree --plan sample-data/Recipe_Item__c.csv --target-org your-org-alias
sf data import tree --plan sample-data/Purchase_Order_Line__c.csv --target-org your-org-alias
sf data import tree --plan sample-data/Inventory_Transaction__c.csv --target-org your-org-alias
sf data import tree --plan sample-data/Stock_Alert__c.csv --target-org your-org-alias
sf data import tree --plan sample-data/Daily_Sales_Summary__c.csv --target-org your-org-alias
```

### Alternative: Data Import Wizard
For a GUI approach:
1. Setup → Data Import Wizard
2. Upload each CSV file manually
3. Map fields appropriately
4. Follow the same dependency order

### Step 3: Verify Data Upload
```bash
# Check record counts
sf data query --query "SELECT COUNT() FROM Account WHERE Type__c != null" --target-org your-org-alias
sf data query --query "SELECT COUNT() FROM Product2" --target-org your-org-alias
sf data query --query "SELECT COUNT() FROM Batch__c" --target-org your-org-alias
```

## Notes
- Some lookup fields reference External IDs (like ProductCode) for easier CSV relationships
- Ensure all picklist values exist in your org before import
- Auto-number fields will be assigned by Salesforce, not from CSV
- DateTime fields use ISO 8601 format (e.g., "2024-08-13T08:00:00Z")

## Troubleshooting
- **Lookup failures**: Verify parent records exist and External IDs match
- **Picklist value errors**: Add missing picklist values in Setup
- **Required field errors**: Check that all required fields have values