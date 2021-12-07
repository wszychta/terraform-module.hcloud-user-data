# terraform-module.hcloud-user-data
## Description
<b>The purpose of this module is to provide ready to use user-data file for Hetzner cloud servers with multiple network managers.</b>

All actions taken to create user-data file are based on [Hetzner server configuration documentation](https://docs.hetzner.com/cloud/networks/server-configuration/), [Hetzner static ip documentation](https://docs.hetzner.com/cloud/servers/static-configuration/), [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/) and my own experience/experiments.

## Supported features
- Generating private networks configuration for instance after initial boot ( only dhcp - no support for static interface configuration ). This module use three different ways of managing networks
  - `interfaces.d` config file - for images:
    - `debian-10`
    - `debian-11`
  - `Netplan` config file - for images:
    - `ubuntu-20.04`
  - `ifcfg` script - for images:
    - `fedora-34`
    - `centos-stream-8`
    - `rocky-8`
- Adding additional users with ssh keys and `sudo` configuration
- Writing additional entries in `/etc/hosts` file
- Writing additional files on instance (ex. cron jobs)
- Running additional shell commands on initial boot (ex. docker instalation)
- Adding additional packages to VM
- Setting instance Timezone
- Upgrading all packages
- Rebooting after finishing all cloud-init tasks

### Working Features for each image

| System image    | Routing Configuration                                  | DNS ip addresses                                       | DNS search domains                                     | `/etc/hosts` file writing | Creating additional users | Writing additional Files | Running additional commands | Upgrading packages | Rebooting instance |
|:---------------:|:------------------------------------------------------:|:------------------------------------------------------:|:------------------------------------------------------:|:-------------------------:|:-------------------------:|:------------------------:|:---------------------------:|:------------------:|:------------------:|
| Ubuntu 20.04    | Yes                                                    | Yes                                                    | Yes                                                    | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Fedora 34       | [Usually Yes](#rhel-private-networking-is-not-working) | [Usually Yes](#rhel-private-networking-is-not-working) | [Usually Yes](#rhel-private-networking-is-not-working) | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Debian 10       | Yes                                                    | Yes                                                    | Yes                                                    | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Debian 11       | Yes                                                    | Yes                                                    | Yes                                                    | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Centos Stream 8 | Yes                                                    | Yes                                                    | Yes                                                    | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | <b>NO</b>          |
| Rocky 8         | Yes                                                    | Yes                                                    | Yes                                                    | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | <b>NO</b>          |

Please take a look at [Known Issues](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#known-issues) section to read why some of the features are not working on described images.

## Tested vms configuration

I have tested this module on below instances types:
- CX11
- CPX11

<b>This module should also work on the rest of standard machines with Local SSD based on avaliable documentation.</b>

This module will not work on:
- CEPH instances (CXxx-CEPH)
- Dedicated instances (CCXxx)

## Usage example

Example for Debian/Ubuntu with few packages installation:
```terraform
module "cloud_config_file" {
  source            = "git::git@github.com:wszychta/terraform-module.hcloud-user-data?ref=tags/2.0.0"
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
    "echo 'test command'"
  ]
  additional_run_commands = [
    "htop",
    "telnet",
    "nano"
  ]
}
```

## Known Issues

### RHEL private networking is not working
This issue is connected with described below [rebooting issue](#cloud-init-reboot-not-working). To fix this issue you need to reboot your instance. Thanks to that Network manager will read new `ifcfg` files and apply changes to all private networks.

affected images:
- `centos-stream-8`
- `rocky-8`

### cloud-init reboot not working
I checked that `power-state-change` module is enabled by default in `/etc/cloud/cloud.cfg`, but for some images cloud-init is not forcing reboot on machine. I don't know if this is bug in cloud-init, images bug or both in the same time.
There is also possibility that when I was testing this module there were no packages which required rebooting instance. You can read more about this in [cloud-init power-state-change](https://cloudinit.readthedocs.io/en/latest/topics/modules.html#power-state-change) module description.

affected images:
- `centos-stream-8`
- `rocky-8`

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
| additional_packages       | `list(string)` | `[]`            | <b>No</b>         | List of additional pckages to install on first boot |
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
| result_interfacesd_file_map         | Result cloud-config for interfaces.d compatible instance |
| interfaced_network_config_file      | Result interfaces.d network file |
| interfaced_nameservers_file         | Result resolvconf file for interfaces.d compatible instance |
| netplan_cloud_config_file_map       | Result cloud-config for Netplan compatible instance |
| netplan_network_file                | Result netplan network file which will be merged to main netplan file |
| netplan_network_merge_script        | Result netplan merge script file |
| result_ifcfg_cloud_config_map       | Result cloud-config for Network manager compatible instance |

## Contributing
### Bug Reports/Feature Requests
Please use the [issues tab](https://github.com/wszychta/terraform-module.hcloud-user-data/issues) to report any bugs or feature requests. 

I can't guarantee that I will work on every bug/feature, because this is my side project, but I will try to keep an eye on any created issue.
Also I have decided to not work on images:
- `ubuntu-18.04`, `centos-7`, `debian-9`, `debian-10` - Because I don't use described types of images

So if somebody knows how to fix any of described issues in [Known issues](#known-issues) please look into [Developing](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#developing) section

### Supporting development
If you like this module and you haven't started working in Hetzner Cloud you can use my [PERSONAL REFERRAL LINK](https://hetzner.cloud/?ref=YQhSB5WwTzqt) to start working with Hetzner cloud.
You will get 20 Euro on start and after spending additional 10 Euro I will get the same amount of money.

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