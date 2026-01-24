# FreeBSD Automation: Cloud-Init, Packer (Proxmox vs QEMU), and Proxmox Integration

A detailed analysis for extensive automation of FreeBSD on Proxmox VE: cloud-init, Packer builders (Proxmox vs QEMU), and end-to-end workflows. Assumes FreeBSD 14.1+ or 15.x and the ISOs from this repo’s [module](../module/) (`freebsd_iso`).

---

## 1. Cloud-Init on FreeBSD

### 1.1 Support and Installation

| FreeBSD | Cloud-init |
|--------|------------|
| **14.1+** | Native support; recommended. |
| **15.0** | Works; same as 14.1. |
| **&lt; 14.1** | Install from ports/packages: `pkg install -y py3*-cloud-init` (e.g. `py311-cloud-init`). |

Enable and start:

```sh
sysrc cloudinit_enable=YES
service cloudinit start
```

### 1.2 Layout and Daemons

Paths (FreeBSD/BSD-style):

| Path | Role |
|------|------|
| `/usr/local/etc/cloud/` | Config from package; vendor overrides in `cloud.cfg.d/` |
| `/usr/local/etc/cloud/cloud.cfg` | Modules, datasources, defaults |
| `/usr/local/etc/cloud/cloud.cfg.d/` | e.g. `05_logging.cfg`, `99_freebsd.cfg` |
| `/var/lib/cloud/` | Ephemeral data, datasource caches, instance data |
| `/var/run/cloud-init/` or `/run/cloud-init/` | Logs, `instance-data.json`, `combined-cloud-config.json` |

Daemons (run in order at boot):

| Order | Service | Command | Phase |
|-------|---------|---------|-------|
| 1 | `cloudinitlocal` | `cloud-init init --local` | Disks, network (early) |
| 2 | `cloudinit` | `cloud-init init` | Core, datasource, user-data |
| 3 | `cloudconfig` | `cloud-init modules --mode config` | Config modules |
| 4 | `cloudfinal` | `cloud-init --mode final` | Packages, scripts-user, etc. |

Modules only run if listed in `cloud_init_modules`, `cloud_config_modules`, or `cloud_final_modules` in `cloud.cfg`. Datasources must be in `datasource_list` or user-data will not be applied.

### 1.3 Datasources

- **NoCloud** – Local or HTTP. Best for Proxmox when you inject `user-data`/`meta-data` via a CD (cidata) or similar; no metadata server needed.
- **ConfigDrive**, **OpenStack**, **EC2**, **GCE**, **Azure**, etc. – Usable when the environment provides the right metadata.

For Proxmox + bpg provider you typically use **NoCloud** via the Cloud-Init drive (CD or disk) that Proxmox creates from the `cicustom`/cloud-init settings.

### 1.4 NoCloud for Local / HTTP Testing

Example `cloud.cfg.d/00_nocloud.cfg`:

```yaml
datasource_list: ["NoCloud", "None"]
datasource:
  NoCloud:
    seedfrom: file:///root/cloud/
network:
  config: disabled
  timeout: 1
```

Seed directory (e.g. `/root/cloud/`):

- `meta-data` – optional, instance-id etc.
- `user-data` – `#cloud-config` or other format.

`seedfrom` can also be `http://...` if you serve meta/user-data over HTTP.

### 1.5 Cloud-Config That Works (FreeBSD, 2024)

Practical, commonly working directives (tested on 24.1.x; your mileage may vary for edge cases):

- `users` – create users, `groups`, `ssh_authorized_keys`, `sudo`, `shell`
- `bootcmd` – early commands
- `write_files` – create files
- `runcmd` – late commands
- `packages` – `pkg install` (often `pkg`-style names, e.g. `www/nginx`)

Example:

```yaml
#cloud-config
users:
  - default
  - name: ansible
    groups: wheel
    shell: /bin/sh
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... your-key

bootcmd:
  - echo bootcmd | tee -a /root/cloud/cloudinit_was_here

write_files:
  - content: |
      writefiles
    path: /root/cloud/writefiles_was_here
    append: true

runcmd:
  - echo runcmd | tee -a /root/cloud/cloudinit_was_here

packages:
  - www/nginx
```

Reported limitations on some setups: `homedir` override, multiple groups via a single `groups` key. Prefer one group or multiple `groups:` entries as documented.

### 1.6 Debugging

- **Validate user-data:**  
  `cloud-init schema --annotate -c user-data`

- **Query merged user-data:**  
  `cloud-init query userdata`

- **Boot/phase analysis:**  
  `cloud-init analyze show`

- **Reset and re-run (destructive):**  
  `rm -rf /run/cloud-init /var/*/cloud*`  
  then `service cloudinit start` (or reboot). Does not undo already-created users, files, etc.

