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

  interfaced_nameservers_list = distinct(compact(flatten([for network_settings in var.private_networks_settings : network_settings.nameservers.addresses])))
  interfaced_nameservers_file = length(local.interfaced_nameservers_list) > 0 ? templatefile(
    "${path.module}/config_templates/interfacesd/nameservers_file.tmpl",
    {
      nameservers_list      = local.interfaced_nameservers_list
      nameservers_file_path = "/etc/resolvconf/resolv.conf.d/head"
    }
  ) : ""
  interfaced_network_config_file = length(var.private_networks_settings) > 0 && var.server_type != "" ? templatefile(
    "${path.module}/config_templates/interfacesd/private_network.tmpl",
    {
      server_type               = var.server_type
      private_networks_settings = var.private_networks_settings
    }
  ) : ""

  interfaced_network_config_file_map = length(var.private_networks_settings) > 0 && var.server_type != "" ? [{
    encoding    = "b64"
    content     = base64encode(local.interfaced_network_config_file)
    owner       = "root:root"
    path        = "/etc/network/interfaces.d/61-my-private-network.cfg"
    permissions = "0644"
  }] : []

  interfaced_nameservers_file_map = length(local.interfaced_nameservers_list) > 0 ? [{
    encoding    = "b64"
    content     = base64encode(local.interfaced_nameservers_file)
    owner       = "root:root"
    path        = "/etc/resolvconf/resolv.conf.d/head"
    permissions = "0644"
  }] : []

  interfaced_cloud_config_file_map = {
    users = local.additional_users_map
    timezone = var.timezone
    write_files = flatten([
      local.additional_hosts_entries_cloud_init_write_files_map,
      local.additional_files_cloud_init_write_files_map,
      local.interfaced_network_config_file_map,
      local.interfaced_nameservers_file_map,
      local.timezone_cloud_init_write_files_map
    ])
    runcmd = length(local.interfaced_nameservers_list) > 0 ? flatten([
      local.additional_hosts_entries_cloud_init_run_cmd_list,
      var.additional_run_commands,
      "systemctl enable resolvconf"
      ]) : flatten([
      local.additional_hosts_entries_cloud_init_run_cmd_list,
      var.additional_run_commands,
    ])
    packages        = length(var.additional_packages) > 0 && length(local.interfaced_nameservers_list) > 0 ? concat(var.additional_packages, ["resolvconf"]) : length(var.additional_packages) > 0 ? var.additional_packages : length(local.interfaced_nameservers_list) > 0 ? ["resolvconf"] : null
    package_upgrade = var.upgrade_all_packages
    power_state = var.timezone != null || var.reboot_instance || var.upgrade_all_packages || length(var.private_networks_settings) > 0 ? {
      mode    = "reboot"
      delay   = "now"
      message = "Reboot the machine after successfull cloud-init run with custom cloud-config file"
    } : {}
  }
}