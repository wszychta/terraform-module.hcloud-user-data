# terraform-module.hcloud-user-data
## Description
<b>The purpose of this module is to provide ready to use user-data file for Hetzner cloud servers with multiple network managers.</b>

All actions taken to create user-data file are based on [Hetzner server configuration documentation](https://docs.hetzner.com/cloud/networks/server-configuration/), [Hetzner static ip documentation](https://docs.hetzner.com/cloud/servers/static-configuration/), [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/) and my own experience/experiments.

## Supported features
- Generating private networks configuration for instance after initial boot
- Adding additional users with ssh keys and `sudo` configuration
- Writing additional files on instance (ex. cron jobs)
- Running additional shell commands on initial boot (ex. docker instalation)

## List of tested vms configuration:

| Hardware Configuration | Ubuntu 18.04 | Ubuntu 20.04 | Fedora 33 | Debian 9 | Debian 10 | Centos 7  | Centos 8  |
|:----------------------:|:------------:|:------------:|:---------:|:--------:|:---------:|:---------:|:---------:|
| CX11                   | Partially    | YES          | YES       | YES      | YES       | Partially | Partially |
| CX21                   | Partially    | YES          | YES       | YES      | YES       | Partially | Partially |
| CPX11                  | Partially    | YES          | YES       | YES      | YES       | Partially | Partially |
| CPX21                  | Partially    | YES          | YES       | YES      | YES       | Partially | Partially |

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
| server_type               | `string` | `empty` |||
| server_image              | `string` | `empty` |||
| additional_users          |<pre>list(object({<br>    username        = string<br>    sudo_options    = string<br>    ssh_public_keys = list(string)<br>}))</pre>| `[]` | <b>No</b> | List of additional users with their options |
| private_networks_settings |<pre>list(object({<br>    routes        = map(list(string))<br>    nameservers   = object({<br>      addresses   = list(string)<br>      search      = list(string)<br>    })<br>})</pre>| `[]` | <b>No</b> ||
| additional_write_files    |<pre>list(object({<br>    content     = string<br>    owner_user  = string<br>    owner_group = string<br>    destination = string<br>    permissions = string<br>}))</pre>| `[]` | <b>No</b> ||
| additional_hosts_entries  |<pre>list(object({<br>    ip        = string<br>    hostnames    = string<br>}))</pre>| `[]` | <b>No</b> ||
| additional_run_commands   |list(string)| `[]` | <b>No</b> ||
| yq_version                | `string` |`v4.6.3`| <b>No</b> | Version of yq script used for merging netplan script |
| yq_binary                 | `string` |`yq_linux_amd64`| <b>No</b> | Binary of yq script used for merging netplan script |

## Outputs

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