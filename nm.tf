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
  nm_network_setup_script = length(var.private_networks_settings) > 0 && var.server_type != "" ? templatefile(
    "${path.module}/config_templates/nm/network_setup_script.sh.tmpl",
    {
      server_type               = var.server_type
      server_image              = var.server_image
      private_networks_settings = var.private_networks_settings
    }
  ) : ""
  nm_network_setup_script_path = "/root/cloud_config_files/network_setup_script.sh"

  # Cloud config final file output
  nm_cloud_config_file = templatefile(
    "${path.module}/config_templates/nm/cloud_init.yaml.tmpl",
    {
      private_network_script_base64        = length(var.private_networks_settings) > 0 ? base64encode(local.nm_network_setup_script) : ""
      private_network_script_path          = local.nm_network_setup_script_path
      server_image                         = var.server_image
      additional_users                     = var.additional_users
      additional_hosts_entries_file_base64 = length(var.additional_hosts_entries) > 0 ? base64encode(local.additional_hosts_entries_file) : ""
      additional_hosts_entries_file_path   = local.additional_hosts_entries_file_path
      additional_write_files               = var.additional_write_files
      additional_run_commands              = var.additional_run_commands
      timezone                             = var.timezone
      upgrade_all_packages                 = var.upgrade_all_packages
      reboot_instance                      = var.reboot_instance
    }
  )
}