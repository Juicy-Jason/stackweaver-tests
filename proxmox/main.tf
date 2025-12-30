# Simple data source to test Proxmox connectivity
data "proxmox_virtual_environment_nodes" "nodes" {}

# Output the node names to verify it works
output "proxmox_nodes" {
  value = data.proxmox_virtual_environment_nodes.nodes.node_names
}
