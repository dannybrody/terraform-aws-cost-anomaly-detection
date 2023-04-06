module "cost_anomaly_detector" {
  source             = "../"
  cost_threshold     = 10
  threshold_type     = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id

  tags = {
    key = "value"
    "caylent:owner" = "manuel.palacios@caylent.com",
	"caylent:workload"= "cost"
  }
}