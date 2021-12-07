# 2.0.0
## Main changes
- Moving from cloud-init definition in template files to terraform maps - this gives more flexibility than working with templates
- Add possibility to define timezone with cloudinit on boot
- Add possibility to install additional packages
- This module doesn't force packages upgrade on first boot if variable `upgrade_all_packages` was set to false
- Resolve DNS issues on all debian systems
- Resolve Network and DNS issues on RHEL systems
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

# 1.0.0
## Main changes
- Initial version of the module - Please read [README](https://github.com/wszychta/terraform-module.hcloud-user-data/blob/master/README.md) for all details