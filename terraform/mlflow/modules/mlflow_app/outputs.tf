output "server_name" {
  description = "Name of the MLflow application server."
  value       = hcloud_server.mlflow.name
}

output "server_ipv4" {
  description = "Public IPv4 address of the MLflow application server."
  value       = hcloud_server.mlflow.ipv4_address
}

output "private_ip" {
  description = "Private IPv4 address of the MLflow application server."
  value       = hcloud_server_network.mlflow.ip
}
