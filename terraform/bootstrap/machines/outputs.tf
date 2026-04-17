output "controlplane_config" {
  sensitive = true
  value = {
    for k, config in data.talos_machine_configuration.controlplane : k => config.machine_configuration
  }
}

output "workers_config" {
  sensitive = true
  value = {
    for k, config in data.talos_machine_configuration.worker : k => config.machine_configuration
  }
}


output "kubeconfig" {
  sensitive = true
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
}

output "talosconfig" {
  sensitive = true
  value     = talos_machine_secrets.this.client_configuration

}
