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

# Common outputs

output "result_file" {
  value = local.result_user_data_file
}

output "result_hosts_file" {
  value = local.additional_hosts_entries_file
}

output "packages_install_script" {
  value = local.packages_install_script_file
}

# interfaces.d outputs

output "result_interfacesd_file_map" {
  value = local.interfaced_cloud_config_file_map
}

output "interfaced_network_config_file" {
  value = local.interfaced_network_config_file
}

output "interfaced_nameservers_file" {
  value = local.interfaced_nameservers_file
}

# Netplan outputs

output "result_netplan_cloud_config_file_map" {
  value = local.netplan_2_cloud_config_file_map
}

output "netplan_network_file" {
  value = local.netplan2_network_config
}

output "netplan_network_merge_script" {
  value = local.netplan2_merge_script_file
}

# ifcfg outputs

output "result_ifcfg_cloud_config_map" {
  value = local.ifcfg_cloud_config_file_map
}

# keyfile outputs

output "result_keyfile_cloud_config_map" {
  value = local.keyfile_cloud_config_file_map
}

output "keyfile_network_config_files_map" {
  value = local.keyfile_network_config_files_map
}