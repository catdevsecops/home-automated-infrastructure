data "terraform_remote_state" "operator" {
  backend = "s3"

  config = {
    bucket       = "catdevsecops-terraform-state"
    key          = "global/roles/secrets-manager.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}

