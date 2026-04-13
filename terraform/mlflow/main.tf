provider "hcloud" {
  token = var.hcloud_token
}

locals {
  network_name         = "${var.project_name}-net"
  postgres_port        = 5432
  postgres_volume_name = "${var.project_name}-postgres-data"
  postgres_volume_path = "/dev/disk/by-id/scsi-0HC_Volume_${local.postgres_volume_name}"
  postgres_password    = var.postgres.database_password != "" ? var.postgres.database_password : random_password.postgres[0].result
  object_storage_host  = trimsuffix(trimprefix(var.object_storage.endpoint, "https://"), "/")

  postgres_cloud_init = var.postgres.cloud_init_file != "" ? templatefile(var.postgres.cloud_init_file, {
    postgres_version        = var.postgres.version
    postgres_port           = local.postgres_port
    postgres_data_device    = local.postgres_volume_path
    postgres_data_mount     = "/var/lib/postgresql"
    postgres_allowed_cidr   = var.app_subnet_ip_range
    postgres_database       = var.postgres.database_name
    postgres_user           = var.postgres.database_user
    postgres_password       = local.postgres_password
    backup_schedule         = var.postgres.backup_schedule
    backup_retention_days   = var.postgres.backup_retention_days
    object_storage_endpoint = var.object_storage.endpoint
    object_storage_bucket   = var.object_storage.bucket
    object_storage_host     = local.object_storage_host
    object_storage_region   = var.object_storage.region
    object_storage_key      = var.object_storage.access_key
    object_storage_secret   = var.object_storage.secret_key
  }) : var.postgres.cloud_init

  mlflow_cloud_init = var.mlflow.cloud_init_file != "" ? templatefile(var.mlflow.cloud_init_file, {
    mlflow_version          = var.mlflow.version
    mlflow_port             = var.mlflow.port
    postgres_host           = module.postgres.private_ip
    postgres_port           = local.postgres_port
    postgres_database       = var.postgres.database_name
    postgres_user           = var.postgres.database_user
    postgres_password       = local.postgres_password
    object_storage_bucket   = var.object_storage.bucket
    object_storage_endpoint = var.object_storage.endpoint
    object_storage_host     = local.object_storage_host
    object_storage_region   = var.object_storage.region
    object_storage_key      = var.object_storage.access_key
    object_storage_secret   = var.object_storage.secret_key
  }) : var.mlflow.cloud_init
}

resource "random_password" "postgres" {
  count   = var.postgres.database_password == "" ? 1 : 0
  length  = 32
  special = false
}

resource "hcloud_ssh_key" "admin" {
  for_each = {
    for key in var.ssh_keys : key.name => key
  }

  name       = "${var.project_name}-${each.value.name}"
  public_key = each.value.public_key
}

resource "hcloud_network" "private" {
  name     = local.network_name
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "app" {
  network_id   = hcloud_network.private.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.app_subnet_ip_range
}

resource "hcloud_network_subnet" "data" {
  network_id   = hcloud_network.private.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.data_subnet_ip_range
}

module "postgres" {
  source = "./modules/postgres"

  project_name           = var.project_name
  location               = var.location
  server_type            = var.postgres.server_type
  image                  = var.postgres.image
  ssh_key_ids            = [for key in hcloud_ssh_key.admin : key.id]
  network_id             = hcloud_network.private.id
  subnet_id              = hcloud_network_subnet.data.id
  ssh_allowed_cidrs      = []
  postgres_allowed_cidrs = [var.app_subnet_ip_range]
  postgres_port          = local.postgres_port
  volume_name            = local.postgres_volume_name
  volume_size            = var.postgres.volume_size
  volume_format          = var.postgres.volume_format
  public_ipv4_enabled    = var.postgres.public_ipv4_enabled
  public_ipv6_enabled    = var.postgres.public_ipv6_enabled
  cloud_init             = local.postgres_cloud_init

  depends_on = [
    hcloud_network_subnet.app,
    hcloud_network_subnet.data,
  ]
}

module "mlflow_app" {
  source = "./modules/mlflow_app"

  project_name         = var.project_name
  location             = var.location
  server_type          = var.mlflow.server_type
  image                = var.mlflow.image
  ssh_key_ids          = [for key in hcloud_ssh_key.admin : key.id]
  network_id           = hcloud_network.private.id
  subnet_id            = hcloud_network_subnet.app.id
  ssh_allowed_cidrs    = var.ssh_allowed_cidrs
  mlflow_allowed_cidrs = [var.app_subnet_ip_range]
  mlflow_port          = var.mlflow.port
  public_ipv4_enabled  = var.mlflow.public_ipv4_enabled
  public_ipv6_enabled  = var.mlflow.public_ipv6_enabled
  cloud_init           = local.mlflow_cloud_init

  depends_on = [
    hcloud_network_subnet.app,
    hcloud_network_subnet.data,
    module.postgres,
  ]
}
