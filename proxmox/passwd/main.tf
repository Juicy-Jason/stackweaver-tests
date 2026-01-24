# Provider initially needs to use a password based authentication to configure the token auth

# Get the PVEAdmin role
# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/virtual_environment_role
data "proxmox_virtual_environment_role" "pve_admin_role" {
  role_id = "PVEAdmin"
}

# Create the terraform service account
# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_user
resource "proxmox_virtual_environment_user" "operations_automation" {
  acl {
    path      = "/"
    propagate = true
    role_id   = data.proxmox_virtual_environment_role.pve_admin_role.role_id
  }

  comment  = "Terraform service account"
  # password = "a-strong-password" - no password since we will be using token based auth
  user_id  = "tf-sa@pve"
}

# Create a token for the Terraform service account
# registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_user_token
resource "proxmox_virtual_environment_user_token" "main_terraform_token" {
  depends_on = [proxmox_virtual_environment_user.operations_automation]
  user_id    = "tf-sa@pve"
  token_name = "terraform"
  
  # Optional settings
  comment            = "Token for Terraform automation"
  expiration_date    = "2026-12-31T23:59:59Z"
  privileges_separation = true  # Important: enables privilege separation
}

# Token ACL: root path. PVEAdmin on / provides Sys.Audit and Sys.Modify, which are required
# for proxmox_virtual_environment_download_file (download from URL) in addition to Datastore.AllocateTemplate.
# Reference: https://forum.proxmox.com/threads/what-privilege-for-download-from-url-iso-storage.126884/
# Reference: https://github.com/bpg/terraform-provider-proxmox/issues/1439
# IMPORTANT: If you do not use the user_token resource above, create the token in the UI first
# (Permissions -> API Tokens -> add -> select user, set an ID, toggle privilege separation).
resource "proxmox_virtual_environment_acl" "terraform_sa_admin_acl" {
  depends_on = [proxmox_virtual_environment_user_token.main_terraform_token]
  path      = "/"                       # Sys.Audit, Sys.Modify required on / for download-from-URL
  role_id   = "PVEAdmin"
  token_id  = proxmox_virtual_environment_user_token.main_terraform_token.id
  propagate = true
}

# Token ACL: storage path for download_from_url (proxmox_virtual_environment_download_file).
# Datastore.AllocateTemplate on /storage/{id} is required. Use /storage/local for the "local" datastore;
# if you use others (e.g. local-lvm), add an ACL for /storage/<datastore_id>.
resource "proxmox_virtual_environment_acl" "terraform_sa_storage_local" {
  depends_on = [proxmox_virtual_environment_user_token.main_terraform_token]
  path      = "/storage/local"
  role_id   = "PVEAdmin"                # Includes Datastore.AllocateTemplate
  token_id  = proxmox_virtual_environment_user_token.main_terraform_token.id
  propagate = true
}

resource "proxmox_virtual_environment_acl" "terraform_sa_storage_local_lvm" {
  depends_on = [proxmox_virtual_environment_user_token.main_terraform_token]
  path      = "/storage/local-lvm"
  role_id   = "PVEAdmin"                # Includes Datastore.AllocateTemplate
  token_id  = proxmox_virtual_environment_user_token.main_terraform_token.id
  propagate = true
}