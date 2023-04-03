module "cost_anomaly_detector" {
  source             = "git@github.com:manu-caylent/cost_anomaly_monitor.git?ref=main"
  cost_threshold     = 10
  threshold_type     = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  tags = {
    key = "value"
  }
}