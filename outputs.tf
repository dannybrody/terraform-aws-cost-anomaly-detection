output "sns_topic_arn" {
  value = var.sns_topic_arn == "" ? aws_sns_topic.cost_anomaly_topic[0].arn : var.sns_topic_arn
}

output "anomaly_monitor_arn" {
  value = aws_ce_anomaly_monitor.anomaly_monitor.arn
}

output "anomaly_subscription_arn" {
  value = aws_ce_anomaly_subscription.anomaly_subscription.arn
}