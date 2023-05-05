locals {
  slack_integration = var.sns_topic_arn != "" || var.enable_slack_integration == false ? 0 : 1
  multi_account = length(var.accounts) == 0 ? false : true
}