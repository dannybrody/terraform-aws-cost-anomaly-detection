output "sns_topic_arn" {
  value = var.sns_topic_arn == "" ? aws_sns_topic.cost_anomaly_topic[0].arn : var.sns_topic_arn
}

output "anomaly_monitor_arn" {
  value = local.multi_account ? aws_ce_anomaly_monitor.linked_account_anomaly_monitor[0].arn : aws_ce_anomaly_monitor.service_anomaly_monitor[0].arn
}

output "anomaly_subscription_arn" {
  value = aws_ce_anomaly_subscription.anomaly_subscription.arn
}