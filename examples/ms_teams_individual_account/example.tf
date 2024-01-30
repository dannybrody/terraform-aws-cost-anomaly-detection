# Module configuration to setup an absolute impact monitor for one account
# This is the config recommended by AWS and should be used on the accounts considerered critical and most used by teams
module "service_cost_anomaly_detector" {
  # source             = "github.com/caylent/terraform-aws-cost-anomaly-detection.git?ref=v1.3.0"
  source                      = "../../"
  alert_threshold             = 20 # $20, because threshold_type is ANOMALY_TOTAL_IMPACT_ABSOLUTE
  threshold_type              = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
  enable_slack_integration    = false
  enable_ms_teams_integration = true
  team_id                     = var.team_id
  teams_channel_id            = var.teams_channel_id
  teams_tenant_id             = var.teams_tenant_id
  deploy_lambda               = true

  tags = {
    key                = "value"
    "caylent:owner"    = "manuel.palacios@caylent.com",
    "caylent:workload" = "cost"
  }
}
