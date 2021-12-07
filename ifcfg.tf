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
  ifcfg_network_root_directory = "/etc/sysconfig/network-scripts"

  ifcfg_network_config_files_map = length(var.private_networks_settings) > 0 ? [for net_config in var.private_networks_settings : 
    {
      encoding    = "b64"
      content     = base64encode(templatefile(
        "${path.module}/config_templates/ifcfg/private_network_config.tmpl",
        {
          server_type           = var.server_type
          device_id             = local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"
          nameservers_addresses = length(net_config.nameservers.addresses) == 0 ? [] : length(net_config.nameservers.addresses) == 1 ? slice(net_config.nameservers.addresses, 0, 1) : slice(net_config.nameservers.addresses, 0, 2)
          search_domains        = length(net_config.nameservers.search) == 0 ? "" : join(" ", net_config.nameservers.search)
        }
      ))
      owner       = "root:root"
      path        = "${local.ifcfg_network_root_directory}/ifcfg-${local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"}"
      permissions = "0644"
    } 
  ] : []

  ifcfg_network_routes_files_map = length(var.private_networks_settings) > 0 ? [for net_config in var.private_networks_settings : 
    length(net_config.routes) > 0 ? {
      encoding    = "b64"
      content     = base64encode(templatefile(
        "${path.module}/config_templates/ifcfg/private_network_routes.tmpl",
        {
          device_id = local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"
          routes    = net_config.routes
        }
      ))
      owner       = "root:root"
      path        = "${local.ifcfg_network_root_directory}/route-${local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"}"
      permissions = "0644"
    } : {}
  ] : []

  ifcfg_network_routes_files_map_no_empty_elements = [for route_file in local.ifcfg_network_routes_files_map : route_file if route_file != {}]

  ifcfg_bootcmd_commands = length(var.private_networks_settings) > 0 ? [for net_config in var.private_networks_settings : "nmcli con up 'System ${local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"}'" ] : []

  ifcfg_cloud_config_file_map = {
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
      local.ifcfg_network_config_files_map,
      local.ifcfg_network_routes_files_map_no_empty_elements,
      local.timezone_cloud_init_write_files_map
    ])
    bootcmd = length(local.ifcfg_bootcmd_commands) > 0 ? local.ifcfg_bootcmd_commands : null
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

  # ifcfg_cloud_config_file = templatefile(
  #   "${path.module}/config_templates/common/cloud_init.yaml.tmpl",
  #   {
  #     cloud_config = yamlencode(local.ifcfg_cloud_config_file_map)
  #   }
  # )
}