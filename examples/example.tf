# Module configuration to setup an absolute impact monitor for one account
# This is the config recommended by AWS
module "service_cost_anomaly_detector" {
  source             = "github.com/caylent/terraform-aws-cost-anomaly-detection.git?ref=v1.2.0"
  alert_threshold    = 20 # $20, because threshold_type is ANOMALY_TOTAL_IMPACT_ABSOLUTE
  threshold_type     = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id

  tags = {
    key                = "value"
    "caylent:owner"    = "manuel.palacios@caylent.com",
    "caylent:workload" = "cost"
  }
}


# Module configuration to setup an absolute impact monitor for several accounts
# Must be deployed on the root account to work
module "multi_account_cost_anomaly_detector" {
  source             = "github.com/caylent/terraform-aws-cost-anomaly-detection.git?ref=v1.2.0"
  alert_threshold    = 10 # 10%, because threshold_type is ANOMALY_TOTAL_IMPACT_PERCENTAGE
  threshold_type     = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
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