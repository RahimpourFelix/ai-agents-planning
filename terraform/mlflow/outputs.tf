output "private_network_id" {
  description = "ID of the private network for the MLflow stack."
  value       = hcloud_network.private.id
}

output "mlflow_server_name" {
  description = "Name of the MLflow application server."
  value       = module.mlflow_app.server_name
}

output "mlflow_server_ipv4" {
  description = "Public IPv4 address of the MLflow application server for SSH access."
  value       = module.mlflow_app.server_ipv4
}

output "mlflow_server_private_ip" {
  description = "Private IPv4 address of the MLflow application server."
  value       = module.mlflow_app.private_ip
}

output "postgres_server_name" {
  description = "Name of the PostgreSQL metadata server."
  value       = module.postgres.server_name
}

output "postgres_server_private_ip" {
  description = "Private IPv4 address of the PostgreSQL metadata server."
  value       = module.postgres.private_ip
}

output "postgres_volume_name" {
  description = "Name of the Hetzner volume attached to PostgreSQL."
  value       = module.postgres.volume_name
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for reaching MLflow privately from an operator workstation."
  value       = "ssh -L ${var.mlflow.port}:127.0.0.1:${var.mlflow.port} ubuntu@${module.mlflow_app.server_ipv4}"
}

output "mlflow_local_url" {
  description = "URL to open after the SSH tunnel is established."
  value       = "http://127.0.0.1:${var.mlflow.port}"
}

output "artifact_bucket" {
  description = "Hetzner Object Storage bucket used for MLflow artifacts and PostgreSQL backups."
  value       = nonsensitive(var.object_storage.bucket)
}
