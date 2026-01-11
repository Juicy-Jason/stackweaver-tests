output "proxmox_version" {
  description = "Proxmox version information"
  value       = data.proxmox_virtual_environment_version.version
}

output "iso_file_path" {
  description = "Path to the downloaded ISO file"
  value       = proxmox_virtual_environment_download_file.test_iso.id
}output "pool_id" {
  description = "ID of the created pool"
  value       = proxmox_virtual_environment_pool.test_pool.pool_id
}