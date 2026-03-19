## Neo4j

- Startup Programm
	- accept/reject within 3-5 days
    - Credits up to 16k
- AuraDB (Hosted)
    - $65/GB/Month
- Self-Hosted
	- Min. 64GB
	- most likely lower price (sales didn't know how much)
    - 64 GB * 30 = $1920
- Dimensions of customers:
    - <1000000 = small 
    - 1 trillion = biggest
    - 1m to 5m = medium

## Graph DB

- **Neo4j**
    - URL: [https://neo4j.com/](https://neo4j.com/)
    - Graph database with built-in vector search; clustering requires Enterprise license.
    - 50 GB = $3250
    - 16 GB = $1040
    - Self-Hosted: ~$2000-3000 min.
- **Memgraph**
    - URL: [https://memgraph.com/](https://memgraph.com/)
    - Cypher-compatible graph database similar to Neo4j; clustering requires enterprise features.
    - 25k / year for 16 GB (~$2000/month)
    - Multitenancy only for Enterprise
- **ArangoDB**
    - URL: [https://www.arangodb.com/](https://www.arangodb.com/)
    - Multi-model database (graph + document + search) with built-in clustering in open source.
    - **FREE for only ArangoDB incl. cluster self-hosted**
- **JanusGraph**
    - URL: [https://janusgraph.org/](https://janusgraph.org/)
    - Distributed graph database on top of Cassandra/HBase + Elasticsearch/OpenSearch; fully open source looks complex
    - **FREE self-hosted**
- **Dgraph**
    - URL: [https://dgraph.io/](https://dgraph.io/)
    - Distributed graph database with built-in clustering; uses GraphQL-based query language instead of Cypher.
    - **FREE self-hosted**
## Vector DB

- **Qdrant**
    - URL: [https://qdrant.tech/](https://qdrant.tech/)
    - Open-source vector database with clustering, filtering, and strong production readiness.
    - Clustering possible, but scaling is manually
- **Weaviate**
    - URL: [https://weaviate.io/](https://weaviate.io/)
    - Vector database with built-in modules and clustering; more platform-oriented.
    - Pricing for SML maybe $1 but base cost is $45
- **Milvus**
    - URL: [https://milvus.io/](https://milvus.io/)
    - Highly scalable vector database designed for large-scale deployments.
    - COMPLEX BUT POWERFUL
- **ChromaDB**
    - URL: [https://www.trychroma.com/](https://www.trychroma.com/)
    - Lightweight vector database for local development and prototyping; no real clustering.

## Postgres based

- **PostgreSQL + pgvector**
    - URL: [https://github.com/pgvector/pgvector](https://github.com/pgvector/pgvector)
    - Traditional relational database extended with vector search; simple and widely used.
- **Apache AGE (PostgreSQL extension)**
    - URL: [https://age.apache.org/](https://age.apache.org/)
    - Graph extension for PostgreSQL adding Cypher-like queries; clustering depends on PostgreSQL setup.