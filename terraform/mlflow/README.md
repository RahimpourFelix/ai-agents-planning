# Terraform MLflow Stack

This stack deploys a private-only MLflow installation on Hetzner Cloud with:

- one MLflow application VM
- one PostgreSQL VM
- one attached Hetzner Volume for PostgreSQL data
- one private network with separate `app` and `data` subnets
- one pre-created Hetzner Object Storage bucket for MLflow artifacts and PostgreSQL backups

The MLflow UI and API are intended to be reached through an SSH tunnel instead of a public load balancer or public DNS record.

## Layout

- `main.tf`: shared network, SSH keys, password generation, and module wiring
- `modules/mlflow_app`: the MLflow VM, firewall, and private network attachment
- `modules/postgres`: the PostgreSQL VM, firewall, volume, and private network attachment
- `cloud-init/mlflow.yaml`: Docker-based MLflow bootstrap
- `cloud-init/postgres.yaml`: PostgreSQL bootstrap, volume mount, and backup job

## Remote State

This stack uses the same Hetzner Object Storage backend pattern as the root `terraform/` stack, but with a dedicated state key.

1. Create a local `backend.hcl` next to this `README.md` by using `backend.hcl.example` as the starting point.
2. Export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, or let `./terraform.sh` prompt for them.
3. Initialize the stack:

```bash
./terraform.sh init
```

The example backend key is:

- `terraform/mlflow.tfstate`

## Configuration

Start from `terraform.tfvars.example` and create a local `terraform.tfvars` in this directory.

Important inputs:

- `ssh_allowed_cidrs`: operator IP allowlist for SSH access to the MLflow host
- `ssh_keys`: individual admin SSH public keys
- `object_storage`: pre-created bucket and credentials
- `mlflow.version`: pinned MLflow version installed into the app container
- `postgres.database_password`: database password, or leave blank to let Terraform generate one

The PostgreSQL VM defaults to private networking only. The MLflow VM keeps a public IPv4 address for SSH, but TCP `5000` is not opened to the public internet.

## Bootstrap Behavior

`cloud-init/mlflow.yaml`:

- installs Docker and the Compose plugin
- builds a pinned MLflow container image on first boot
- configures PostgreSQL as the backend store
- configures Hetzner Object Storage as the artifact destination
- registers a `systemd` unit so MLflow comes back after reboots

`cloud-init/postgres.yaml`:

- installs PostgreSQL from Ubuntu packages
- waits for the attached Hetzner Volume and mounts it at `/var/lib/postgresql`
- recreates the main PostgreSQL cluster on the attached volume
- restricts database access to the MLflow app subnet
- creates the MLflow database and user
- uploads nightly `pg_dump` backups to the configured Object Storage bucket

## Daily Workflow

```bash
./terraform.sh plan
./terraform.sh apply
```

## Verification

After `apply`, inspect the outputs:

- `ssh_tunnel_command`
- `mlflow_local_url`
- `mlflow_server_ipv4`
- `postgres_server_private_ip`

Then:

1. Start the SSH tunnel using the `ssh_tunnel_command` output.
2. Open the `mlflow_local_url` output in your browser.
3. Confirm the service is healthy on the host:

```bash
ssh ubuntu@<mlflow-public-ip> sudo /usr/local/bin/check-mlflow.sh
```

4. Create a test experiment and upload a small artifact.
5. Confirm artifacts land in the configured Object Storage bucket.
6. Verify PostgreSQL backups appear under `s3://<bucket>/postgres/<hostname>/`.

## Notes

- This stack intentionally does not create a public load balancer, DNS zone, or TLS certificate.
- If you want Terraform to manage the artifact bucket itself, add an S3-compatible provider and bucket resource in a later iteration.
- Tighten `ssh_allowed_cidrs` to known operator IPs before applying in production.
