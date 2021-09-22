# terraform-module.hcloud-user-data
## Description
<b>The purpose of this module is to provide ready to use user-data file for Hetzner cloud servers with multiple network managers.</b>

All actions taken to create user-data file are based on [Hetzner server configuration documentation](https://docs.hetzner.com/cloud/networks/server-configuration/), [Hetzner static ip documentation](https://docs.hetzner.com/cloud/servers/static-configuration/), [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/) and my own experience/experiments.

## Supported features
- Generating private networks configuration for instance after initial boot ( only dhcp - no support for static interface configuration ). This module use three different ways of managing networks
  - `interfaces.d` config file - for images:
    - `ubuntu-18.04`
    - `debian-9`
    - `debian-10`
  - `Netplan` config file - for images:
    - `ubuntu-20.04`
  - `Network manager` script - for images:
    - `fedora-33`
    - `centos-7`
    - `centos-8`
- Adding additional users with ssh keys and `sudo` configuration
- Writing additional entries in `/etc/hosts` file
- Writing additional files on instance (ex. cron jobs)
- Running additional shell commands on initial boot (ex. docker instalation)
- Upgrading all packages
- Rebooting after finishing all cloud-init tasks

### Working Features for each image

| System image | Routing Configuration | DNS ip addresses | DNS search domains | `/etc/hosts` file writing | Creating additional users | Writing additional Files | Running additional commands | Upgrading packages | Rebooting instance |
|:------------:|:---------------------:|:----------------:|:------------------:|:-------------------------:|:-------------------------:|:------------------------:|:---------------------------:|:------------------:|:------------------:|
| Ubuntu 18.04 | Yes                   | Yes              | <b>NO</b>          | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Ubuntu 20.04 | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Fedora 33    | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Debian 9     | Yes                   | Yes              | <b>NO</b>          | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Debian 10    | Yes                   | Yes              | <b>NO</b>          | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Centos 7     | Yes                   | <b>NO</b>        | <b>NO</b>          | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | <b>NO</b>          |
| Centos 8     | <b>NO</b>             | <b>NO</b>        | <b>NO</b>          | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | <b>NO</b>          |

Please take a look at [Known Issues](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#known-issues) section to read why some of the features are not working on described images.

## Tested vms configuration

I have tested this module on below instances types:
- CX11
- CPX11

This module should also work on bigger machines based on avaliable documentation.

## Usage example

Example for Debian/Ubuntu with few packages installation:
```
module "cloud_config_file" {
  source            = "git::git@github.com:wszychta/terraform-module.hcloud-user-data?ref=tags/1.0.0"
  server_type       = "cpx11"
  server_image      = "ubuntu-20.04"
  additional_users  = [
    {
      username = "local"
      sudo_options = "ALL=(ALL) NOPASSWD:ALL"
      ssh_public_keys = [
        "ssh-rsa ..................."
      ]
    }
  ]
  additional_hosts_entries = [
    {
      ip = "192.168.0.4"
      hostnames = [
        "host1.lab.net",
        "host1"
      ]
    },
    {
      ip = "192.168.0.5"
      hostnames = [
        "host2.lab.net",
        "host2"
      ]
    },
  ]
  private_networks_settings = [
    {
      routes = {
        "192.168.0.1" = [
          "192.168.0.0/24",
          "192.168.1.0/24"
        ]
      }
      nameservers = {
        addresses = [
          "192.168.0.3"
        ]
        search = [
          "lab.net",
        ]
      }
    }
  ]
  additional_run_commands = [
    "apt-get install -y htop telnet nano"
  ]
}
```

## Known Issues

### DNS search option doesn't work
affected images:
- `ubuntu-18.04`
- `debian-9`
- `debian-10`

### All DNS settings not working
The libc resolver may not support more than 3 nameservers and by default Hetzner is configuring three nameservers with cloud-init

affected images:
- `centos-7`

### Networking part not working
For some reasons Network manager is not able to manage Hetzner private networks after initial boot. I have contacted Hetzner support and they advised me to remove `hc-utils`, but I haven't tested that. This module will still generate neccessary configuration script in `/root/cloud_config_files/network_setup_script.sh`, but before running it you will need to make sure that Network Manager is able to configure additional interfaces

affected images:
- `centos-8`

### cloud-init reboot not working
I checked that `power-state-change` module is enabled by default in `/etc/cloud/cloud.cfg`, but for some images cloud-init is not forcing reboot on machine. I don't know if this is bug in cloud-init, centos images or both in the same time.

affected images:
- `centos-7`
- `centos-8`

## Variables

| Variable name             | variable type  | default value   | Required variable | Description |
|:-------------------------:|:---------------|:---------------:|:-----------------:|:-----------:|
| server_type               | `string`       | `empty`         | <b>Yes</b>        | Hetzner server type (ex. cpx11) |
| server_image              | `string`       | `empty`         | <b>Yes</b>        | Instance system image |
| additional_users          |<pre>list(object({<br>    username        = string<br>    sudo_options    = string<br>    ssh_public_keys = list(string)<br>}))</pre>| `[]` | <b>No</b> | List of additional users with their options |
| private_networks_settings |<pre>list(object({<br>    routes        = map(list(string))<br>    nameservers   = object({<br>      addresses   = list(string)<br>      search      = list(string)<br>    })<br>})</pre>| `[]` | <b>No</b> | List of configuration for all private networks.<br><b>Note:</b> Routes are defined as <b>map(list(string))</b> where key is a <b>gateway ip address</b> and list contains all <b> network destinations</b>.<br><b>Example:</b> `"192.168.0.1" = ["192.168.0.0/24","192.168.1.0/24"]` |
| additional_write_files    |<pre>list(object({<br>    content     = string<br>    owner_user  = string<br>    owner_group = string<br>    destination = string<br>    permissions = string<br>}))</pre>| `[]` | <b>No</b> | List of additional files to create on first boot.<br><b>Note:</b> inside `content` value please provide <u><i>plain text content of the file</i></u> (not the path to the file).<br>You can use terraform to generate file from template or to read existing file from local machine |
| additional_hosts_entries  |<pre>list(object({<br>    ip        = string<br>    hostnames    = string<br>}))</pre>| `[]` | <b>No</b> | List of entries for `/etc/hosts` file. There is possibility to define multiple hostnames per single ip address |
| additional_run_commands   | `list(string)` | `[]`            | <b>No</b>         | List of additional commands to run on boot |
| timezone                  | `string`       | `Europe/Berlin` | <b>No</b>         | Timezone for the VM |
| upgrade_all_packages      | `bool`         | `true`          | <b>No</b>         | Set to false when there is no need to upgrade packages on first boot |
| reboot_instance           | `bool`         | `true`          | <b>No</b>         | Set to false when there is no need for instance reboot after finishing cloud-init tasks |
| yq_version                | `string`       |`v4.6.3`         | <b>No</b>         | Version of yq script used for merging netplan script |
| yq_binary                 | `string`       |`yq_linux_amd64` | <b>No</b>         | Binary of yq script used for merging netplan script |

## Outputs

| Output name                         | Description |
|:-----------------------------------:|:------------|
| result_file                         | Result cloud-config file which will be used by instance (depending on provided `server_image` variable) |
| result_hosts_file                   | Result host entries file which will be injected into `/etc/hosts` file |
| result_nm_file                      | Result cloud-config for Network manager compatible instance |
| result_nm_network_file              | Result Network manager configuration script |
| result_interfacesd_file             | Result cloud-config for interfaces.d compatible instance |
| result_interfacesd_network_file     | Result interfaces.d network file |
| result_interfacesd_nameservers_file | Result resolvconf file for interfaces.d compatible instance |
| result_netplan_file                 | Result cloud-config for Netplan compatible instance |
| result_netplan_network_file         | Result netplan network file which will be merged to main netplan file |
| result_netplan_network_merge_script | Result netplan merge script file |

## Contributing
### Bug Reports/Feature Requests
Please use the [issues tab](https://github.com/wszychta/terraform-module.hcloud-user-data/issues) to report any bugs or file feature requests. 

I can't guarantee that I will work on every bug/feature, because this is my side project, but I will try to keep an eye on any created issue.
Also I have decided to not work on images:
- `ubuntu-18.04`, `centos-7`, `debian-9`, `debian-10` - Because I don't use described types of images
- `centos-8` - Because of the problems described in [Known Issues](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#known-issues)
- `ubuntu-16.04` and `fedora-32` - Because they will not be avaliable on Hetzner cloud after <b>June 24 2021</b>

So if somebody knows how to fix any of described issues please look into [Developing](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#developing) section

### Developing
If you have and idea how to improve this module please:
1. Fork this module from `master` branch
2. Work on your changes inside your fork
3. Create Pull Request on this respository.
4. In my spare time I will look at proposed changes

## Copyright 
Copyright © 2021 Wojciech Szychta

## License
GNU GENERAL PUBLIC LICENSE Version 3