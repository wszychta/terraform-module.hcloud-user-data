variable "server_type" {
  type      = string
  default   = ""
}

variable "server_image" {
  type      = string
  default   = ""
}

variable "additional_users" {
  type = list(object({
    username        = string
    sudo_options    = string
    ssh_public_keys = list(string)
  }))
  default = []
}

variable "private_networks_settings" {
  type = list(object(
    {
      routes                = map(list(string))
      nameservers           = object(
        {
          addresses           = list(string)
          search              = list(string)
        }
      )
    }
  ))
  default = []
}

variable "additional_write_files" {
  type = list(object({
    content     = string
    owner_user  = string
    owner_group = string
    destination = string
    permissions = string
  }))
  default = []
}

variable "additional_hosts_entries" {
  type = list(object({
    ip        = string
    hostnames = list(string)
  }))
  default = []
}

variable "additional_run_commands" {
  type = list(string)
  default = []
}

variable "upgrade_all_packages" {
  type = bool
  default = true
}

variable "reboot_instance" {
  type = bool
  default = true
}

variable "timezone" {
  type = string
  default = "Europe/Berlin"
}

variable "yq_version" {
  type = string
  default = "v4.6.3"
}

variable "yq_binary" {
  type = string
  default = "yq_linux_amd64"
}