# Common outputs

output "result_file" {
  value = local.result_user_data_file
}

output "result_hosts_file" {
  value = local.additional_hosts_entries_file
}

# interfaces.d outputs

output "result_interfacesd_file" {
  value = local.interfaced_cloud_config_file
}

output "result_interfacesd_network_file" {
  value = local.interfaced_network_file
}

output "result_interfacesd_nameservers_file" {
  value = local.interfaced_nameservers_file
}

# Netplan outputs

output "result_netplan_file" {
  value = local.netplan_2_cloud_config_file
}

output "result_netplan_network_file" {
  value = local.netplan_2_network_file
}

output "result_netplan_network_merge_script" {
  value = local.netplan_2_network_merge_script
}

# ifcfg outputs

output "result_ifcfg_cloud_config_map" {
  value = local.ifcfg_cloud_config_file_map
}

# output "result_network_v1_config_file" {
#   value = yamlencode(local.network_v1_file_map)
# }

# test outputs

output "os_image_name_without_version" {
  value = local.os_image_name_without_version
}