- **Logs / instance data:**  
  ` /var/lib/cloud/data/result.json`, `status.json`; `/var/run/cloud-init/instance-data.json`, `combined-cloud-config.json`.

### 1.7 Proxmox + Cloud-Init (bpg)

Once you have a FreeBSD VM or template **with cloud-init installed and enabled**:

- Use the [bpg Proxmox cloud-init guide](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-init).
- `proxmox_virtual_environment_vm` with `initialization` (user-data, SSH keys, IP config, etc.) works like on Linux; the guest must have cloud-init and a supported datasource (NoCloud for the Proxmox Cloud-Init CD).

---

## 2. Packer: Proxmox vs QEMU Builder

### 2.1 Overview

| Aspect | **QEMU** | **Proxmox (proxmox-iso / proxmox-clone)** |
|--------|----------|-------------------------------------------|
| **Plugin** | `hashicorp/qemu` (official) | `hashicorp/proxmox` (community, HashiCorp docs) |
| **Output** | File(s) on build host: `output_directory` with `qcow2` or `raw` | **Proxmox VM template** in a PVE datastore (cluster-wide) |
| **Where VM runs** | Local QEMU/KVM on the Packer host | **On a Proxmox node**; Packer drives PVE API |
| **Network** | User-mode, or `net_bridge` (e.g. `virbr0`) on the Packer host | Proxmox bridges, e.g. `vmbr0`; `network_adapters` with `bridge`, `vlan_tag`, etc. |
| **Storage** | Local paths; `disk_size`, `format` (qcow2/raw) | Proxmox `storage_pool` (e.g. `local-lvm`); `disks` with `storage_pool`, `disk_size`, `format` |
| **ISO** | `iso_url` + `iso_checksum`; Packer downloads and uses locally | `boot_iso` with `iso_file` (datastore path like `local:iso/xxx.iso`) or `iso_url`; can upload to PVE or `iso_download_pve` |
| **Communicator** | SSH/WinRM to VM on build host; port forward or bridge | SSH/WinRM to VM on **Proxmox**; Packer discovers IP from `vm_interface` (or QEMU guest agent) |
| **Cloud-init in template** | Manual: you copy image into Proxmox and attach Cloud-Init | **`cloud_init = true`**: adds empty Cloud-Init CD after convert-to-template; `cloud_init_storage_pool`, `cloud_init_disk_type` |
| **Build from existing image** | `disk_image` + optional `use_backing_file` | **`proxmox-clone`**: clone from cloud-init template, reprovision, convert to new template |

### 2.2 QEMU Builder (Summary)

- **Single builder:** `qemu`.
- **Role:** Build a KVM image on the **Packer host** (local QEMU).
- **Result:** Directory with `qcow2` or `raw` (and optional `efivars.fd` when UEFI).
- **Typical use:** Portable images; CI on a build server; then import into Proxmox, OpenStack, etc. yourself.

Important options (high level):

- `iso_url`, `iso_checksum` (or `iso_checksum = "file:..."`).
- `output_directory`, `format` (`qcow2`|`raw`), `disk_size`, `disk_interface` (e.g. `virtio`).
- `accelerator` (`kvm`, `tcg`, …).
- `http_directory` / `http_content` + `{{ .HTTPIP }}` / `{{ .HTTPPort }}` in `boot_command`.
- `boot_command`, `boot_wait`, `boot_steps` (or `boot_command`).
- `communicator` (SSH/WinRM), `ssh_*`, `winrm_*`.
- `net_device`, `net_bridge` (for real bridge).
- `headless`, `vnc_*`, `qemuargs`, `machine_type`, `cpus`/`sockets`/`cores`/`threads`.
- UEFI: `efi_boot`, `efi_firmware_code`, `efi_firmware_vars`.

**No** Proxmox API, no native “template” or “cloud-init CD” in PVE. You must:

1. Build the image with QEMU.
2. Copy/import into Proxmox (e.g. `qm importdisk`, create VM, convert to template).
3. Manually add a Cloud-Init drive (or CD) and configure the VM so PVE can inject user-data (e.g. via the Proxmox Cloud-Init UI or `qm set`).

### 2.3 Proxmox Builder: `proxmox-iso`

- **Type:** `proxmox-iso`.
- **Role:** Create a **new** VM on Proxmox from an **ISO**, install, provision, then **convert to template**. Result stays in PVE.

Required/important:

- `proxmox_url` (e.g. `https://host:8006/api2/json`), `username`, `password` or `token`, `insecure_skip_tls_verify` if needed.
- `node` (which PVE node to create the VM on).
- `boot_iso` (replaces deprecated `iso_file`/`iso_url` at top level):
  - `iso_file` (e.g. `local:iso/FreeBSD-15.0-RELEASE-amd64-bootonly.iso`) **or** `iso_url` + `iso_checksum`;
  - `type` (e.g. `scsi`), `unmount`, `iso_storage_pool` when uploading.

