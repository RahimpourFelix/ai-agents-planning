output "load_balancer_name" {
  description = "Name of the load balancer."
  value       = module.customerapp.load_balancer_name
}

output "load_balancer_ipv4" {
  description = "Public IPv4 address of the load balancer."
  value       = module.customerapp.load_balancer_ipv4
}

output "server_names" {
  description = "Names of the app servers."
  value       = module.customerapp.server_names
}

output "server_ipv4_addresses" {
  description = "Public IPv4 addresses of the app servers for SSH."
  value       = module.customerapp.server_ipv4_addresses
}

output "private_network_id" {
  description = "ID of the private network."
  value       = hcloud_network.private.id
}

output "customerapp_domain" {
  description = "Domain name configured for the customer app."
  value       = var.customerapp.domain
}

output "dns_zone" {
  description = "Hetzner DNS zone managed for this stack."
  value       = hcloud_zone.customerapp.name
}

output "customerapp_zone_nameservers" {
  description = "Hetzner authoritative nameservers to delegate the customer app zone to."
  value       = hcloud_zone.customerapp.authoritative_nameservers
}
