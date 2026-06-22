# Ansible Setup Playbook

Automates the "SETTING UP NEW SYS" steps from the top-level README.

## Prerequisites

- Ansible >= 2.12 on the control node
- Target nodes reachable as `root` via SSH
- SW tarball already unpacked to `/root/swfw/Cn5k-sw_<version>/` on each node
- Intel oneAPI offline installer already copied to `/root/` on each node
- Firmware package already copied to `/root/<fw_pkg_path>/` on each node

## Quick start

1. Edit `inventory.ini` — add your hostnames/IPs under `[nodes]`.
2. Review `group_vars/nodes.yml` — update `sw_version`, `oneapi_installer`,
   `kernel_srpm`, and `fw_pkg` to match your release.
3. For the node that will run the Fabric Manager, set `opafm_node: true` in
   its host_vars file or pass `-e opafm_node=true` on the command line.
4. Run:

```bash
ansible-playbook -i inventory.ini site.yml
```

## IPoIB IP addressing

The playbook detects `ib*d1` interfaces automatically. You must supply the
`ipoib_ipaddr` variable per host (e.g. in `host_vars/<hostname>.yml`) so each
interface gets the correct static IP. Follow the convention from the README:
node `rb11` → `10.228.222.11` / `10.228.223.11` for two interfaces.

## What the playbook does (in order)

1. Checks/sets `iommu=pt` boot parameter (reboots if needed)
2. Deploys `/etc/hosts` from `config/hosts`
3. Deploys `config/opxs.repo` to `/etc/yum.repos.d/`
4. Installs all required packages (`kernel-abi-stablelists`, build tools, pdsh, cn5000 meta)
5. Installs Intel oneAPI toolkit silently
6. Rebuilds and installs the kernel SRPM
7. Loads and persists the `hfi1` kernel module
8. Updates SuperNIC firmware via `updateAgent`
9. Sets up passwordless SSH between all nodes
10. Configures IPoIB interfaces (`ifcfg-ib*d1`)
11. Optionally enables the `opafm` Fabric Manager service
