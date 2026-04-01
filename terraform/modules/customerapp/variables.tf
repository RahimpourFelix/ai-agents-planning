variable "project_name" {
  description = "Prefix used for customer app resource names."
  type        = string
}

variable "location" {
  description = "Hetzner location for all customer app resources."
  type        = string
}

variable "server_type" {
  description = "Hetzner server type for each customer app machine."
  type        = string
}

variable "load_balancer_type" {
  description = "Hetzner load balancer type for the customer app."
  type        = string
}

variable "instance_count" {
  description = "How many app servers should be created."
  type        = number
}

variable "image" {
  description = "Hetzner OS image for the servers."
  type        = string
}

variable "ssh_key_ids" {
  description = "Hetzner SSH key IDs to install on the servers."
  type        = list(number)
}

variable "network_id" {
  description = "Private network ID used by the servers and load balancer."
  type        = number
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH on the servers."
  type        = list(string)
}

variable "subnet_ip_range" {
  description = "Private subnet range allowed to reach the app port."
  type        = string
}

variable "backend_port" {
  description = "Port the app listens on behind the load balancer."
  type        = number
}

variable "cloud_init" {
  description = "Optional cloud-init user_data rendered into each server."
  type        = string
  default     = ""
}
