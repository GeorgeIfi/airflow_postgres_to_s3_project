-- QUICK BUSINESS INSIGHTS
-- Fast queries using Gold layer tables for immediate results

-- 1. Revenue Overview (Gold Layer)
SELECT 
    COUNT(*) as total_days_with_sales,
    SUM(total_revenue) as total_revenue_all_time,
    AVG(total_revenue) as avg_daily_revenue,
    MAX(total_revenue) as best_day_revenue,
    MIN(total_revenue) as lowest_day_revenue
FROM shopease_catalog.daily_sales_summary;

-- 2. Top 10 Products by Revenue (Gold Layer)
SELECT 
    product_name,
    category,
    total_revenue,
    total_orders
FROM shopease_catalog.product_performance
ORDER BY total_revenue DESC
LIMIT 10;

-- 3. Recent Sales Trend (Gold Layer)
SELECT 
    sales_date,
    total_revenue,
    total_transactions,
    unique_customers
FROM shopease_catalog.daily_sales_summary
ORDER BY sales_date DESC
LIMIT 14;

-- 4. Category Performance (Gold Layer)
SELECT 
    category,
    COUNT(*) as products_in_category,
    SUM(total_revenue) as category_revenue,
    AVG(total_revenue) as avg_product_revenue
FROM shopease_catalog.product_performance
GROUP BY category
ORDER BY category_revenue DESC;

-- 5. Customer Count by State (Raw Tables)
SELECT 
    state,
    COUNT(*) as customer_count
FROM shopease_catalog.customers
GROUP BY state
ORDER BY customer_count DESC
LIMIT 10;