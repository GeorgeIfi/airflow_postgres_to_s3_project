# ShopEase Data Lake Project - Final Summary

## What You've Built

A complete **end-to-end data pipeline** with medallion architecture (Bronze/Silver/Gold) that extracts 1M+ sales records from PostgreSQL, transforms them, and loads them into AWS S3 for analytics using Athena.

```
PostgreSQL (1,020,500+ records)
    ↓
Apache Airflow (Orchestration)
    ↓
AWS S3 Data Lake (shopease-stg)
    ├── Bronze Layer (CSV - Raw data)
    ├── Silver Layer (CSV - Cleaned & validated)
    └── Gold Layer (Parquet - Business analytics)
    ↓
Terraform (Infrastructure as Code)
    ├── AWS Glue Database (shopease_catalog)
    ├── 3 Glue Crawlers (Bronze/Silver/Gold)
    ├── IAM Roles & Permissions
    └── Athena Workgroup (shopease-analytics)
    ↓
AWS Athena (SQL Analytics) ✅
```

---

## Architecture Components

### 1. Data Source
- **PostgreSQL Database**: `data_postgres` container
- **6 Tables**: customers (7,500), products (600), stores (5), inventory (3,000), sales_managers (5), sale_transactions (1,020,500)
- **Total Data**: ~112MB

### 2. Orchestration Layer
- **Apache Airflow**: Running in Docker containers
- **Web UI**: http://localhost:8080 (admin/admin)
- **Scheduler**: Automated task execution
- **DAGs**: 
  - `medallion_etl_pipeline` - Main ETL pipeline
  - `trigger_glue_crawlers` - Catalog data in Glue
  - `setup_connections` - Configure Airflow connections
  - `restore_dump_dag` - Restore database from dump

### 3. Data Lake (AWS S3)
- **Bucket**: `shopease-stg`
- **Region**: `us-east-1`
- **Structure**:
  ```
  s3://shopease-stg/
  ├── bronze/
  │   ├── customers/customers.csv
  │   ├── products/products.csv
  │   ├── stores/stores.csv
  │   ├── inventory/inventory.csv
  │   ├── sales_managers/sales_managers.csv
  │   └── transactions/sale_transactions.csv
  ├── silver/
  │   ├── customers/customers_cleaned.csv
  │   ├── products/products_cleaned.csv
  │   └── transactions/transactions_cleaned.csv
  ├── gold/
  │   ├── daily_sales_summary/data.parquet
  │   ├── product_performance/data.parquet
  │   └── customer_analytics/data.parquet
  └── athena-results/ (query outputs)
  ```

### 4. Infrastructure (Terraform)
- **Glue Database**: `shopease_catalog`
- **IAM Role**: `GlueServiceRole` (for Glue crawlers)
- **Glue Crawlers**:
  - `shopease-bronze-crawler` → Catalogs Bronze layer
  - `shopease-silver-crawler` → Catalogs Silver layer
  - `shopease-gold-crawler` → Catalogs Gold layer
- **Athena Workgroup**: `shopease-analytics`
- **IAM User Permissions**: Added Glue, Athena, and limited IAM access to `shopease_user`

### 5. Analytics Layer (AWS Athena)
- **Database**: `shopease_catalog`
- **Workgroup**: `shopease-analytics`
- **Query Result Location**: `s3://shopease-stg/athena-results/`
- **Available Tables**:
  - `daily_sales_summary` - Daily revenue and transaction metrics
  - `product_performance` - Product sales analytics
  - `customers` - Customer master data
  - `products` - Product catalog
  - `stores` - Store information
  - `transactions` - Sales transactions
  - `silver` - Cleaned data tables

---

## Medallion Architecture Explained

### Bronze Layer (Raw Data)
- **Format**: CSV
- **Purpose**: Store raw data exactly as extracted from source
- **Transformations**: None (minimal - just COPY from PostgreSQL)
- **Use Case**: Data lineage, reprocessing, auditing

### Silver Layer (Cleaned Data)
- **Format**: CSV
- **Purpose**: Cleaned, validated, and standardized data
- **Transformations**:
  - Remove duplicates
  - Standardize formats (UPPER, TRIM, LOWER)
  - Data validation (NOT NULL checks, price > 0)
  - Add calculated fields (total_amount, year, month, day)
- **Use Case**: Data science, ML models, downstream applications

### Gold Layer (Business Analytics)
- **Format**: Parquet (columnar, compressed)
- **Purpose**: Business-ready aggregated datasets
- **Transformations**:
  - Daily sales summaries
  - Product performance metrics
  - Customer analytics (RFM analysis)
  - Aggregations (SUM, AVG, COUNT)
- **Use Case**: BI dashboards, executive reports, Athena queries

---

