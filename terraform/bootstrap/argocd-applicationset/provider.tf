terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
  }
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket       = "catdevsecops-terraform-state"
    key          = "bootstrap/argocd-applicationset.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }

}

provider "kubernetes" {
  config_path = "~/.kube/config"
}


