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

  # Configure additional hosts entries
  additional_hosts_entries_file = length(var.additional_hosts_entries) == 0 ? "" : templatefile(
    "${path.module}/config_templates/common/additional_hosts_entries_file.tmpl",
    {
      additional_hosts_entries = var.additional_hosts_entries,
    }
  )
  additional_hosts_entries_file_path = "/root/cloud_config_files/additional_hosts_file"
  additional_hosts_entries_cloud_init_write_files_map = local.additional_hosts_entries_file != "" ? {
    encoding    = "b64"
    content     = base64encode(local.additional_hosts_entries_file)
    owner       = "root:root"
    path        = local.additional_hosts_entries_file_path
    permissions = "0644"
  } : {}
  additional_hosts_entries_cloud_init_run_cmd_list = local.additional_hosts_entries_file != "" ? [
    "cat ${local.additional_hosts_entries_file_path} >> /etc/hosts",
    "cat ${local.additional_hosts_entries_file_path} >> /etc/cloud/templates/hosts.debian.tmpl",
    "cat ${local.additional_hosts_entries_file_path} >> /etc/cloud/templates/hosts.rhel.tmpl"
  ] : []

  additional_files_cloud_init_write_files_map = length(var.additional_write_files) > 0 ? [for file in var.additional_write_files :
    {
      encoding    = "b64"
      content     = base64encode(file.content)
      owner       = "${file.owner_user}:${file.owner_group}"
      path        = file.destination
      permissions = file.permissions
    }
  ] : []

  timezone_cloud_init_write_files_map = {
    encoding    = "b64"
    content     = base64encode(var.timezone)
    owner       = "root:root"
    path        = "/etc/timezone"
    permissions = "0644"
  }

  cloud_config_files_map = {
    "debian-9" = {
      "cx"  = local.interfaced_cloud_config_file
      "cpx" = local.netplan_2_cloud_config_file
    }
    "debian-10" = {
      "cx"  = local.interfaced_cloud_config_file
      "cpx" = local.netplan_2_cloud_config_file
    }
    "debian-11" = {
      "cx"  = local.interfaced_cloud_config_file
      "cpx" = local.netplan_2_cloud_config_file
    }
    "ubuntu-20.04" = {
      "cx"  = local.netplan_2_cloud_config_file
      "cpx" = local.netplan_2_cloud_config_file
    }
    "fedora-34" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    },
    # "fedora-35" = {
    #   "cx"  = local.ifcfg_cloud_config_file_map
    #   "cpx" = local.ifcfg_cloud_config_file_map
    # }
    "centos-7" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
    "centos-stream-8" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
    "rocky-8" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
  }

  server_type_letters_only      = replace(var.server_type, "/[1-9]+/", "")
  os_image_name_without_version = join("-", compact([for element in split("-", var.server_image) : replace(element, "/[1-9]+/", "")]))
  system_user_data_files        = local.cloud_config_files_map[var.server_image]
  # result_user_data_file         = local.system_user_data_files[local.server_type_letters_only]

  result_user_data_file = templatefile(
    "${path.module}/config_templates/common/cloud_init.yaml.tmpl",
    {
      cloud_config = yamlencode(local.system_user_data_files[local.server_type_letters_only])
    }
  )
}