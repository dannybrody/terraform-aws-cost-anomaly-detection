terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "manuel-palacios/"
    key    = "state/cost_anomaly.tfstate"
  }
}