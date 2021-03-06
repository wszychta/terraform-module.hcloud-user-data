
# 2.1.1
- Fix Netplan network configuration on boot with - empty map of nameservers and empty list of routes is passed to neplan config insted o `null`
- Fix sudo and ssh-authorized-keys injection 

# 2.1.0
- Update structure of the variable `private_networks_settings` to work fine with with [hcloud-server module](https://github.com/wszychta/terraform-module.hcloud-server) - new variables are not used for now, but it makes space for future improvements
- Add requirements
- Remove notice about CEPH instances - they are not avaliable anymore

## Warnings
<b>Please check described variable new structure. Previous one will not work with this version of the module. Result file will not change after applying this version of module.</b>

# 2.0.1
- Fix readme
# 2.0.0
## Main changes
- Moving from cloud-init definition in template files to terraform maps - this gives more flexibility than working with templates
- Add possibility to define timezone with cloudinit on boot
- Add possibility to install additional packages
- This module doesn't force packages upgrade on first boot if variable `upgrade_all_packages` was set to false
- Resolve DNS issues on supported debian systems
- Resolve Network and DNS issues on supported RHEL systems
- Remove unsupported images:
    - fedora-33
    - centos-7
    - centos-8 - Please read this [post](https://blog.centos.org/2020/12/future-is-centos-stream/) for more details
    - debian-9
    - ubuntu-18.04
- Add new supported images:
    - fedora-34
    - rocky-8
    - centos-stream-8

## Warnings
<b>This is breaking change, please take a look at all [Outputs](README.md#outputs). Names of the `outputs` have changed since version 1.0.0</b>

# 1.0.0
## Main changes
- Initial version of the module - Please read [README](https://github.com/wszychta/terraform-module.hcloud-user-data/blob/master/README.md) for all details