## Key Technologies Used

| Technology | Purpose | Version |
|------------|---------|---------|
| Apache Airflow | Workflow orchestration | 2.7.3 |
| PostgreSQL | Source database | 15 |
| AWS S3 | Data lake storage | - |
| AWS Glue | Data catalog & crawlers | - |
| AWS Athena | SQL analytics engine | - |
| Terraform | Infrastructure as Code | 1.14.1 |
| Docker | Containerization | - |
| Python | ETL scripts | 3.11 |
| Pandas | Data transformation | - |
| PyArrow | Parquet file handling | - |

---

## Project Files Structure

```
airflow_postgres_to_s3_project/
├── dags/
│   ├── medallion_etl_pipeline.py      # Main ETL pipeline
│   ├── trigger_glue_crawlers.py       # Catalog data in Glue
│   ├── setup_connections.py           # Airflow connections
│   └── restore_dump_dag.py            # Database restore
├── terraform/
│   ├── main.tf                        # Infrastructure resources
│   ├── variables.tf                   # Input variables
│   ├── outputs.tf                     # Output values
│   ├── terraform.tfvars               # Variable values
│   └── iam_permissions.tf             # IAM policies
├── sql/
│   └── athena/
│       └── sample_queries.sql         # Example Athena queries
├── dumps/
│   └── sales_db.dump                  # PostgreSQL backup (112MB)
├── scripts/
│   ├── deploy_infrastructure.sh       # Terraform deployment
│   ├── query_athena.sh                # Query Athena from CLI
│   └── cleanup_s3.sh                  # Delete S3 data
├── docker-compose.yml                 # Container orchestration
├── Dockerfile                         # Airflow container image
├── requirements.txt                   # Python dependencies
├── .env                               # Environment variables
├── PROJECT_REPORT.md                  # Detailed challenges & solutions
├── ATHENA_QUERY_GUIDE.md              # Query examples
├── AWS_MANUAL_SETUP_GUIDE.md          # IAM permission setup
└── PROJECT_SUMMARY.md                 # This file
```

---

## How to Use

### Start the Pipeline

1. **Start Docker containers**:
   ```bash
   docker-compose up -d
   ```

2. **Access Airflow UI**:
   - URL: http://localhost:8080
   - Username: `admin`
   - Password: `admin`

3. **Run the ETL pipeline**:
   - Trigger DAG: `medallion_etl_pipeline`
   - Wait 2-3 minutes for completion

4. **Catalog the data**:
   - Trigger DAG: `trigger_glue_crawlers`
   - Wait 2-5 minutes for crawlers to complete

5. **Query in Athena**:
   - Go to AWS Console → Athena
   - Select workgroup: `shopease-analytics`
   - Database: `shopease_catalog`
   - Run queries!

### Sample Athena Queries

**Top 10 Revenue Days**:
```sql
SELECT 
    sales_date,
    total_revenue,
    total_transactions,
    unique_customers
FROM shopease_catalog.daily_sales_summary
ORDER BY total_revenue DESC
LIMIT 10;
```

**Best Selling Products**:
```sql
SELECT 
    product_name,
    category,
    total_revenue,
    total_quantity_sold
FROM shopease_catalog.product_performance
ORDER BY total_revenue DESC
LIMIT 10;
```

**Sales by Store**:
```sql
SELECT 
    s.store_name,
    COUNT(*) as transactions,
    SUM(t.quantity * t.unit_price) as revenue
FROM shopease_catalog.transactions t
JOIN shopease_catalog.stores s ON t.store_id = s.store_id
GROUP BY s.store_name
ORDER BY revenue DESC;
```

---

## Infrastructure Management

### Deploy Infrastructure (Terraform)

```bash
cd terraform
export AWS_ACCESS_KEY_ID=<your-key>
export AWS_SECRET_ACCESS_KEY=<your-secret>
terraform init
terraform apply -auto-approve
```

**Creates**:
- Glue database and crawlers
- IAM roles and permissions
- Athena workgroup

### Destroy Infrastructure

```bash
cd terraform
terraform destroy -auto-approve
```

**Deletes**:
- All Glue resources
- IAM roles (keeps user permissions)
- Athena workgroup

**Note**: S3 data is NOT deleted by Terraform

---

## Cost Analysis

### Storage Costs
- **S3 Storage**: ~$0.0024/month (~105MB at $0.023/GB)
- **Annual**: ~$0.03 (3 cents per year)

### Compute Costs
- **Glue Crawlers**: ~$0.05 per run (2-5 minutes)
- **Athena Queries**: 
  - Gold layer (Parquet): ~$0.000025 per query
  - Bronze/Silver (CSV): ~$0.00025 per query
- **IAM/Glue Database**: FREE

