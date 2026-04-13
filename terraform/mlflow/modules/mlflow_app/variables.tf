variable "project_name" {
  description = "Prefix used for MLflow application resource names."
  type        = string
}

variable "location" {
  description = "Hetzner location for the MLflow application server."
  type        = string
}

variable "server_type" {
  description = "Hetzner server type for the MLflow application server."
  type        = string
}

variable "image" {
  description = "Hetzner OS image for the MLflow application server."
  type        = string
}

variable "ssh_key_ids" {
  description = "Hetzner SSH key IDs to install on the MLflow application server."
  type        = list(number)
}

variable "network_id" {
  description = "Private network ID used by the MLflow application server."
  type        = number
}

variable "subnet_id" {
  description = "Private subnet ID for the MLflow application server."
  type        = number
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH on the MLflow application server."
  type        = list(string)
}

variable "mlflow_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the MLflow port."
  type        = list(string)
}

variable "mlflow_port" {
  description = "Port exposed by the MLflow server."
  type        = number
}

variable "public_ipv4_enabled" {
  description = "Whether the MLflow application server should have a public IPv4 address."
  type        = bool
}

variable "public_ipv6_enabled" {
  description = "Whether the MLflow application server should have a public IPv6 address."
  type        = bool
}

variable "cloud_init" {
  description = "Rendered cloud-init content for the MLflow application server."
  type        = string
  default     = ""
}
