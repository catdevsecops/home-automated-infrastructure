# Generates cluster PKI + secrets and persists them in state.
# WARNING: destroying this resource forces a full cluster rebuild.
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}


resource "talos_machine_configuration_apply" "controlplanes" {
  for_each                    = var.controlplane_nodes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[each.key].machine_configuration
  node                        = each.value
}

resource "talos_machine_configuration_apply" "workers" {
  for_each                    = var.worker_nodes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
  node                        = each.value
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplanes
  ]
  node                 = lookup(var.controlplane_nodes, "athos", "10.10.15.9")
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = lookup(var.controlplane_nodes, "athos", "10.10.15.9")
}
