output "load_balancer_name" {
  description = "Name of the customer app load balancer."
  value       = hcloud_load_balancer.app.name
}

output "load_balancer_ipv4" {
  description = "Public IPv4 address of the customer app load balancer."
  value       = hcloud_load_balancer.app.ipv4
}

output "server_names" {
  description = "Names of the customer app servers."
  value       = [for server in hcloud_server.app : server.name]
}

output "server_ipv4_addresses" {
  description = "Public IPv4 addresses of the customer app servers."
  value       = [for server in hcloud_server.app : server.ipv4_address]
}
