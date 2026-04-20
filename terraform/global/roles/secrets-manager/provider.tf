terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
  }
  required_version = ">= 1.14"

  backend "s3" {
    bucket       = "catdevsecops-terraform-state"
    key          = "global/roles/secrets-manager/machines.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "us-east-2"
}
