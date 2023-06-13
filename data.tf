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

data "aws_iam_policy_document" "inline_policy" {

  statement {
    actions = [
      "ce:ListSavingsPlansPurchaseRecommendationGeneration",
      "ce:ListCostAllocationTags",
      "ce:GetCostAndUsage",
      "ce:ListCostCategoryDefinitions",
      "ce:GetCostForecast"
    ]
    resources = [
      "arn:aws:ce:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/GetCostAndUsage",
      "arn:aws:ce:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/GetCostForecast"
    ]
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

data "archive_file" "lambda_deployment_package" {
  depends_on       = [null_resource.pip_installation]
  type             = "zip"
  source_dir       = "${path.module}/lambda"
  output_path      = "${path.module}/cost_monitor.zip"
  output_file_mode = "0666"
}
