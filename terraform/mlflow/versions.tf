terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }

    random = {
      source = "hashicorp/random"
    }
  }
}
