variable "threshold_type" {
  description = "especify if the alert with trigger based on a total amount or a percentage"
  type        = string

  validation {
    condition     = contains(["AMOUNT", "PERCENT"], var.threshold_type)
    error_message = "threshold_type must be AMOUNT or PERCENT"
  }
}
variable "cost_threshold" {
  description = "Defines the value to trigger an alert"
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
