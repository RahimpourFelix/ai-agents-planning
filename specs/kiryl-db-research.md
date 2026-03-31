---

## Eliminated Options

### Neo4j
- URL: https://neo4j.com/
- Clustering requires **Enterprise license** (not free)
- AuraDB (Hosted): $65/GB/Month → 16GB = $1,040/mo, 50GB = $3,250/mo
- Self-Hosted: ~$2,000–3,000/mo minimum
- Multi-tenancy: Enterprise only
- Startup Program: up to $16k credits, decision in 3–5 days — worth trying if nothing else works
- **Verdict: Too expensive for a startup unless Startup Program credits accepted**

### Memgraph
- URL: https://memgraph.com/
- Cypher-compatible, similar to Neo4j
- $25k/year for 16GB (~$2,000/month)
- Multi-tenancy: Enterprise only
- Clustering: Enterprise only
- **Verdict: Eliminated — too expensive, same problems as Neo4j**

### ArangoDB
- URL: https://arangodb.com/
- Multi-model (graph + document + vector + search) — technically very capable
- **⚠️ License changed from Apache 2.0 → BSL 1.1 starting v3.12 (2024)**
- Community Edition explicitly: *"does not include the right to Commercial use or rights to distribute or embed within other products"*
- Community Edition data limit: **100GB per cluster**
- Source: https://arangodb.com/community-license/
- Enterprise Edition: custom pricing (contact sales)
- **Verdict: Eliminated — Community Edition cannot be used for B2B SaaS commercially**

### ChromaDB
- URL: https://www.trychroma.com/
- Lightweight, good for local dev/prototyping only
- No real clustering, not production-ready at scale
- **Verdict: Eliminated — dev/prototype tool only**

### Apache AGE (PostgreSQL extension)
- URL: https://age.apache.org/
- Cypher-like queries on top of PostgreSQL
- Still immature — deep graph queries (3+ hops) are slow
- Clustering depends entirely on PostgreSQL setup (complex)
- **Verdict: Eliminated — too immature for production graph workloads**

---

## ⚠️ Possible but Complex

### JanusGraph
- URL: https://janusgraph.org/
- Fully open source, Apache 2.0 — commercially usable ✅
- Native distributed clustering ✅
- Mature and battle-tested ✅
- **Problem: NOT a standalone DB** — requires:
  - Cassandra or HBase (storage backend)
  - Elasticsearch or OpenSearch (index backend)
  - = 3 separate systems to operate
- Vector search: only through Elasticsearch (not native graph-vector)
- Query language: Gremlin (not Cypher)
- **Verdict: Possible, but ops complexity is very high for a startup. Only consider if engineering bandwidth allows.**

### Dgraph
- URL: https://dgraph.io/
- Fully open source, Apache 2.0 — commercially usable ✅
- Native distributed clustering out of the box ✅
- Good CI/CD — Kubernetes operator available ✅
- **Problem: Query language is GraphQL+**, not Cypher — significant learning curve and fewer LLM framework integrations
- Vector search: weak/limited
- LangChain / LlamaIndex integrations: minimal
- **Verdict: Possible if team is okay with GraphQL+, but loses Neo4j parity on query language and LLM tooling**

### PostgreSQL + pgvector
- URL: https://github.com/pgvector/pgvector
- Free, Apache 2.0, commercially usable ✅
- Excellent CI/CD, Postgres ecosystem is best-in-class ✅
- Vector search: native via pgvector ✅
- **Problem: Not a graph DB** — no native graph traversal
- Graph-like queries possible with recursive CTEs but slow at scale
- Clustering: possible via Citus or Patroni but complex
- **Verdict: Good if graph traversal depth is shallow (1–2 hops). Not suitable for deep GraphRAG.**

---

## Top Candidate

### FalkorDB (Self-Hosted OSS)
- URL: https://falkordb.com/
- GitHub: https://github.com/FalkorDB/FalkorDB
- License: **Apache 2.0** — fully commercially usable ✅
- Built specifically for **GraphRAG** use cases ✅
- Native vector search (HNSW index) ✅
- **OpenCypher compatible** — same query language as Neo4j ✅
- Native multi-tenancy (multiple isolated graphs per instance) ✅
- LangChain + LlamaIndex integrations exist ✅

