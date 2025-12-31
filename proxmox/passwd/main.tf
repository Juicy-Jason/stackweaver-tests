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
  user_id    = "tf-sa@pve"
  token_name = "terraform"
  
  # Optional settings
  comment            = "Token for Terraform automation"
  expiration_date    = "2026-12-31T23:59:59Z"
  privileges_separation = true  # Important: enables privilege separation
}

# Test resource: Create a token ACL (matching what works in UI) - once we have this rights we can switch to a token based provider configuration
# IMPORTANT: if you don't use the user_token resource above you need to manually create the token in the UI first
# - Go to the Proxmox UI -> Permissions -> API Tokens -> add -> select user, set an ID and toggle privilege separation
# Reference: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_acl
resource "proxmox_virtual_environment_acl" "terraform_sa_admin_acl" {
  path      = "/"                       # Use / path for full access
  role_id   = "PVEAdmin"                # Admin role on / path
  token_id  = proxmox_virtual_environment_user_token.main_terraform_token.id
  propagate = false
}