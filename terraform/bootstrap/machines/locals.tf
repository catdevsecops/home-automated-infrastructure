locals {
  schematic_id = data.terraform_remote_state.cluster.outputs.schematic_id

  machinename_workers_patch = { for w, ip in var.worker_nodes : w => yamlencode({
    apiVersion = "v1alpha1"
    kind       = "HostnameConfig"
    hostname   = w
    auto       = "off"
    })
  }

  machinename_workers_kubelet_patch = { for cp, ip in var.worker_nodes : cp =>
    yamlencode({
      machine = {
        kubelet = {
          extraMounts = [
            {
              destination = "/var/lib/dind"
              source : "/var/mnt/dind"
              type    = "bind"
              options = ["bind", "rw", "rshared"]
            },
            {
              destination = "/var/lib/traefik"
              source : "/var/mnt/traefik"
              type    = "bind"
              options = ["bind", "rw", "rshared"]
            },
            {
              destination = "/var/lib/postgres-data"
              source : "/var/mnt/postgres-data"
              type    = "bind"
              options = ["bind", "rw", "rshared"]
            },
            {
              destination = "/var/lib/prometheus-data"
              source : "/var/mnt/prometheus-data"
              type    = "bind"
              options = ["bind", "rw", "rshared"]
            },

          ]
          extraArgs = {
            rotate-server-certificates = true
            address : "0.0.0.0"
            node-ip : ip
          }
        }
      }
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

  machinename_controlplane_kubelet_patch = { for cp, ip in var.controlplane_nodes : cp =>
    yamlencode({
      machine = {
        certSANs = [
          "10.10.15.9",
          "10.10.15.10",
          "10.10.15.11",
          "athos.lan.skynet",
          "porthos.lan.skynet",
          "aramis.lan.skynet",
          "127.0.0.1",
          "skynet.cavaleiro.in",
          "skynet.internal.cavaleiro.in"
        ]
        kubelet = {
          extraArgs = {
            rotate-server-certificates = true
            address : "0.0.0.0"
            node-ip : ip
          }
        }
      }
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

