
locals {
  netplan_network_file = length(var.private_networks_settings) > 0 && var.server_type != "" ? templatefile(
    "${path.module}/config_templates/netplan/private_network.tmpl",
    {
      server_type               = var.server_type,
      private_networks_settings = var.private_networks_settings
    }
  ) : ""
  netplan_network_file_path = "/root/cloud_config_files/config.yaml"

  # Script used for merging generated network file with existing netplan file
  netplan_network_merge_script = length(var.private_networks_settings) > 0 ? templatefile(
    "${path.module}/config_templates/netplan/merge_network_files.sh.tmpl",
    {
      yq_version                = var.yq_version,
      yq_binary                 = var.yq_binary,
      private_network_file_path = local.network_file_path,
      netplan_file_path         = "/etc/netplan/50-cloud-init.yaml",
    }
  ) : ""
  netplan_network_merge_script_path = "/root/cloud_config_files/merge_script.sh"

  # Cloud config final file output
  netplan_cloud_config_file = templatefile(
    "${path.module}/config_templates/netplan/cloud_init.yaml.tmpl",
    {
      private_network_file_base64           = length(var.private_networks_settings) > 0 ? base64encode(local.netplan_network_file) : "",
      private_network_file_path             = local.netplan_network_file_path,
      network_merge_script_path             = local.netplan_network_merge_script_path
      network_merge_script_base64           = length(var.private_networks_settings) > 0 ? base64encode(local.netplan_network_merge_script) : "",
      additional_users                      = var.additional_users,
      additional_hosts_entries_file_base64  = length(var.additional_hosts_entries) > 0 ? base64encode(local.additional_hosts_entries_file) : "",
      additional_hosts_entries_file_path    = local.additional_hosts_entries_file_path
      additional_write_files                = var.additional_write_files,
      additional_run_commands               = var.additional_run_commands
    }
  )
}