variable "hcloud_token" {
  description = "Hetzner Cloud API token."
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Prefix used for Hetzner resource names."
  type        = string
  default     = "app"
}

variable "location" {
  description = "Hetzner location for all resources. Use nbg1 for Nuremberg."
  type        = string
  default     = "nbg1"
}

variable "network_zone" {
  description = "Hetzner network zone for the private subnet."
  type        = string
  default     = "eu-central"
}

variable "customerapp" {
  description = "Customer app stack settings passed into the customerapp module."
  type = object({
    domain             = string
    server_type        = string
    load_balancer_type = string
    instance_count     = number
    image              = string
    backend_port       = number
    cloud_init         = optional(string, "")
  })
  default = {
    domain             = "knowlestry.com"
    server_type        = "cpx21"
    load_balancer_type = "lb11"
    instance_count     = 1
    image              = "ubuntu-24.04"
    backend_port       = 80
    cloud_init         = ""
  }
}

variable "ssh_keys" {
  description = "Named SSH public keys that should be uploaded to Hetzner and installed on the servers."
  type = list(object({
    name       = string
    public_key = string
  }))
}

variable "network_ip_range" {
  description = "IP range for the private network."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_ip_range" {
  description = "Subnet range for the private application subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach SSH on the servers."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

