# Simple data source to test Proxmox connectivity
data "proxmox_virtual_environment_version" "version" {}

# Test resource: Create a Pool for testing
# Pools are logical groupings of VMs/resources in Proxmox
# Reference: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_pool
resource "proxmox_virtual_environment_pool" "test_pool" {
  comment = "Test pool created by StackWeaver"
  pool_id = var.pool_id
}