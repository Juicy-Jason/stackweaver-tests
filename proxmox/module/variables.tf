variable "node_name" {
  description = "Proxmox node name where the test resource will be created"
  type        = string
  default     = "pve"
}

# Latest Debian amd64 netinst ISO URL and filename are resolved at plan time
# via get-debian-netinst-url.sh (fetches cdimage directory listing; works for 13.x, 14.x, etc.).

variable "freebsd_version" {
  description = "FreeBSD release version for amd64 ISO (e.g. 15.0). Used in the rigid download.freebsd.org path."
  type        = string
  default     = "15.0"
}

variable "freebsd_image_type" {
  description = "FreeBSD amd64 image type: bootonly (minimal, network install), disc1, or dvd1."
  type        = string
  default     = "bootonly"
}

variable "pool_id" {
  description = "Pool ID for the test pool"
  type        = string
  default     = "stackweaver-pool"
}

