# KITCHEN SINK TESTS

The kitchensink tests run asynchronous IMB-Biband jobs with OPX and TCP providers alongside an nsdperf job using verbs.

## RUNNING

There are a lot of options for the kitchen sink tests.
You can see them in util:universal_opts.
Override any of the defaults on the command line.
The test is run with `./kitchensink_screen.sh KEY=value` for as many key value pairs as necessary.

The logs will be saved to `/tmp/<last 6 of switch guid>_<switch ports>_<date: MM-DD_HH-MM>`.
This output directory also shows up at the top of the command line output.
The output directory will have files for TCP, OPX, and nsdperf.

The script reads from a config file `config-${nm}.sh` where `nm` is the first two characters of the hostname where the script is running.

## SETTING UP NEW SYS

Create a new config based on server names and populate it with the hostnames, IP addresses, and PPN intended as default (PPN=NCORES/4), NCORES is the number of physical cores on the server. To make this work, servers that are intended to be run together must be given names that have the same first two letters (i.e. rb11,rb12). And these names must not have the same first two letters as other groups of servers intended for this task (cots, cncc is cutting it close).

That being said, groups of servers with different names CAN be run together under this script. The user can set set HOSTNM as a comma delimited list of hosts and the PPN variables on the command line.

### Get SW/FW

Grab sw and fw from the shared space, i.e. phwfstl030 and transfer to the new servers.

Currently using `/nfs/shares/stlbuilds/Release/DEVOPS_STAGING/12.1.2.0.8`.

Unpack the sw tarball for this distro, e.g. `CN5000_OPXSoftware-RHEL9.7-12.1.2.0.32.tgz`.

Put the resulting folder (should contain the rpms in the top level) in `/root/swfw/Cn5k-sw_12.1.2.0.32`. Change the prefix of the Cn5k dir to match the SW release. Make sure that the path matches the `baseurl` key in opxs.repo.

Move `config/opxs.repo` to `/etc/yum.repos.d`.

Get intel oneapi: (wget) https://registrationcenter-download.intel.com/akdlm/IRC_NAS/71180075-e4e3-4c6f-bbbb-19017ed0cf7d/intel-oneapi-toolkit-2026.0.0.198_offline.sh

You can look around for a new one on that site too.

### INSTALL SW

**On every node**

``` bash
dnf install -y kernel-abi-stablelists

dnf install -y cmake pkgconfig numactl hwloc hwloc-devel

dnf -y install pdsh
dnf -y install pdsh-rcmd-ssh
dnf -y remove pdsh-rcmd-rsh

sh ./intel-oneapi-toolkit-2026.0.0.198_offline.sh -a --silent --eula accept

dnf clean all && dnf makecache

dnf install -y cn5000_pkgs_non_gpu_meta

rpmbuild --rebuild --target x86_64 opxs-kernel-updates-5.14.0_611.5.1.el9_7.x86_64-322.src.rpm

dnf install -y /root/rpmbuild/RPMS/x86_64/*
```

### LOAD KERNEL MODULE

``` bash
lsmod | grep hfi
modprobe hfi1
lsmod | grep hfi
```

### UPDATE JKR FW

``` bash
updateAgent -V
updateAgent -v ~/12.1.1.1.7/CN5000_SuperNICFirmware-12.1.1.1.3/CN5000.SuperNICFirmware.12_1_1_1_3-V1.pkg
```

### HOSTNAMES

Set up `/etc/hosts` using `config/hosts` as a template.

It's just a list:

``` bash
IPADDR HOSTNAME
# So like 10.228.221.125 rb11
```

Leave the localhost stuff at the top unchanged.
The ipoib addresses don't need to be there unless you want to ssh using them.

### SET UP PASSWORDLESS SSH

**NOTE IMPORTANT:** You must actually log into each server from each other server (including itself) in order to activate the authorized_keys.
Without this, nsdperf (and pdsh/pdcp) won't work.

Copy the key from each server `/root/.ssh/id_rsa.pub` to each other server's `/root/.ssh/authorized_keys`.
Each server should have the keys to all other servers and itself.

### IPOIB setup

Once the hfi1 kernel module has been installed (after the rpmbuild).
You can check for the ib_ipoib kernel module with lsmod.

If it's there look for it on `ifconfig`.
If you see an ip address there, it's probably done, but double check with `nmcli connection show`.
The interfaces (ifname: ib*d1) should show up in green.

**NOTE:** If there's two hfis there should be two ifnames. The correct ifnames are the names that end in d1 (this refers to the second port on the NIC which is the active port).

If the ib_ipoib kernel module isn't loaded, power cycle the server and see if it's loaded after.
If it's loaded and there's no ip in ifconfig, and if it isn't green in nmcli.
Then copy the `config/ifcfg-templ.cfg` to `/etc/sysconfig/network-scripts` and rename it `ifcfg-[ifname]` for each ifname.
Change the DEVICE key to match the ifname. Change the IPADDR to an ip address.
I match the ip address to the hostname.
That is: node name rb11 has IPADDR: 10.228.222.11 and 10.228.223.11 for the two interfaces.
Use 222, 223, 224, 225, etc... for as the third field for the interfaces in alphanumeric order.

### OPAFM

If this/these servers are on their own ib network, set up the opafm service.

**NOTE IMPORTANT:** Only one opafm service can be active on an ib network at a time.

Copy `config/opafm.xml` to `/etc/opa-fm` on the node you've elected to be your FM node and run `systemctl enable opafm`.

Stop and start the service as needed. This can often fix missing links.

To check that all the links are up on an ibnetwork run `opaextractlids` and check for missing links.
