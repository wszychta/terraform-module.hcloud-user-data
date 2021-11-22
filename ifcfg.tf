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

  ifcfg_network_config_files = length(var.private_networks_settings) > 0 ? [for net_config in var.private_networks_settings :
    {
      "device_id" = var.os_image_name_without_version == "fedora" ? "eth${sum([1, index(var.private_networks_settings, net_config)])}" : local.server_type_letters_only == "cpx" ? "enp${sum([7, index(var.private_networks_settings, net_config)])}s0" : "ens${sum([10, index(var.private_networks_settings, net_config)])}"
      "ifcfg" = base64encode(templatefile(
        "${path.module}/config_templates/ifcfg/private_network_config.tmpl",
        {
          server_type           = var.server_type
          device_id             = "enp${sum([7, index(var.private_networks_settings, net_config)])}s0"
          nameservers_addresses = length(net_config.nameservers.addresses) == 0 ? [] : length(net_config.nameservers.addresses) == 1 ? slice(net_config.nameservers.addresses, 0, 1) : slice(net_config.nameservers.addresses, 0, 2)
          search_domains        = length(net_config.nameservers.search) == 0 ? "" : join(" ", net_config.nameservers.search)
        }
      ))
      "routes" = length(net_config.routes) > 0 ? base64encode(templatefile(
        "${path.module}/config_templates/ifcfg/private_network_routes.tmpl",
        {
          device_id = "enp${sum([7, index(var.private_networks_settings, net_config)])}s0"
          routes    = net_config.routes
        }
      )) : ""
    }
  ] : []

  # Cloud config final file output
  ifcfg_cloud_config_file = templatefile(
    "${path.module}/config_templates/ifcfg/cloud_init.yaml.tmpl",
    {
      ifcfg_network_root_directory         = local.ifcfg_network_root_directory
      ifcfg_network_config_files           = local.ifcfg_network_config_files
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