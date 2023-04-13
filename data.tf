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
