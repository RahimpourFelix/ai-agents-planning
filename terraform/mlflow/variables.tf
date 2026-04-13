variable "hcloud_token" {
  description = "Hetzner Cloud API token."
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Prefix used for MLflow resource names."
  type        = string
  default     = "mlflow"
}

variable "location" {
  description = "Hetzner location for all MLflow resources."
  type        = string
  default     = "nbg1"
}

variable "network_zone" {
  description = "Hetzner network zone for the private subnets."
  type        = string
  default     = "eu-central"
}

variable "network_ip_range" {
  description = "IP range for the private MLflow network."
  type        = string
  default     = "10.20.0.0/16"
}

variable "app_subnet_ip_range" {
  description = "CIDR range for the MLflow application subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "data_subnet_ip_range" {
  description = "CIDR range for the PostgreSQL subnet."
  type        = string
  default     = "10.20.2.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH on the MLflow app server."
  type        = list(string)
}

variable "ssh_keys" {
  description = "Named SSH public keys that should be uploaded to Hetzner and installed on the servers."
  type = list(object({
    name       = string
    public_key = string
  }))
}

variable "object_storage" {
  description = "Pre-created Hetzner Object Storage bucket and credentials for MLflow artifacts and PostgreSQL backups."
  type = object({
    endpoint   = string
    bucket     = string
    access_key = string
    secret_key = string
    region     = optional(string, "main")
  })
  sensitive = true
}

variable "mlflow" {
  description = "MLflow application settings."
  type = object({
    server_type         = string
    image               = string
    port                = number
    version             = string
    public_ipv4_enabled = optional(bool, true)
    public_ipv6_enabled = optional(bool, false)
    cloud_init_file     = optional(string, "cloud-init/mlflow.yaml")
    cloud_init          = optional(string, "")
  })
  default = {
    server_type         = "cpx21"
    image               = "ubuntu-24.04"
    port                = 5000
    version             = "3.5.0"
    public_ipv4_enabled = true
    public_ipv6_enabled = false
    cloud_init_file     = "cloud-init/mlflow.yaml"
    cloud_init          = ""
  }
}

variable "postgres" {
  description = "PostgreSQL settings for the MLflow metadata store."
  type = object({
    server_type           = string
    image                 = string
    version               = number
    volume_size           = number
    volume_format         = optional(string, "ext4")
    database_name         = string
    database_user         = string
    database_password     = optional(string, "")
    backup_schedule       = optional(string, "17 3 * * *")
    backup_retention_days = optional(number, 7)
    public_ipv4_enabled   = optional(bool, false)
    public_ipv6_enabled   = optional(bool, false)
    cloud_init_file       = optional(string, "cloud-init/postgres.yaml")
    cloud_init            = optional(string, "")
  })
  default = {
    server_type           = "cpx21"
    image                 = "ubuntu-24.04"
    version               = 16
    volume_size           = 50
    volume_format         = "ext4"
    database_name         = "mlflow"
    database_user         = "mlflow"
    database_password     = ""
    backup_schedule       = "17 3 * * *"
    backup_retention_days = 7
    public_ipv4_enabled   = false
    public_ipv6_enabled   = false
    cloud_init_file       = "cloud-init/postgres.yaml"
    cloud_init            = ""
  }
  sensitive = true
}
