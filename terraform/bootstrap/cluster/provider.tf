terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
  }
  required_version = ">= 1.14"

  backend "s3" {
    bucket       = "catdevsecops-terraform-state"
    key          = "bootstrap/cluster.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "talos" {}
