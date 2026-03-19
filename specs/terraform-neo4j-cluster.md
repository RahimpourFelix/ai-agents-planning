# Terraform + Hetzner Neo4j Cluster Spec

## Goal

Provision a demo Neo4j cluster on Hetzner Cloud with Terraform.

The initial rollout should use:

- 3 smaller Neo4j nodes
- 1 small reverse proxy VM
- private networking between cluster members
- persistent storage for database data

This cluster is explicitly a demo environment, not a production-grade deployment.

## Important Design Note

The standard baseline for this spec is a 3-node Neo4j cluster.

With 3 primary-capable nodes:

- the cluster has a sane quorum baseline
- leader election is operationally more realistic
- rolling maintenance is safer than with 2 nodes
- the topology is suitable as a standard clustered starting point

This cluster is still a demo environment, but it should start with the minimum topology that behaves like a real clustered deployment.

## Scope

This spec covers:

- infrastructure layout on Hetzner Cloud
- Terraform-managed resources
- bootstrap sequence for Neo4j clustering
- reverse proxy usage
- operational pitfalls
- scaling paths from the initial 3-node baseline

This spec does not yet cover:

- full CI/CD automation
- advanced backup orchestration
- multi-region failover
- Kubernetes-based deployment

## Assumptions

This spec makes the following explicit assumptions for the first implementation:

- Neo4j edition: `Neo4j Enterprise Edition`
- Neo4j version: `5.26 LTS`
- OS image: `ubuntu-24.04`
- installation method: native package install on the VM, not a container-based deployment
- cluster size for the first rollout: `3` nodes
- access proxy type: one small reverse proxy VM running `Caddy`, `Nginx`, or `HAProxy`
- Browser/UI access path: through the reverse proxy VM
- driver access path: through node DNS names or another routing-aware approach, not through the reverse proxy by default
- TLS termination for Browser/UI: at the reverse proxy VM
- Bolt load balancing: disabled by default
- public exposure default: HTTP(S) only
- SSH access: key-based admin access without assuming fixed source IPs

These assumptions are intentionally opinionated so the Terraform implementation has a concrete target instead of leaving critical deployment choices open.

## Target Architecture

### Initial Demo Topology

- `neo4j-1`: small Hetzner VM, private IP, attached data volume
- `neo4j-2`: small Hetzner VM, private IP, attached data volume
- `neo4j-3`: small Hetzner VM, private IP, attached data volume
- `neo4j-proxy`: small reverse proxy VM
- `neo4j-net`: private Hetzner network for intra-cluster traffic

### Traffic Model

Use the reverse proxy primarily for:

- Neo4j Browser / HTTP access
- admin access patterns that benefit from one stable endpoint
- simple demo traffic

Do not assume that a generic reverse proxy is the ideal entry point for Neo4j driver traffic.

Neo4j drivers are cluster-aware and often work better when clients connect with Neo4j routing enabled via `neo4j://` and a set of advertised addresses. A plain reverse proxy can interfere with routing discovery, leader targeting, or failure handling if it hides the actual cluster topology.

Recommended approach:

- use the reverse proxy for HTTP(S) access to Browser and simple demos
- use direct node addresses or DNS records for real driver-based cluster access
- keep Bolt load balancing disabled by default
- if Bolt is put behind the reverse proxy for the demo later, treat that as convenience rather than the long-term architecture

### Access Patterns

Split access patterns explicitly:

- Browser/UI access: users connect to the reverse proxy VM over HTTP(S)
- driver access: applications connect to node DNS names or another routing-aware access pattern that preserves Neo4j topology awareness
- admin SSH access: direct to nodes using SSH keys, ideally through VPN, a temporary firewall opening, or the Hetzner console when no fixed admin IPs are available

The reverse proxy is the default public entry point for Browser/UI traffic, but it is not the default public entry point for Bolt driver traffic.

## Terraform Resources

The Terraform stack should create the following:

### Core Infrastructure

- Hetzner provider configuration
- project variables for region, instance type, image, SSH keys, and node count
- private network and subnet
- firewall rules
- 3 Neo4j servers
- 3 persistent volumes
- 1 reverse proxy VM
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

Use smaller Hetzner instance types for the demo, for example:

- `cpx21` or similar if memory headroom is preferred
- `cx22` or similar if cost is the main concern

Neo4j is memory-sensitive. If there is uncertainty, prefer the option with more RAM over slightly cheaper compute.

### Storage

Each node should have:

- one dedicated persistent volume for Neo4j data
- filesystem mounted to a stable path such as `/var/lib/neo4j`

Keep OS disk and data disk logically separate so nodes can be replaced without losing data volumes.

### Networking

Use private IPs for:

