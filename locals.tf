locals {
  slack_integration        = var.sns_topic_arn != "" || var.enable_slack_integration == false ? 0 : 1
  ms_teams_integration     = var.sns_topic_arn != "" || var.enable_ms_teams_integration == false ? 0 : 1
  chatbot_integration_role = var.enable_slack_integration || var.enable_ms_teams_integration ? 1 : 0
  multi_account            = length(var.accounts) == 0 ? false : true
  deploy_lambda            = var.deploy_lambda ? 1 : 0
}
