from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

dag = DAG(
    'medallion_etl_pipeline',
    default_args=default_args,
    description='Bronze, Silver, Gold ETL Pipeline',
    schedule_interval=None,
    catchup=False
)

# BRONZE LAYER - Raw data from PostgreSQL
bronze_layer = BashOperator(
    task_id='bronze_layer_extract',
    bash_command='''
    export PGPASSWORD=${DATA_POSTGRES_PASSWORD}
    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
    
    echo "=== BRONZE LAYER: Raw Data Extraction ==="
    
    # Extract raw data to Bronze layer (CSV format, minimal transformation)
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} -c "\\COPY customers TO '/tmp/bronze_customers.csv' WITH CSV HEADER"
    aws s3 cp /tmp/bronze_customers.csv s3://${S3_BUCKET}/bronze/customers/customers.csv
    
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} -c "\\COPY products TO '/tmp/bronze_products.csv' WITH CSV HEADER"
    aws s3 cp /tmp/bronze_products.csv s3://${S3_BUCKET}/bronze/products/products.csv
    
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} -c "\\COPY stores TO '/tmp/bronze_stores.csv' WITH CSV HEADER"
    aws s3 cp /tmp/bronze_stores.csv s3://${S3_BUCKET}/bronze/stores/stores.csv
    
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} -c "\\COPY inventory TO '/tmp/bronze_inventory.csv' WITH CSV HEADER"
    aws s3 cp /tmp/bronze_inventory.csv s3://${S3_BUCKET}/bronze/inventory/inventory.csv
    
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} -c "\\COPY sales_managers TO '/tmp/bronze_sales_managers.csv' WITH CSV HEADER"
    aws s3 cp /tmp/bronze_sales_managers.csv s3://${S3_BUCKET}/bronze/sales_managers/sales_managers.csv
    
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} -c "\\COPY sale_transactions TO '/tmp/bronze_transactions.csv' WITH CSV HEADER"
    aws s3 cp /tmp/bronze_transactions.csv s3://${S3_BUCKET}/bronze/transactions/sale_transactions.csv
    
    echo "Bronze layer extraction completed"
    ''',
    dag=dag
)

# SILVER LAYER - Cleaned and validated data
silver_layer = BashOperator(
    task_id='silver_layer_transform',
    bash_command='''
    export PGPASSWORD=${DATA_POSTGRES_PASSWORD}
    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
    
    echo "=== SILVER LAYER: Data Cleaning & Validation ==="
    
    # Clean customers data
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} << 'EOF'
\COPY (SELECT DISTINCT customer_id, TRIM(UPPER(customer_name)) as customer_name, LOWER(TRIM(email)) as email, phone, address, city, state, zip_code, created_at, updated_at FROM customers WHERE customer_name IS NOT NULL AND email IS NOT NULL ORDER BY customer_id) TO '/tmp/silver_customers.csv' WITH CSV HEADER
EOF
    aws s3 cp /tmp/silver_customers.csv s3://${S3_BUCKET}/silver/customers/customers_cleaned.csv
    
    # Clean products data
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} << 'EOF'
\COPY (SELECT product_id, TRIM(product_name) as product_name, TRIM(UPPER(category)) as category, ROUND(price::numeric, 2) as price, TRIM(description) as description, created_at, updated_at FROM products WHERE product_name IS NOT NULL AND price > 0 ORDER BY product_id) TO '/tmp/silver_products.csv' WITH CSV HEADER
EOF
    aws s3 cp /tmp/silver_products.csv s3://${S3_BUCKET}/silver/products/products_cleaned.csv
    
    # Clean transactions data
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} << 'EOF'
\COPY (SELECT transaction_id, store_id, customer_id, product_id, quantity, ROUND(unit_price::numeric, 2) as unit_price, ROUND((quantity * unit_price)::numeric, 2) as total_amount, payment_method, sales_channel, created_at::date as transaction_date, EXTRACT(YEAR FROM created_at) as year, EXTRACT(MONTH FROM created_at) as month, EXTRACT(DAY FROM created_at) as day, created_at, updated_at FROM sale_transactions WHERE quantity > 0 AND unit_price > 0 ORDER BY created_at DESC) TO '/tmp/silver_transactions.csv' WITH CSV HEADER
EOF
    aws s3 cp /tmp/silver_transactions.csv s3://${S3_BUCKET}/silver/transactions/transactions_cleaned.csv
    
    echo "Silver layer transformation completed"
    ''',
    dag=dag
)

