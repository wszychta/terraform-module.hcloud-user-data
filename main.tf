locals {
  supported_os_map = {
    interfaced = [
      "debian-10",
    ],
    nm = [
      "fedora-33",
      "centos-7",
      "centos-8"
    ]
    netplan = [
      "Ubuntu-20.04"
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

  result_user_data_file = contains(local.supported_os_map["nm"], var.server_image) ? local.nm_cloud_config_file : contains(local.supported_os_map["interfaced"], var.server_image) ? local.interfaced_cloud_config_file : ""
}