#### Cluster (Self-Hosted)
- Cluster deployment via Docker: https://docs.falkordb.com/operations/cluster.html
- Kubernetes via Helm chart + KubeBlocks operator: https://docs.falkordb.com/operations/kubeblocks.html
- Supports: standalone / replication / sharding topologies
- **Free in self-hosted OSS — cluster is NOT behind a paywall**

#### Cloud Plans (FalkorDB managed — NOT needed if self-hosting)
| Plan | Price | Cluster |
|---|---|---|
| FREE | $0 | ❌ |
| STARTUP | $73/1GB/mo | ❌ |
| PRO | $350/8GB/mo | ✅ |
| ENTERPRISE | Custom | ✅ |

> These cloud plans are irrelevant if you self-host on GCP/Hetzner — you get cluster for free.

#### Limitations / Risks
- Young project (seed stage, Tel Aviv) — smaller community than Neo4j
- No built-in graph algorithm library (like Neo4j GDS) — no Louvain, PageRank out of the box
- Workaround for clustering/graph algorithms: export to NetworkX or run sklearn-based clustering on embeddings

#### Docs
- Operations overview: https://docs.falkordb.com/operations/
- Vector search: https://docs.falkordb.com/vector-search.html
- Performance benchmarks vs Neo4j: https://benchmark.falkordb.com/

---

## Vector DB (Standalone — if graph DB doesn't cover it)

> Note: FalkorDB has native vector search, so a separate vector DB may not be needed.

### Qdrant
- URL: https://qdrant.tech/
- Open-source, Apache 2.0 ✅
- Strong production readiness, filtering, clustering
- Clustering possible but manual scaling
- **Best standalone vector DB if needed separately**

### Weaviate
- URL: https://weaviate.io/
- More platform-oriented, built-in modules
- Base cloud cost ~$45/mo
- **Good but overkill if FalkorDB handles vectors**

### Milvus
- URL: https://milvus.io/
- Highly scalable, designed for massive deployments
- Complex to operate
- **Only relevant at very large scale**

---

## Summary Table

| DB | License | Commercial | Cluster (free) | Cypher | Vector | LLM integrations | Verdict |
|---|---|---|---|---|---|---|---|
| **FalkorDB OSS** | Apache 2.0 | ✅ | ✅ self-hosted | ✅ | ✅ native | ✅ | ⭐ Top pick |
| **Dgraph** | Apache 2.0 | ✅ | ✅ native | ❌ GraphQL+ | ⚠️ weak | ⚠️ limited | Backup option |
| **JanusGraph** | Apache 2.0 | ✅ | ✅ native | ❌ Gremlin | ⚠️ via ES | ⚠️ limited | Too complex |
| **pgvector+AGE** | Apache 2.0 | ✅ | ⚠️ complex | ⚠️ AGE syroi | ✅ | ✅ | Not for deep graph |
| **ArangoDB** | BSL 1.1 | ❌ Community | ✅ | ❌ AQL | ✅ | ✅ | License blocks B2B |
| **Neo4j** | Commercial | ✅ | ❌ Enterprise$ | ✅ | ✅ | ✅ best | Too expensive |
| **Memgraph** | Commercial | ✅ | ❌ Enterprise$ | ✅ | ✅ | ✅ | Too expensive |

---

## Recommendation

**Go with FalkorDB self-hosted on GCP/Hetzner via Kubernetes.**

- Zero licensing cost
- Covers GraphRAG, chunk nodes + embeddings natively
- Cluster + HA available free via KubeBlocks / Helm
- Cypher = no relearning from Neo4j
- Multi-tenancy built-in for B2B clients
- If graph algorithms (Louvain etc.) become critical later → run NetworkX/sklearn offline and write results back as node properties

**Only reconsider if:**
- FalkorDB's maturity becomes a production risk → then Neo4j Startup Program ($16k credits) is the fallback
- Graph traversal depth is shallow and data is relational → then pgvector alone might suffice