# GOLD LAYER - Business-ready aggregated data in Parquet format
gold_layer = BashOperator(
    task_id='gold_layer_aggregate',
    bash_command='''
    export PGPASSWORD=${DATA_POSTGRES_PASSWORD}
    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
    
    echo "=== GOLD LAYER: Business Analytics Tables (Parquet) ==="
    
    # Daily sales summary
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} << 'EOF'
\COPY (SELECT created_at::date as sales_date, COUNT(*) as total_transactions, SUM(quantity) as total_items_sold, ROUND(SUM(quantity * unit_price)::numeric, 2) as total_revenue, ROUND(AVG(quantity * unit_price)::numeric, 2) as avg_transaction_value, COUNT(DISTINCT customer_id) as unique_customers, COUNT(DISTINCT product_id) as unique_products FROM sale_transactions WHERE quantity > 0 AND unit_price > 0 GROUP BY created_at::date ORDER BY sales_date DESC) TO '/tmp/gold_daily_sales.csv' WITH CSV HEADER
EOF
    python3 -c "import pandas as pd; df = pd.read_csv('/tmp/gold_daily_sales.csv'); df.to_parquet('/tmp/gold_daily_sales.parquet', index=False)"
    aws s3 cp /tmp/gold_daily_sales.parquet s3://${S3_BUCKET}/gold/daily_sales_summary/data.parquet
    
    # Product performance
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} << 'EOF'
\COPY (SELECT p.product_id, p.product_name, p.category, COUNT(st.transaction_id) as total_orders, SUM(st.quantity) as total_quantity_sold, ROUND(SUM(st.quantity * st.unit_price)::numeric, 2) as total_revenue, ROUND(AVG(st.quantity * st.unit_price)::numeric, 2) as avg_order_value, ROUND(AVG(st.quantity)::numeric, 2) as avg_quantity_per_order FROM products p JOIN sale_transactions st ON p.product_id = st.product_id WHERE st.quantity > 0 AND st.unit_price > 0 GROUP BY p.product_id, p.product_name, p.category ORDER BY total_revenue DESC) TO '/tmp/gold_product_performance.csv' WITH CSV HEADER
EOF
    python3 -c "import pandas as pd; df = pd.read_csv('/tmp/gold_product_performance.csv'); df.to_parquet('/tmp/gold_product_performance.parquet', index=False)"
    aws s3 cp /tmp/gold_product_performance.parquet s3://${S3_BUCKET}/gold/product_performance/data.parquet
    
    # Customer analytics
    psql -h data_postgres -p 5432 -U ${DATA_POSTGRES_USER} -d ${DATA_POSTGRES_DB} << 'EOF'
\COPY (SELECT c.customer_id, c.customer_name, c.city, c.state, COUNT(st.transaction_id) as total_purchases, SUM(st.quantity) as total_items_bought, ROUND(SUM(st.quantity * st.unit_price)::numeric, 2) as total_spent, ROUND(AVG(st.quantity * st.unit_price)::numeric, 2) as avg_order_value, MIN(st.created_at::date) as first_purchase_date, MAX(st.created_at::date) as last_purchase_date FROM customers c JOIN sale_transactions st ON c.customer_id = st.customer_id WHERE st.quantity > 0 AND st.unit_price > 0 GROUP BY c.customer_id, c.customer_name, c.city, c.state ORDER BY total_spent DESC) TO '/tmp/gold_customer_analytics.csv' WITH CSV HEADER
EOF
    python3 -c "import pandas as pd; df = pd.read_csv('/tmp/gold_customer_analytics.csv'); df.to_parquet('/tmp/gold_customer_analytics.parquet', index=False)"
    aws s3 cp /tmp/gold_customer_analytics.parquet s3://${S3_BUCKET}/gold/customer_analytics/data.parquet
    
    echo "Gold layer aggregation completed (Parquet format)"
    ''',
    dag=dag
)

# Set task dependencies for medallion architecture
bronze_layer >> silver_layer >> gold_layer