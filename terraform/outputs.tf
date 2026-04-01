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
