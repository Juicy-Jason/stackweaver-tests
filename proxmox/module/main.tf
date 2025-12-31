# Simple data source to test Proxmox connectivity
data "proxmox_virtual_environment_version" "version" {}

# Download an ISO file to the local datastore
# This resource downloads files from a URL to a Proxmox datastore
# The datastore must have at least 10GB free space
# Reference: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file
resource "proxmox_virtual_environment_download_file" "test_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name
  url          = var.iso_url
  file_name    = var.iso_filename

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

# Test resource: Create a token ACL (matching what works in UI)
# The UI shows token ACLs work (root@pam!tf), so let's test with a token
# Reference: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_acl
resource "proxmox_virtual_environment_acl" "test_acl" {
  path      = "/"                       # Use / path for full access
  role_id   = "PVEAdmin"                # Admin role on / path
  token_id  = "root@pam!tf"             # Use the same token that works in UI
  propagate = false
}