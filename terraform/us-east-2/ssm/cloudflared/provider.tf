terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
  }
  required_version = ">= 1.14"
}

provider "aws" {
  region = "us-east-2"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
