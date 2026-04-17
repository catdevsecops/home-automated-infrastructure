data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket       = "catdevsecops-terraform-state"
    key          = "bootstrap/cluster.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}



# ---------------------------------------------------------------------------
# Controlplane machineconfigs
# ---------------------------------------------------------------------------
data "talos_machine_configuration" "controlplane" {
  for_each = var.controlplane_nodes

  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version

  config_patches = [local.general_patch, local.machinename_controlplane_patch[each.key]]
}

# ---------------------------------------------------------------------------
# Worker machineconfigs
# ---------------------------------------------------------------------------
data "talos_machine_configuration" "worker" {
  for_each = var.worker_nodes

  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = var.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version

  config_patches = [local.machinename_workers_patch[each.key], local.general_patch]
}

