output "server_name" {
  description = "Name of the PostgreSQL server."
  value       = hcloud_server.postgres.name
}

output "private_ip" {
  description = "Private IPv4 address of the PostgreSQL server."
  value       = hcloud_server_network.postgres.ip
}

output "volume_name" {
  description = "Name of the Hetzner volume attached to PostgreSQL."
  value       = hcloud_volume.postgres_data.name
}
