output "proxmox_version" {
  description = "Proxmox version information"
  value       = data.proxmox_virtual_environment_version.version
}

