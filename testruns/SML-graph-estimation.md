# SML Graph + Vector Storage Estimation

## Entity Node Size

| Field                 | Example                          | Size             |
| --------------------- | -------------------------------- | ---------------- |
| canonical_name        | "theta wide-coat strip"          | ~22 bytes        |
| type                  | "Equipment.StaticEquipment.Pipe" | ~35 bytes        |
| embedding             | 768 floats                       | 3,072 bytes      |
| embedding_hash        | "decffba1caa486b4..."            | ~32 bytes        |
| failure_count         | 1                                | ~8 bytes         |
| incident_count        | 1                                | ~8 bytes         |
| last_seen             | datetime                         | ~30 bytes        |
| mention_count         | 2                                | ~8 bytes         |
| **Total**             |                                  | **~3,215 bytes** |
| **Without embedding** |                                  | **~143 bytes**   |

## Chunk Node Size

| Component         | Size             |
| ----------------- | ---------------- |
| doc_id + metadata | included         |
| raw text (~500B)  | ~500 bytes       |
| position          | included         |
| embedding (768)   | 3,072 bytes      |
| **Total**         | **~3,584 bytes** |

Notes:
- Raw text size varies depending on chunking strategy

## Relationship Size

| Component          | Size           |
| ------------------ | -------------- |
| confidence         | included       |
| source_document    | included       |
| source_span        | ~200 bytes     |
| review_status      | included       |
| timestamp          | included       |
| **Total per edge** | **~254 bytes** |

Observations

- Relationships outnumber nodes significantly
- Storage is dominated by relationships, not nodes
- Removing source_span / source_document reduces size but removes traceability
- Embeddings are unavoidable in vector-based systems
- Neo4j stores embeddings in a separate HNSW index (not part of traversal record)
- Node size without embeddings drops to ~134–143 bytes

## Example Dataset (Measured)

| Metric        | Value  |
| ------------- | ------ |
| Nodes         | 2,647  |
| Relationships | 27,869 |
| Total size    | ~10 MB |

## Larger Dataset Example (SML subset)

| Metric        | Value   |
| ------------- | ------- |
| Nodes         | 5,740   |
| Relationships | 457,402 |

## Scaling Estimate

| Input Size    | Estimated Storage |
| ------------- | ----------------- |
| ~200k tickets | ~1.5 GB           |
