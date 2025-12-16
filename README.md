# Airflow PostgreSQL to S3 Data Pipeline

A complete end-to-end data pipeline that extracts data from PostgreSQL, processes it through Bronze/Silver/Gold layers in S3, and makes it queryable via AWS Athena.

## 🏗️ Architecture

```
PostgreSQL → Airflow → S3 (Bronze/Silver/Gold) → AWS Glue → Amazon Athena
```

## 🚀 Features

- **Medallion Architecture**: Bronze (raw), Silver (cleaned), Gold (analytics-ready)
- **Infrastructure as Code**: Terraform for AWS resources
- **Containerized**: Docker Compose for local development
- **Dev Container Ready**: VS Code dev container configuration for seamless development
- **Business Analytics**: Pre-built SQL queries for stakeholder insights
- **Cost Optimized**: Uses Parquet format in Gold layer for fast, cheap queries

## 📋 Prerequisites

- Docker & Docker Compose
- AWS Account with appropriate permissions
- Terraform for infrastructure deployment
- VS Code with Dev Containers extension (optional)

## 🛠️ Quick Start

### Option 1: Dev Container (Recommended)
1. **Open in VS Code**
   ```bash
   git clone <your-repo>
   cd airflow_postgres_to_s3_project
   code .
   ```

2. **Reopen in Container**
   - VS Code will prompt to "Reopen in Container"
   - Or use Command Palette: `Dev Containers: Reopen in Container`

3. **Setup Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your AWS credentials and S3 bucket
   ```

### Option 2: Docker Compose
1. **Clone and Setup**
   ```bash
   git clone <your-repo>
   cd airflow_postgres_to_s3_project
   cp .env.example .env
   # Edit .env with your AWS credentials and S3 bucket
   ```

2. **Start Services**
   ```bash
   docker-compose up -d
   ```

3. **Access Airflow**
   - URL: http://localhost:8080
   - Username: admin
   - Password: admin

4. **Deploy AWS Infrastructure** (Optional)
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

## 📊 Available DAGs

- `restore_sales_dump` - Load sample data
- `medallion_etl_pipeline` - Main ETL process
- `trigger_glue_crawlers` - Catalog data in AWS Glue

## 🔍 Business Analytics

Pre-built SQL queries available in `/sql/athena/`:
- `working_business_queries.sql` - Complete business analysis
- `quick_insights.sql` - Fast performance insights

## 🏢 Use Cases

- Sales performance analysis
- Customer segmentation
- Product performance tracking
- Geographic market analysis
- Payment method insights

## 📈 Sample Insights

- Revenue trends and growth analysis
- Top performing products and categories
- Customer lifetime value segmentation
- Geographic performance by state
- Sales channel effectiveness

## 🔧 Configuration

Key configuration files:
- `.env` - Environment variables
- `docker-compose.yml` - Service definitions
- `.devcontainer/` - Dev container configuration
- `terraform/` - AWS infrastructure
- `dags/` - Airflow pipeline definitions

## 💰 Cost Optimization

- Uses S3 for cost-effective storage
- Parquet format in Gold layer reduces query costs
- Athena pay-per-query model
- Estimated monthly cost: <$5 for small datasets

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.