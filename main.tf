resource "aws_sns_topic" "cost_anomaly_topic" {
  name              = "CostAnomalyUpdates"
  kms_master_key_id = data.aws_kms_key.SNS_KMS_key.arn
  tags              = var.tags
}

data "aws_iam_policy_document" "sns_topic_policy_document" {
  policy_id = "__default_policy_ID"

  statement {
    sid = "AWSAnomalyDetectionSNSPublishingPermissions"

    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.cost_anomaly_topic.arn,
    ]
  }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn = aws_sns_topic.cost_anomaly_topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy_document.json
}

resource "aws_ce_anomaly_monitor" "anomaly_monitor" {
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  tags              = var.tags
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription" {
  name = "RealtimeAnomalySubscription"
  threshold_expression {
    dimension {
      key           = local.threshold_expression_key
      values        = [var.cost_threshold]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.anomaly_monitor.arn,
  ]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomaly_topic.arn
  }

  depends_on = [
    aws_sns_topic_policy.sns_topic_policy,
  ]
  tags = var.tags
}


resource "awscc_chatbot_slack_channel_configuration" "chatbot_slack_channel" {
  count              = var.enable_slack_integration ? 1 : 0
  configuration_name = "cost-anomaly-alerts"
  iam_role_arn       = data.aws_iam_role.chatbot_service_role.arn
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  guardrail_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess", ]
  sns_topic_arns     = [aws_sns_topic.cost_anomaly_topic.arn, ]
}