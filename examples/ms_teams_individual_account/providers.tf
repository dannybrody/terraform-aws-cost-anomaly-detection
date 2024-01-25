terraform {
  required_version = "~> 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 0.68"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}