locals {
  threshold_expression_key = var.threshold_type == "AMOUNT" ? "ANOMALY_TOTAL_IMPACT_ABSOLUTE" : "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
}