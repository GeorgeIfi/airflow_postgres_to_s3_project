# Optional: CloudWatch monitoring for production

# CloudWatch Log Group for Glue Crawlers
resource "aws_cloudwatch_log_group" "glue_crawlers" {
  name              = "/aws/glue/crawlers/shopease"
  retention_in_days = 7
}

# CloudWatch Alarm for Failed Glue Crawlers
resource "aws_cloudwatch_metric_alarm" "crawler_failures" {
  alarm_name          = "shopease-crawler-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  namespace           = "Glue"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Glue crawler fails"
  
  # Optional: Add SNS topic for email notifications
  # alarm_actions = [aws_sns_topic.alerts.arn]
}

# CloudWatch Dashboard (Optional)
resource "aws_cloudwatch_dashboard" "pipeline_monitoring" {
  dashboard_name = "shopease-data-pipeline"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", { stat = "Average" }],
            ["AWS/Athena", "DataScannedInBytes", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Data Lake Metrics"
        }
      }
    ]
  })
}
