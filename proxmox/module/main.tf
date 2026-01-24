# Simple data source to test Proxmox connectivity
data "proxmox_virtual_environment_version" "version" {}

# Resolve latest Debian amd64 netinst ISO from cdimage.debian.org directory listing.
# See get-debian-netinst-url.sh (matches debian-MAJOR.MINOR.PATCH-amd64-netinst.iso; "current" = latest stable).
data "external" "debian_netinst" {
  program = ["sh", "${path.module}/get-debian-netinst-url.sh"]
}

# Download an ISO file to the local datastore
# This resource downloads files from a URL to a Proxmox datastore
# The datastore must have at least 10GB free space
# Reference: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file
resource "proxmox_virtual_environment_download_file" "test_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name
  url          = data.external.debian_netinst.result.iso_url
  file_name    = data.external.debian_netinst.result.iso_filename

  # Optional: Verify the download (set to true to verify checksums if available)
  verify = false
}

# Test resource: Create a Pool for testing
# Pools are logical groupings of VMs/resources in Proxmox
# Reference: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_pool
resource "proxmox_virtual_environment_pool" "test_pool" {
  comment = "Test pool created by StackWeaver"
  pool_id = var.pool_id
}