-- Create Bronze Tables Manually in Athena
-- Run these in Athena Query Editor if crawlers failed

CREATE EXTERNAL TABLE IF NOT EXISTS shopease_catalog.bronze_customers (
    customer_id bigint,
    customer_name string,
    email string,
    phone string,
    address string,
    city string,
    state string,
    zip_code string,
    registration_date string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES ('field.delim' = ',')
STORED AS TEXTFILE
LOCATION 's3://shopease-stg/bronze/customers/'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE IF NOT EXISTS shopease_catalog.bronze_products (
    product_id bigint,
    product_name string,
    category string,
    price double,
    cost double,
    supplier_id bigint
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES ('field.delim' = ',')
STORED AS TEXTFILE
LOCATION 's3://shopease-stg/bronze/products/'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE IF NOT EXISTS shopease_catalog.bronze_transactions (
    transaction_id bigint,
    customer_id bigint,
    product_id bigint,
    store_id bigint,
    quantity bigint,
    unit_price double,
    total_amount double,
    transaction_date string,
    sales_manager_id bigint
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES ('field.delim' = ',')
STORED AS TEXTFILE
LOCATION 's3://shopease-stg/bronze/transactions/'
TBLPROPERTIES ('skip.header.line.count'='1');