locals {
  schematic_id = data.terraform_remote_state.cluster.outputs.schematic_id


  machinename_workers_patch = { for w, ip in var.worker_nodes : w => yamlencode({
    apiVersion = "v1alpha1"
    kind       = "HostnameConfig"
    hostname   = w
    auto       = "off"
    })
  }
  machinename_controlplane_patch = { for cp, ip in var.controlplane_nodes : cp =>
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      hostname   = cp
      auto       = "off"
    })
  }
  general_patch = yamlencode({
    machine = {
      features = {
        kubePrism = {
          enabled = true
          port : 7445
        }
      }
      install = {
        image = "factory.talos.dev/nocloud-installer/${local.schematic_id}:${var.talos_version}"
        disk  = "/dev/mmcblk0"
      }
      network = {
        interfaces = [{
          interface = "eth0"
          dhcp      = true
        }]
      }
    }
  })
}

