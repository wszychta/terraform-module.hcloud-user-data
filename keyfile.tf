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
  keyfile_network_root_directory = "/etc/NetworkManager/system-connections"

  keyfile_network_config_files_map = length(var.private_networks_settings) > 0 ? [for net_config in var.private_networks_settings :
    {
      encoding = "b64"
      content = base64encode(templatefile(
        "${path.module}/config_templates/keyfile/con.nmconnection.tmpl",
        {
          device_id             = local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"
          nameservers_addresses = length(net_config.nameservers.addresses) == 0 ? [] : net_config.nameservers.addresses
          search_domains        = length(net_config.nameservers.search) == 0 ? [] : net_config.nameservers.search
          routes = flatten([for gateway, networks in net_config.routes : [
            for network in networks : "${network},${gateway}"
          ]])
        }
      ))
      owner       = "root:root"
      path        = "${local.keyfile_network_root_directory}/${local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"}"
      permissions = "0600"
    }
  ] : []

  # keyfile_bootcmd_commands = length(var.private_networks_settings) > 0 ? [for net_config in var.private_networks_settings : "nmcli con up '${local.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"}'"] : []

  keyfile_cloud_config_file_map = {
    users    = local.additional_users_map
    timezone = var.timezone
    write_files = flatten([
      local.additional_hosts_entries_cloud_init_write_files_map,
      local.additional_files_cloud_init_write_files_map,
      local.keyfile_network_config_files_map,
      local.timezone_cloud_init_write_files_map,
      local.packages_install_script_file_map
    ])
    # bootcmd = length(local.keyfile_bootcmd_commands) > 0 ? local.keyfile_bootcmd_commands : null
    runcmd = flatten([
      local.additional_hosts_entries_cloud_init_run_cmd_list,
      (var.upgrade_all_packages || length(var.additional_packages) > 0) && var.private_networks_only ? [".${local.packages_install_script_path}"] : [],
      var.additional_run_commands
    ])
    packages        = length(var.additional_packages) > 0 && var.private_networks_only != true ? var.additional_packages : null
    package_upgrade = var.upgrade_all_packages && var.private_networks_only != true ? true : false
    power_state = var.timezone != null || var.reboot_instance || var.upgrade_all_packages || length(var.private_networks_settings) > 0 ? {
      mode    = "reboot"
      delay   = "now"
      message = "Reboot the machine after successfull cloud-init run with custom cloud-config file"
    } : {}
  }
}