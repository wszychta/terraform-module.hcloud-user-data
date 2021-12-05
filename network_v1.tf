/*
Terraform module for creating Hetzner cloud compatible user-data file
Copyright (C) 2021 Wojciech Szychta

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
locals {
  network_v1_file_map = length(var.private_networks_settings) > 0 && var.server_type != "" ? {
    network = {
      version = 1
      config = [for network_config in var.private_networks_settings :
        {
          type = "physical"
          name = local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, network_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, network_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, network_config)])}"
          subnets = [
            {
              type            = "dhcp"
              dns_nameservers = length(network_config.nameservers.addresses) > 0 ? network_config.nameservers.addresses : null
              dns_search      = length(network_config.nameservers.search) > 0 ? network_config.nameservers.search : null
              routes = length(network_config.routes) > 0 ? flatten([for gateway, destinations in network_config.routes : [for destination in destinations :
                {
                  gateway = gateway
                  netmask = cidrnetmask(destination)
                  network = split("/", destination)[0]
                }
                ]
              ]) : null
            }
          ]
        }
      ]
    }
  } : null
  network_v1_file_path = "/etc/cloud/cloud.cfg.d/99-private-network-config.cfg"
  network_v1_cloud_init_write_files_map = length(var.private_networks_settings) > 0 && var.server_type != "" ? {
    encoding    = "b64"
    content     = base64encode(yamlencode(local.network_v1_file_map))
    owner       = "root:root"
    path        = local.network_v1_file_path
    permissions = "0644"
  } : {}

  # Cloud config final file output
  network_v1_cloud_config_file_map = {
    users = length(var.additional_users) > 0 ? [for user in var.additional_users :
      {
        name            = user.username
        sudo_options    = user.sudo_options
        ssh_public_keys = length(user.ssh_public_keys) > 0 ? user.ssh_public_keys : null
      }
    ] : null
    timezone = var.timezone
    write_files = flatten([
      local.additional_hosts_entries_cloud_init_write_files_map,
      local.additional_files_cloud_init_write_files_map,
      local.network_v1_cloud_init_write_files_map,
      local.timezone_cloud_init_write_files_map
    ])
    runcmd = flatten([
      local.additional_hosts_entries_cloud_init_run_cmd_list,
      var.additional_run_commands
    ])
    package_upgrade = var.upgrade_all_packages
    power_state = var.timezone != null || var.reboot_instance || var.upgrade_all_packages || length(var.private_networks_settings) > 0 ? {
      mode    = "reboot"
      delay   = "now"
      message = "Reboot the machine after successfull cloud-init run with custom cloud-config file"
    } : null
  }
  network_v1_cloud_config_file = templatefile(
    "${path.module}/config_templates/network_v1/cloud_init.yaml.tmpl",
    {
      cloud_config = yamlencode(local.network_v1_cloud_config_file_map)
    }
  )
}