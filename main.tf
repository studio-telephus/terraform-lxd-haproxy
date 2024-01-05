locals {
  node_variable_prefix = "HAPROXY_NODE_"
  haproxy_nodes = [for i, item in var.servers : {
    key : "${local.node_variable_prefix}${i}",
    value : "${item.address}:${item.port}"
  }]
}

resource "null_resource" "container_environment" {
  triggers = {
    for item in local.haproxy_nodes : item.key => item.value
  }
}

module "container_haproxy" {
  source    = "github.com/studio-telephus/terraform-lxd-instance.git?ref=1.0.3"
  name      = var.name
  profiles  = var.profiles
  image     = var.image
  autostart = var.autostart
  nic = {
    name = var.nicname
    properties = {
      nictype        = var.nictype
      parent         = var.nicparent
      "ipv4.address" = var.ipv4_address
    }
  }
  mount_dirs             = concat(["${path.module}/filesystem", ], var.mount_dirs)
  exec_enabled           = var.exec_enabled
  exec                   = var.exec
  local_exec_interpreter = var.local_exec_interpreter
  environment = merge(
    null_resource.container_environment.triggers,
    {
      "NODE_VARIABLE_PREFIX" = local.node_variable_prefix
      "BIND_PORT"            = var.bind_port
    },
    var.environment
  )
}