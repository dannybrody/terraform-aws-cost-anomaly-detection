resource "aws_sns_topic" "cost_anomaly_topic" {
  count = var.sns_topic_arn == "" ? 1 : 0
  name  = "${var.name}-topic"
  tags  = var.tags
}

data "aws_iam_policy_document" "sns_topic_policy_document" {
  count     = var.sns_topic_arn == "" ? 1 : 0
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
      aws_sns_topic.cost_anomaly_topic[0].arn,
    ]
  }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  count = var.sns_topic_arn == "" ? 1 : 0
  arn   = aws_sns_topic.cost_anomaly_topic[count.index].arn

  policy = data.aws_iam_policy_document.sns_topic_policy_document[count.index].json
}

resource "aws_ce_anomaly_monitor" "service_anomaly_monitor" {
  count             = var.multi_account ? 0 : 1
  name              = var.name
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  tags              = var.tags
}

resource "aws_ce_anomaly_monitor" "linked_account_anomaly_monitor" {
  count        = var.multi_account ? 1 : 0
  name         = var.name
  monitor_type = "CUSTOM"
  monitor_specification = jsonencode(
    {
      # Do not remove null values. Otherwise TF will recreate the monitor on each apply
      And            = null
      CostCategories = null
      Dimensions = {
        Key          = "LINKED_ACCOUNT"
        MatchOptions = null
        Values       = var.accounts
      }
      Not  = null
      Or   = null
      Tags = null
    }
  )
  tags = var.tags
  lifecycle {
    precondition {
      condition = length(var.accounts) > 0
      error_message = "If multi_account is true, accounts can't be empty"
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription" {
  name = "${var.name}-subscription"
  threshold_expression {
    dimension {
      key           = var.threshold_type
      values        = [var.alert_threshold]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  frequency = "IMMEDIATE" # required for alerts sent to SNS

  monitor_arn_list = [
    var.multi_account ? aws_ce_anomaly_monitor.linked_account_anomaly_monitor[0].arn : aws_ce_anomaly_monitor.service_anomaly_monitor[0].arn,
  ]

  subscriber {
    type    = "SNS"
    address = var.sns_topic_arn == "" ? aws_sns_topic.cost_anomaly_topic[0].arn : var.sns_topic_arn
  }

  depends_on = [
    aws_sns_topic_policy.sns_topic_policy, aws_sns_topic.cost_anomaly_topic
  ]
  tags = var.tags
}


resource "awscc_chatbot_slack_channel_configuration" "chatbot_slack_channel" {
  count              = var.enable_slack_integration ? 1 : 0
  configuration_name = "${var.name}-slack-config"
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id
  guardrail_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess", ]
  sns_topic_arns     = [var.sns_topic_arn == "" ? aws_sns_topic.cost_anomaly_topic[count.index].arn : var.sns_topic_arn]
}

data "aws_iam_policy_document" "chatbot_channel_policy_document" {
  statement {
    actions = [
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "sns:Unsubscribe",
      "sns:Subscribe",
      "sns:ListSubscriptions"
    ]
    resources = [var.sns_topic_arn == "" ? aws_sns_topic.cost_anomaly_topic[0].arn : var.sns_topic_arn]
  }
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/chatbot/*"]
  }
}

resource "aws_iam_policy" "chatbot_channel_policy" {
  name   = "${var.name}-channel-policy"
  policy = data.aws_iam_policy_document.chatbot_channel_policy_document.json
}


data "aws_iam_policy_document" "chatbot_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["management.chatbot.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "chatbot_role" {
  name               = "${var.name}-chatbot-role"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "chatbot_role_attachement" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = aws_iam_policy.chatbot_channel_policy.arn
}