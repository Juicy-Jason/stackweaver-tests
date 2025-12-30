# # Simple data source to test Proxmox connectivity - using version for simplicity
# data "proxmox_virtual_environment_version" "version" {}

# Simple resource creation - add a hosts entry
resource "proxmox_virtual_environment_hosts" "test_entry" {
  node_name = "test-node"
  entry {
    address  = "192.168.1.100"
    hostnames = ["test-terraform.local"]
  }
}

# # Output the version to verify it works
# output "proxmox_version" {
#   value = data.proxmox_virtual_environment_version.version
# }