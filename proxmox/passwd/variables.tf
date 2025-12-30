variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "proxmox_username" {
  description = "Proxmox username"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}