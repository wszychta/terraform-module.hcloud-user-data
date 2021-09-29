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
  netplan_network_file = length(var.private_networks_settings) > 0 && var.server_type != "" ? templatefile(
    "${path.module}/config_templates/netplan/private_network.tmpl",
    {
      server_type               = var.server_type
      private_networks_settings = var.private_networks_settings
    }
  ) : ""
  netplan_network_file_path = "/root/cloud_config_files/config.yaml"

  # Script used for merging generated network file with existing netplan file
  netplan_network_merge_script = length(var.private_networks_settings) > 0 ? templatefile(
    "${path.module}/config_templates/netplan/merge_network_files.sh.tmpl",
    {
      yq_version                = var.yq_version
      yq_binary                 = var.yq_binary
      private_network_file_path = local.netplan_network_file_path
      netplan_file_path         = "/etc/netplan/50-cloud-init.yaml"
    }
  ) : ""
  netplan_network_merge_script_path = "/root/cloud_config_files/merge_script.sh"

  # Cloud config final file output
  netplan_cloud_config_file = templatefile(
    "${path.module}/config_templates/netplan/cloud_init.yaml.tmpl",
    {
      private_network_file_base64          = length(var.private_networks_settings) > 0 ? base64encode(local.netplan_network_file) : ""
      private_network_file_path            = local.netplan_network_file_path
      network_merge_script_path            = local.netplan_network_merge_script_path
      network_merge_script_base64          = length(var.private_networks_settings) > 0 ? base64encode(local.netplan_network_merge_script) : ""
      additional_users                     = var.additional_users
      additional_hosts_entries_file_base64 = length(var.additional_hosts_entries) > 0 ? base64encode(local.additional_hosts_entries_file) : ""
      additional_hosts_entries_file_path   = local.additional_hosts_entries_file_path
      additional_write_files               = var.additional_write_files
      additional_run_commands              = var.additional_run_commands
      upgrade_all_packages                 = var.upgrade_all_packages
      timezone                             = var.timezone
      reboot_instance                      = var.reboot_instance
    }
  )
}