variable "node_name" {
  description = "Proxmox node name where the test resource will be created"
  type        = string
  default     = "pve"
}

# this url changes each time there is a new stable so go to https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ and copy the link from there if the one provided no longer works
variable "iso_url" {
  description = "URL of the ISO file to download"
  type        = string
  default     = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.2.0-amd64-netinst.iso"
}

variable "iso_filename" {
  description = "Filename for the downloaded ISO"
  type        = string
  default     = "debian-13.2.0-amd64-netinst.iso"
}

variable "pool_id" {
  description = "Pool ID for the test pool"
  type        = string
  default     = "stackweaver-pool"
}