### Total Project Cost
- **One-time setup**: ~$0.05
- **Monthly**: ~$0.01 (if no queries)
- **Per 1000 queries**: ~$0.025 (Gold layer)

**You'd need 20,000 queries to spend $1!**

---

## Key Features

✅ **Medallion Architecture** - Industry-standard Bronze/Silver/Gold layers  
✅ **Infrastructure as Code** - Reproducible with Terraform  
✅ **Orchestration** - Automated with Apache Airflow  
✅ **Scalable** - Handles millions of records  
✅ **Cost-Effective** - Pay-per-query model  
✅ **Analytics-Ready** - Query with standard SQL  
✅ **Parquet Format** - Optimized for analytics (10-100x faster)  
✅ **Data Quality** - Validation and cleaning in Silver layer  
✅ **Containerized** - Easy deployment with Docker  
✅ **Version Controlled** - All code in Git  

---

## Challenges Solved

1. **SQLAlchemy Version Conflict** - Fixed compatibility with Airflow 2.7.3
2. **Docker Permission Issues** - Configured proper user permissions (50000:0)
3. **PostgreSQL Dump Format** - Used `psql -f` instead of `pg_restore`
4. **AWS IAM Permissions** - Added Glue, Athena, and IAM access to user
5. **SQL Syntax Errors** - Fixed `\COPY` command with heredoc syntax
6. **Parquet File Structure** - Organized files in folders for Glue crawler
7. **Glue Crawler Configuration** - Proper S3 path structure for cataloging
8. **Athena Result Location** - Configured S3 output location for queries

See `PROJECT_REPORT.md` for detailed solutions.

---

## Quick Commands Reference

### Docker
```bash
# Start all containers
docker-compose up -d

# Stop all containers
docker-compose down

# View logs
docker-compose logs -f airflow

# Check container status
docker ps
```

### Airflow
```bash
# Trigger DAG
docker exec airflow_postgres_to_s3_project-airflow-1 airflow dags trigger medallion_etl_pipeline

# Check DAG status
docker exec airflow_postgres_to_s3_project-airflow-1 airflow dags list

# View task logs
docker exec airflow_postgres_to_s3_project-airflow-1 airflow tasks states-for-dag-run <dag_id> <run_id>
```

### Terraform
```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy -auto-approve

# Show outputs
terraform output
```

### AWS CLI (from Airflow container)
```bash
# List S3 files
docker exec airflow_postgres_to_s3_project-airflow-1 aws s3 ls s3://shopease-stg/ --recursive

# Start crawler
docker exec airflow_postgres_to_s3_project-airflow-1 aws glue start-crawler --name shopease-gold-crawler

# List Glue tables
docker exec airflow_postgres_to_s3_project-airflow-1 aws glue get-tables --database-name shopease_catalog
```

---

## Next Steps & Enhancements

### Immediate
- [ ] Schedule `medallion_etl_pipeline` to run daily
- [ ] Add data quality checks (Great Expectations)
- [ ] Create AWS QuickSight dashboards
- [ ] Set up email alerts for DAG failures

### Advanced
- [ ] Implement incremental loads (CDC)
- [ ] Add data partitioning by date
- [ ] Create dbt models for transformations
- [ ] Add unit tests for DAGs
- [ ] Implement CI/CD pipeline
- [ ] Add data lineage tracking
- [ ] Create customer segmentation models
- [ ] Build real-time streaming pipeline (Kinesis)

---

## Resources & Documentation

- **Airflow Docs**: https://airflow.apache.org/docs/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS Glue**: https://docs.aws.amazon.com/glue/
- **AWS Athena**: https://docs.aws.amazon.com/athena/
- **Medallion Architecture**: https://www.databricks.com/glossary/medallion-architecture

---

## Project Metadata

- **Project Name**: ShopEase Data Lake
- **Created**: December 2024
- **Data Volume**: 1,020,500 transactions
- **Technologies**: 10+ (Airflow, PostgreSQL, AWS S3, Glue, Athena, Terraform, Docker, Python)
- **Architecture**: Medallion (Bronze/Silver/Gold)
- **Status**: ✅ Production Ready

---

## Conclusion

You've successfully built a **production-grade data lake** with:
- Automated ETL pipelines
- Infrastructure as Code
- Scalable cloud storage
- SQL analytics capabilities
- Cost-effective architecture

This project demonstrates expertise in:
- Data Engineering
- Cloud Architecture (AWS)
- DevOps (Docker, Terraform)
- Workflow Orchestration (Airflow)
- Data Modeling (Medallion Architecture)

**Congratulations! 🎉**

---

*For detailed troubleshooting and challenges faced, see `PROJECT_REPORT.md`*  
*For Athena query examples, see `ATHENA_QUERY_GUIDE.md`*
