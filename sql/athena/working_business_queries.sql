-- WORKING BUSINESS IMPACT QUERIES
-- Executive Dashboard for ShopEase Business Performance

-- ==============================================
-- 1. EXECUTIVE SUMMARY - KEY BUSINESS METRICS (Using Gold Layer)
-- ==============================================

-- Total Revenue and Key Metrics
SELECT 
    'Total Revenue' as metric,
    CONCAT('$', FORMAT_NUMBER(SUM(total_revenue), 2)) as value,
    'All Time' as period
FROM shopease_catalog.daily_sales_summary

UNION ALL

SELECT 
    'Total Transactions' as metric,
    FORMAT_NUMBER(SUM(total_transactions), 0) as value,
    'All Time' as period
FROM shopease_catalog.daily_sales_summary

UNION ALL

SELECT 
    'Average Daily Revenue' as metric,
    CONCAT('$', FORMAT_NUMBER(AVG(total_revenue), 2)) as value,
    'Daily Average' as period
FROM shopease_catalog.daily_sales_summary;

-- ==============================================
-- 2. DAILY SALES PERFORMANCE (Gold Layer - Best Performance)
-- ==============================================
SELECT 
    sales_date,
    total_transactions,
    total_revenue,
    avg_transaction_value,
    unique_customers
FROM shopease_catalog.daily_sales_summary
ORDER BY sales_date DESC
LIMIT 30;

-- ==============================================
-- 3. TOP PERFORMING PRODUCTS (Gold Layer)
-- ==============================================
SELECT 
    product_name,
    category,
    total_revenue,
    total_quantity_sold,
    total_orders,
    avg_order_value
FROM shopease_catalog.product_performance
ORDER BY total_revenue DESC
LIMIT 15;

-- ==============================================
-- 4. CUSTOMER SEGMENTATION (Raw Tables)
-- ==============================================
WITH customer_metrics AS (
    SELECT 
        c.customer_name,
        c.city,
        c.state,
        COUNT(*) as total_orders,
        SUM(t.quantity * t.unit_price) as total_spent,
        AVG(t.quantity * t.unit_price) as avg_order_value
    FROM shopease_catalog.customers c
    JOIN shopease_catalog.transactions t ON c.customer_id = t.customer_id
    GROUP BY c.customer_name, c.city, c.state
)
SELECT 
    CASE 
        WHEN total_spent >= 2000 THEN 'VIP (>$2000)'
        WHEN total_spent >= 1000 THEN 'High Value ($1000-$2000)'
        WHEN total_spent >= 500 THEN 'Medium Value ($500-$1000)'
        ELSE 'Low Value (<$500)'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_customer_value,
    SUM(total_spent) as segment_total_revenue
FROM customer_metrics
GROUP BY 
    CASE 
        WHEN total_spent >= 2000 THEN 'VIP (>$2000)'
        WHEN total_spent >= 1000 THEN 'High Value ($1000-$2000)'
        WHEN total_spent >= 500 THEN 'Medium Value ($500-$1000)'
        ELSE 'Low Value (<$500)'
    END
ORDER BY segment_total_revenue DESC;

-- ==============================================
-- 5. GEOGRAPHIC PERFORMANCE (Raw Tables)
-- ==============================================
SELECT 
    c.state,
    COUNT(DISTINCT c.customer_id) as total_customers,
    SUM(t.quantity * t.unit_price) as total_revenue,
    AVG(t.quantity * t.unit_price) as avg_order_value,
    COUNT(*) as total_orders,
    ROUND(SUM(t.quantity * t.unit_price) / COUNT(DISTINCT c.customer_id), 2) as revenue_per_customer
FROM shopease_catalog.customers c
JOIN shopease_catalog.transactions t ON c.customer_id = t.customer_id
GROUP BY c.state
ORDER BY total_revenue DESC;

-- ==============================================
-- 6. PAYMENT METHOD ANALYSIS
-- ==============================================
SELECT 
    payment_method,
    COUNT(*) as transaction_count,
    SUM(quantity * unit_price) as total_revenue,
    AVG(quantity * unit_price) as avg_transaction_value,
    ROUND(SUM(quantity * unit_price) * 100.0 / SUM(SUM(quantity * unit_price)) OVER (), 2) as revenue_percentage
FROM shopease_catalog.transactions
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- ==============================================
-- 7. SALES CHANNEL PERFORMANCE
-- ==============================================
SELECT 
    sales_channel,
    COUNT(*) as total_transactions,
    SUM(quantity * unit_price) as channel_revenue,
    AVG(quantity * unit_price) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM shopease_catalog.transactions
GROUP BY sales_channel
ORDER BY channel_revenue DESC;

-- ==============================================
-- 8. STORE PERFORMANCE
-- ==============================================
SELECT 
    s.store_name,
    COUNT(*) as total_transactions,
    SUM(t.quantity * t.unit_price) as total_revenue,
    COUNT(DISTINCT t.customer_id) as unique_customers,
    AVG(t.quantity * t.unit_price) as avg_transaction_value
FROM shopease_catalog.transactions t
JOIN shopease_catalog.stores s ON t.store_id = s.store_id
GROUP BY s.store_name
ORDER BY total_revenue DESC;