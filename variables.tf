variable "threshold_type" {
  description = "especify if the alert with trigger based on a total amount or a percentage"
  type        = string

  validation {
    condition     = contains(["ANOMALY_TOTAL_IMPACT_ABSOLUTE", "ANOMALY_TOTAL_IMPACT_PERCENTAGE"], var.threshold_type)
    error_message = "threshold_type must be  ANOMALY_TOTAL_IMPACT_ABSOLUTE for an alert based on absolute value or ANOMALY_TOTAL_IMPACT_PERCENTAGE for a percentage alert"
  }
}
variable "cost_threshold" {
  description = "Defines the value to trigger an alert depending on the value chosen for the threshold_type variable, it will represent a percentage or an actual cost increase"
  type        = number
}

variable "slack_channel_id" {
  description = "right click on the channel name, copy channel URL, and use the letters and number after the last /"
  type        = string
}

variable "slack_workspace_id" {
  description = "ID of your slack slack_workspace_id"
  type        = string
}

variable "enable_slack_integration" {
  description = "If false, the module will create an SNS topic without an slack channel integration. Use it when another subscriber to the SNS topic is preffered"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "name for the monitors, topic, etc"
  type        = string
  default     = "cost-Anomaly-monitor"
}

variable "SNS_KMS_key" {
  description = "id of the KMS key to encrypt SNS messages"
  type        = string
  default     = "alias/aws/sns"
}

variable "sns_topic_arn" {
  description = "ARN of an already existing SNS topic to send alerts"
  type = string
  default = ""
}