- intra-cluster communication
- replication
- Raft / discovery traffic

Restrict public exposure to:

- reverse proxy frontend ports for Browser/UI only
- SSH minimized and controlled with key-based access rather than relying on fixed admin IP allowlists

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

Containerization can be revisited later, but it should not be the initial implementation path for this demo cluster.

### TLS Termination

For the initial implementation:

- Browser/UI TLS terminates at the reverse proxy VM
- backend traffic from the reverse proxy to the Neo4j nodes may remain private-network HTTP for the demo
- cluster-internal traffic stays on the private network
- if public Bolt is enabled in a later phase, TLS for Bolt should terminate on the Neo4j node or use a routing-aware design that preserves Neo4j driver behaviour

This spec does not assume public Bolt access by default.

## Required Ports

The implementation shall make the following ports explicit in firewall rules, node config, and documentation:

- `7474`: Neo4j HTTP endpoint
- `7473`: Neo4j HTTPS endpoint
- `7687`: Neo4j Bolt endpoint
- `6000`: cluster discovery / coordination on the private network
- `7000`: Raft / cluster consensus on the private network
- `7688`: cluster-internal service or admin traffic on the private network if enabled by the selected configuration

Exposure rules for this spec:

- `7474` and `7473` may be exposed behind the reverse proxy for Browser/UI access
- `7687` is not public by default
- `7687` may be exposed publicly only if explicitly enabled for the demo
- `6000`, `7000`, and `7688` must be private-network only
- direct public access to cluster ports on node public interfaces must be blocked

Only HTTP(S) is public by default.

## Rollout Steps

### 1. Create Terraform Base

Create a Terraform configuration that defines:

- Hetzner provider
- project-level variables
- common tags / labels
- outputs for public endpoints and private node IPs

Include variables for:

- `node_count`
- `server_type`
- `location`
- `image`
- `ssh_keys`
- `volume_size_gb`
- `neo4j_version`
- `enable_bolt_lb`
- `enable_public_bolt`
- `admin_ssh_access_mode`
- `browser_dns_name`
- `node_dns_names`

For this initial spec, `node_count = 3`.
For this initial spec, `neo4j_version = 5.26 LTS`, `image = ubuntu-24.04`, `enable_bolt_lb = false`, and `enable_public_bolt = false`.

### 2. Provision Private Network

Create a Hetzner private network and subnet for all Neo4j nodes.

Requirements:

- every node gets a stable private IP
- all cluster communication uses private addresses
- security groups / firewall rules allow only required east-west traffic

### 3. Provision Firewall Rules

Allow:

- SSH only through the chosen admin access method, for example VPN-restricted access, a short-lived firewall opening, or Hetzner console recovery access
- HTTP / HTTPS from approved sources or public internet if needed for demos
- Bolt only if explicitly required and explicitly enabled
- internal cluster ports only within the private network

Block:

- public access to internal cluster ports
- unrestricted SSH
- public Bolt when `enable_public_bolt = false`

Do not assume fixed source IPs for SSH administration. Preferred approaches are:

- SSH over a VPN such as WireGuard or Tailscale
- temporarily opening SSH during maintenance and closing it afterward
- using the Hetzner console for break-glass access

### 4. Provision Neo4j Nodes

For each node, Terraform should create:

- server instance
- attached persistent volume
- private network attachment
- cloud-init or bootstrap script

Bootstrap should install:

- Java if required by the chosen Neo4j packaging approach
- `Neo4j Enterprise Edition 5.26 LTS`
- required OS packages
- monitoring agent if desired

Bootstrap should use the package-install path for the selected OS image rather than a container runtime.

### 5. Mount and Prepare Persistent Storage

On first boot:

- partition and format the attached volume if needed
- mount it to the Neo4j data path
- persist the mount in `fstab`
- ensure correct ownership for the Neo4j service user

### 6. Configure Neo4j for Clustering

Each node must be configured with:

- a unique server identity
- listen addresses
- advertised addresses
- discovery / cluster member list
- memory settings appropriate to node size
- auth settings

Use private IPs for all advertised cluster-internal endpoints.
Use node DNS names for addresses that clients are expected to reach directly.

The configuration should be templated from Terraform inputs so node addresses are not manually edited after provisioning.

The implementation must not advertise addresses to clients that are only valid inside the private network unless those clients also run inside that same private network.

### 7. Bootstrap the Cluster

Use a deterministic bootstrap sequence:

1. provision all three Neo4j nodes
2. render cluster config with the full member list
3. start Neo4j on the first node
4. start Neo4j on the second node
5. start Neo4j on the third node
6. validate that the cluster has formed
7. confirm which node is leader

Add explicit health checks after bootstrap rather than assuming service readiness from systemd alone.