Optional (selection):

- `vm_id`, `vm_name`, `template_name`, `template_description`, `pool`, `tags`.
- `memory`, `ballooning_minimum`, `cores`, `sockets`, `cpu_type` (e.g. `host`), `numa`.
- `os` (e.g. `l26` for Linux 2.6+; FreeBSD often `other`).
- `machine` (`pc`|`q35`), `bios` (`seabios`|`ovmf`), `efi_config`.
- `disks`: `type`, `storage_pool`, `disk_size`, `format`, `cache_mode`, `io_thread`, `discard`, `ssd`, etc.
- `network_adapters`: `model` (e.g. `virtio`, `e1000`), `bridge`, `vlan_tag`, `firewall`, `mac_address`, `mtu`, `packet_queues`.
- `boot`, `qemu_agent`, `scsi_controller`, `onboot`, `disable_kvm`.
- **`cloud_init`**: set to `true` to add an **empty Cloud-Init CD** after conversion to template; `cloud_init_storage_pool`, `cloud_init_disk_type` (e.g. `ide`).
- `additional_iso_files` (e.g. VirtIO drivers, or a custom `cidata` ISO).
- `http_directory`, `http_content`, `http_port_min/max`, `http_bind_address`; `{{ .HTTPIP }}`, `{{ .HTTPPort }}` in `boot_command`.
- `boot_command`, `boot_wait`, `boot_key_interval`, `boot_keygroup_interval`.
- `cd_content` / `cd_files` + `cd_label` (second CD, e.g. for kickstart/autounattend or NoCloud `user-data`/`meta-data`).
- `rng0` (VirtIO RNG), `vga`, `serials`, `pci_devices`, `qemu_additional_args`.
- `vm_interface` (for Packer to find the VM’s IP); otherwise QEMU agent or first non-loopback.

ISO can come from:

- **Datastore:** `iso_file = "local:iso/FreeBSD-15.0-RELEASE-amd64-bootonly.iso"` (uploaded beforehand, e.g. by Terraform `proxmox_virtual_environment_download_file.freebsd_iso`).
- **URL:** `boot_iso { iso_url = "https://...", iso_checksum = "sha256:..." }`; Packer downloads; optional `iso_storage_pool` and `iso_download_pve` to have PVE pull the file.

### 2.4 Proxmox Builder: `proxmox-clone`

- **Type:** `proxmox-clone`.
- **Role:** **Clone** an existing **cloud-init VM template** in PVE, run provisioners, then convert the cloned VM to a **new template**. No ISO install step.

Required:

- `clone_vm` (name) or `clone_vm_id` (VMID).

Same optional blocks as `proxmox-iso` for CPUs, memory, network, disks, `cloud_init`, `efi_config`, `rng0`, etc. Disks in the config **replace** the cloned VM’s disks; omit `disks` to reuse.

Clone-specific:

- `full_clone` (default `true`).
- `nameserver`, `searchdomain`, `ipconfig` (Cloud-Init IP) for the **clone’s** Cloud-Init.

Use case: you already have a “golden” FreeBSD + cloud-init template (e.g. built once with `proxmox-iso` or imported). `proxmox-clone` then layers Ansible/shell/chef etc. and produces derived templates (e.g. app-specific) without reinstalling from ISO.

### 2.5 When to Use Which

| Goal | Builder |
|------|---------|
| Image for **Proxmox only**, want template + Cloud-Init CD in one step | `proxmox-iso` (and optionally `proxmox-clone` later) |
| Image for **multiple backends** (Proxmox, AWS, GCP, …) or **CI without PVE** | **QEMU**; then post-process/import into each target |
| **No Proxmox** at build time; only QEMU/KVM on a build server | **QEMU** |
| **Reuse existing PVE cloud-init template** and only add packages/config | `proxmox-clone` |
| **Full control** over `qemu`/`qemu-img` CLI | **QEMU** (`qemuargs`, `qemu_img_args`) |

### 2.6 FreeBSD-Specific Packer Notes

- **Communicator:** SSH. FreeBSD does not use WinRM. Ensure `sshd` is enabled and port is open after install; either in `bsdinstall`/post-install or via `boot_command` + `http_directory` script.
- **VirtIO:** Use `virtio` for network and, if possible, `virtio` or `virtio-scsi` for disks to avoid extra drivers. FreeBSD has in-tree VirtIO support.
- **`os`:** Usually `other` for FreeBSD in Proxmox; `l26` is for Linux.
- **Unattended install:** FreeBSD’s `bsdinstall` can be driven by:
  - `bsdinstall script /path/to/install.cfg` (scripted install),
  - `bsdinstall scriptedpart` (unattended partitioning),
  - or a custom script fetched via `http_directory` and invoked from `boot_command` (e.g. `set kFreeBSD.ftp=...` or similar, depending on image).  
  Packer’s `boot_command` sends keystrokes; you need a sequence that gets to a shell or the right `bsdinstall` entry and then points at your HTTP-served script.
