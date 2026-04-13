locals {
  firewall_name = "${var.project_name}-mlflow-fw"
  server_name   = "${var.project_name}-mlflow-01"
}

resource "hcloud_firewall" "mlflow" {
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
    for_each = var.mlflow_allowed_cidrs
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = tostring(var.mlflow_port)
      source_ips = [rule.value]
    }
  }
}

resource "hcloud_server" "mlflow" {
  name        = local.server_name
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = var.ssh_key_ids
  firewall_ids = [
    hcloud_firewall.mlflow.id,
  ]

  labels = {
    project = var.project_name
    role    = "mlflow"
  }

  public_net {
    ipv4_enabled = var.public_ipv4_enabled
    ipv6_enabled = var.public_ipv6_enabled
  }

  user_data = var.cloud_init != "" ? var.cloud_init : null
}

resource "hcloud_server_network" "mlflow" {
  server_id  = hcloud_server.mlflow.id
  network_id = var.network_id
  subnet_id  = var.subnet_id
}
