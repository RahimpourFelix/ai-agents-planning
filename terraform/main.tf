provider "hcloud" {
  token = var.hcloud_token
}

locals {
  network_name = "${var.project_name}-net"
}

resource "hcloud_ssh_key" "admin" {
  for_each = {
    for key in var.ssh_keys : key.name => key
  }

  name       = "${var.project_name}-${each.value.name}"
  public_key = each.value.public_key
}

resource "hcloud_network" "private" {
  name     = local.network_name
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "private" {
  network_id   = hcloud_network.private.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_ip_range
}

resource "hcloud_zone" "customerapp" {
  name = var.customerapp.domain
  mode = "primary"
}

module "customerapp" {
  source = "./modules/customerapp"

  project_name       = var.project_name
  location           = var.location
  domain             = var.customerapp.domain
  server_type        = var.customerapp.server_type
  load_balancer_type = var.customerapp.load_balancer_type
  instance_count     = var.customerapp.instance_count
  image              = var.customerapp.image
  ssh_key_ids        = [for key in hcloud_ssh_key.admin : key.id]
  network_id         = hcloud_network.private.id
  ssh_allowed_cidrs  = var.ssh_allowed_cidrs
  subnet_ip_range    = var.subnet_ip_range
  backend_port       = var.customerapp.backend_port
  cloud_init         = var.customerapp.cloud_init

  depends_on = [
    hcloud_network_subnet.private,
    hcloud_zone.customerapp,
  ]
}

resource "hcloud_zone_rrset" "customerapp_apex_a" {
  zone = hcloud_zone.customerapp.name
  name = "@"
  type = "A"
  records = [{
    value = module.customerapp.load_balancer_ipv4
  }]
}
