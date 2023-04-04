terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "0.48.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}