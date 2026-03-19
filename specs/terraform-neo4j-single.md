# Terraform + Hetzner Neo4j Single Node Spec

## Goal

Provision a demo single-node Neo4j deployment on Hetzner Cloud with Terraform.

The initial rollout should use:

- 1 Neo4j VM
- 1 small reverse proxy VM
- optional private networking between the proxy and the Neo4j node
- persistent storage for database data

This environment is explicitly a demo and development-style deployment, not a production-grade highly available system.

## Important Design Note

This spec is intentionally for a single Neo4j node running Community Edition.

That means:

- no clustering
- no leader election
- no Enterprise-only clustering features
- simpler provisioning and lower cost
- no high availability at the database layer

This is the right choice when:

- Enterprise clustering is not required
- the workload is modest
- cost and simplicity matter more than HA
- the goal is a straightforward first Neo4j deployment

## Scope

This spec covers:

- infrastructure layout on Hetzner Cloud
- Terraform-managed resources
- bootstrap sequence for a single Neo4j node
- reverse proxy usage
- operational pitfalls
- basic scaling paths from the initial single-node baseline

This spec does not yet cover:

- clustering
- cross-node replication
- automated failover
- full CI/CD automation
- multi-region failover
- Kubernetes-based deployment

## Assumptions

This spec makes the following explicit assumptions for the first implementation:

- Neo4j edition: `Neo4j Community Edition`
- Neo4j version: `5.26`
- OS image: `ubuntu-24.04`
- installation method: native package install on the VM, not a container-based deployment
- cluster size for the first rollout: `1` node
- access proxy type: one small reverse proxy VM running `Caddy`, `Nginx`, or `HAProxy`
- Browser/UI access path: through the reverse proxy VM
- driver access path: through the node DNS name or a private-network address, not through the reverse proxy by default
- TLS termination for Browser/UI: at the reverse proxy VM
- public Bolt access: disabled by default
- public exposure default: HTTP(S) only
- SSH access: key-based admin access without assuming fixed source IPs

These assumptions are intentionally opinionated so the Terraform implementation has a concrete target instead of leaving critical deployment choices open.

## Target Architecture

### Initial Demo Topology

- `neo4j-1`: small Hetzner VM, attached data volume
- `neo4j-proxy`: small reverse proxy VM
- `neo4j-net`: optional private network between proxy and database node

### Traffic Model

Use the reverse proxy primarily for:

- Neo4j Browser / HTTP access
- admin access patterns that benefit from one stable endpoint
- simple demo traffic

Since this is a single node deployment, there is no cluster routing to preserve between multiple members. Even so, it is still better to keep Browser/UI traffic and direct driver traffic conceptually separate.

Recommended approach:

- use the reverse proxy for HTTP(S) access to Browser and simple demos
- use the node DNS name or private address for driver access
- keep public Bolt disabled by default
- only proxy Bolt later if there is a clear operational reason to do so

### Access Patterns

Split access patterns explicitly:

- Browser/UI access: users connect to the reverse proxy VM over HTTP(S)
- driver access: applications connect to the Neo4j node DNS name or private address
- admin SSH access: direct to the proxy VM and Neo4j VM using SSH keys, ideally through VPN, a temporary firewall opening, or the Hetzner console when no fixed admin IPs are available

The reverse proxy is the default public entry point for Browser/UI traffic, but it is not the default public entry point for Bolt driver traffic.

## Terraform Resources

The Terraform stack should create the following:

### Core Infrastructure

- Hetzner provider configuration
- project variables for region, instance type, image, SSH keys, and volume size
- firewall rules
- 1 Neo4j server
- 1 persistent volume
- 1 reverse proxy VM
- optional private network and subnet
- optional DNS records

### Suggested Terraform Modules or Logical Units

- `network`
- `security`
- `compute`
- `storage`
- `proxy`
- `bootstrap`

Even if implemented in one Terraform root module initially, keep these concerns separated in file structure.

## Suggested Infrastructure Choices

### Node Size

Use a small Hetzner instance type for the first rollout, for example:

- `cpx21` if memory headroom is preferred
- `cx22` if cost is the main concern

Neo4j is memory-sensitive. If there is uncertainty, prefer the option with more RAM over slightly cheaper compute.

### Storage

The Neo4j node should have:

- one dedicated persistent volume for Neo4j data
- filesystem mounted to a stable path such as `/var/lib/neo4j`

Keep OS disk and data disk logically separate so the VM can be replaced without automatically discarding the database volume.

### Networking

Use a private network if:

- the proxy VM and Neo4j node should communicate without exposing the node directly
- future growth may add more application-side infrastructure

