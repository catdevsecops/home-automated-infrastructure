data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = "v1.12.6"
  filters = {
    names = [
      "cloudflared",
      "ecr-credential-provider",
      "zfs"
    ]
  }
}

data "talos_image_factory_urls" "this" {
  talos_version = "v1.12.6"
  schematic_id  = talos_image_factory_schematic.this.id
  architecture  = "arm64"
  sbc           = "rpi_generic"
}


data "talos_image_factory_overlays_versions" "this" {
  # get the latest talos version
  talos_version = "v1.12.6"
  filters = {
    name = "rpi_generic"
  }
}




resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      overlay = {
        image = one(data.talos_image_factory_overlays_versions.this.overlays_info.*.image)
        name  = one(data.talos_image_factory_overlays_versions.this.overlays_info.*.name)
      }

      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}


output "schematic_id" {
  value = talos_image_factory_schematic.this.id
}

