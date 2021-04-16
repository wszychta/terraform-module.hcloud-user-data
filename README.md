# terraform-module.hcloud-user-data
## Description
<b>The purpose of this module is to provide ready to use user-data file for Hetzner cloud servers with multiple network managers.</b>

All actions taken to create user-data file are based on [Hetzner server configuration documentation](https://docs.hetzner.com/cloud/networks/server-configuration/), [Hetzner static ip documentation](https://docs.hetzner.com/cloud/servers/static-configuration/), [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/) and my own experience/experiments.

## Supported features
- Generating private networks configuration for instance after initial boot only with dhcp ( no support for static interface configuration )
- Adding additional users with ssh keys and `sudo` configuration
- Writing additional files on instance (ex. cron jobs)
- Running additional shell commands on initial boot (ex. docker instalation)

## List of tested vms configuration:

| Hardware Configuration | Ubuntu 18.04 | Ubuntu 20.04 | Fedora 33 | Debian 9 | Debian 10 | Centos 7  | Centos 8  |
|:----------------------:|:------------:|:------------:|:---------:|:--------:|:---------:|:---------:|:---------:|
| CX11                   | Partially    | YES          | YES       | YES      | YES       | Partially | Partially |
| CPX11                  | Partially    | YES          | YES       | YES      | YES       | Partially | Partially |

I will not test this module on bigger machines, but it should work fine also on them.

## Known Issues

### Ubuntu 18.04
- `/ect/resolv.conf` - DNS search option doesn't work for some unknown to me reasons.
### Centos 7
- `/ect/resolv.conf` - DNS search option doesn't work for some unknown to me reasons.
### Centos 8
- <b>Networking part is not working at all.</b> For some reasons Network manager is not able to manage Hetzner private networks after initial boot. I have contacted Hetzner support and they advised me to remove `hc-utils`, but I haven't tested that. This module will still generate neccessary configuration script in `/root/cloud_config_files/network_setup_script.sh`, but before running it you will need to make sure that Network Manager is able to configure additional interfaces

## Variables

| Variable name             | variable type | default value | Required variable | Description |
|:-------------------------:|:--------------|:-------------:|:-----------------:|:-----------:|
| server_type               | `string` | `empty` | <b>Yes</b> | Hetzner server type (ex. cpx11) |
| server_image              | `string` | `empty` | <b>Yes</b> | Instance system image |
| additional_users          |<pre>list(object({<br>    username        = string<br>    sudo_options    = string<br>    ssh_public_keys = list(string)<br>}))</pre>| `[]` | <b>No</b> | List of additional users with their options |
| private_networks_settings |<pre>list(object({<br>    routes        = map(list(string))<br>    nameservers   = object({<br>      addresses   = list(string)<br>      search      = list(string)<br>    })<br>})</pre>| `[]` | <b>No</b> | List of configuration for all private networks.<br><b>Note:</b> Routes are defined as <b>map(list(string))</b> where key is a <b>gateway ip address</b> and list contains all <b> network destinations</b>.<br><b>Example:</b> `"192.168.0.1" = ["192.168.0.0/24","192.168.1.0/24"]` |
| additional_write_files    |<pre>list(object({<br>    content     = string<br>    owner_user  = string<br>    owner_group = string<br>    destination = string<br>    permissions = string<br>}))</pre>| `[]` | <b>No</b> | List of additional files to create on first boot.<br><b>Note:</b> inside `content` value please provide <u><i>plain text content of the file</i></u> (not the path to the file).<br>You can use terraform to generate file from template or to read existing file from local machine |
| additional_hosts_entries  |<pre>list(object({<br>    ip        = string<br>    hostnames    = string<br>}))</pre>| `[]` | <b>No</b> | List of entries for `/etc/hosts` file. There is possibility to define multiple hostnames per single ip address |
| additional_run_commands   | `list(string)` | `[]` | <b>No</b> | List of additional commands to run on boot |
| yq_version                | `string` |`v4.6.3`| <b>No</b> | Version of yq script used for merging netplan script |
| yq_binary                 | `string` |`yq_linux_amd64`| <b>No</b> | Binary of yq script used for merging netplan script |

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
- `ubuntu-18.04` and `centos-7` - Because I don't use both types of images
- `centos-8` - Because of the problem described in Known Issues part
- `ubuntu-16.04` and `fedora-32` - Because they will not be avaliable on Hetzner cloud after <b>June 24 2021</b>

### Developing
If you have and idea how to improve this module please:
1. Fork this module from `master` branch
2. Work on your changes inside your fork
3. Create Pull Request on this respository.
4. In my spare time I will look at your changes

## Copyright 
Copyright © 2021 Wojciech Szychta