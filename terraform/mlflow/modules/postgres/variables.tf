variable "project_name" {
  description = "Prefix used for PostgreSQL resource names."
  type        = string
}

variable "location" {
  description = "Hetzner location for the PostgreSQL server."
  type        = string
}

variable "server_type" {
  description = "Hetzner server type for the PostgreSQL server."
  type        = string
}

variable "image" {
  description = "Hetzner OS image for the PostgreSQL server."
  type        = string
}

variable "ssh_key_ids" {
  description = "Hetzner SSH key IDs to install on the PostgreSQL server."
  type        = list(number)
}

variable "network_id" {
  description = "Private network ID used by the PostgreSQL server."
  type        = number
}

variable "subnet_id" {
  description = "Private subnet ID for the PostgreSQL server."
  type        = number
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH on the PostgreSQL server."
  type        = list(string)
}

variable "postgres_allowed_cidrs" {
  description = "CIDR blocks allowed to reach PostgreSQL."
  type        = list(string)
}

variable "postgres_port" {
  description = "Port exposed by PostgreSQL."
  type        = number
}

variable "volume_name" {
  description = "Name of the Hetzner volume attached to PostgreSQL."
  type        = string
}

variable "volume_size" {
  description = "Size of the Hetzner volume attached to PostgreSQL in GB."
  type        = number
}

variable "volume_format" {
  description = "Filesystem type expected on the PostgreSQL data volume."
  type        = string
}

variable "public_ipv4_enabled" {
  description = "Whether the PostgreSQL server should have a public IPv4 address."
  type        = bool
}

variable "public_ipv6_enabled" {
  description = "Whether the PostgreSQL server should have a public IPv6 address."
  type        = bool
}

variable "cloud_init" {
  description = "Rendered cloud-init content for the PostgreSQL server."
  type        = string
  default     = ""
}
