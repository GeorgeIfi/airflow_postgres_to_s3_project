output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = data.aws_s3_bucket.data_lake.bucket
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.data_catalog.name
}

output "glue_role_arn" {
  description = "ARN of the Glue IAM role"
  value       = aws_iam_role.glue_role.arn
}

output "bronze_crawler_name" {
  description = "Name of the Bronze Glue crawler"
  value       = aws_glue_crawler.bronze_crawler.name
}

output "silver_crawler_name" {
  description = "Name of the Silver Glue crawler"
  value       = aws_glue_crawler.silver_crawler.name
}

output "gold_crawler_name" {
  description = "Name of the Gold Glue crawler"
  value       = aws_glue_crawler.gold_crawler.name
}

output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}