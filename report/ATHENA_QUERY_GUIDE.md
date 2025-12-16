# Athena Query Guide

## Access Athena

1. Go to AWS Console → **Athena**
2. Select workgroup: **shopease-analytics**
3. Database: **shopease_catalog**

## Available Tables

Your Glue crawlers created these tables:

### Bronze Layer (Raw CSV)
- `bronze_customers`
- `bronze_products`
- `bronze_stores`
- `bronze_inventory`
- `bronze_sales_managers`
- `bronze_transactions` (sale_transactions)

### Silver Layer (Cleaned CSV)
- `silver_customers_cleaned`
- `silver_products_cleaned`
- `silver_transactions_cleaned`

### Gold Layer (Parquet - Analytics Ready)
- `gold_daily_sales_summary`
- `gold_product_performance`
- `gold_customer_analytics`

## Sample Queries

### 1. Top 10 Customers by Spending
```sql
SELECT 
    customer_name,
    total_spent,
    total_purchases,
    avg_order_value
FROM shopease_catalog.gold_customer_analytics
ORDER BY total_spent DESC
LIMIT 10;
```

### 2. Daily Sales Trend
```sql
SELECT 
    sales_date,
    total_revenue,
    total_transactions,
    unique_customers
FROM shopease_catalog.gold_daily_sales_summary
ORDER BY sales_date DESC
LIMIT 30;
```

### 3. Top Selling Products
```sql
SELECT 
    product_name,
    category,
    total_revenue,
    total_quantity_sold,
    total_orders
FROM shopease_catalog.gold_product_performance
ORDER BY total_revenue DESC
LIMIT 10;
```

### 4. Sales by Store (from Bronze layer)
```sql
SELECT 
    s.store_name,
    COUNT(*) as total_transactions,
    SUM(t.quantity * t.unit_price) as total_revenue
FROM shopease_catalog.bronze_transactions t
JOIN shopease_catalog.bronze_stores s ON t.store_id = s.store_id
GROUP BY s.store_name
ORDER BY total_revenue DESC;
```

### 5. Monthly Revenue Trend
```sql
SELECT 
    DATE_TRUNC('month', sales_date) as month,
    SUM(total_revenue) as monthly_revenue,
    SUM(total_transactions) as monthly_transactions
FROM shopease_catalog.gold_daily_sales_summary
GROUP BY DATE_TRUNC('month', sales_date)
ORDER BY month DESC;
```

## Query Costs

- **Gold layer (Parquet)**: ~$0.000025 per query (0.0025 cents)
- **Bronze/Silver (CSV)**: ~$0.00025 per query (0.025 cents)

**Tip**: Always query Gold layer for best performance and lowest cost!

## Your Complete Data Pipeline

```
PostgreSQL (1M+ records)
    ↓
Airflow: medallion_etl_pipeline
    ↓
S3: shopease-stg/
    ├── bronze/ (raw CSV)
    ├── silver/ (cleaned CSV)
    └── gold/ (parquet analytics)
    ↓
Glue Crawlers (catalog tables)
    ↓
Athena: shopease_catalog
    └── Query with SQL!
```

## Next Steps

1. Run queries in Athena console
2. Create visualizations in QuickSight (optional)
3. Schedule `medallion_etl_pipeline` to run daily
4. Add more transformations to Gold layer as needed

Enjoy your data lake! 🚀
