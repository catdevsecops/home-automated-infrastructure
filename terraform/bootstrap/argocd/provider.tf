terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.40.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
  }
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket       = "catdevsecops-terraform-state"
    key          = "bootstrap/argocd.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }

}

provider "aws" {
  region = "us-east-2"
}

provider "helm" {
  kubernetes = {
  }
}
