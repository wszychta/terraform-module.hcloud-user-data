# Common outputs

output "result_file" {
  value = local.result_user_data_file
}

output "result_hosts_file" {
  value = local.additional_hosts_entries_file
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