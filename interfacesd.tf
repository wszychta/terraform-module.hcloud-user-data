
locals {
  interfaced_network_file = length(var.private_networks_settings) > 0 && var.server_type != "" ? templatefile(
    "${path.module}/config_templates/interfacesd/private_network.tmpl",
    {
      server_type               = var.server_type,
      private_networks_settings = var.private_networks_settings
    }
  ) : ""
  interfaced_network_file_path = "/etc/network/interfaces.d/61-my-private-network.cfg"

  # resolvconf file with all nameservers inside it
  interfaced_nameservers_file_path = "/etc/resolvconf/resolv.conf.d/head"
  interfaced_nameservers_list      = compact(flatten([for network_settings in var.private_networks_settings : network_settings.nameservers.addresses]))
  interfaced_nameservers_file      = length(local.interfaced_nameservers_list) == 0 ? "" : templatefile(
    "${path.module}/config_templates/interfacesd/nameservers_file.tmpl",
    {
      nameservers_list = local.interfaced_nameservers_list
      nameservers_file_path = local.interfaced_nameservers_file_path
    }
  )

  # Cloud config final file output
  interfaced_cloud_config_file = templatefile(
    "${path.module}/config_templates/interfacesd/cloud_init.yaml.tmpl",
    {
      private_network_file_base64           = length(var.private_networks_settings) > 0 ? base64encode(local.interfaced_network_file) : "",
      private_network_file_path             = local.interfaced_network_file_path,
      nameservers_file_base64               = length(local.interfaced_nameservers_list) > 0 ? base64encode(local.interfaced_nameservers_file) : ""
      nameservers_file_path                 = local.interfaced_nameservers_file_path
      additional_users                      = var.additional_users,
      additional_hosts_entries_file_base64  = length(var.additional_hosts_entries) > 0 ? base64encode(local.additional_hosts_entries_file) : "",
      additional_hosts_entries_file_path    = local.additional_hosts_entries_file_path
      additional_write_files                = var.additional_write_files,
      additional_run_commands               = var.additional_run_commands
    }
  )
}