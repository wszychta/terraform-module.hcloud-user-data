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
    - `ubuntu-22.04`
  - `NetworkManager keyfile` script - for images:
    - `fedora-36`
    - `fedora-37`
    - `centos-stream-8`
    - `centos-stream-9`
    - `rocky-8`
    - `rocky-9`
- Adding additional users with ssh keys and `sudo` configuration
- Writing additional entries in `/etc/hosts` file
- Writing additional files on instance (ex. cron jobs)
- Running additional shell commands on initial boot (ex. docker instalation)
- Adding additional packages to VM
- Setting instance Timezone
- Upgrading all packages
- Rebooting after finishing all cloud-init tasks

### Working Features for each image

| System image    | Routing Configuration | DNS ip addresses | DNS search domains | `/etc/hosts` file writing | Creating additional users | Writing additional Files | Running additional commands | Upgrading packages | Rebooting instance |
|:---------------:|:---------------------:|:----------------:|:------------------:|:-------------------------:|:-------------------------:|:------------------------:|:---------------------------:|:------------------:|:------------------:|
| Ubuntu 20.04    | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Ubuntu 22.04    | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Debian 10       | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Debian 11       | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Fedora 36       | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Fedora 37       | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Centos Stream 8 | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Centos Stream 9 | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Rocky 8         | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |
| Rocky 9         | Yes                   | Yes              | Yes                | Yes                       | Yes                       | Yes                      | Yes                         | Yes                | Yes                |

Please take a look at [Known Issues](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#known-issues) section to read why some of the features are not working on described images.

## Tested vms configuration

I have tested this module on below instances types:
- CX11
- CPX11

<b>This module should also work on the rest of standard machines with Local SSD based on avaliable documentation.</b>

This module will not work on:
- Dedicated instances (CCXxx)

## Usage example

Example for Debian/Ubuntu with few packages installation:
```terraform
module "cloud_config_file" {
  source            = "git::git@github.com:wszychta/terraform-module.hcloud-user-data?ref=tags/2.2.0"
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
          "0.0.0.0/0" # To enable access to public network via NAT
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

There are no `Known Issues` known to me for now - please let me know if you will find any.

### Internet Access with only private networks defined
To enable access to the internet from instance without public ip addresses there are several things to do:
- Prepare NAT instance with public IP address or PFsense/Opnsense which will have rules for NAT-ing
- Add in Hetzner Cloud Console or via hcloud/terraform tool route `0.0.0.0/0` to previously prepared NAT instance/router
- Add route `0.0.0.0/0` to one of the interfaces defined in `private_networks_settings` - take a look at the example above
- Add one or more DNS servers to `nameservers` in `private_networks_settings` (They can be public ones or private) - take a look at the example above

## Variables

| Variable name             | variable type  | default value   | Required variable | Description |
|:-------------------------:|:---------------|:---------------:|:-----------------:|:-----------:|
| server_type               | `string`       | `empty`         | <b>Yes</b>        | Hetzner server type (ex. cpx11) |
| server_image              | `string`       | `empty`         | <b>Yes</b>        | Instance system image |
| additional_users          |<pre>list(object({<br>    username        = string<br>    sudo_options    = string<br>    ssh_public_keys = list(string)<br>}))</pre>| `[]` | <b>No</b> | List of additional users with their options |
| private_networks_only     | `bool`         | `false`         | <b>No</b>         | Set to `true` when there are no public IP addresses defined for the instance |
| private_networks_settings |<pre>list(object({<br>    network_id    = string<br>    ip            = string<br>    alias_ips     = list(string)<br>    routes        = map(list(string))<br>    nameservers   = object({<br>      addresses   = list(string)<br>      search      = list(string)<br>    })<br>})</pre>| `[]` | <b>No</b> | List of configuration for all private networks.<br><b>Note:</b> Routes are defined as <b>map(list(string))</b> where key is a <b>gateway ip address</b> and list contains all <b> network destinations</b>.<br><b>Example:</b> `"192.168.0.1" = ["192.168.0.0/24","192.168.1.0/24"]` |
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

| Output name                          | Description |
|:------------------------------------:|:------------|
| result_file                          | Result cloud-config file which will be used by instance (depending on provided `server_image` variable) |
| result_hosts_file                    | Result host entries file which will be injected into `/etc/hosts` file |
| packages_install_script              | Result packages install script if there are no public network addresses defined for this instance |
| result_interfacesd_file_map          | Result cloud-config for interfaces.d compatible instance |
| interfaced_network_config_file       | Result interfaces.d network file |
| interfaced_nameservers_file          | Result resolvconf file for interfaces.d compatible instance |
| result_netplan_cloud_config_file_map | Result cloud-config for Netplan compatible instance |
| netplan_network_file                 | Result netplan network file which will be merged to main netplan file |
| netplan_network_merge_script         | Result netplan merge script file |
| result_ifcfg_cloud_config_map        | Result cloud-config for ifcfg network compatible instance |
| ifcfg_network_config_files_map       | Result ifcfg network config files map |
| ifcfg_network_routes_files_map       | Result ifcfg network routes files map |
| result_keyfile_cloud_config_map      | Result cloud-config for Network manager keyfile compatible instance |
| keyfile_network_config_files_map     | Result Network manager keyfiles map |

## Contributing
### Bug Reports/Feature Requests
Please use the [issues tab](https://github.com/wszychta/terraform-module.hcloud-user-data/issues) to report any bugs or feature requests. 

I can't guarantee that I will work on every bug/feature, because this is my side project, but I will try to keep an eye on any created issue.

So if somebody will discover any error please look into [Developing](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#developing) section

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
Copyright © 2023 Wojciech Szychta

## License
GNU GENERAL PUBLIC LICENSE Version 3