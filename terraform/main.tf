terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Use existing S3 bucket
data "aws_s3_bucket" "data_lake" {
  bucket = var.s3_bucket_name
}

# Glue Database
resource "aws_glue_catalog_database" "data_catalog" {
  name        = "shopease_catalog"
  description = "Sales data catalog for ShopEase project"
}

# IAM Role for Glue
resource "aws_iam_role" "glue_role" {
  name = "GlueServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_s3_full_access" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Glue Crawler for Bronze layer
resource "aws_glue_crawler" "bronze_crawler" {
  database_name = aws_glue_catalog_database.data_catalog.name
  name          = "shopease-bronze-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${data.aws_s3_bucket.data_lake.bucket}/bronze/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}

# Glue Crawler for Silver layer
resource "aws_glue_crawler" "silver_crawler" {
  database_name = aws_glue_catalog_database.data_catalog.name
  name          = "shopease-silver-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${data.aws_s3_bucket.data_lake.bucket}/silver/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}

# Glue Crawler for Gold layer
resource "aws_glue_crawler" "gold_crawler" {
  database_name = aws_glue_catalog_database.data_catalog.name
  name          = "shopease-gold-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${data.aws_s3_bucket.data_lake.bucket}/gold/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}

# Athena Workgroup
resource "aws_athena_workgroup" "main" {
  name          = "shopease-analytics"
  description   = "Workgroup for sales data analytics"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${data.aws_s3_bucket.data_lake.bucket}/athena-results/"
    }
  }
}