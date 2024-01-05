variable "name" {
  type = string
}

variable "image" {
  type = string
  default = "images:debian/bookworm"
}

variable "profiles" {
  type    = list(string)
  default = []
}

variable "autostart" {
  type    = bool
  default = false
}

variable "mount_dirs" {
  type    = list(string)
  default = []
}

variable "exec_enabled" {
  type    = bool
  default = true
}

variable "exec" {
  type    = string
  default = "/mnt/install.sh"
}

variable "local_exec_interpreter" {
  type    = list(string)
  default = ["/bin/bash", "-c"]
}

variable "environment" {
  type    = map(any)
  default = {}
}

variable "nicparent" {
  type = string
}

variable "nicname" {
  type    = string
  default = "eth0"
}

variable "nictype" {
  type    = string
  default = "bridged"
}

variable "ipv4_address" {
  type = string
}

variable "bind_port" {
  type = number
}

variable "servers" {
  type = list(object({
    address = string
    port    = string
  }))
}
