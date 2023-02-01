/*
Terraform module for creating Hetzner cloud compatible user-data file
Copyright (C) 2023 Wojciech Szychta

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
variable "server_type" {
  type    = string
  default = ""
}

variable "server_image" {
  type    = string
  default = ""
}

variable "additional_users" {
  type = list(object({
    username        = string
    sudo_options    = string
    ssh_public_keys = list(string)
  }))
  default = []
}

variable "private_networks_only" {
  type    = bool
  default = false
}

variable "private_networks_settings" {
  type = list(object(
    {
      network_id = string
      ip         = string
      alias_ips  = list(string)
      routes     = map(list(string))
      nameservers = object(
        {
          addresses = list(string)
          search    = list(string)
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
  type    = list(string)
  default = []
}

variable "additional_packages" {
  type    = list(string)
  default = []
}

variable "upgrade_all_packages" {
  type    = bool
  default = true
}

variable "reboot_instance" {
  type    = bool
  default = true
}

variable "timezone" {
  type    = string
  default = "Europe/Berlin"
}

variable "yq_version" {
  type    = string
  default = "v4.30.5"
}

variable "yq_binary" {
  type    = string
  default = "yq_linux_amd64"
}