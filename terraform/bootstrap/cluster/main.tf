data "talos_image_factory_extensions_versions" "this" {
  # get the latest talos version
  talos_version = var.talos_version
  filters = {
    names = [
      "ecr-credential-provider",
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
  talos_version = var.talos_version
  filters = {
    name = "rpi_generic"
  }
}


resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      overlay = {
        image = data.talos_image_factory_overlays_versions.this.overlays_info[0].image
        name  = data.talos_image_factory_overlays_versions.this.overlays_info[0].name
      }

      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