### 8. Create the Reverse Proxy VM

Create a small reverse proxy VM and configure `Caddy`, `Nginx`, or `HAProxy` on it.

Required behaviour:

- frontend services for HTTP / HTTPS
- reverse proxy to the Neo4j Browser/UI endpoints on the cluster nodes
- health checks against cluster members
- DNS name for the Browser/UI endpoint pointing to the proxy VM

Preferred use:

- `Caddy` if simple HTTPS termination and straightforward config are preferred
- `Nginx` if a conventional HTTP reverse proxy setup is preferred
- `HAProxy` if future TCP / Bolt proxying is more likely

Optional:

- Bolt on `7687` only if needed for the demo and explicitly enabled

If Bolt is exposed through the reverse proxy, document clearly that:

- this is a convenience endpoint
- driver routing may still require direct node awareness
- failover behaviour may differ from native Neo4j routing expectations

For the initial implementation:

- Browser/UI traffic is sent through the reverse proxy
- Bolt load balancing remains disabled
- driver access should use node DNS names or another routing-aware approach

### 9. Validate the Deployment

Validation should include:

- all three Neo4j nodes reachable over private network
- Neo4j service active on all three nodes
- Browser/UI health endpoint checks through the reverse proxy
- node-level health endpoint checks on each member
- `SHOW SERVERS` confirms all expected members are present
- a leader is visible and confirmed present
- writes and reads succeed
- reverse proxy health checks green
- advertised addresses visible to clients are resolvable and reachable from the intended client network

Validation should be explicit, not implied. At minimum:

1. confirm the reverse proxy health endpoint reports healthy upstreams
2. confirm each Neo4j node responds on its expected health endpoint
3. run `SHOW SERVERS` and confirm all three members are listed with the expected addresses and states
4. confirm a leader is present
5. execute a test write
6. execute a test read that returns the written data
7. confirm the Browser/UI DNS name resolves correctly
8. confirm each advertised node DNS name resolves and is reachable from the intended client environment

### 10. Document Recovery and Rebuild

For demo stability, define at least the basic rebuild procedure:

- replace a failed VM without destroying the data volume unintentionally
- reattach the volume if recovering the same member
- recreate the member cleanly if required
- rejoin the node to the cluster

Lifecycle handling must be explicit:

- if the VM is lost but the member data volume is intact and should remain the same logical member, detach the volume from the failed VM, attach it to the replacement VM, preserve the member identity, and validate that the node rejoins with the expected addresses
- if the old volume is damaged, stale, or should not carry forward the previous member state, do not reuse it blindly
- if the node is rebuilt as a fresh cluster member, reintroduce it cleanly rather than assuming the old cluster identity can be reused
- if stored cluster identity and the new runtime identity no longer match, unbind the member state before rejoining

Detach and reuse a volume when:

- the goal is to preserve the same logical node
- the on-disk state is trusted
- the original member can no longer run concurrently elsewhere

Create a fresh member or cleanly reintroduce / unbind when:

- the original node identity cannot be preserved safely
- the old data directory contains stale cluster metadata
- a replacement node is intended to join as a new member rather than resume the old one
- there is any doubt that the reused volume still represents a clean continuation of the previous member

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

Certificates must match the addresses Neo4j advertises to clients. A mismatch between reverse proxy hostname, node hostnames, and Neo4j advertised addresses is a common source of failed connections.

For this spec, the default is:

- TLS terminates at the reverse proxy for Browser/UI traffic
- public Bolt is disabled unless explicitly enabled later

## Pitfalls and Risks

### 1. Dropping Below Three Cluster Members

This is the biggest topology pitfall.

The standard design in this spec is 3 primary-capable nodes because that is the minimum sane clustered baseline. If one node is removed permanently without replacing it, the cluster becomes operationally much more fragile.

Risks include:

- reduced maintenance safety
- less headroom for failures
- more brittle leader changes
- operational pressure to keep every remaining node healthy at all times

### 2. Reverse Proxy Can Hide Cluster Topology

Neo4j cluster-aware drivers expect topology information and leader routing behaviour.

A generic reverse proxy can:

- send writes to the wrong node
- obscure the current leader
- create confusing failure behaviour
- make troubleshooting harder

Use the reverse proxy carefully and do not treat it as a complete substitute for native Neo4j routing.

This is why the default access split in this spec is:

- Browser/UI via the reverse proxy
- driver access via node DNS names or another routing-aware design

### 3. Advertised Address Misconfiguration

If Neo4j advertises:

- public IPs when it should use private IPs
- node hostnames that clients cannot resolve
- reverse proxy address instead of node addresses for internal cluster traffic

then cluster discovery or client connectivity can fail in non-obvious ways.

### 4. Storage Performance and Latency

