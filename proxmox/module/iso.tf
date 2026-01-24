# --- Debian ---
# Resolve latest Debian amd64 netinst ISO from cdimage.debian.org directory listing.
# See get-debian-netinst-url.sh (matches debian-MAJOR.MINOR.PATCH-amd64-netinst.iso; "current" = latest stable).
data "external" "debian_netinst" {
  program = ["sh", "${path.module}/get-debian-netinst-url.sh"]
}

# Download Debian netinst ISO to the local datastore.
# Reference: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file
resource "proxmox_virtual_environment_download_file" "test_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name
  url          = data.external.debian_netinst.result.iso_url
  file_name    = data.external.debian_netinst.result.iso_filename
  verify       = false
}

# --- FreeBSD ---
# Resolve FreeBSD amd64 ISO URL and SHA256 from the official CHECKSUM file.
# Rigid scheme: https://download.freebsd.org/releases/ISO-IMAGES/{version}/
# and CHECKSUM.SHA256-FreeBSD-{version}-RELEASE-amd64
data "external" "freebsd_iso" {
  program = ["sh", "${path.module}/get-freebsd-iso-url.sh", var.freebsd_version, var.freebsd_image_type]
}

# Download FreeBSD amd64 ISO with SHA256 verification from the official CHECKSUM.
resource "proxmox_virtual_environment_download_file" "freebsd_iso" {
  content_type        = "iso"
  datastore_id        = "local"
  node_name           = var.node_name
  url                 = data.external.freebsd_iso.result.iso_url
  file_name           = data.external.freebsd_iso.result.iso_filename
  checksum            = data.external.freebsd_iso.result.sha256
  checksum_algorithm  = "sha256"
}