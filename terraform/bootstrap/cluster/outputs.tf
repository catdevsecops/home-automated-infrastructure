output "disk_image_url" {
  value = data.talos_image_factory_urls.this.urls.disk_image
}

output "schematic_id" {
  value = talos_image_factory_schematic.this.id
}
