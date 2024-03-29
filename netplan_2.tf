/*
Terraform module for creating Hetzner cloud compatible user-data file
Copyright (C) 2023 Wojciech Szychta

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

  netplan2_network_file_path         = "/root/cloud_config_files/config.yaml"
  netplan2_network_merge_script_path = "/root/cloud_config_files/merge_script.sh"

  # Netplan network file definition
  netplan2_network_config = {
    network = {
      version  = 2
      renderer = "networkd"
      ethernets = {
        for network_settings in var.private_networks_settings : regex("[a-z]+", var.server_type) == "cpx" ? "enp${sum([7, index(var.private_networks_settings, network_settings)])}s0" : "ens1${index(var.private_networks_settings, network_settings)}" => {
          dhcp4 = true
          nameservers = length(network_settings.nameservers.addresses) > 0 || length(network_settings.nameservers.search) > 0 ? {
            addresses = length(network_settings.nameservers.addresses) > 0 ? network_settings.nameservers.addresses : null
            search    = length(network_settings.nameservers.search) > 0 ? network_settings.nameservers.search : null
          } : {}
          routes = length(network_settings.routes) > 0 ? flatten([
            for gateway_ip, subnets in network_settings.routes : [
              for subnet in subnets : {
                to      = subnet
                via     = gateway_ip
                on-link = true
              }
            ]
          ]) : []
        }
      }
    }
  }

  netplan2_network_config_file_map = length(var.private_networks_settings) > 0 && var.server_type != "" ? [{
    encoding    = "b64"
    content     = base64encode(yamlencode(local.netplan2_network_config))
    owner       = "root:root"
    path        = local.netplan2_network_file_path
    permissions = "0644"
  }] : []

  # Netplan merge script definition
  netplan2_merge_script_file = length(var.private_networks_settings) > 0 ? templatefile(
    "${path.module}/config_templates/netplan_2/merge_network_files.sh.tmpl",
    {
      yq_version                = var.yq_version
      yq_binary                 = var.yq_binary
      private_networks_only     = var.private_networks_only
      private_network_file_path = local.netplan2_network_file_path
      netplan_file_path         = "/etc/netplan/50-cloud-init.yaml"
    }
  ) : ""

  netplan2_merge_script_file_map = length(var.private_networks_settings) > 0 ? [{
    encoding    = "b64"
    content     = base64encode(local.netplan2_merge_script_file)
    owner       = "root:root"
    path        = local.netplan2_network_merge_script_path
    permissions = "0700"
  }] : []

  # Cloud config definition map
  netplan_2_cloud_config_file_map = {
    users    = local.additional_users_map
    timezone = var.timezone
    write_files = flatten([
      local.additional_hosts_entries_cloud_init_write_files_map,
      local.additional_files_cloud_init_write_files_map,
      local.netplan2_network_config_file_map,
      local.netplan2_merge_script_file_map,
      local.packages_install_script_file_map,
      local.timezone_cloud_init_write_files_map
    ])
    runcmd = length(var.private_networks_settings) > 0 ? flatten([
      local.additional_hosts_entries_cloud_init_run_cmd_list,
      ".${local.netplan2_network_merge_script_path}",
      (var.upgrade_all_packages || length(var.additional_packages) > 0) && var.private_networks_only ? [".${local.packages_install_script_path}"] : [],
      var.additional_run_commands
      ]) : flatten([
      local.additional_hosts_entries_cloud_init_run_cmd_list,
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