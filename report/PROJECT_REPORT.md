# Airflow PostgreSQL to S3 ETL Project Report

## Project Overview
Built a complete end-to-end data pipeline using Apache Airflow to extract data from PostgreSQL and load it to AWS S3, following medallion architecture (Bronze, Silver, Gold layers) with AWS Glue and Athena integration.

## Architecture
```
PostgreSQL → Airflow ETL → S3 (Bronze/Silver/Gold) → Glue Crawler → Data Catalog → Athena
```

## Technologies Used
- **Apache Airflow 2.7.3** - Workflow orchestration
- **PostgreSQL 15** - Source database with 1M+ sales records
- **AWS S3** - Data lake storage
- **AWS Glue** - Data catalog and ETL
- **Amazon Athena** - SQL analytics
- **Docker & Docker Compose** - Containerization
- **pgAdmin** - Database management
- **Python** - ETL scripting

## Challenges Faced & Solutions

### 1. **Dependency Conflicts**
**Challenge**: SQLAlchemy version conflict between Airflow 2.7.3 and newer versions
```
ERROR: Cannot install sqlalchemy==2.0.23 because apache-airflow 2.7.3 depends on sqlalchemy<2.0
```
**Solution**: Updated requirements.txt to use compatible version range
```
sqlalchemy>=1.4.28,<2.0
```

### 2. **Docker Container Visibility**
**Challenge**: Containers not showing in Docker Desktop GUI due to dev container environment
**Solution**: 
- Used command line tools: `docker ps`, `docker-compose ps`
- Installed Docker extension in VS Code for container management
- Used port forwarding for web interfaces

### 3. **PostgreSQL Dump Restoration**
**Challenge**: Wrong restore command causing failures
```
ERROR: input file appears to be a text format dump. Please use psql.
```
**Solution**: Changed from `pg_restore` to `psql -f` for text format dumps
```bash
psql -h data_postgres -p 5432 -U datauser -d datadb -f /dumps/sales_db.dump
```

### 4. **Airflow User Authentication**
**Challenge**: Login failures with incorrect credentials
```
Login Failed for user: airflow
```
**Solution**: Used correct default credentials
- Username: `admin`
- Password: `admin`

### 5. **Missing AWS CLI in Containers**
**Challenge**: S3 upload failures due to missing AWS CLI
```
/bin/bash: line 4: aws: command not found
```
**Solution**: Updated Dockerfile to install AWS CLI
```dockerfile
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install
```

### 6. **AWS S3 Permissions**
**Challenge**: Access denied errors during S3 uploads
```
User: arn:aws:iam::592035937176:user/shopease_user is not authorized to perform: s3:PutObject
```
**Solution**: Added proper IAM policies for S3 access
```json
{
    "Effect": "Allow",
    "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
    "Resource": "arn:aws:s3:::shopease-stg/*"
}
```

### 7. **Missing PostgresToS3Operator**
**Challenge**: Import errors for Airflow AWS providers
```
ModuleNotFoundError: No module named 'airflow.providers.amazon.aws.transfers.postgres_to_s3'
```
**Solution**: Used BashOperator with psql and aws cli commands instead of specialized operators

### 8. **Port Forwarding in Dev Environment**
**Challenge**: Web interfaces not accessible on localhost
**Solution**: Used VS Code port forwarding feature via PORTS tab

### 9. **AWS Glue IAM Permission Denied**
**Challenge**: Glue crawler creation failed due to insufficient IAM permissions
```
AccessDeniedException: User: arn:aws:iam::592035937176:user/shopease_user is not authorized to perform: glue:CreateCrawler
```
**Solution**: Manually added IAM policies to shopease_user via AWS Console:
- `AWSGlueConsoleFullAccess` - For Glue database and crawler management
- `AmazonAthenaFullAccess` - For Athena workgroup and queries
- `IAMFullAccess` (or custom limited policy) - For creating Glue service roles

### 10. **Terraform vs Airflow for Infrastructure**
**Challenge**: Initially used Airflow DAG (`glue_athena_setup`) for infrastructure setup, which is not reproducible or easily destroyable
**Solution**: Migrated to Terraform for infrastructure as code:
- Created `terraform/main.tf` with Glue database, crawlers, IAM roles, and Athena workgroup
- Terraform allows `terraform apply` to create and `terraform destroy` to remove all resources
- Kept Airflow DAGs only for data pipeline orchestration
- Separation of concerns: Terraform = Infrastructure, Airflow = Data workflows

### 11. **SQL COPY Command Syntax Errors in Silver/Gold Layers**
**Challenge**: Bash escaping issues with `\COPY` command in psql
```
ERROR: syntax error at or near "\"
LINE 2: \COPY (
```
**Solution**: Used heredoc syntax instead of `-c` flag for multi-line SQL
```bash
psql -h data_postgres -p 5432 -U datauser -d datadb << 'EOF'
\COPY (SELECT ...) TO '/tmp/file.csv' WITH CSV HEADER
EOF
```

### 12. **Parquet Files Not Readable by Glue Crawler**
**Challenge**: Glue crawler created tables but Athena queries returned 0 rows
```
SELECT COUNT(*) FROM daily_sales_summary_parquet; -- Returns 0
```
**Root Cause**: Crawler pointed to individual Parquet files instead of folders
```
s3://shopease-stg/gold/analytics/daily_sales_summary.parquet  ❌ (single file)
```
**Solution**: Reorganized Gold layer to use folder structure
```
s3://shopease-stg/gold/daily_sales_summary/data.parquet  ✅ (file in folder)
s3://shopease-stg/gold/product_performance/data.parquet  ✅
s3://shopease-stg/gold/customer_analytics/data.parquet   ✅
```
Glue crawlers require folders, not individual files, to properly catalog Parquet data

