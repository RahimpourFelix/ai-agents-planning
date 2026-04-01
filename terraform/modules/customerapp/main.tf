locals {
  load_balancer_name = "${var.project_name}-lb"
  firewall_name      = "${var.project_name}-app-fw"
}

resource "hcloud_firewall" "app" {
  name = local.firewall_name

  dynamic "rule" {
    for_each = var.ssh_allowed_cidrs
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "22"
      source_ips = [rule.value]
    }
  }

  dynamic "rule" {
    for_each = [var.subnet_ip_range]
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = tostring(var.backend_port)
      source_ips = [rule.value]
    }
  }
}

resource "hcloud_server" "app" {
  count       = var.instance_count
  name        = format("%s-app-%02d", var.project_name, count.index + 1)
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = var.ssh_key_ids
  firewall_ids = [
    hcloud_firewall.app.id
  ]

  labels = {
    project = var.project_name
    role    = "app"
  }

  user_data = var.cloud_init != "" ? var.cloud_init : null
}

resource "hcloud_server_network" "app" {
  count      = var.instance_count
  server_id  = hcloud_server.app[count.index].id
  network_id = var.network_id
}

resource "hcloud_load_balancer" "app" {
  name               = local.load_balancer_name
  load_balancer_type = var.load_balancer_type
  location           = var.location

  algorithm {
    type = "round_robin"
  }
}

resource "hcloud_load_balancer_network" "app" {
  load_balancer_id = hcloud_load_balancer.app.id
  network_id       = var.network_id
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.app.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = var.backend_port
  proxyprotocol    = false

  health_check {
    protocol = "tcp"
    port     = var.backend_port
    interval = 10
    timeout  = 10
    retries  = 3
  }
}

resource "hcloud_load_balancer_target" "app" {
  count            = var.instance_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.app.id
  server_id        = hcloud_server.app[count.index].id
  use_private_ip   = true

  depends_on = [
    hcloud_server_network.app,
    hcloud_load_balancer_network.app,
  ]
}
