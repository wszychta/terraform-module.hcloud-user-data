# Common outputs

output "result_file" {
  value = local.result_user_data_file
}

output "result_hosts_file" {
  value = local.additional_hosts_entries_file
}

# NM outputs

output "result_nm_file" {
  value = local.nm_network_setup_script
}

output "result_nm_network_file" {
  value = local.nm_network_setup_script_path
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
  value = local.netplan_cloud_config_file
}

output "result_netplan_network_file" {
  value = local.netplan_network_file
}

output "result_netplan_network_merge_script" {
  value = local.netplan_network_merge_script
}