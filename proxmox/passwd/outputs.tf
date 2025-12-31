# Output the token secret so we can use it to configure the token based provider (only available on creation)
output "token_value" {
  value     = proxmox_virtual_environment_user_token.main_terraform_token.value
  sensitive = true
}