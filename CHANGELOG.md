# 1.1.0
## Main changes
- Add possibility to define timezone with cloudinit on boot
- This module doesn't force packages upgrade on first boot if variable `upgrade_all_packages` was set to false
- Resolve DNS issues on all debian systems
- Remove unsupported images:
    - fedora-33
- Add new supported images:
    - fedora-34

# 1.0.0
## Main changes
- Initial version of the module - Please read [README](https://github.com/wszychta/terraform-module.hcloud-user-data/blob/master/README.md) for all details