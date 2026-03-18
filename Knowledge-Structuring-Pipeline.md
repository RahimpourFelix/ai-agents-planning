KNOWLEDGE STRUCTURING PIPELINE -- END-TO-END SYSTEM OVERVIEW
=============================================================



TABLE OF CONTENTS
-----------------
  1. What This System Does
  2. Input Data -- What Comes In, What Works Best
  3. Pipeline Overview -- High-Level Flow
  4. Configuration (settings.yaml)
  5. Living Documents -- Self-Growing Knowledge Base. (*PARAMETER - is it better with a list of seed documents? or we should start clean for each new client. Ask the clients if they have some documentstion - we can build the seed living documents from it. We can also do custom client evaluation using that)
  extra - (treat ground truth and messy data differently - will help in the eval and rulebook phase)
  6. Ingestion Pipeline -- From Raw Text to Knowledge Graph
  7. Knowledge Graph -- Neo4j Storage Model
  8. Retrieval Strategies -- Query Resolution (Detailed)
  9. QA Evaluation Framework
 10. Ingestion Evaluation Framework
 11. Current Limitations and Improvement Roadmap


================================================================================
1. WHAT THIS SYSTEM DOES
================================================================================

Takes raw, unstructured maintenance work orders (noisy, abbreviated, misspelled
text written by field technicians) and turns them into a structured knowledge
graph. Then answers natural language questions against that graph using multiple
retrieval strategies.

The system is designed to learn the domain from the data itself, without
pre-defined domain dictionaries or manual entity lists. It starts with a
minimal seed ontology and vocabulary, and grows its understanding over time
through a living documents mechanism.

End-to-end flow:
  Raw tickets --> LLM extraction --> Entity resolution --> Confidence scoring
  --> Knowledge graph (Neo4j) --> Multiple retrieval strategies --> QA answers


================================================================================
2. INPUT DATA -- WHAT COMES IN, WHAT WORKS BEST
================================================================================
-extra:
OVERALL GOAL:
KH is supposed to describe the real system behaviour in the best possible way without ambiguous referneces.
WE want to make the underlying hidden information visible to everyone
What makes good qualified data in the KH:
- agents need to be able to use it well
- no typos, formal strcutured
- content-dependent 
- rulebook 
    * status quo is in the ticket, descr. of the situation and the was was done to  resolve it (in the KH - 1) if-then/ condition-consequence 2) action 3) process description 4) concept relations/ hierarchy)
    * in tickets we have 100s of examples of individual situations -> we want to get to general descriptions of situations/ system behaviour
    * how do we evaluate the rulebook
