terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
  }
  required_version = ">= 1.5.7"
}

terraform {
  backend "s3" {
    bucket         = "catdevsecops-terraform-state"
    key            = "bootstrap/cluster.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "talos" {}