Neo4j performance depends heavily on:

- disk latency
- memory sizing
- page cache sizing

Cheap or undersized nodes may work for demos but can become unstable under import load, analytics load, or large graph traversals.

### 5. Volume Snapshots Are Not Enough by Themselves

Raw infrastructure snapshots are useful, but they are not always the safest logical backup approach for a running clustered database.

For anything beyond basic demo recovery, plan for:

- Neo4j-aware backup procedures
- consistent backup scheduling
- restore testing

### 6. Rolling Changes Still Require Care

Even with 3 nodes, patching, resizing, or restarting members should be sequenced carefully.

Operational changes should assume:

- temporary cluster state changes during maintenance
- careful sequencing
- explicit validation after each restart

### 7. Terraform Drift vs Runtime Drift

Terraform may know that the VM exists, but not whether:

- Neo4j joined the cluster
- the correct node is leader
- the data volume is mounted correctly
- application config drifted after manual fixes

Add runtime validation outside Terraform.

## Scaling Strategy

There are three practical scaling paths.

### 1. Vertical Scaling

Fastest option for a demo:

- move to larger Hetzner instance types
- increase RAM first
- then adjust CPU and storage as needed

Use this when:

- the graph grows but topology stays simple
- the main pain point is memory pressure or query speed

### 2. Add Read Replicas / Secondary Nodes

After establishing a 3-primary cluster, scale read capacity by adding non-primary nodes if supported by the selected Neo4j edition and version.

Use this when:

- demo workloads evolve into read-heavy workloads
- multiple users are browsing or querying simultaneously
- writes are modest but graph exploration is frequent

Benefits:

- offload read traffic
- keep primary nodes focused on writes and cluster coordination
- improve resilience for read workloads

### 3. Scale the Access Layer

If Browser/UI traffic grows, scale the access layer separately from the database cluster.

Options:

- resize the reverse proxy VM vertically
- replace the single proxy VM with a small redundant proxy pair later
- reintroduce a load balancer in front of proxy nodes only if access-layer HA becomes necessary

This keeps cluster scaling and public-entry scaling as separate concerns.

## How to Scale This Specific Demo Cluster

### Near-Term Recommendation

Start with the 3-node standard cluster, but plan the Terraform module boundaries so the following changes are easy:

- raise `node_count` beyond `3`
- add per-node metadata and IP outputs
- template cluster member lists dynamically
- support different roles later if needed
- replace the single reverse proxy VM with a more redundant access layer later if needed

### Preferred Upgrade Path

1. keep the initial 3-node clustered rollout simple
2. validate provisioning, bootstrap, proxying, and backup procedures
3. keep driver access separate from Browser/UI access
4. add read replicas only after the 3-primary layout is stable
5. scale the reverse proxy layer only if Browser/UI traffic or public-entry requirements grow

### When to Scale

Scale vertically if:

- memory usage is the first bottleneck
- imports are slow because nodes are too small
- the workload is still simple

Scale with read replicas if:

- reads dominate
- more users need concurrent query access
- the primary nodes are healthy but query concurrency is growing

Scale the access layer if:

- Browser/UI traffic grows independently of database load
- public endpoint resilience becomes important
- TLS termination or proxy configuration becomes a bottleneck

## Recommended Deliverables

The implementation work should produce:

- Terraform code for Hetzner network, firewall, compute, volumes, and proxy VM
- bootstrap templates or cloud-init files for Neo4j installation
- parameterized Neo4j config templates
- a short runbook for bootstrap, validation, backup, and node replacement
- reverse proxy configuration for Browser/UI access
- outputs documenting node IPs, proxy address, and access endpoints
- explicit documentation of edition, version, OS image, install method, and TLS/Bolt access decisions

## Acceptance Criteria

The spec is satisfied when:

- Terraform can provision 3 Neo4j nodes in Hetzner Cloud
- each node has persistent storage attached and mounted
- nodes can communicate over a private network
- Neo4j cluster configuration is applied automatically
- the cluster forms successfully
- the reverse proxy exposes Browser/UI endpoints
- public access is HTTP(S) only by default
- Bolt is public only if explicitly enabled
- cluster ports remain private-network only
- `SHOW SERVERS` confirms the expected 3 members
- a leader is confirmed present
- a test write and read both succeed
- client-visible advertised addresses are resolvable and reachable from the intended client network
- the path to read scaling and access-layer scaling is documented

## Final Recommendation

Proceed with the 3-node clustered baseline and keep the public access layer simple.

The most important architectural note in this spec is:

- 3 primary nodes are the standard baseline
- a small reverse proxy VM is enough for Browser/UI access at this stage
- driver access should still avoid relying on the public proxy as a substitute for Neo4j cluster routing