FORMAT
------
  - JSON array of ticket objects
  - Each ticket has at minimum: an ID field and a text field
  - Field names are configurable in settings.yaml (input.id_col, input.text_col)
  - CSV is also supported (one row per ticket)

  Example:
    {"ticket_id": "TK-0042", "description": "HRM-M on L1 tripping on overload
     again. slab temp must be too low. reduct at 52%. cf. doc 9960"}

WHAT MAKES GOOD INPUT DATA
---------------------------

  - Tickets that explicitly mention equipment names, error codes, parameters
  - Structured abbreviations the system can learn (HRM, CRM, AF, etc.)
  - Enough volume for patterns to emerge (50-100 minimum, 500+ ideal)
  - Mix of routine and complex tickets for diverse knowledge extraction

WHAT MAKES BAD INPUT DATA
--------------------------
  - Extremely short tickets (under 20 words) -- too little context for triples
  - Tickets with only implicit references ("the machine broke again" with no
    specifics) -- LLM cannot extract structured facts
  - Heavy use of internal codes never defined anywhere in any ticket -- the
    system can still extract them as entities but cannot resolve what they mean
  - Very long tickets (1000+ words) -- chunking helps but extraction quality
    can degrade

WHAT THE SYSTEM HANDLES WELL
-----------------------------
  - Typos, abbreviations, missing punctuation (designed for noisy text)
  - Mixed languages or jargon within tickets
  - Incomplete sentences and telegraphic style
  - Implicit relationships (if enough context exists in surrounding text)

FAILURE MODES TO EXPECT
------------------------
  - Tickets with implicit error codes (error described but code never stated)
    tend to produce zero triples -- 12 of 19 failures in our test run
  - Very noisy text with garbled characters or control tokens reduces yield
  - Tickets describing multiple unrelated issues in one block split poorly


================================================================================
3. PIPELINE OVERVIEW -- HIGH-LEVEL FLOW
================================================================================

  INGESTION (offline, batch)
  --------------------------
    Step 0:  Term Ranking (TF-IDF + BM25 + spaCy phrase extraction)
    Step 1:  Chunking (dual tokenizer: Gemma for Vertex, tiktoken for OpenAI)
    Step 2:  LLM Extraction (schema-constrained triple extraction). If we plug in a fine tuned model here it will be a lot more reliable and require less human feedback. We need special data to fine tune - 
    Step 2b: Type Bridging (4-tier alignment to ontology)
    Step 6a: Confidence Scoring (4-factor objective score)
    Step 6b: Routing (auto-add vs review queue)
    Step 7:  Entity Resolution (exact -> fuzzy -> semantic cascade)
    Step 8:  Neo4j Write (high-confidence triples only)
    Step 9:  Reasoning (Clingo ASP rule-based inference)
    +        Document Refinement (auto-update living documents)
    +        Review Queue (items for human review)

-note for later - how can we imporve this using the industrial context. including the typical questions that industry needs answered

  POST-INGESTION (offline, batch)
  --------------------------------
    Embedding:     Generate BGE embeddings for entities and chunks
    Vector Index:  Create HNSW indexes in Neo4j
    BM25 Index:    Build keyword search index from chunk texts
    LightRAG:      Build community summaries (for S1 strategy)

  QUERY RESOLUTION (online, per question)
  ----------------------------------------
    Strategy selection -> Retrieval (vector + graph + keyword) -> Answer generation

  EVALUATION (offline, batch)
  ----------------------------
    Run all strategies on evaluation questions -> automatic metrics + LLM judge


================================================================================
4. CONFIGURATION (settings.yaml)
================================================================================

  Location: v4_pipeline/config/settings.yaml

  PROJECT METADATA
  ----------------
    name:     V4 Living Documents Pipeline
    version:  0.4.0

  PATHS
  -----
    living_documents:    living_documents/
    thesaurus:           living_documents/dictionaries/thesaurus.json
    ontology:            living_documents/dictionaries/ontology.json
    few_shot_examples:   living_documents/examples/few_shot_examples.json
    failed_cypher_log:   living_documents/failed_cypher_queries.json

  LLM SETTINGS
  -------------
    model:               gemini-2.5-flash-lite  (Vertex AI, configurable)
    provider:            vertex  (or openai)
    temperature:         0.0  (deterministic extraction)
    max_tokens:          16384  (global), 4096 (extraction override)

  INPUT SETTINGS
  ---------------
    id_col:              ticket_id
    text_col:            description

  EXTRACTION
  -----------
    max_workers:         10  (parallel ticket processing)
    requests_per_minute: 200  (proactive rate limiter)
    max_tokens:          4096
    use_instructor:      true  (Pydantic schema-constrained output)
    instructor_retries:  0  (fallback to manual JSON parsing on failure)
    min_triples:         1  (warn if ticket yields fewer)
    max_triples:         50  (cap per ticket)

  CHUNKING
  ---------
    max_tokens:          2500  (per chunk, in LLM tokens)
    overlap_tokens:      200
    short_ticket:        500 chars  (skip chunking below this)

  CONFIDENCE SCORING
  -------------------
    auto_add_threshold:  0.70  (triples above this go directly to graph)
    quick_review:        0.50  (triples between 0.50-0.70 need quick review)
    below 0.50:          full review required

    Weights (4 factors):
      source_grounding:    0.40  (is the triple grounded in source text?)
      thesaurus_match:     0.20  (are entities in the vocabulary?)
      taxonomy_compliance: 0.20  (do entity types exist in ontology?)
      relation_validity:   0.20  (is the relation well-formed?)

    Type constraint checking enabled by default (replaces legacy PMI filtering)

  ENTITY RESOLUTION
  ------------------
    Fuzzy matching (RapidFuzz):
      auto_threshold:    0.95  (auto-merge above this)
      suggest_threshold: 0.90  (suggest merge, needs review)
    Semantic matching (BGE embeddings):
      auto_threshold:    0.90
      suggest_threshold: 0.85

  NEO4J
  ------
    uri:                 bolt://localhost:7687
    include_ontology:    false  (write ontology types as nodes)
    include_instance_of: false  (add INSTANCE_OF edges)

  REASONING
  ----------
    engine:              clingo  (Answer Set Programming)
    alternative:         legacy  (custom forward-chaining, slower)

  RETRIEVAL
  ----------
    Embedding:
      model:             BAAI/bge-base-en-v1.5  (768-dim)
      batch_size:        128
    Vector indexes:
      entity_index:      entity_embeddings  (HNSW, cosine)
      chunk_index:       chunk_embeddings   (HNSW, cosine)
      entity_top_k:      5
      chunk_top_k:       10
    Graph expansion:
      max_hops:          2
      max_nodes:         200
      max_paths:         50
    Text-to-Cypher:
      hybrid_mode:       true
      max_retries:       3
    S4 HybGRAG:
      max_iterations:    3
    Answer generation:
      max_context_tokens: 8000
      chunks_pct:        0.50
      graph_pct:         0.30
      community_pct:     0.20
    RRF fusion:
      k:                 60
      final_k:           5

  REFINEMENT
  -----------
    auto_apply_threshold: 0.85  (auto-update living docs above this)

  THESAURUS
  ----------
    970+ entries from MaintNorm, Mudlark, MaintKG, LexiClean, MWO2KG sources


================================================================================
5. LIVING DOCUMENTS -- SELF-GROWING KNOWLEDGE BASE
================================================================================

  CONCEPT
  -------
  Living documents are the system's evolving domain knowledge. They start from
  minimal seed sets and grow automatically as the pipeline processes more data.
  This is core to the design: the system learns domain vocabulary, entity types,
  and relation patterns from real data rather than requiring upfront definition.

  DIRECTORY STRUCTURE
  --------------------
    living_documents/
      dictionaries/
        ontology.json           Entity type hierarchy + relation types + rules
        thesaurus.json          Controlled vocabulary (canonical names, aliases)
        domain_dictionaries.json  970+ term corrections (typo -> canonical)
      examples/
        few_shot_examples.json  In-context learning examples for extraction
        cypher_examples.json    Few-shot examples for Cypher generation
        router_examples.json    Examples for S4 HybGRAG router
        critic_examples.json    Examples for S4 critic loop

  SEED SETS (starting point)
  --------------------------
    default_seed_sets/
      seed_dictionaries/
        ontology.json           Minimal type hierarchy (generic equipment types)
        thesaurus.json          Minimal vocabulary (common maintenance terms)

  HOW LIVING DOCUMENTS GROW
  --------------------------
  After each pipeline run:

    1. New entities discovered during extraction get proposed as thesaurus
       additions (with aliases learned from the tickets)

    2. New entity types proposed by the LLM get evaluated against the
       existing ontology -- if confidence >= 0.85 they are auto-added,
       otherwise queued for human review

    3. New relation types are proposed when the LLM uses relation names
       not in the ontology

    4. Few-shot examples are updated with high-quality extractions from
       the current run

    5. All changes are versioned with timestamps

  RESET
  ------
    scripts/tools/reset_living_documents.py
    Copies seed sets back to the active living_documents directory.
    Use this to start fresh. Creates a backup before overwriting.

  ONTOLOGY STRUCTURE
  -------------------
    Entity type hierarchy (dotted path notation):
      Equipment
        Equipment.RotatingEquipment
          Equipment.RotatingEquipment.Pump
          Equipment.RotatingEquipment.Motor
        Equipment.StaticEquipment
          Equipment.StaticEquipment.Vessel
        Equipment.Instrument
      Component
        Component.Mechanical
          Component.Mechanical.Bearing
          Component.Mechanical.Seal
      FailureMode
        FailureMode.Leakage
        FailureMode.Vibration
        FailureMode.Malfunction
      ProcessParameter
      System
        System.ProductionLine
      Value
        Value.Identifier
        Value.Measurement

    Relation types (with domain/range constraints):
      HAS_FAILURE_MODE:  Equipment/Component -> FailureMode
      HAS_COMPONENT:     Equipment -> Component
      LOCATED_ON:        Equipment -> System.ProductionLine
      HAS_PARAMETER:     Equipment -> ProcessParameter
      HAS_IDENTIFIER:    any -> Value.Identifier
      CAUSES:            FailureMode -> FailureMode
      TRIGGERS:          FailureMode -> FailureMode
      ...

    Inference rules (Datalog-style, executed by Clingo ASP):
      "if X HAS_PART Y and Y HAS_PART Z then X HAS_PART Z"

  THESAURUS STRUCTURE
  --------------------
    Each entry (SKOS-inspired hierarchy):
      canonical:    "Centrifugal Pump"
      type:         "Equipment.RotatingEquipment.Pump"
      aliases:      ["centrifugal", "CF pump", "cent. pump"]
      broader:      "pump"
      narrower:     ["cp-100", "cp-200"]
      confidence:   1.0
      source:       "seed_vocabulary" or "pipeline_discovery"


================================================================================
6. INGESTION PIPELINE -- FROM RAW TEXT TO KNOWLEDGE GRAPH
================================================================================

  STEP 0: TERM RANKING
  ----------------------
    Purpose:    Identify important domain terms before extraction
    Method:     TF-IDF + BM25 scoring + spaCy noun phrase extraction
    Output:     Ranked term list used to guide extraction prompts

  STEP 1: CHUNKING
  ------------------
    Purpose:    Split long tickets into LLM-digestible pieces
    Method:     Token-based sliding window (2500 tokens, 200 overlap)
    Tokenizer:  Gemma (Vertex AI) or tiktoken (OpenAI), auto-selected
    Skip:       Tickets under 500 characters processed as single chunk
    Dedup:      Triples deduplicated across overlapping chunks

  STEP 2: LLM EXTRACTION
  ------------------------
    Purpose:    Extract structured (subject, relation, object) triples from text
    Approach:   AutoSchemaKG-style
                (AutoSchemaKG paper -- LLM-driven KG construction with
                 ontology as soft reference, not hard constraint)

    LLM:        Gemini 2.5 Flash Lite via Vertex AI (Google GenAI SDK)
    Method:     Schema-constrained output via Instructor library (Pydantic)
                Fallback: manual JSON parsing if Instructor unavailable

    Prompt includes:
      - Ontology entity types (as reference, not requirement)
      - Thesaurus entries (known entities and aliases)
      - Few-shot examples (from living documents)
      - Source text chunk
      - Instruction to extract triples with confidence scores

    Output per triple:
      subject:        entity name (as found in text)
      subject_type:   dotted type path (from ontology or proposed new)
      relation:       UPPER_SNAKE_CASE relation name
      object:         entity name or value
      object_type:    dotted type path
      confidence:     0.0-1.0 (LLM self-assessed)
      source_span:    verbatim text from input
      reasoning:      1-sentence explanation

    Parallelization:  10 workers (ThreadPoolExecutor, configurable)
    Rate limiting:    200 RPM with exponential backoff on 429 errors
    Error handling:   Auth failures abort immediately, other errors logged

  STEP 2b: TYPE BRIDGING
  ------------------------
    Purpose:    Align LLM-proposed types to existing ontology
    Approach:   AutoSchemaKG-style 4-tier alignment
                (AutoSchemaKG paper -- taxonomy alignment step)

    Tiers:
      1. Exact match in ontology
      2. Substring/prefix match
      3. Semantic similarity (BGE embedding cosine)
      4. Create new type (flagged for review)

    Also normalizes relation names to UPPER_SNAKE_CASE convention

  STEP 6a: CONFIDENCE SCORING
  -----------------------------
    Purpose:    Objective quality score for each triple (replaces LLM self-report)
    Method:     4-factor weighted average + LLM modifier

    Factor 1: Source Grounding (weight 0.40)
      Checks if the triple's source_span actually appears in the ticket text
      Scores: 1.0 (exact match), 0.7 (fuzzy >85%), 0.5 (partial), 0.3 (missing)

    Factor 2: Thesaurus Match (weight 0.20)
      Checks if subject and object are known entities in the thesaurus
      Scores: 1.0 (both known), 0.7 (one known), 0.5 (types match), 0.3 (neither)

    Factor 3: Taxonomy Compliance (weight 0.20)
      Checks if entity types exist in the ontology hierarchy
      Scores: 1.0 (both exist), 0.7 (one exists), 0.3 (neither)

    Factor 4: Relation Validity (weight 0.20)
      Checks if relation type exists and domain/range constraints are satisfied
      Scores: 1.0 (valid + correct domain/range), 0.7 (valid, wrong domain/range),
              0.5 (unknown but proper format), 0.2 (malformed)

    Final computation:
      weighted_avg = 0.4*grounding + 0.2*thesaurus + 0.2*taxonomy + 0.2*relation
      llm_modifier = 0.8 + 0.2 * llm_confidence  (compresses self-report)
      objective_score = weighted_avg * llm_modifier

    Type constraint checking:
      Additional penalty (-0.3) if domain/range constraints violated

  STEP 6b: ROUTING
  ------------------
    Purpose:    Decide what happens to each triple based on confidence
    Decision tree:
      Score >= 0.70                           --> AUTO_ADD (written to graph)
      Score 0.50-0.70                         --> QUICK_REVIEW
      Score < 0.50                            --> FULL_REVIEW
      New entity type not in ontology         --> NEW_TYPE (flagged)
      New relation type not in ontology       --> NEW_RELATION (flagged)
      Entity not in thesaurus (non-Value)     --> NEW_ENTITY (still auto-add
                                                   if score >= threshold)

  STEP 7: ENTITY RESOLUTION
  ---------------------------
    Purpose:    Merge duplicate entities, resolve aliases to canonical names
    Method:     3-step cascade

    Step 1: Exact Match
      Normalize (lowercase, strip, collapse spaces, strip trailing 's')
      Check canonical names and thesaurus aliases
      Score: 1.0 (certain match)

    Step 2: Fuzzy String Matching
      Library: RapidFuzz (token_sort_ratio)
      Auto-merge: >= 0.95 similarity
      Suggest merge (needs review): >= 0.90
      Below 0.90: no match

    Step 3: Semantic Matching
      Model: BAAI/bge-base-en-v1.5 (768-dim, runs on CPU)
      Cosine similarity on entity name + type embeddings
      Auto-merge: >= 0.90 similarity
      Suggest merge: >= 0.85
      Optimization: filters by same entity type first

    If no match found: entity treated as new (flagged for review)

  STEP 8: NEO4J WRITE
  ---------------------
    Purpose:    Write high-confidence triples to the knowledge graph
    Only writes: AUTO_ADD triples (score >= 0.70)
    Skips:      Review queue items, new types, new relations

    Node creation:
      MERGE on canonical_name (unique key)
      Label: leaf type name (e.g., Pump, Bearing)
      Properties: type (full path), last_seen, mention_count

    Relationship creation:
      MERGE with source/target canonical names
      Properties: confidence, source_document, source_span, timestamp

    Value properties:
      HAS_IDENTIFIER triples stored as node properties instead of edges
      Example: (pump).identifier = "EXT-201"

    Self-loops removed (subject == object after resolution)

  STEP 9: REASONING
  -------------------
    Purpose:    Infer new triples from existing ones using logical rules
    Engine:     Clingo ASP (Answer Set Programming)
                (Potassco project -- production-grade logic solver)

    Process:
      1. Load existing triples as ASP facts
      2. Convert ontology inference rules from Datalog to ASP syntax
      3. Ground + solve for stable model
      4. Extract new triples not in original facts
      5. Write inferred triples to Neo4j

    Example rule:
      Input:  "if (?x HAS_PART ?y) AND (?y HAS_PART ?z) then (?x HAS_PART ?z)"
      ASP:    has_part(X,Z) :- has_part(X,Y), has_part(Y,Z).

  DOCUMENT REFINEMENT
  ---------------------
    Purpose:    Auto-update living documents with discoveries from this run

    Process:
      1. Collect discoveries: new entities, proposed types, new relations
      2. Generate refinement proposals
      3. Auto-apply if confidence >= 0.85:
         - Add new thesaurus entries (with aliases from tickets)
         - Add new ontology types (under closest parent)
      4. Queue lower-confidence proposals for human review
      5. Increment version on living documents

  REVIEW QUEUE
  --------------
    Purpose:    Human-in-the-loop quality control

    Categories:
      triple_review:     Low-confidence triples needing yes/no
      new_entity:        Unknown entities needing approval
      new_type:          Proposed ontology types needing approval
      new_relation:      Proposed relation types needing approval
      merge_suggestion:  Possible duplicate entities needing decision

    Each item has:
      - Plain English question ("We found 'hydraulic pump'. Add it?")
      - Explanation (why it needs review)
      - Options (approve / reject / modify)
      - Source text context
      - Confidence breakdown
      - Priority score (0-100)

    Output: review_queue.json + human_review.md (readable format)


================================================================================
7. KNOWLEDGE GRAPH -- NEO4J STORAGE MODEL
================================================================================

  DATABASE
  --------
    Neo4j 5.11+ (required for native vector index support)
    Database naming: auto-generated per run (e.g., v4_20260304)

  NODE TYPES
  -----------
    (:Entity)      Equipment, components, failure modes, parameters
      Properties:  canonical_name, type, description, last_seen,
                   mention_count, embedding (768-dim float array),
                   embedding_hash (md5 for incremental updates)

    (:Chunk)       Text retrieval chunks from source tickets
      Properties:  doc_id, text, position, embedding (768-dim float array)

    (:OntologyType)  Type hierarchy nodes (optional, if include_ontology=true)

  RELATIONSHIP TYPES
  -------------------
    HAS_FAILURE_MODE, HAS_COMPONENT, LOCATED_ON, HAS_PARAMETER,
    HAS_IDENTIFIER, CAUSES, TRIGGERS, PART_OF, etc.
    (grows as pipeline discovers new relation types)

    (:Chunk)-[:MENTIONS]->(:Entity)  Links chunks to entities they reference

  VECTOR INDEXES (HNSW)
  ----------------------
    entity_embeddings:  768-dim cosine on Entity.embedding
    chunk_embeddings:   768-dim cosine on Chunk.embedding

  EMBEDDINGS
  -----------
    Model:      BAAI/bge-base-en-v1.5 (768 dimensions)
    Entity text: "{name} (type: {type}). {description}. Connected to: ..."
    Chunk text:  raw ticket text (400-word windows, 50-word overlap)
    Incremental: only re-embeds entities whose description changed (md5 hash)


================================================================================
8. RETRIEVAL STRATEGIES -- QUERY RESOLUTION
================================================================================

  Six strategies available, each optimized for different question types.
  All share common components (vector search, BM25, embeddings) but combine
  them differently.

  SHARED COMPONENTS
  ------------------

    GraphVectorRetriever
      Neo4j HNSW vector search on entity and chunk embeddings
      Two backends: neo4j-graphrag library (if installed) or direct Cypher
      Uses db.index.vector.queryNodes() for similarity search

    BM25Retriever
      Keyword search via bm25s library
      Loads all Chunk texts from Neo4j, builds inverted index
      Good for: rare tokens, IDs, error codes, exact matches

    CascadeEntityLinker
      5-stage entity linking for questions:
        0. Regex ID patterns (WO-12345, EQ-001)
        1. Exact substring match on canonical names
        2. Thesaurus alias lookup
        3. RapidFuzz fuzzy matching
        4. BGE embedding nearest-neighbor search

    CrossEncoderReranker
      Model: cross-encoder/ms-marco-MiniLM-L-12-v2
      Reranks fused retrieval results by relevance
      Optional (disabled by default)

    RRF Fusion
      Reciprocal Rank Fusion
      (Cormack et al. -- "RRF outperforms Condorcet and individual
       rank learning methods", SIGIR 2009)
      Merges multiple ranked lists: score = sum(1 / (k + rank + 1)), k=60
      Deduplicates by (doc_id + text hash)

    AnswerGenerator
      Channel-aware LLM answer generation
      3 context channels with budget allocation:
        Text evidence:      50% of context budget
        Graph facts:        30%
        Community summaries: 20%
      Citation format: [Text], [Graph], [Summary] tags

  --------------------------------------------------------------------------

  S1: GRAPH-AS-RAG (Community Summaries)
  ----------------------------------------
    Source:     LightRAG library (HKUDS/LightRAG, Hong Kong University)
    Alternate:  Microsoft GraphRAG

    Approach:
      Offline: Build entity graph -> Louvain community detection ->
               LLM generates summary per community
      Online:  Query matched to relevant communities -> return summaries

    Step-by-step (LightRAG mode, default):
      1. Embed the question
      2. Local search: match question to graph neighborhoods + chunk context
      3. Global search: match question to community summaries (hierarchical)
      4. Combine local + global results (hybrid mode)
      5. Tag all sources as community summaries
      6. Generate answer from community context

    Step-by-step (MS GraphRAG mode, alternative):
      1. Build DataFrames from Neo4j (entities, relationships, chunks)
      2. Detect communities: Louvain algorithm on exported NetworkX graph
      3. Generate community reports: LLM summarizes each community's
         entities, relationships, and related chunks
      4. Local search: match question to entity neighborhoods within communities
      5. Global search: match question to community reports with dynamic selection
      6. Generate answer from matched community reports

    Query modes: naive, local, global, hybrid (default)

    Best for:   Overview questions ("tell me about", "summarize", "explain")
    LLM calls:  ~2 (community matching + answer generation)

    Vector DB:  Standalone NanoVectorDB inside LightRAG
                (does NOT use Neo4j vector indexes)

  --------------------------------------------------------------------------

  S2: RAG + GRAPH ENRICHMENT
  ----------------------------
    Approach:   Query enrichment through graph expansion, multi-channel fusion.
                The core idea: first identify what entities the question is about,
                then expand the graph around them to build richer context, then
                fuse multiple retrieval channels for comprehensive evidence.

    Full pipeline:
      1. Entity linking (5-stage cascade on question text):
         a. Regex ID patterns (WO-12345, EQ-001)
         b. Exact substring match on canonical entity names
         c. Thesaurus alias lookup
         d. RapidFuzz fuzzy matching (token_sort_ratio)
         e. BGE embedding nearest-neighbor search
         Returns: list of matched entities with confidence scores

      2. Graph expansion (constrained neighborhood):
         For each linked entity, run Cypher to collect 1-2 hop neighbors
         ordered by node degree (most connected first), limited to 200 nodes
         and 50 paths. Extracts neighbor names and relation types as
         "expansion terms" (up to 30 terms) for query enrichment.

      3. Vector search with original query (chunk top_k=10)
         Standard HNSW cosine search over Chunk embeddings

      4. Vector search with enriched query (original + expansion terms)
         Same search but query is augmented with graph neighbor terms,
         pulling in chunks related to the entity's neighborhood

      5. Entity embedding search (top_k=5)
         HNSW search over Entity embeddings, returns entity descriptions

      6. BM25 keyword search (top_k=10)
         Inverted index search via bm25s library, good for exact codes/IDs

      7. Text-to-Cypher (optional structured query)
         LLM generates a Cypher query for additional graph insight (+1 LLM call)

      8. RRF fusion of all channels
         Reciprocal Rank Fusion merges all ranked lists:
         score = sum(1 / (k + rank + 1)), k=60
         Deduplicates by (doc_id + text hash), keeps highest score

      9. Cross-encoder reranking (optional)
         ms-marco-MiniLM-L-12-v2 reranks fused results by relevance

     10. Channel-separated answer generation
         Sources split into text_evidence vs graph_facts channels
         AnswerGenerator allocates context budget: 50% text, 30% graph, 20% community

    Best for:   General questions, entity-focused lookups
    LLM calls:  2-3 (entity linking is rule-based, Cypher generation +1, answer +1)

    Vector DB:  Neo4j HNSW (both chunk and entity indexes)

  --------------------------------------------------------------------------

  S3: TEXT-TO-CYPHER
  --------------------
    Approach:   LLM generates Cypher queries for structured graph search.
                Best for questions with a clear structured answer: counts,
                lists, filters, date ranges. Falls back to S2 if Cypher fails.

    Question classification (regex-based, zero LLM cost):
      "how many", "count"                    -> Cypher appropriate
      "list all", "list the"                 -> Cypher appropriate
      "which ... have/has/are/is"            -> Cypher appropriate
      "between X and Y" (date ranges)        -> Cypher appropriate
      "last service/maintenance"             -> Cypher appropriate
      "total", "filter"                      -> Cypher appropriate

    Pipeline:
      1. Classify question using regex patterns (no LLM call)

      2. Cypher generation with self-healing retry (up to 3 attempts):
         Attempt 1: LLM prompt includes Neo4j schema (all labels, relationship
                    types, property keys) + few-shot Cypher examples from
                    living documents + the question
         Attempt 2+: Same prompt but also includes the previous Cypher attempt
                     and the error message, asking the LLM to fix it
         Each attempt: execute EXPLAIN first (syntax check), then run query

      3. Safety checks before execution:
         - Read-only verification (no MERGE, CREATE, DELETE, SET)
         - LIMIT clause present (prevent full-scan)
         - Label validation (all labels exist in schema)
         - No Cartesian product detection

      4. Hybrid text supplement (if Cypher succeeds):
         - Vector search (top_k=5) for additional text context
         - BM25 search (top_k=5) for keyword matches
         - These supplement the Cypher results, not replace them

      5. Answer generation:
         Cypher results as primary graph context + text supplement
         LLM generates answer citing both sources

      6. Fallback: If Cypher fails after all retries, delegates entirely to S2
         (graph enrichment). Result still labeled as S3 but includes
         fallback flag and the failed Cypher attempt for debugging.

    Best for:   Structured queries ("how many", "list all", "which ... have")
    LLM calls:  2-3 (Cypher generation x retries + answer generation)

    Vector DB:  Neo4j HNSW (supplementary only, Cypher is primary)

  --------------------------------------------------------------------------

  S4: HYBGRAG (Hybrid Retrieval with Critic Loop)
  --------------------------------------------------
    Source:     HybGRAG paper (arXiv:2412.16311)
               (hybrid graph-RAG with iterative retrieval refinement)

    Core concept: Retriever bank + LLM router + validator/commenter critic loop.
    Systematically detects missing evidence and triggers targeted re-retrieval.
    Unlike S2/S3 which run a fixed pipeline once, S4 iteratively refines its
    retrieval based on LLM feedback about what went wrong.

    Algorithm (up to T=3 iterations):

      Iteration t:
        1. ROUTER (LLM call):
           Input: question + feedback from previous iteration (if any)
                  + available entity types + relation types + few-shot examples
           Output: extracted entities, relations, module choice (hybrid or text),
                   reasoning for the choice
           The router decides WHAT to search for and HOW.

        2. RETRIEVE (no LLM call, runs retriever bank):
           If module == "hybrid" (graph + text):
             a. Text vector search: HNSW over Chunk embeddings (top_k=10)
             b. BM25 keyword search (top_k=10)
             c. Entity embedding search: HNSW over Entity embeddings (top_k=5)
             d. Graph neighborhood: for each router-specified entity, expand
                1-2 hops along router-specified relation types (or all types)
                Limited to 50 edges per entity.
             e. Cypher sub-questions (optional): LLM generates targeted Cypher
             f. RRF fusion of all 5 channels + optional cross-encoder reranking

           If module == "text" (text only):
             a. Text vector search (top_k=15, higher than hybrid)
             b. BM25 keyword search (top_k=15)
             c. RRF fusion + optional reranking

        3. VALIDATOR (LLM call):
           Input: question + all retrieved evidence + router reasoning
           Question: "Is this evidence SUFFICIENT to answer correctly?"
           Checks: entities from question present? relationships relevant?
                   enough context for complete answer?
           Output: valid (true/false) + reason

           If valid == true: EXIT loop, use this evidence

        4. COMMENTER (LLM call, only if validator said "not valid"):
           Input: question + module + entities + relations + evidence
           Classifies the error type and provides corrective feedback.

           Error types and programmatic corrective actions:
             incorrect_entity     -> remove worst-scoring entity from list,
                                     lower fuzzy matching threshold
             incorrect_relation   -> drop relation filter, search ALL relation
                                     types instead of router-specified ones
             missing_entity       -> double vector top_k (10->20),
                                     lower fuzzy threshold for broader matching
             no_entity            -> force text-only module, BM25 keyword
                                     extraction as fallback
             no_intersection      -> increase max_hops (2->3) and max_nodes
                                     (200->400) for wider graph exploration
             incorrect_intersection -> try alternative seed entity
             incorrect_module     -> switch from hybrid to text or vice versa

           The feedback + action are applied to the NEXT iteration's router call.

      After loop (max iterations reached or validator approved):
        5. ANSWER GENERATION (LLM call):
           Best evidence (from iteration with most sources) separated into
           text_evidence and graph_facts channels.
           AnswerGenerator produces final answer with channel citations.

    Tracking: Each iteration's feedback, error type, and action are logged
    in the retriever_trace and critic_feedback fields for debugging.

    Best for:   Complex questions requiring iterative refinement, multi-hop
                reasoning, questions where the first retrieval attempt misses
    LLM calls:  3 per iteration (router + validator + commenter) + 1 answer
                Typical: 4-10 total (1-3 iterations)

    Vector DB:  Neo4j HNSW (both chunk and entity indexes)

  --------------------------------------------------------------------------

  ROUTER: STRATEGY DISPATCHER
  -----------------------------
    Approach:   Rule-based question classification, dispatches to best strategy.
                Zero LLM cost for routing itself -- all classification is regex.
                Strategies are lazy-loaded (only initialized on first use).

    Classification rules:
      "how many", "count", "list all" etc.        -> S3 (Text-to-Cypher)
      "tell me about", "summarize", "explain" etc. -> S1 (LightRAG)
      default (anything else)                      -> S4 (HybGRAG)
      fallback (if selected strategy fails/errors) -> S2 (Graph Enrichment)

    The router always has a fallback: if the primary strategy raises an
    exception or returns empty results, it silently retries with S2 (the most
    robust general-purpose strategy).

    LLM calls:  0 (classification is regex-based, delegates to chosen strategy)

  --------------------------------------------------------------------------

  NAIVE RAG: BASELINE
  ---------------------
    Approach:   Pure vector similarity search, no graph, no enrichment.
                Standard RAG architecture used as a controlled baseline to
                measure the value-add of graph-based strategies.

    Technology stack:
      Embedding model:  BAAI/bge-base-en-v1.5 (768-dim, sentence-transformers)
      Vector index:     Neo4j HNSW (cosine similarity) on Chunk nodes
      LLM:              Gemini 2.5 Flash Lite (same as other strategies)
      No external vector DB (no ChromaDB, no FAISS, no LangChain)

    Pipeline:
      1. Embed question using BGE model (same model used for chunk embeddings)
      2. HNSW cosine search over Chunk node embeddings (top_k=10)
      3. Filter empty chunks, concatenate remaining texts as plain context
      4. LLM generates answer from text-only context
         (graph_context and community_context explicitly set to "Not used")

    What it does NOT do:
      - No graph traversal or neighborhood expansion
      - No entity linking (no cascade, no thesaurus lookup)
      - No Cypher query generation
      - No BM25 keyword search
      - No cross-encoder reranking
      - No RRF fusion (single retrieval channel)
      - No community summaries

    Best for:   Baseline comparison to isolate graph value-add. If naive RAG
                scores close to graph strategies, the graph is not adding value.
                If graph strategies score significantly higher, the KG enrichment
                is justified.
    LLM calls:  1 (answer generation only)

    Vector DB:  Neo4j HNSW (chunks only, no entity index used)


================================================================================
9. QA EVALUATION FRAMEWORK
================================================================================

  OVERVIEW
  --------
  Runs all strategies on a set of evaluation questions, collects both automatic
  metrics and LLM judge scores, produces per-question and per-strategy reports.

  EVALUATION QUESTIONS
  ---------------------
    248 questions across 5 categories:

    Category           Count   Example
    --------           -----   -------
    lookup              99     "What is the role of a Hot Rolling Mill?"
    latent_discovery    55     "What happens when exit tension higher than entry?"
    structured          44     "What are the series variants for the CRM?"
    diagnostic          38     "What happens when tension too high for strip thickness?"
    multi_hop           12     "How can problems at CRM affect FRM?"

    Each question has:
      id:            unique identifier
      question:      natural language question
      category:      question type
      answer_type:   "span" (text answer) or "set" (list of entities)
      gold_result:   expected correct answer
      gold_entities: (for set type) expected entity list
      rule_id:       (optional) links to domain rule for knowledge evaluation

  AUTOMATIC METRICS (no LLM cost)
  --------------------------------

    Answer metrics (require gold_result):
      span_overlap_f1:   Token-level F1 between answer and gold (for span type)
      set_f1:            Set precision/recall F1 (for set type)
      set_precision:     |predicted intersection gold| / |predicted|
      set_recall:        |predicted intersection gold| / |gold|

    Retrieval metrics:
      source_count:      Total evidence sources retrieved
      source_diversity:  Unique document IDs
      channel_coverage:  Breakdown by type (text_chunk, graph_fact, cypher_result)
      dedup_ratio:       Unique texts / total (1.0 = no duplicates)

    Faithfulness heuristics:
      evidence_mention_ratio:  Fraction of answer words found in evidence
      token_overlap_score:     Bidirectional coverage (answer<->evidence)
      flagged_low_faithfulness: True if mention_ratio < 0.50

    Cypher metrics (for S3):
      syntax_ok:         EXPLAIN passes
      executes_ok:       Query runs without error
      result_count:      Rows returned
      safety_score:      Weighted average of read-only, LIMIT, no full-scan checks

  LLM JUDGE (5 dimensions, requires --judge flag)
  -------------------------------------------------
    Judge model: gemini-2.5-flash-lite (configurable)

    Dimension 1: Faithfulness (always runs)
      Decomposes answer into claims, checks each against evidence
      Output: float 0-1 (fraction of supported claims)

    Dimension 2: Relevance (always runs)
      Does the answer address the question?
      Output: 0 (no), 1 (partial), 2 (fully addresses)

    Dimension 3: Evidence Quality (always runs)
      Would an engineer trust this evidence to verify the answer?
      Output: 0 (insufficient) or 1 (sufficient)

    Dimension 4: Correctness (only if gold_result present)
      Does the answer match the expected correct answer?
      Output: 0 (wrong), 1 (partial), 2 (correct)
      Ignores phrasing differences, focuses on essential information

    Dimension 5: Domain Knowledge (only if rule_id present)
      Does the answer demonstrate understanding of the maintenance rule?
      Evaluates: condition -> effect -> recommendation chain
      Output: 0 (no understanding), 1 (partial), 2 (correct understanding)
      Distinguishes DOC rules (documented) from LATENT rules (tribal knowledge)

  RULE CONTEXTS
  --------------
    40 domain rules used for Dimension 5 evaluation:
      6 DOC rules (documented procedures)
      34 LATENT rules (undocumented tribal knowledge)

    Each rule has:
      condition:        what triggers the rule
      effect:           what goes wrong
      recommend:        what to do about it
      machines:         affected equipment types
      error_codes:      related error codes
      knowledge_source: DOC or LATENT

  OUTPUT FILES
  -------------
    benchmark_YYYYMMDD_HHMMSS.json    Full results (per-question + per-strategy)
    benchmark_YYYYMMDD_HHMMSS.jsonl   Incremental per-eval records
    eval_log_YYYYMMDD_HHMMSS.txt      Terminal log
    cost_report_YYYYMMDD_HHMMSS.json  LLM token usage breakdown

  COST
  -----
    Judge dimensions:           4-5 LLM calls per question per strategy
    248 questions x 6 strategies = ~1488 evaluations x 5 calls = ~7440 LLM calls
    Estimated cost at flash-lite: ~$0.50-1.00 for full benchmark run


================================================================================
10. INGESTION EVALUATION FRAMEWORK
================================================================================

  OVERVIEW
  --------
  Evaluates the quality of the ingestion pipeline itself (extraction, graph
  structure, entity resolution, reasoning) independently of question answering.
  All modules are orchestrated by a single runner that collects metrics, checks
  them against configurable thresholds, and generates JSON + Markdown reports.

  Location: v4_pipeline/evaluation_ingestion/
  Runner:   evaluation_ingestion/runner.py

  --------------------------------------------------------------------------

  MODULE 1: EXTRACTION METRICS
  ------------------------------
    Purpose:    Measure triple extraction quality (precision, recall, F1)

    Metrics computed:
      Micro P/R/F1:           Global TP/FP/FN across all triples
      Macro F1:               Average F1 per relation type
      Ontology Conformance:   % triples with valid relation types and entity types
                              matching the ontology schema (target >= 0.90)
      Hallucination Rate:     % entities NOT grounded in the source text
                              (lower = better)

    Matching modes:
      Exact:  subject, relation, object must all match exactly
      Fuzzy:  RapidFuzz token_sort_ratio with configurable threshold
              (useful when gold standard has different surface forms)

    Inputs: predicted triples, gold standard triples (optional),
            ontology (for conformance), source texts (for hallucination check)

    Target: Micro F1 >= 0.75, Ontology Conformance >= 0.90

  --------------------------------------------------------------------------

  MODULE 2: STRUCTURAL METRICS (No Ground Truth Required)
  ---------------------------------------------------------
    Purpose:    Assess graph topology and schema utilization without gold standard

    Graph topology:
      Basic stats:            Node count, edge count, density, average degree
      Connected components:   Weakly connected component count, largest component
                              fraction (target: largest WCC > 95% of nodes)
      Degree distribution:    Min/max/median degree, power-law alpha fit
                              (healthy KG typically alpha 2.0-3.0)
      Orphan rate:            Isolated nodes with no edges (target < 5%)
      Clustering:             Average clustering coefficient, triangle count

    Schema utilization:
      ICR:                    Instantiated Class Ratio = classes_with_instances /
                              total_defined_classes (measures ontology coverage)
      IPR:                    Instantiated Property Ratio = properties_used /
                              total_defined_properties
      Property richness:      Average distinct properties per entity type
      Relationship richness:  Object properties / total properties

    Relation distribution:    Balance check across relation types (detects if
                              one relation type dominates the graph)

    Libraries: networkx (required), powerlaw (optional for distribution fit)

  --------------------------------------------------------------------------

  MODULE 3: COMPLETENESS METRICS (No Ground Truth Required)
  -----------------------------------------------------------
    Purpose:    Estimate how much of the domain was captured

    Property completeness:
      For each (entity_class, relation_type) pair defined in the ontology,
      measures: instances_with_property / total_instances_of_class
      Reports average completeness and gaps (properties below 50% fill rate)

    Capture-recapture estimation (optional):
      If two independent extractors are available (e.g., different LLMs or
      different prompt versions), applies Lincoln-Petersen and Chapman estimators
      to estimate the true total number of triples in the domain:
        N_hat = (n1 * n2) / overlap
      Reports estimated recall for each extractor.

  --------------------------------------------------------------------------

  MODULE 4: CALIBRATION METRICS
  --------------------------------
    Purpose:    Check if confidence scores are well-calibrated (a triple scored
                at 0.8 should be correct ~80% of the time)

    Metrics:
      ECE:          Expected Calibration Error (target < 0.05)
                    = sum(|bin_size|/n * |accuracy(bin) - avg_confidence(bin)|)
      MCE:          Maximum Calibration Error (worst bin gap)
      Brier Score:  Mean squared error of probabilities (target < 0.10)
                    = (1/N) * sum((confidence_i - correct_i)^2)

    Binning:  10 bins by default (0.0-0.1, 0.1-0.2, ..., 0.9-1.0)
              Per-bin breakdown: count, avg_confidence, accuracy, gap

    Outputs:  Reliability diagram PNG (matplotlib) showing calibration curve
              vs perfect diagonal

    Inputs:   List of confidence scores + list of correctness labels (boolean)

    Libraries: sklearn (optional), matplotlib (optional for diagram)

  --------------------------------------------------------------------------

  MODULE 5: REASONING METRICS
  ------------------------------
    Purpose:    Evaluate the quality of logical inference (Clingo ASP output)

    Metrics:
      Base/inferred counts:   How many triples existed before vs after reasoning
      Amplification ratio:    inferred_count / base_count
      Rule coverage:          total_rules vs approved_rules in ontology
      Support per relation:   Count of unique (subject, object) pairs for each
                              inferred relation type
      Head coverage:          HC = support / total_head_relation_facts per relation
                              (target HC >= 0.01 for active rules)
      Self-referential count: Triples where subject == object (should be 0)
      Validation rate:        If a newer KG version is available, % of inferred
                              triples confirmed (target >= 0.70)

    Inputs: inferred triples, base triples, ontology (with logical_rules)

  --------------------------------------------------------------------------

  MODULE 6: SHACL VALIDATION
  -----------------------------
    Purpose:    Validate graph data against RDF schema constraints

    Process:
      1. Convert pipeline triples to RDF graph (rdflib)
      2. Auto-generate SHACL shapes from ontology relation_types
         (domain/range constraints become sh:class constraints)
      3. Run pySHACL validator
      4. Report violations with focus node, path, and message

    Metrics:
      conforms:           Boolean (does data pass all constraints?)
      violation_count:    Number of constraint violations
      conformance_rate:   (total - violations) / total (target >= 0.95)
      violations:         Array of violation details (up to 50 examples)

    Libraries: rdflib (required), pyshacl (required)

  --------------------------------------------------------------------------

  MODULE 7: ENTITY RESOLUTION METRICS
  --------------------------------------
    Purpose:    Measure entity clustering quality (did we correctly merge
                duplicate entities and keep distinct ones separate?)

    Metrics:
      B-Cubed P/R/F1:    Per-element clustering metric (target F1 >= 0.85)
                          B3P: avg precision per element (how pure is its cluster)
                          B3R: avg recall per element (how complete is its cluster)
      Variation of Info:  VI = H(C|C') + H(C'|C), lower = better, 0 = perfect
      Cluster stats:      cluster_count, singleton_clusters, largest_cluster,
                          avg_cluster_size (no ground truth needed)

    Inputs: predicted clusters (from entity resolution step),
            gold clusters (optional, for B-Cubed and VI)

  --------------------------------------------------------------------------

  MODULE 8: TERM RANKING METRICS
  ---------------------------------
    Purpose:    Evaluate quality of Step 0 term ranking (TF-IDF + BM25)

    Metrics:
      Precision@K:  Fraction of top-K ranked terms that are relevant
                    (target P@10 >= 0.70)
      MAP@K:        Mean Average Precision across documents
      NDCG@K:       Normalized Discounted Cumulative Gain
                    Accounts for position (top-ranked terms matter more)
                    (target NDCG@10 >= 0.70)

    Inputs: ranked terms per document, gold relevant terms per document

    Libraries: sklearn (optional), pytrec_eval (optional for TREC metrics)

  --------------------------------------------------------------------------

  MODULE 9: LINK PREDICTION (Optional, Computationally Expensive)
  ------------------------------------------------------------------
    Purpose:    Train KG embedding model and evaluate graph completeness
                via self-supervised link prediction

    Process:
      1. Convert triples to PyKEEN TriplesFactory
      2. Split into train/test (80/20 default)
      3. Train embedding model (ComplEx, RotatE, or TransE)
      4. Evaluate on held-out test triples

    Metrics:
      MRR:          Mean Reciprocal Rank (target >= 0.30)
      Hits@1:       Proportion of test triples ranked 1st
      Hits@3:       Proportion ranked in top 3
      Hits@10:      Proportion ranked in top 10 (target >= 0.50)
      AMRI:         Adjusted Mean Rank Index = 1 - (2*MR)/(|E|+1)

    Can also score existing triples for plausibility (noise detection):
      Low-scoring existing triples are likely extraction errors.

    Requires minimum 20 triples to run.

    Libraries: PyKEEN (required), torch (required)

  --------------------------------------------------------------------------

  MODULE 10: PREPROCESSING METRICS
  -----------------------------------
    Purpose:    Evaluate text normalization and abbreviation expansion quality

    Metrics:
      Exact Match Accuracy:     Correctly expanded / total (target >= 0.90)
      Character Error Rate:     CER = (substitutions + deletions + insertions) /
                                reference_length (target < 0.10)
      Word Error Rate:          WER at word level
      Known Abbreviation Rate:  abbreviations_in_dictionary / total_detected
      OOV Rate:                 tokens_not_in_vocabulary / total_tokens

    Inputs: predicted expansions, gold reference expansions, vocabulary

    Libraries: jiwer (optional for CER/WER)

  --------------------------------------------------------------------------

  THRESHOLD CHECKS AND REPORTING
  --------------------------------
    The runner checks all computed metrics against configurable targets:

    Metric                    Target      Direction
    ------                    ------      ---------
    triple_f1                 >= 0.75     higher is better
    b3_f1                     >= 0.85     higher is better
    ece                       < 0.05      lower is better
    brier_score               < 0.10      lower is better
    mrr                       >= 0.30     higher is better
    hits_at_10                >= 0.50     higher is better
    shacl_conformance_rate    >= 0.95     higher is better
    orphan_rate               < 0.05      lower is better
    ontology_conformance_rate >= 0.90     higher is better

    Output files:
      evaluation_report.json    Full metrics + threshold pass/fail
      evaluation_report.md      Human-readable Markdown with tables and summaries


================================================================================
11. CURRENT LIMITATIONS AND IMPROVEMENT ROADMAP
================================================================================

  EXTRACTION QUALITY
  -------------------
    Current:  Generic LLM (Gemini Flash Lite) extracts triples from noisy text.
              81% ticket success rate, 34% auto-add rate (rest needs review).

    Improvement: Fine-tune the extraction LLM on domain-specific maintenance
    text. A fine-tuned model would:
      - Better understand maintenance abbreviations and jargon natively
      - Produce higher-confidence triples (more auto-adds, less review queue)
      - Reduce the 19% ticket failure rate (especially implicit error codes)
      - Reduce human review burden significantly

    Improvement: Few-shot example curation. As the living documents accumulate
    high-quality extraction examples, the in-context learning improves. Each
    pipeline run should feed its best extractions back as examples.

  ENTITY RESOLUTION
  ------------------
    Current:  3-step cascade (exact, fuzzy, semantic) works well for clear
              matches but struggles with highly abbreviated or novel entities.

    Improvement: Train a domain-specific entity linking model on the accumulated
    review decisions. After enough human reviews, the merge/reject patterns can
    train a classifier that replaces or augments the threshold-based cascade.

  LIVING DOCUMENTS GROWTH
  -------------------------
    Current:  Auto-apply threshold at 0.85 is conservative. Most discoveries
              go to the review queue rather than being auto-added.

    Improvement: As confidence in the system grows (validated by evaluation
    metrics), the auto-apply threshold can be progressively lowered. More
    tickets processed = richer thesaurus = better entity resolution = higher
    confidence scores = more auto-adds. This is the intended virtuous cycle.

    Improvement: Cross-run learning. Currently each pipeline run is independent
    (living docs carry over, but the extraction model does not learn). Adding a
    feedback loop where review decisions influence the next run's prompts or
    model weights would accelerate convergence.

  REVIEW QUEUE PROCESSING
  -------------------------
    Current:  811 items pending in review queue from 100 tickets. This does not
              scale to thousands of tickets without tooling.

    Improvement: Build batch review UI with smart grouping (all triples about
    the same entity together, all similar merge suggestions together). The
    review_ui scaffolding exists but needs production polish.

    Improvement: Active learning -- prioritize review items that would most
    improve extraction quality. A reviewed "new entity type" has more impact
    than a reviewed low-confidence triple.

  RETRIEVAL STRATEGIES
  ---------------------
    Current:  S2 and S3 show some retrieval capability. S4, Router, and
              naive_rag return empty contexts for most questions. This is
              because the graph is sparse (only 395 auto-added triples).

    Improvement: The graph needs more data. Either process more tickets, lower
    the auto-add threshold, or approve review queue items. The strategies
    themselves are architecturally sound but need a denser graph to work with.

    Improvement: Vector index quality depends on entity descriptions. Currently
    entities have minimal descriptions (just what the LLM extracted). Richer
    descriptions from accumulated ticket context would improve embedding quality
    and thus vector retrieval.

  REASONING
  ----------
    Current:  Clingo ASP reasoning produces 0 inferred triples because the
              seed ontology has minimal inference rules.

    Improvement: As domain experts add inference rules to the ontology (e.g.,
    "if equipment X has failure mode Y and Y causes Z, then X is at risk of Z"),
    the reasoning step will produce meaningful inferences. This is a human
    knowledge engineering task that compounds over time.

  EVALUATION
  -----------
    Current:  248 evaluation questions with gold answers. Many questions ask
              about definitional knowledge ("What is the role of HRM?") that
              the system is designed to discover, not be told.

    Improvement: Separate evaluation into tiers:
      Tier 1: Can the system find entities it extracted? (graph recall)
      Tier 2: Can the system answer questions using extracted relationships?
      Tier 3: Can the system discover undocumented patterns? (latent rules)
    Currently all tiers are mixed, making it hard to isolate what is working.

  PARALLELIZATION
  -----------------
    Current:  ThreadPoolExecutor with 10 workers. Global caches (embedding
              model, BM25 index, cross-encoder) lack thread locks. Race
              conditions possible on first load.

    Improvement: Add threading locks to all global caches. Pre-warm models
    on the main thread before spawning workers. Consider lowering default
    workers to 3-4 for CPU-bound embedding work.

  COST OPTIMIZATION
  ------------------
    Current:  Gemini 2.5 Flash Lite at $0.15 per 100 tickets (extraction) +
              ~$0.01 per 10 questions (evaluation). Very cost-effective.

    Improvement: For production scale (10,000+ tickets), consider batching
    extraction requests, caching repeated entity resolutions, and using
    smaller models for confidence scoring and type bridging steps that
    currently use the same LLM as extraction.


================================================================================
END OF DOCUMENT
================================================================================

Technologies used:
  LLM:            Google Gemini 2.5 Flash Lite (via Vertex AI, google-genai SDK)
  Graph DB:       Neo4j 5.11+ (native vector index, Cypher query language)
  Embeddings:     BAAI/bge-base-en-v1.5 (768-dim, sentence-transformers)
  Reranking:      cross-encoder/ms-marco-MiniLM-L-12-v2 (optional)
  Fuzzy matching: RapidFuzz (token_sort_ratio)
  Reasoning:      Clingo ASP solver (Potassco project)
  Keyword search: bm25s library
  Community RAG:  LightRAG (HKUDS/LightRAG)
  Schema output:  Instructor library (Pydantic-constrained LLM output)
  Vector search:  Neo4j HNSW indexes (cosine similarity)
  RRF fusion:     Cormack et al., SIGIR 2009

Papers referenced:
  AutoSchemaKG    -- LLM-driven KG construction with ontology as soft reference
  HybGRAG         -- arXiv:2412.16311, hybrid graph-RAG with critic loop
  RRF             -- Cormack et al., SIGIR 2009, reciprocal rank fusion
  SKOS            -- W3C 2009, vocabulary structure (broader/narrower/alias)
  LightRAG        -- HKUDS, community-level graph summarization for RAG
