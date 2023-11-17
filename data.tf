data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

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
      "*"
    ]
  }
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

data "aws_iam_policy_document" "lambda_policy" {

  statement {
    actions = [
      "ce:ListSavingsPlansPurchaseRecommendationGeneration",
      "ce:ListCostAllocationTags",
      "ce:GetCostAndUsage",
      "ce:ListCostCategoryDefinitions",
      "ce:GetCostForecast"
    ]
    # AWS recommendation to allow IAM users to use the AWS Cost Explorer API
    # https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-example-policies.html#example-policy-ce-api
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
    ]
  }
  statement {
    actions = [
      "SNS:Publish",
    ]

    resources = [
      var.sns_topic_arn != "" ? var.sns_topic_arn : aws_sns_topic.cost_anomaly_topic[0].arn
    ]
  }
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

data "archive_file" "lambda_deployment_package" {
  type             = "zip"
  source_dir       = "${path.module}/src"
  output_path      = "${path.module}/cost_monitor.zip"
  output_file_mode = "0666"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}