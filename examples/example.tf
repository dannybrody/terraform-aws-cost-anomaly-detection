module "cost_anomaly_detector" {
  source             = "git@github.com:caylent/terraform-aws-cost-anomaly-detection.git"
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