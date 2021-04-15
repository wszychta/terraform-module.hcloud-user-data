locals {
  supported_os_map = {
    interfaced = [
      "debian-10",
      "debian-9",
      "ubuntu-18.04"
    ],
    nm = [
      "fedora-33",
      "centos-7",
      "centos-8"
    ]
    netplan = [
      "ubuntu-20.04",
    ]
  }
  
  # Configure additional hosts entries
  additional_hosts_entries_file = length(var.additional_hosts_entries) == 0 ? "" : templatefile(
    "${path.module}/config_templates/common/additional_hosts_entries_file.tmpl",
    {
      additional_hosts_entries  = var.additional_hosts_entries,
    }
  )
  additional_hosts_entries_file_path = "/root/cloud_config_files/additional_hosts_file"

  result_user_data_file = contains(local.supported_os_map["nm"], lower(var.server_image)) ? local.nm_cloud_config_file : contains(local.supported_os_map["interfaced"], lower(var.server_image)) ? local.interfaced_cloud_config_file : contains(local.supported_os_map["netplan"], lower(var.server_image)) ? local.netplan_cloud_config_file : ""
}