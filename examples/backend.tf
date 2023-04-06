terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "tfstate-jmpcba/"
    key    = "cost_anomaly_detector/cost_anomaly_detector.tfstate"
  }
}