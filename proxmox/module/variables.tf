variable "node_name" {
  description = "Proxmox node name where the test resource will be created"
  type        = string
  default     = "pve"
}

# Latest Debian amd64 netinst ISO URL and filename are resolved at plan time
# via get-debian-netinst-url.sh (fetches cdimage directory listing; works for 13.x, 14.x, etc.).

variable "pool_id" {
  description = "Pool ID for the test pool"
  type        = string
  default     = "stackweaver-pool"
}