- **Cloud-init in the image:** For `proxmox-iso`, do **not** need cloud-init in the ISO; you can:
  - Install and enable cloud-init in a **provisioner** (e.g. shell) after the base install, then set `cloud_init = true` so the template gets the empty Cloud-Init CD; or
  - Use `proxmox-clone` from a template that already has cloud-init.

---

## 3. End-to-End Automation Workflows

### 3.1 Build a FreeBSD + Cloud-Init Template on Proxmox (proxmox-iso)

1. **Terraform:** Ensure the FreeBSD ISO is on PVE, e.g. `proxmox_virtual_environment_download_file.freebsd_iso` from this repo’s module → `local:iso/FreeBSD-15.0-RELEASE-amd64-bootonly.iso` (or your chosen path).

2. **Packer `proxmox-iso`:**
   - `boot_iso`: `iso_file = "local:iso/FreeBSD-15.0-RELEASE-amd64-bootonly.iso"` (and `iso_checksum` if you prefer to verify).
   - `http_directory` with e.g. `install.sh` (bsdinstall script or custom script) and/or `user-data`/`meta-data` for NoCloud if you want to test cloud-init in the same build.
   - `boot_command`: sequence to boot installer and pass `url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh` (or whatever your installer expects).
   - `disks` on `local-lvm` (or your pool), `network_adapters` on `vmbr0`, `virtio`.
   - Provisioners: at least install and enable cloud-init, set `sysrc cloudinit_enable=YES`, optionally `pkg install -y qemu-guest-agent` and enable it.
   - `cloud_init = true` so the final template gets the empty Cloud-Init CD.

3. **Output:** A Proxmox template. Use it from `proxmox_virtual_environment_vm` with `initialization` (user-data, SSH keys, IP) as in the bpg cloud-init guide.

### 3.2 Build with QEMU, Then Import into Proxmox

1. **Packer QEMU:** `iso_url` = FreeBSD ISO, `iso_checksum`, `boot_command` + `http_directory` to automate install; provisioners to install cloud-init and qemu-guest-agent.
2. **Output:** `output_directory` with `qcow2` (or `raw`).
3. **Import to Proxmox (manual or script):**
   - Create VM: `qm create <vmid> --name freebsd-15 --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci`
   - Import disk: `qm importdisk <vmid> /path/to/packer.qcow2 <storage>`
   - Attach disk, set boot, convert to template.
   - Add Cloud-Init drive (empty) and set `ide2` (or appropriate) to `cloudinit` so PVE can inject user-data.

You can automate step 3 with a **Packer post-processor** (e.g. custom script that runs `qm importdisk` and `qm set`), or a separate Ansible/Terraform flow.

### 3.3 Iterate with proxmox-clone

1. Start from the template built in 3.1 (FreeBSD + cloud-init).
2. `proxmox-clone` with `clone_vm = "freebsd-15-cloudinit"` (or VMID).
3. Add provisioners (Ansible, shell, etc.) to install stacks (e.g. nginx, DB, monitoring).
4. Convert to a new template, e.g. `template_name = "freebsd-15-web"`.
5. `proxmox_virtual_environment_vm` clones from `freebsd-15-web` and uses `initialization` for per-VM user-data.

---

## 4. References

- [HashiCorp Packer – Proxmox](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox) (proxmox-iso, proxmox-clone)
- [HashiCorp Packer – QEMU](https://developer.hashicorp.com/packer/integrations/hashicorp/qemu)
- [bpg/proxmox – cloud-init guide](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-init)
- [FreeBSD – Using cloud-init (D. Chadwick, 2024)](https://people.freebsd.org/~dch/posts/2024-07-25-cloudinit/)
- [cloud-init – NoCloud](https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html)
- [cloud-init – Datasources](https://cloudinit.readthedocs.io/en/latest/reference/datasources.html)
- [bsdinstall(8)](https://man.freebsd.org/bsdinstall/8), [FreeBSD forums – bsdinstall scripted](https://forums.freebsd.org/threads/bsdinstall-unattended-scripted-install.28862/)

---

## 5. This Repo’s Pieces

- **FreeBSD ISO:** [proxmox/module/iso.tf](../module/iso.tf), [get-freebsd-iso-url.sh](../module/get-freebsd-iso-url.sh). Variables: `freebsd_version`, `freebsd_image_type`. Output: `freebsd_iso_file_path`. Use that path in Packer as `iso_file` (e.g. `local:iso/FreeBSD-15.0-RELEASE-amd64-bootonly.iso` after upload) or to derive `iso_url`/`iso_checksum` if you prefer to point Packer at a URL.
