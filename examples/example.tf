module "cost_anomaly_detector" {
  source             = "git@github.com:jmpcba/cost_anomaly_detection.git"
  cost_threshold     = 0.1
  threshold_type     = "AMOUNT"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  tags = {
    key = "value"
  }
}