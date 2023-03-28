data "aws_caller_identity" "current" {}

data "aws_kms_key" "SNS_KMS_key" {
  key_id = "alias/aws/sns"
}

data "aws_iam_role" "chatbot_service_role" {
  name = "AWSServiceRoleForAWSChatbot"
}