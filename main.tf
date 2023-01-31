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

  additional_users_map = length(var.additional_users) > 0 ? [for user in var.additional_users :
    {
      name                = user.username
      sudo                = user.sudo_options
      ssh_authorized_keys = length(user.ssh_public_keys) > 0 ? user.ssh_public_keys : null
    }
  ] : []

  timezone_cloud_init_write_files_map = {
    encoding    = "b64"
    content     = base64encode(var.timezone)
    owner       = "root:root"
    path        = "/etc/timezone"
    permissions = "0644"
  }

  # Update/install packages script file definition
  packages_install_script_path = "/root/cloud_config_files/packages_install_script.sh"
  packages_install_script_file = length(var.private_networks_settings) > 0 && var.private_networks_only ? templatefile(
    "${path.module}/config_templates/common/install_packages_private_network.sh.tmpl",
    {
      upgrade_all_packages     = var.upgrade_all_packages
      additional_packages      = local.os_image_name_without_version == "debian" && length(local.interfaced_nameservers_list) > 0 ? concat(var.additional_packages, ["resolvconf"]) : var.additional_packages
      restart_network          = local.os_image_name_without_version != "ubuntu" ? true : false
      restart_network_service  = local.os_image_name_without_version == "debian" ? "networking" : "NetworkManager"
      restart_network_commands = local.keyfile_bootcmd_commands
      package_manager          = local.os_image_name_without_version == "debian" || local.os_image_name_without_version == "ubuntu" ? "apt" : "dnf"
    }
  ) : ""

  packages_install_script_file_map = length(var.private_networks_settings) > 0 && var.private_networks_only ? [{
    encoding    = "b64"
    content     = base64encode(local.packages_install_script_file)
    owner       = "root:root"
    path        = local.packages_install_script_path
    permissions = "0700"
  }] : []

  cloud_config_files_map = {
    "debian-10" = {
      "cx"  = local.interfaced_cloud_config_file_map
      "cpx" = local.interfaced_cloud_config_file_map
    }
    "debian-11" = {
      "cx"  = local.interfaced_cloud_config_file_map
      "cpx" = local.interfaced_cloud_config_file_map
    }
    "ubuntu-20.04" = {
      "cx"  = local.netplan_2_cloud_config_file_map
      "cpx" = local.netplan_2_cloud_config_file_map
    }
    "ubuntu-22.04" = {
      "cx"  = local.netplan_2_cloud_config_file_map
      "cpx" = local.netplan_2_cloud_config_file_map
    }
    "fedora-36" = {
      "cx"  = local.keyfile_cloud_config_file_map
      "cpx" = local.keyfile_cloud_config_file_map
    }
    "fedora-37" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
    "centos-stream-8" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
    "centos-stream-9" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
    "rocky-8" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
    "rocky-9" = {
      "cx"  = local.ifcfg_cloud_config_file_map
      "cpx" = local.ifcfg_cloud_config_file_map
    }
  }

  server_type_letters_only      = replace(var.server_type, "/[0-9]+/", "")
  os_image_name_without_version = join("-", slice(split("-", var.server_image), 0, length(split("-", var.server_image)) - 1))
  system_user_data_files        = local.cloud_config_files_map[var.server_image]

  result_user_data_file = templatefile(
    "${path.module}/config_templates/common/cloud_init.yaml.tmpl",
    {
      cloud_config = yamlencode(local.system_user_data_files[local.server_type_letters_only])
    }
  )
}