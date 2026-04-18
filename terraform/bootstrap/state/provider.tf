terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.40.0"
    }
  }
  required_version = ">= 1.6"
}

provider "aws" {
  region = "us-east-2"
}
