# Simple data source to test Proxmox connectivity
data "proxmox_virtual_environment_version" "version" {}

# Test resource: Add an APT repository to a Proxmox node
# This doesn't require any VMs to be present
resource "proxmox_virtual_environment_apt_repository" "test_repo" {
  enabled   = true
  file_path = "/etc/apt/sources.list.d/test-terraform.list"
  index     = 0
  node      = var.node_name

  content = <<-EOT
    deb http://deb.debian.org/debian bookworm main
  EOT
}