Restrict public exposure to:

- reverse proxy frontend ports for Browser/UI only
- SSH minimized and controlled with key-based access rather than relying on fixed admin IP allowlists

Direct public access to the Neo4j node should be kept minimal.

### OS Image

Use `ubuntu-24.04` as the exact server image for the first rollout.

Rationale:

- current LTS-style base image
- straightforward package management
- good operational familiarity

### Installation Method

Use a native package install on the VM, not a container install.

Rationale:

- simpler first Terraform rollout
- easier integration with attached block volumes
- fewer moving parts during bootstrap and rebuild
- more direct service management with `systemd`

Containerization can be revisited later, but it should not be the initial implementation path for this demo deployment.

### TLS Termination

For the initial implementation:

- Browser/UI TLS terminates at the reverse proxy VM
- backend traffic from the reverse proxy to the Neo4j node may remain private-network HTTP for the demo
- if public Bolt is enabled in a later phase, TLS for Bolt should terminate on the Neo4j node or be handled by a deliberately designed TCP proxy setup

This spec does not assume public Bolt access by default.

## Required Ports

The implementation shall make the following ports explicit in firewall rules, node config, and documentation:

- `7474`: Neo4j HTTP endpoint
- `7473`: Neo4j HTTPS endpoint
- `7687`: Neo4j Bolt endpoint

Exposure rules for this spec:

- `7474` and `7473` may be exposed behind the reverse proxy for Browser/UI access
- `7687` is not public by default
- `7687` may be exposed publicly only if explicitly enabled for the demo
- direct public access to Neo4j service ports on the node should be blocked unless there is an explicit reason to expose them

Only HTTP(S) is public by default.

## Rollout Steps

### 1. Create Terraform Base

Create a Terraform configuration that defines:

- Hetzner provider
- project-level variables
- common tags / labels
- outputs for public endpoints and private IPs

Include variables for:

- `server_type`
- `proxy_server_type`
- `location`
- `image`
- `ssh_keys`
- `volume_size_gb`
- `neo4j_version`
- `enable_public_bolt`
- `admin_ssh_access_mode`
- `browser_dns_name`
- `node_dns_name`

For this initial spec, `neo4j_version = 5.26`, `image = ubuntu-24.04`, and `enable_public_bolt = false`.

### 2. Provision Networking

Provision either:

- a private network between proxy and node, or
- a minimal direct-connect design with strict firewall rules

Preferred default:

- use a private network between the proxy VM and the Neo4j node

Requirements:

- the proxy can reach the Neo4j HTTP endpoint
- management access is restricted
- direct public access to Neo4j service ports is minimized

### 3. Provision Firewall Rules

Allow:

- SSH only through the chosen admin access method, for example VPN-restricted access, a short-lived firewall opening, or Hetzner console recovery access
- HTTP / HTTPS to the reverse proxy from approved sources or public internet if needed for demos
- Bolt only if explicitly required and enabled

Block:

- unrestricted SSH
- public Bolt when `enable_public_bolt = false`
- unnecessary direct access to `7474`, `7473`, and `7687` on the Neo4j node

Do not assume fixed source IPs for SSH administration. Preferred approaches are:

- SSH over a VPN such as WireGuard or Tailscale
- temporarily opening SSH during maintenance and closing it afterward
- using the Hetzner console for break-glass access

### 4. Provision the Neo4j Node

Terraform should create:

- the Neo4j VM
- the attached persistent volume
- network attachments
- cloud-init or bootstrap script

Bootstrap should install:

- Java if required by the chosen Neo4j packaging approach
- `Neo4j Community Edition 5.26`
- required OS packages
- monitoring agent if desired

Bootstrap should use the package-install path for the selected OS image rather than a container runtime.

### 5. Mount and Prepare Persistent Storage

On first boot:

- partition and format the attached volume if needed
- mount it to the Neo4j data path
- persist the mount in `fstab`
- ensure correct ownership for the Neo4j service user

### 6. Configure Neo4j

The node must be configured with:

- listen addresses
- advertised addresses
- memory settings appropriate to node size
- auth settings

Use a client-reachable DNS name for addresses that external clients are expected to use directly.

The configuration should be templated from Terraform inputs so node addresses are not manually edited after provisioning.

The implementation must not advertise addresses to clients that they cannot resolve or reach from their intended network.

### 7. Bootstrap the Node

Use a deterministic bootstrap sequence:

1. provision the Neo4j node
2. render the Neo4j config from Terraform inputs
3. start Neo4j
4. confirm the service is healthy
5. validate Browser/UI access and direct driver access expectations

