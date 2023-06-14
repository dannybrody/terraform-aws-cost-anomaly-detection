terraform {
  required_version = "~> 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~>0.48"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
    archive = {
      source = "hashicorp/archive"
      version = "2.4.0"
    }
  }
}