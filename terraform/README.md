# Terraform Hetzner Starter

This folder now starts with a generic Hetzner setup for Nuremberg:

- one `LB11` load balancer with TLS termination
- one `CPX11` app server
- one private network
- one firewall on the servers
- SSH access to the servers
- one managed DNS zone for `knowlestry.com`
- one managed certificate for `chat.knowlestry.com`

The structure is ready to scale horizontally by increasing `instance_count`, which will add more `CPX11` machines behind the same load balancer.

The customer-facing app stack now lives in `modules/customerapp`, while the root module keeps shared infrastructure such as provider config, SSH keys, network, and subnet.

## Terraform State In Hetzner Object Storage

This stack now uses Hetzner Object Storage via Terraform's built-in `s3` backend.

Configured values:

- bucket: `knowlestry-terraform`
- key: `terraform/customerapp.tfstate`
- endpoint: `https://nbg1.your-objectstorage.com`

### What "folder" means here

Object Storage does not need a real folder resource for Terraform state. The `key` value:

- `terraform/customerapp.tfstate`

acts like a `terraform/` folder inside the bucket.

### One-Time State Setup

The backend files are now already present in the root `terraform/` folder:

- `backend.tf`
- `backend.hcl`

Before running `terraform init`, provide your Hetzner Object Storage S3 credentials. You can either export them manually:

```bash
export AWS_ACCESS_KEY_ID="replace-me"
export AWS_SECRET_ACCESS_KEY="replace-me"
```

or let `./terraform.sh` prompt for them automatically.

Do not put these backend credentials into `terraform.tfvars`. The `s3` backend is initialized before normal Terraform input variables are loaded, so backend auth must come from environment variables or directly from `backend.hcl`.

If this stack has never been initialized against Object Storage before, initialize the backend:

```bash
./terraform.sh init
```

If you already have local state and want to move it into Object Storage, run this one time:

```bash
./terraform.sh init -migrate-state
```

You do not need `-migrate-state` again unless you move the state to a different backend, bucket, or key in the future.

### Daily Workflow

After the backend is set up, normal day-to-day work is just:

```bash
./terraform.sh plan
./terraform.sh apply
```

You only need to run `init` again when providers, modules, or backend configuration change.

### New Teammate Setup With Existing Remote State

If someone new starts working on this Terraform after the state already exists in Object Storage, they do not manually download the state file first.

They need:

- this repository
- access to the bucket `knowlestry-terraform`
- the Hetzner Object Storage S3 access key and secret key
- the local `backend.hcl` configuration, or the equivalent values recreated locally

Then they can run:

```bash
./terraform.sh init
./terraform.sh plan
```

Terraform will connect to the configured remote backend and use the existing state automatically.

The state object may not be visible in the bucket until Terraform has actually written state there. If there was no prior local state to migrate, the object is typically created after the first successful `apply`.

## Traffic Model

- Public traffic enters through the load balancer on `443`
- TLS terminates at the Hetzner load balancer using a managed certificate
- The load balancer forwards plain HTTP to the app servers on `customerapp.backend_port`
- App servers only allow app traffic from the private subnet
- SSH is still open to the servers based on `ssh_allowed_cidrs`

## Quick Start

1. Review `terraform.tfvars` and make sure these are set:

- `hcloud_token`
- `ssh_keys`
- `location = "nbg1"`
- `dns_zone = "knowlestry.com"`
- `customerapp.domain = "chat.knowlestry.com"`
- `customerapp.server_type = "cpx21"` or another available server type
- `customerapp.load_balancer_type = "lb11"`

2. Initialize Terraform:

   ```bash
   ./terraform.sh init
   ```

3. Review the plan:

   ```bash
   ./terraform.sh plan
   ```

4. Apply when ready:

   ```bash
   ./terraform.sh apply
   ```

## Notes

- This starter assumes TLS terminates on the Hetzner load balancer and the app listens on `customerapp.backend_port`, which now defaults to `80`.
- Module-specific settings such as server type, load balancer type, instance count, image, and backend port are grouped under the root `customerapp` variable because `terraform.tfvars` only applies to the root module.
- If your app listens on a different internal port, change `customerapp.backend_port`.
- Each admin should have their own entry in `ssh_keys` so access can be added or removed cleanly without sharing private keys.
- `terraform.tfvars` is for normal Terraform variables like `hcloud_token` and `ssh_keys`, not for backend S3 credentials.

## App Bootstrap

The `customerapp.cloud_init` field can be used to run first-boot setup on each app server. A starter example is included at:

- `cloud-init/chat-app-docker.yaml`

It currently:

- installs Docker from the official Docker apt repository
- enables the Docker service
- starts a placeholder container with `nginx:latest` on port `80`

To use it, set this inside the `customerapp` object in `terraform.tfvars`:

```hcl
customerapp = {
  domain             = "chat.knowlestry.com"
  server_type        = "cpx22"
  load_balancer_type = "lb11"
  instance_count     = 1
  image              = "ubuntu-24.04"
  backend_port       = 80
  cloud_init_file    = "cloud-init/chat-app-docker.yaml"
}
```

Use `cloud_init_file` in `terraform.tfvars`, not `file(...)` directly. Terraform variable files only accept literal values, so the actual file loading is done inside the Terraform configuration.

For your original placeholder, the main fixes were:

- `nginx:latest` should be published as `-p 80:80`, not `-p 80:8080`
- the Docker apt repository line is safer under `bash -lc`
- `gnupg` should be present before managing apt key material

## Good Next Steps

- tighten `ssh_allowed_cidrs` to your own IPs instead of the current open default
- add a cloud-init bootstrap for your app or reverse proxy
- raise `instance_count` when you want more servers behind the same load balancer