Add explicit health checks after bootstrap rather than assuming service readiness from systemd alone.

### 8. Create the Reverse Proxy VM

Create a small reverse proxy VM and configure `Caddy`, `Nginx`, or `HAProxy` on it.

Required behaviour:

- frontend services for HTTP / HTTPS
- reverse proxy to the Neo4j Browser/UI endpoint
- DNS name for the Browser/UI endpoint pointing to the proxy VM

Preferred use:

- `Caddy` if simple HTTPS termination and straightforward config are preferred
- `Nginx` if a conventional HTTP reverse proxy setup is preferred
- `HAProxy` if future TCP / Bolt proxying is more likely

Optional:

- Bolt on `7687` only if needed for the demo and explicitly enabled

For the initial implementation:

- Browser/UI traffic is sent through the reverse proxy
- public Bolt remains disabled
- driver access should use the node DNS name or private-network address

### 9. Validate the Deployment

Validation should include:

- the Neo4j node reachable over the intended network path
- Neo4j service active
- Browser/UI health endpoint checks through the reverse proxy
- node-level health endpoint checks on the Neo4j VM
- a test write and read succeed
- reverse proxy health checks green
- advertised addresses visible to clients are resolvable and reachable from the intended client network

Validation should be explicit, not implied. At minimum:

1. confirm the reverse proxy health endpoint reports the backend healthy
2. confirm the Neo4j node responds on its expected health endpoint
3. confirm the Browser/UI DNS name resolves correctly
4. execute a test write
5. execute a test read that returns the written data
6. confirm the advertised node DNS name resolves and is reachable from the intended client environment

### 10. Document Recovery and Rebuild

For demo stability, define at least the basic rebuild procedure:

- replace a failed VM without destroying the data volume unintentionally
- reattach the volume if recovering the same node
- recreate the node cleanly if required
- validate the node comes back with the expected configuration

Lifecycle handling must be explicit:

- if the VM is lost but the data volume is intact and should remain the same logical node, detach the volume from the failed VM, attach it to the replacement VM, preserve the intended DNS identity, and validate the node starts cleanly
- if the old volume is damaged, stale, or should not carry forward the previous state, do not reuse it blindly
- if the node is rebuilt as a fresh database instance, make that explicit and do not assume the previous on-disk state is safe to reuse

Detach and reuse a volume when:

- the goal is to preserve the same logical node
- the on-disk state is trusted
- the original VM can no longer run concurrently elsewhere

Create a fresh node when:

- the old data directory is stale or untrusted
- the host identity is being deliberately replaced
- there is any doubt that the reused volume still represents a clean continuation of the previous node

## Configuration Guidance

### Terraform vs Configuration Management

Terraform should provision infrastructure and render initial bootstrap artifacts, but it is not ideal for ongoing in-place application reconfiguration.

Preferred split:

- Terraform provisions network, VMs, volumes, proxy VM, and bootstrap templates
- cloud-init handles first boot setup
- optional Ansible or simple scripts handle repeatable application config updates

This avoids turning every operational change into brittle instance recreation.

### Secrets

Do not hardcode:

- Neo4j admin password
- TLS private keys
- backup credentials

Use a secret source or inject them securely at deploy time.

### TLS

If the demo is externally accessible, prefer TLS for:

- Browser access
- Bolt if exposed publicly

Certificates must match the addresses Neo4j advertises to clients. A mismatch between reverse proxy hostname, node hostname, and Neo4j advertised addresses is a common source of failed connections.

For this spec, the default is:

- TLS terminates at the reverse proxy for Browser/UI traffic
- public Bolt is disabled unless explicitly enabled later

## Pitfalls and Risks

### 1. No Database-Layer High Availability

This is the biggest architectural limitation of the single-node design.

If the node fails:

- writes stop
- reads stop
- the service is unavailable until the node is restored or rebuilt

This is acceptable for a demo or low-risk environment, but it should be documented as a known limitation from day one.

### 2. Reverse Proxy Can Blur Access Expectations

The reverse proxy is useful for Browser/UI access, but it should not become an accidental substitute for all access patterns.

Risks include:

- treating Browser access and application driver access as identical
- exposing Bolt publicly without intending to
- making troubleshooting harder if the proxy hides whether a failure is in Neo4j or in the proxy

This is why the default access split in this spec is:

- Browser/UI via the reverse proxy
- driver access via the node DNS name or private-network address

### 3. Advertised Address Misconfiguration

If Neo4j advertises:

- a hostname clients cannot resolve
- a private address to clients outside the private network
- the reverse proxy hostname instead of the node hostname for direct driver usage

