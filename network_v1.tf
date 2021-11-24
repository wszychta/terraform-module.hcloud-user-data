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
  # network_v1_interfaces = [for network_config in var.private_networks_settings :
  #   {
  #     type = "physical"
  #     name = "????"
  #     subnets = [
  #       {
  #         type = "dhcp"
  #         dns_nameservers = length(network_config.nameservers.addresses) > 0 ? network_config.nameservers.addresses : null
  #         dns_search = length(network_config.nameservers.search) > 0 ? network_config.nameservers.search : null
  #         routes = length(network_config.routes) > 0 ? flatten([ for gateway,destinations in network_config.routes : [ for destination in destinations :
  #             {
  #               gateway = gateway
  #               netmask = cidrnetmask(destination)
  #               network = split("/",destination)[0]
  #             }
  #           ]
  #         ]) : null
  #       }
  #     ]
  #   }
  # ]
  network_v1_file_map = length(var.private_networks_settings) > 0 && var.server_type != "" ? { 
    network = {
      version = 1
      config = [for network_config in var.private_networks_settings :
        {
          type = "physical"
          name = "????"
          subnets = [
            {
              type = "dhcp"
              dns_nameservers = length(network_config.nameservers.addresses) > 0 ? network_config.nameservers.addresses : null
              dns_search = length(network_config.nameservers.search) > 0 ? network_config.nameservers.search : null
              routes = length(network_config.routes) > 0 ? flatten([ for gateway,destinations in network_config.routes : [ for destination in destinations :
                  {
                    gateway = gateway
                    netmask = cidrnetmask(destination)
                    network = split("/",destination)[0]
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

  # Cloud config final file output
  network_v1_cloud_config_file = templatefile(
    "${path.module}/config_templates/network_v1/cloud_init.yaml.tmpl",
    {
      private_network_file_base64          = length(var.private_networks_settings) > 0 ? base64encode(yamlencode(local.network_v1_file_map)) : ""
      private_network_file_path            = local.network_v1_file_path
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