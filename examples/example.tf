# Module configuration to setup an absolute impact monitor for several accounts
# Must be deployed on the root account to work
module "multi_account_cost_anomaly_detector" {
  source             = "github.com/caylent/terraform-aws-cost-anomaly-detection.git?ref=v1.0.0"
  alert_threshold    = 0.1
  threshold_type     = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  accounts = [
    # list of AWS accounts to monitor
  ]

  tags = {
    key                = "value"
    "caylent:owner"    = "manuel.palacios@caylent.com",
    "caylent:workload" = "cost"
  }
}

# For example purposes only. This will only work if terraform apply is run with -target=module.multi_account_cost_anomaly_detector
# This module uses a percentage threshold, monitors services in just one account, and uses the sns topic of the multi account module above.
module "service_cost_anomaly_detector" {
  source             = "github.com/caylent/terraform-aws-cost-anomaly-detection.git?ref=v1.0.0"
  alert_threshold    = 20
  threshold_type     = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  multi_account = false
  sns_topic_arn = module.multi_account_cost_anomaly_detector.sns_topic_arn

  tags = {
    key                = "value"
    "caylent:owner"    = "manuel.palacios@caylent.com",
    "caylent:workload" = "cost"
  }
}