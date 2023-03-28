terraform {
  backend "s3" {
    bucket = "tfstate-jmpcba"
    key    = "cost_anomaly_detector/cost_anomaly_detector.tfstate"
    region = "us-east-1"
  }
}