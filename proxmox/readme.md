# Production Grade Proxmox setup

The goal of this test template is to roll out a production ready proxmox environment using stackweaver. Since stackweaver is only the orchestraton backend this configuration can be packed into a module later for production usage is I ever find myself in need of this.

## Architecture

I'll try to shoot for the best security / automation I can possibly get out of this [community provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

### 2 phase design

1. Use password based auth to bootstrap service account with api key and correct access rights found in [passwd](./passwd/) folder
2. Use the configured service account to create a production ready VM deployment setup using cloud init integration and ubuntu cloud vms or maybe even arch depending on the cloud init integration there. Use the following resources to get a lay of the land:
 - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file
 - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-init
 - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm

### FreeBSD ISOs and automation

The [module](./module/) downloads FreeBSD amd64 ISOs from `download.freebsd.org` using the rigid path scheme (`/releases/ISO-IMAGES/{version}/`) and verifies them with the official `CHECKSUM.SHA256-FreeBSD-{version}-RELEASE-amd64` file.

**→ Full analysis:** [docs/FREEBSD-AUTOMATION.md](./docs/FREEBSD-AUTOMATION.md) — cloud-init (layout, daemons, datasources, NoCloud, debugging), Packer **Proxmox vs QEMU** (proxmox-iso, proxmox-clone, when to use which), and end-to-end workflows for extensive automation.

**Short version:** Cloud-init works on FreeBSD 14.1+; the [Proxmox Packer plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox) (proxmox-iso, proxmox-clone) produces templates directly in PVE with optional `cloud_init = true`. QEMU builder outputs local images you can import into Proxmox or other backends.
