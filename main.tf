resource "aws_sns_topic" "cost_anomaly_topic" {
  name              = "${var.name}-topic"
  kms_master_key_id = var.SNS_KMS_key
  tags              = var.tags
}

data "aws_iam_policy_document" "sns_topic_policy_document" {
  policy_id = "${var.name}-policy-ID"

  statement {
    sid = "${var.name}-SNS-publishing-permissions"

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
  name              = var.name
  monitor_type      = "DIMENSIONAL" # recommended by AWS 
  monitor_dimension = "SERVICE" # recommended by AWS
  tags              = var.tags
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription" {
  name = "${var.name}-subscription"
  threshold_expression {
    dimension {
      key           = var.threshold_type
      values        = [var.cost_threshold]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  frequency = "IMMEDIATE" # required for alerts sent to SNS

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
  configuration_name = "${var.name}-slack-config"
  iam_role_arn       = data.aws_iam_role.chatbot_service_role.arn
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  guardrail_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess", ]
  sns_topic_arns     = [aws_sns_topic.cost_anomaly_topic.arn]
}