then client connectivity can fail in non-obvious ways.

### 4. Storage Performance and Latency

Neo4j performance depends heavily on:

- disk latency
- memory sizing
- page cache sizing

Cheap or undersized nodes may work for demos but can become unstable under import load, analytics load, or large graph traversals.

### 5. Volume Snapshots Are Not Enough by Themselves

Raw infrastructure snapshots are useful, but they are not always the safest logical backup approach for an active database.

For anything beyond basic demo recovery, plan for:

- Neo4j-aware backup procedures
- consistent backup scheduling
- restore testing

### 6. Terraform Drift vs Runtime Drift

Terraform may know that the VM exists, but not whether:

- Neo4j is actually healthy
- the data volume is mounted correctly
- the proxy still routes correctly
- application config drifted after manual fixes

Add runtime validation outside Terraform.

## Scaling Strategy

There are three practical scaling paths.

### 1. Vertical Scaling

Fastest option for a demo:

- move to a larger Hetzner instance type
- increase RAM first
- then adjust CPU and storage as needed

Use this when:

- the dataset grows
- memory pressure is the main bottleneck
- the workload is still operationally simple

### 2. Scale the Access Layer

If Browser/UI traffic grows, scale the access layer separately from the database node.

Options:

- resize the reverse proxy VM vertically
- replace the single proxy VM with a small redundant proxy pair later
- introduce a load balancer in front of proxy nodes only if access-layer HA becomes necessary

This keeps public-entry scaling separate from the database architecture.

### 3. Upgrade to an Enterprise Cluster Later

If the deployment outgrows a single node, move to a separate Enterprise cluster design rather than trying to treat the Community single-node deployment as if it were already clustered.

Use this when:

- high availability becomes required
- maintenance downtime becomes unacceptable
- read and write concurrency outgrow what a single node can comfortably handle

Preferred path:

1. keep the single-node deployment simple
2. validate data model, workload shape, and operating procedures
3. move to the dedicated cluster spec when HA or scale justifies it

## How to Scale This Specific Single-Node Deployment

### Near-Term Recommendation

Start with the single-node standard deployment, but plan the Terraform module boundaries so the following changes are easy:

- raise instance size later
- expand volume size later
- add per-node metadata and DNS outputs cleanly
- replace the single reverse proxy VM with a more redundant access layer later if needed
- migrate to the cluster spec later without rethinking the whole repository structure

### Preferred Upgrade Path

1. keep the initial single-node rollout simple
2. validate provisioning, bootstrap, proxying, and backup procedures
3. keep driver access separate from Browser/UI access
4. scale vertically first if the workload grows
5. move to the cluster spec only when HA or higher throughput actually justifies Enterprise Edition

### When to Scale

Scale vertically if:

- memory usage is the first bottleneck
- imports are slow because the node is too small
- the workload is still simple

Scale the access layer if:

- Browser/UI traffic grows independently of database load
- public endpoint resilience becomes important
- TLS termination or proxy configuration becomes a bottleneck

Move to the cluster spec if:

- downtime becomes unacceptable
- a single node is no longer sufficient
- HA or more advanced scaling is required

## Recommended Deliverables

The implementation work should produce:

- Terraform code for Hetzner network, firewall, compute, volume, and proxy VM
- bootstrap templates or cloud-init files for Neo4j installation
- parameterized Neo4j config templates
- a short runbook for bootstrap, validation, backup, and node replacement
- reverse proxy configuration for Browser/UI access
- outputs documenting node IPs, proxy address, and access endpoints
- explicit documentation of edition, version, OS image, install method, and TLS/Bolt access decisions

## Acceptance Criteria

The spec is satisfied when:

- Terraform can provision 1 Neo4j node in Hetzner Cloud
- the node has persistent storage attached and mounted
- the node is reachable over the intended network path
- Neo4j configuration is applied automatically
- the service starts successfully
- the reverse proxy exposes Browser/UI endpoints
- public access is HTTP(S) only by default
- Bolt is public only if explicitly enabled
- a test write and read both succeed
- client-visible advertised addresses are resolvable and reachable from the intended client network
- the path to vertical scaling, access-layer scaling, and later cluster migration is documented

## Final Recommendation

Proceed with the single-node Community Edition baseline if simplicity and lower cost matter more than HA.

The most important architectural note in this spec is:

- 1 Community Edition node is enough for a straightforward demo deployment
- a small reverse proxy VM is enough for Browser/UI access at this stage
- move to the cluster spec only when HA or larger-scale requirements actually justify it
