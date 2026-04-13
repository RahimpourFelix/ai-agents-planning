locals {
  firewall_name = "${var.project_name}-postgres-fw"
  server_name   = "${var.project_name}-postgres-01"
}

resource "hcloud_firewall" "postgres" {
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
    for_each = var.postgres_allowed_cidrs
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = tostring(var.postgres_port)
      source_ips = [rule.value]
    }
  }
}

resource "hcloud_volume" "postgres_data" {
  name     = var.volume_name
  size     = var.volume_size
  location = var.location
  format   = var.volume_format
  labels = {
    project = var.project_name
    role    = "postgres-data"
  }
}

resource "hcloud_server" "postgres" {
  name        = local.server_name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = var.ssh_key_ids
  firewall_ids = [
    hcloud_firewall.postgres.id,
  ]

  labels = {
    project = var.project_name
    role    = "postgres"
  }

  public_net {
    ipv4_enabled = var.public_ipv4_enabled
    ipv6_enabled = var.public_ipv6_enabled
  }

  user_data = var.cloud_init != "" ? var.cloud_init : null
}

resource "hcloud_server_network" "postgres" {
  server_id  = hcloud_server.postgres.id
  network_id = var.network_id
  subnet_id  = var.subnet_id
}

resource "hcloud_volume_attachment" "postgres_data" {
  volume_id = hcloud_volume.postgres_data.id
  server_id = hcloud_server.postgres.id
  automount = false
}
