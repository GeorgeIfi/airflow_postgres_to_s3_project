# Pipeline Architecture Diagram

## High-Level Data Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────────────┐
│   PostgreSQL    │    │     Airflow     │    │               AWS S3                │
│   (Source DB)   │───▶│   Orchestrator  │───▶│        Medallion Architecture       │
│                 │    │                 │    │                                     │
│ • Sales Data    │    │ • ETL DAGs      │    │ ┌─────────┬─────────┬─────────┐   │
│ • Customer Data │    │ • Scheduling    │    │ │ Bronze  │ Silver  │  Gold   │   │
│ • Product Data  │    │ • Monitoring    │    │ │ (Raw)   │(Cleaned)│(Curated)│   │
└─────────────────┘    └─────────────────┘    │ └─────────┴─────────┴─────────┘   │
                                              └─────────────────────────────────────┘
                                                              │
                                              ┌─────────────────────────────────────┐
                                              │           AWS Glue              │
                                              │        Data Catalog             │───┐
                                              │                                 │   │
                                              │ • Schema Discovery              │   │
                                              │ • Metadata Management          │   │
                                              └─────────────────────────────────────┘   │
                                                                                      │
                                              ┌─────────────────────────────────────┐   │
                                              │         Amazon Athena           │◀──┘
                                              │       Query Engine              │
                                              │                                 │
                                              │ • SQL Analytics                 │
                                              │ • Business Intelligence         │
                                              └─────────────────────────────────────┘
```

## Detailed Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              AIRFLOW ORCHESTRATION LAYER                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                    │
│  │restore_sales_   │  │medallion_etl_   │  │trigger_glue_    │                    │
│  │dump             │  │pipeline         │  │crawlers         │                    │
│  │                 │  │                 │  │                 │                    │
│  │• Load sample    │  │• Extract from   │  │• Catalog Bronze │                    │
│  │  data           │  │  PostgreSQL     │  │• Catalog Silver │                    │
│  │• Initialize DB  │  │• Transform data │  │• Catalog Gold   │                    │
│  └─────────────────┘  │• Load to S3     │  │• Update schemas │                    │
│                       └─────────────────┘  └─────────────────┘                    │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                 DATA STORAGE LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                    │
│  │   BRONZE LAYER  │  │  SILVER LAYER   │  │   GOLD LAYER    │                    │
│  │   s3://bucket/  │  │   s3://bucket/  │  │   s3://bucket/  │                    │
│  │   bronze/       │  │   silver/       │  │   gold/         │                    │
│  │                 │  │                 │  │                 │                    │
│  │• Raw JSON/CSV   │  │• Cleaned data   │  │• Parquet format │                    │
│  │• Exact copy     │  │• Validated      │  │• Partitioned    │                    │
│  │• Timestamped    │  │• Standardized   │  │• Aggregated     │                    │
│  │• Immutable      │  │• Deduplicated   │  │• Analytics-ready│                    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                    │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ANALYTICS LAYER                                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────┐                    ┌─────────────────┐                        │
│  │   AWS GLUE      │                    │  AMAZON ATHENA  │                        │
│  │                 │                    │                 │                        │
│  │• Crawlers       │───────────────────▶│• SQL Queries    │                        │
│  │• Data Catalog   │                    │• Business Logic │                        │
│  │• Schema Mgmt    │                    │• Reporting      │                        │
│  │• Partitions     │                    │• Dashboards     │                        │
│  └─────────────────┘                    └─────────────────┘                        │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Sequence

```
1. PostgreSQL Source
   ├── Sales transactions
   ├── Customer information  
   ├── Product catalog
   └── Order details

2. Airflow Extraction
   ├── Connect to PostgreSQL
   ├── Execute SQL queries
   ├── Extract incremental data
   └── Handle data validation

3. Bronze Layer (Raw)
   ├── Store exact copy as JSON/CSV
   ├── Preserve original structure
   ├── Add ingestion timestamp
   └── Maintain data lineage

4. Silver Layer (Cleaned)
   ├── Data quality checks
   ├── Schema standardization
   ├── Deduplication
   └── Data type conversion

5. Gold Layer (Curated)
   ├── Business logic application
   ├── Aggregations and calculations
   ├── Parquet format conversion
   └── Partitioning for performance

6. AWS Glue Cataloging
   ├── Discover schemas automatically
   ├── Create/update table definitions
   ├── Manage partitions
   └── Enable Athena queries

7. Athena Analytics
   ├── SQL-based analysis
   ├── Business intelligence queries
   ├── Performance reporting
   └── Cost-effective querying
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Source** | PostgreSQL | Transactional database |
| **Orchestration** | Apache Airflow | Workflow management |
| **Storage** | Amazon S3 | Data lake storage |
| **Processing** | Python/Pandas | Data transformation |
| **Cataloging** | AWS Glue | Metadata management |
| **Analytics** | Amazon Athena | Serverless SQL queries |
| **Infrastructure** | Docker Compose | Local development |
| **IaC** | Terraform | Cloud resource management |

## Key Benefits

- **Scalability**: Handles growing data volumes
- **Cost Efficiency**: Pay-per-query model with Athena
- **Reliability**: Medallion architecture ensures data quality
- **Flexibility**: SQL-based analytics for business users
- **Maintainability**: Infrastructure as Code approach