### 13. **Athena Query Result Location Error**
**Challenge**: DBeaver connection failed with S3 location error
```
The S3 location provided to save your query results is invalid
```
**Solution**: 
- Created `athena-results` folder in S3: `s3://shopease-stg/athena-results/`
- Used correct format without trailing slash in DBeaver: `s3://shopease-stg/athena-results`
- Configured Athena workgroup with proper output location via Terraform

### 14. **Empty Athena Query Results**
**Challenge**: Queries executed successfully but returned no data in results tab
**Solution**: 
- Re-ran medallion ETL pipeline with fixed folder structure
- Triggered Glue crawlers to re-catalog data: `aws glue start-crawler --name shopease-gold-crawler`
- Waited for crawlers to complete (2-5 minutes)
- Queried new table names: `daily_sales_summary`, `product_performance` (not the old `*_parquet` tables)
- Verified data exists: `SELECT COUNT(*) FROM daily_sales_summary` returned actual row counts

## Final Architecture Implementation

### Data Pipeline Components
1. **Source**: PostgreSQL with 6 tables (1M+ transactions)
2. **ETL**: Airflow DAGs for Bronze → Silver → Gold transformation
3. **Storage**: S3 with medallion architecture
4. **Infrastructure**: Terraform for Glue, Athena, and IAM resources
5. **Catalog**: AWS Glue crawlers for metadata
6. **Analytics**: Amazon Athena for SQL queries

### Medallion Architecture Layers
- **Bronze**: Raw data extraction (CSV format) - `s3://shopease-stg/bronze/`
- **Silver**: Cleaned and validated data with transformations (CSV) - `s3://shopease-stg/silver/`
- **Gold**: Business-ready aggregated analytics tables (Parquet) - `s3://shopease-stg/gold/`

### Key DAGs Created
1. `setup_connections` - Automated Airflow connection setup
2. `restore_dump_dag` - Database restoration from dump file
3. `medallion_etl_pipeline` - Bronze/Silver/Gold ETL (Main pipeline)
4. `trigger_glue_crawlers` - Trigger Glue crawlers to catalog data

### Terraform Infrastructure
1. **Glue Database**: `shopease_catalog`
2. **IAM Role**: `GlueServiceRole` with S3 and Glue permissions
3. **Glue Crawlers**: 
   - `shopease-bronze-crawler` → Bronze layer
   - `shopease-silver-crawler` → Silver layer
   - `shopease-gold-crawler` → Gold layer
4. **Athena Workgroup**: `shopease-analytics` with S3 result location
5. **IAM User Permissions**: Added Glue, Athena, and limited IAM access to `shopease_user`

## Data Volume Processed
- **Customers**: 7,500 records
- **Products**: 600 records
- **Stores**: 5 records
- **Inventory**: 3,000 records
- **Sales Managers**: 5 records
- **Transactions**: 1,020,500 records

## Key Learnings
1. **Version Compatibility**: Always check dependency compatibility in containerized environments
2. **Environment Awareness**: Dev containers require different approaches for GUI access
3. **Error Handling**: Proper error analysis leads to faster resolution
4. **Security**: AWS IAM permissions are critical for cloud integrations
5. **Architecture**: Medallion architecture provides better data quality and lineage
6. **Infrastructure as Code**: Use Terraform for infrastructure, Airflow for data workflows - separation of concerns
7. **Glue Crawler Requirements**: Parquet files must be in folders, not as individual files
8. **SQL in Bash**: Use heredoc syntax for complex multi-line SQL commands to avoid escaping issues
9. **Data Format**: Parquet format in Gold layer provides 10-100x faster queries and lower costs
10. **Iterative Development**: Test each layer independently before moving to the next

## Final Deliverables
- ✅ Complete ETL pipeline with Airflow (medallion architecture)
- ✅ PostgreSQL database with 1M+ sales records
- ✅ S3 data lake with Bronze/Silver/Gold layers
- ✅ Terraform infrastructure as code (reproducible)
- ✅ AWS Glue data catalog with 3 crawlers
- ✅ Athena analytics with working queries
- ✅ pgAdmin for database management
- ✅ Docker containerized environment
- ✅ Parquet format for optimized analytics
- ✅ Comprehensive documentation (PROJECT_SUMMARY.md, ATHENA_QUERY_GUIDE.md)

## Project Success Metrics
- **Data Pipeline**: Successfully processes 1M+ records
- **Automation**: Fully automated ETL with Airflow scheduling
- **Scalability**: Medallion architecture supports data growth
- **Analytics**: Business-ready data in Athena
- **Monitoring**: Airflow UI for pipeline monitoring

## Future Enhancements
1. Add data quality checks with Great Expectations
2. Implement incremental data loading (CDC)
3. Add monitoring and alerting (email notifications)
4. Create AWS QuickSight dashboards
5. Implement data lineage tracking
6. Add dbt for transformation layer
7. Implement CI/CD pipeline for DAGs
8. Add unit tests for Airflow DAGs
9. Partition data by date for better performance
10. Build real-time streaming with Kinesis

---
*Project completed successfully with all major challenges resolved and a production-ready data pipeline delivered.*