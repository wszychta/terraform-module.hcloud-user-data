# terraform-module.hcloud-user-data
## Description
<b>The purpose of this module is to provide ready to use user-data file for Hetzner cloud servers with multiple network managers.</b>

All actions taken to create user-data file are based on [Hetzner server configuration documentation](https://docs.hetzner.com/cloud/networks/server-configuration/), [Hetzner static ip documentation](https://docs.hetzner.com/cloud/servers/static-configuration/), [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/) and my own experience/experiments.

## List of tested vms configuration:

| Hardware Configuration | Ubuntu 20.04 | Fedora 33 | Debian 10 |
|:----------------------:|:------------:|:---------:|:---------:|
| CX11                   | YES          | YES       | YES       |
| CX21                   | YES          | YES       | YES       |
| CPX11                  | YES          | YES       | YES       |
| CPX21                  | YES          | YES       | YES       |

## Contributing
### Bug Reports/Feature Requests
Please use the [issues tab](https://github.com/wszychta/terraform-module.hcloud-user-data/issues) to report any bugs or file feature requests. 

I can't guarantee that I will work on every bug/feature, because this is my side project, but I will try to keep an eye on any created issue.

### Developing
If you have and idea how to improve this module please:
1. Fork this module from `master` branch
2. Work on your changes inside your fork
3. Create Pull Request on this respository.
4. In my spare time I will look at your changes

## Copyright 
Copyright © 2021 Wojciech Szychta