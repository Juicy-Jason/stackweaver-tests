# Use the shared module for test resources
module "proxmox_test" {
  source = "../module"

  node_name = var.proxmox_node
}

# Output the version to verify it works
output "proxmox_version" {
  value = module.proxmox_test.proxmox_version
}