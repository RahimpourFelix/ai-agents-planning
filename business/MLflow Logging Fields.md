# MLflow Logging Fields — Raw "Ingredients" Spec

**Audience:** AI researcher / engineer wiring MLflow into the Knowlestry platform.

**Purpose:** The source docs (`business/Knowlestry Analytics`, `business/UI & Interaction Metrics`) describe the *derived* metrics the business wants (the "dishes"). `business/MLflow Metrics Reference.md` lists those derived metrics with their formulas. **This doc lists the raw atomic fields you must log so every one of those formulas is computable.**

Rule of thumb: if a downstream analyst cannot rebuild a formula in the reference doc from the fields below, a field is missing.

---

## 1. Logging model

Three layers. Each field below is tagged with the layer it belongs in.

| Layer | MLflow construct | Emitted when | Typical cardinality |
|---|---|---|---|
| **R** — per-request | run (or nested run) per LLM/tool call; `mlflow.log_metric`, `log_param`, `set_tag` | Every inference, retrieval, tool call, guardrail check | High — 1 per call |
| **S** — per-session / per-workflow | parent run wrapping R children; or MLflow trace | Session start/end; workflow complete | Medium |
| **U** — per-user / per-billing-period | batch roll-up run | Daily/weekly/monthly job | Low |
| **T** — training / eval run | standard MLflow experiment run | Every model train or eval | Low |
| **C** — config / constants | not logged per call — stored once (tags on experiment, config table) | Rarely changes | — |

Cost/revenue numbers: log in **USD** (or a single currency) and in **base units**, not pre-aggregated. All timestamps: **UTC, ISO-8601, ms precision**.

---

## 2. Per-request fields (Layer R) — the main unit

Log these on every model/tool/retrieval call. This is where most formulas bottom out.

### 2.1 Identity & lineage
| Field | Type | Notes / feeds |
|---|---|---|
| `request_id` | uuid | primary key |
| `parent_request_id` | uuid \| null | set on retries & tool sub-calls → retry amplification, workflow depth |
| `root_request_id` | uuid | same as `request_id` for initial user-issued request; inherited by all children → calls-per-user-action, calls-per-workflow |
| `session_id` | uuid | groups requests into a session → SPO, TIC, cost-per-session |
| `workflow_id` | uuid | groups into a business workflow → cost/revenue per workflow |
| `intent_id` | uuid \| null | links to the user intent that triggered this request → ICR, ISR |
| `user_id` | string (hashed) | → per-user cost/revenue distribution, heavy-user concentration |
| `tenant_id` / `hub_id` | string | Knowlestry Hub |
| `agent_id` | enum: `MachineIQ`, `OptimizeAI`, `InsightAI`, `MaintainAI`, `OnboardAI`, `SupportAI`, `InnovateAI`, `Custom` | routing & per-agent unit economics |
| `custom_agent_id` | string \| null | when `agent_id=Custom` |
| `ts_request_start` | timestamp | latency & concurrency |
| `ts_request_end` | timestamp | latency & concurrency |

### 2.2 Model & routing
| Field | Type | Notes / feeds |
|---|---|---|
| `model_id` | string | e.g. `claude-opus-4-7` |
| `model_tier` | enum: `small` \| `medium` \| `large` | Blended CPI with cascading, model routing distribution |
| `router_decision_reason` | string | planner / heuristic / override |
| `router_predicted_tier` | enum | vs `model_tier` actually used → Routing Accuracy |
| `fallback_from_model_id` | string \| null | set when we escalated to a bigger model → Fallback rate |
| `is_retry` | bool | retry rate, retry amplification |
| `retry_attempt_index` | int (0 = original) | retry amplification factor |

### 2.3 Tokens & context
| Field | Type | Notes / feeds |
|---|---|---|
| `tokens_input` | int | cost per token, tokens per request |
| `tokens_output` | int | same |
| `tokens_cached_read` | int | cache hit accounting |
| `tokens_cached_write` | int | cache population cost |
| `context_tokens_total` | int | Context size growth rate |
| `context_tokens_useful` | int (engineer-estimated or cited) | Context bloat ratio = total/useful |
| `retrieval_tokens_retrieved` | int | retrieval bloat |
| `retrieval_tokens_used` | int (tokens actually cited/grounded) | Retrieval hit rate, retrieved-vs-used ratio |
| `retrieval_chunks_retrieved` | int | same |
| `retrieval_chunks_cited` | int | same |
| `retrieval_hit` | bool | Retrieval hit rate |

### 2.4 Costs (USD, per-request, NEVER pre-averaged)
Log all of these as separate metrics so COGS and margin can be broken down. Zero is a valid value.

| Field | Feeds |
|---|---|
| `cost_inference_usd` | CPI, Cost per request, p95 cost |
| `cost_retrieval_usd` | Retrieval cost, COGS breakdown |
| `cost_orchestration_usd` | planner/validator overhead — COGS breakdown |
| `cost_retry_usd` | cost attributable to retries — Retry cost |
| `cost_evaluation_usd` | cost of online eval / LLM-as-judge on this request — Eval overhead |
| `cost_guardrail_usd` | guardrail checks |
| `cost_logging_storage_usd` | logging/storage cost per interaction |
| `cost_concurrency_provision_usd` | amortized reserved-capacity share (can be attributed in roll-up; log 0 per-call if allocated offline) |
| `cost_model_license_usd` | when using licensed third-party models |
| `cost_total_usd` | **sum** of the above — fully-loaded cost per request |

### 2.5 Latency (ms)
| Field | Feeds |
|---|---|
| `latency_queue_ms` | Queue time / wait time |
| `latency_retrieval_ms` | Latency added by retrieval |
| `latency_inference_ms` | per-step latency |
| `latency_postprocess_ms` | |
| `latency_total_ms` | total latency, latency under load |

### 2.6 Outcome & quality
| Field | Type | Feeds |
|---|---|---|
| `success` | bool | Success rate / task completion rate |
| `success_after_retry` | bool | Retry-induced success rate |
| `error_type` | enum: `none`, `timeout`, `model_error`, `tool_error`, `guardrail_block`, `validation_fail`, `hallucination`, `other` | Error rate, hallucination rate |
| `guardrail_triggered` | bool | Guardrail trigger rate |
| `guardrail_ids` | list\<string\> | which policy fired |
| `hallucination_flag` | bool \| null (null = not evaluated) | Hallucination rate |
| `output_hash` | string | Consistency score (same input → same output) requires deterministic input hash + output hash |
| `input_hash` | string | same |
| `hitl_involved` | bool | Human-in-the-loop rate |
| `hitl_minutes` | float | Automation value per customer |
| `user_discarded_output` | bool | "Waste" usage |

### 2.7 Concurrency & infra (sampled gauges also OK as Layer R tags)
| Field | Feeds |
|---|---|
| `concurrent_requests_at_start` | int | Peak concurrent requests, Concurrency utilization |
| `capacity_provisioned` | int | Concurrency utilization % |
| `region` / `cluster` | string | Overprovisioning cost, peak vs average load |

### 2.8 Interaction / UI context (needed for UI & Interaction Metrics)
| Field | Feeds |
|---|---|
| `input_modality` | enum: `text`, `voice`, `visual`, `file_upload`, `mixed` | Multimodal-input tracking |
| `input_is_natural_language_goal` | bool | Intent Capture Rate (ICR) |
| `triggered_by` | enum: `user`, `proactive_agent_nudge`, `scheduled`, `tool_chain` | Proactive Nudge tracking |
| `usage_mode` | enum: `exploration`, `production` | Exploration vs production ratio |

---

## 3. Per-session / per-workflow fields (Layer S)

A parent run aggregating many R-layer calls. Log these **once per session/workflow completion**.

| Field | Type | Feeds |
|---|---|---|
| `session_id` / `workflow_id` | uuid | key |
| `user_id`, `tenant_id`, `agent_id` | — | inherited |
| `ts_session_start`, `ts_session_end` | ts | |
| `intent_submitted_at` | ts | TIC |
| `intent_completed_at` | ts \| null | TIC |
| `intent_status` | enum: `completed`, `failed`, `abandoned`, `partial` | ISR |
| `intent_required_manual_correction` | bool | ISR (counts as "not successful") |
| `intent_text` | string (PII-scrubbed) | ICR denominator check |
| `interactions_count` | int | **Steps per Outcome (SPO)** |
| `calls_total` | int | Calls per workflow, retry amplification numerator |
| `calls_initial` | int | retry amplification denominator |
| `workflow_depth_max` | int | Workflow depth (steps per request) |
| `fallback_to_large_count` | int | Fallback rate to larger models |
| `workflow_cost_total_usd` | float | Cost per workflow, fully-loaded |
| `workflow_success` | bool | Cost per successful outcome |
| `workflow_type` | string | reusable taxonomy for Workflow Repeatability (ADS input) |
| `workflow_template_id` | string \| null | Workflow Repeatability: set when session used a shared/reusable template |
| `human_steps_before_automation` | int \| null | HITL Reduction (baseline) |
| `human_steps_after_automation` | int | HITL Reduction |
| `hours_saved_estimate` | float | Automation Value per Customer |
| `customer_hourly_cost_usd` | float (can come from C) | Automation Value |

---

## 4. Per-user / billing fields (Layer U)

Roll-up run (daily/weekly/monthly). Drives all "behavioral revenue" metrics.

| Field | Feeds |
|---|---|
| `user_id`, `user_segment` (`power` / `simple`), `user_role` (`engineering_expert`/`technical_staff`/`data_science`/`management`/`other_dept`), `company_type` (`component_mfr`/`machine_mfr`/`plant_mfr`/`factory_operator`) | Segmentation for ARPU distribution, heavy-user profitability, contribution margin per segment |
| `period_start`, `period_end` | roll-up key |
| `requests_total`, `workflows_total`, `tokens_total` | usage base |
| `cost_total_usd` (by COGS category) | Cost per user |
| `revenue_total_usd` | Revenue per user, ARPU distribution |
| `revenue_attributable_to_output_usd` | **Value per Token (VPT)** numerator (split by workflow/request if feasible) |
| `revenue_subscription_usd` / `revenue_overage_usd` | Overage revenue %, hybrid-pricing split |
| `included_quota` / `usage_vs_quota` | % users exceeding included quota |
| `price_per_unit_usd` | p95 cost vs price (safety margin) |
| `cac_usd` (period attribution) | CAC decay rate |
| `acquisition_cohort` / `cohort_month` | CAC decay, retention |
| `active_workflows_count` | engagement |
| `exploration_share`, `production_share` | Exploration vs production usage ratio |
| `retry_share` | Retry-driven usage % |
| `waste_share` (% of calls with `user_discarded_output=true` or low-value tag) | "Waste" usage |
| `churned` (bool) / `churn_date` | churn rate |
| `is_heavy_user` (top-N% flag, recomputed) | Heavy user cost concentration |

---

## 5. Training / eval run fields (Layer T)

Offline MLflow experiments for model training, synthetic-data generation, and evaluation.

### 5.1 Training run
- `model_version`, `base_model_id`, `train_start_ts`, `train_end_ts`
- `dataset_id`, `dataset_version`
- `real_data_size_tokens`, `synthetic_data_size_tokens` → Real-to-synthetic ratio, Data Coverage Ratio
- `required_data_size_tokens` (target) → Data Coverage Ratio
- `synthetic_data_cost_usd`, `total_training_data_cost_usd` → **SDCR**
- `total_data_volume_tokens` (cumulative) → **DNEM** (`1 + log(total/initial)`)
- `initial_data_volume_tokens` (baseline constant — Layer C) → DNEM

### 5.2 Eval run
Log alongside each model version; ideally with both "with synthetic" and "without synthetic" variants.

| Field | Feeds |
|---|---|
| `accuracy` (task-appropriate, e.g. F1, exact match) | MPI, Performance Lift |
| `latency_score` (normalized 0–1) | MPI |
| `cost_efficiency_score` (normalized 0–1) | MPI |
| `mpi_weights_w1_w2_w3` (Layer C) | MPI weights |
| `perf_with_synth`, `perf_without_synth` | Performance Lift = `(with-without)/without` |
| `drift_score` (vs reference distribution) | Model drift detection frequency |
| `consistency_score` (from same-input replay) | Consistency score |
| `eval_cost_usd` | Cost of evaluation per request (amortize to R) |

### 5.3 Dataset quality (Layer C/T)
- `realism_score`, `diversity_score`, `label_accuracy_score` → **DQS** = `w1·Realism + w2·Diversity + w3·Label Accuracy`
- `proprietary_data_volume_tokens` / `total_data_used_tokens` → Data Exclusivity Ratio
- `data_uniqueness_score` (manual or competitive analysis) → Context Moat Strength

---

## 6. Agentic / Vertical / Team — structured metadata (Layer C, reviewed quarterly)

These are not runtime-loggable from user traffic; they are **inputs the engineer must surface as tracked configuration** so valuation dashboards can recompute.

### 6.1 Agentic Depth Score inputs
- `task_autonomy_pct` = (tasks completed without human input) / (all tasks) — **computable from Layer S** `intent_status='completed' AND hitl_involved=false`
- `workflow_repeatability_pct` = share of sessions matching a known `workflow_template_id` — **computable from Layer S**
- `decision_complexity_score` = average `workflow_depth_max` or a calibrated 1–5 rubric — **computable from Layer S**
- ADS weights `w1, w2, w3` (constants)

### 6.2 Vertical Depth Score inputs
- `domain_specific_features_pct`, `custom_workflows_count`, `industry_integrations_count`
- VDS weights
- `proprietary_data_volume`, `data_uniqueness`, `switching_cost_estimate` → CMS
- `time_to_replicate_months` — analyst estimate

### 6.3 Regulatory inputs
- `risk_discount_pct`, `compliance_costs_usd_period`, `data_sensitivity_score`, `geographic_exposure_score`, `model_risk_level_score`, RES weights
- `p_regulation_event`, `impact_usd` → ERI

### 6.4 Team premium (metadata only, not per-run)
- `research_pedigree_score`, `prior_exits_count`, `domain_expertise_score` → FSS
- `shipped_products_count`, `revenue_traction_usd`, `hiring_quality_score`, `months_since_founding` → ECI
- `senior_engineers_count`, `team_size_total` → Talent Density
- `inbound_candidates_count`, `hires_total` → Hiring Magnetism

---

## 7. Concurrency gauges & infrastructure counters

Emit as periodic metrics (every N seconds) in a separate MLflow run or time-series store; keys correlate by `tenant_id`/`region`/`ts`.

- `concurrent_requests_gauge` → Peak concurrent requests
- `capacity_provisioned_gauge` → Overprovisioning cost = `(provisioned − used)/provisioned`
- `queue_depth_gauge`
- `reserved_capacity_cost_usd_per_hour` (Layer C) → attributing `cost_concurrency_provision_usd` to requests
- `peak_load_flag` (derived) → Margin under peak load, Concurrency shock resilience

---

## 8. Derivable? — quick reference

Every formula from `MLflow Metrics Reference.md` must be derivable from the fields above. The table below shows the non-obvious derivations.

| Derived metric | Derivation from raw fields |
|---|---|
| p95 cost per request | percentile of `cost_total_usd` over R |
| Retry amplification factor | `sum(calls_total) / sum(calls_initial)` over S, OR `count(requests) / count(requests where retry_attempt_index=0)` over R |
| Heavy-user cost concentration | sort U by `cost_total_usd`; share from top-5% |
| Context bloat ratio | `context_tokens_total / context_tokens_useful` |
| Retrieval hit rate | `sum(retrieval_chunks_cited) / sum(retrieval_chunks_retrieved)` or `mean(retrieval_hit)` |
| Fallback rate to larger models | `count(fallback_from_model_id IS NOT NULL) / count(*)` |
| Consistency score | group R by `input_hash`; fraction with identical `output_hash` across replays |
| Routing Accuracy | `count(router_predicted_tier == model_tier) / count(*)` |
| ICR | `count(sessions WHERE any request has input_is_natural_language_goal=true) / count(sessions)` |
| ISR | `count(intents WHERE intent_status='completed' AND NOT intent_required_manual_correction) / count(intents)` |
| TIC | `avg(intent_completed_at − intent_submitted_at)` |
| SPO | `avg(interactions_count)` over successful sessions |
| Blended CPI with cascading | `sum(cost_inference_usd) / count(*)` grouped by `model_tier`, weighted by tier share |
| Value per Token | `sum(revenue_attributable_to_output_usd) / sum(tokens_output)` |
| Contribution margin per segment | `sum(revenue_total_usd − cost_total_usd)` grouped by `user_segment` |
| Margin under peak load | restrict to R where `peak_load_flag=true`; same formula |
| HITL Reduction | `(human_steps_before_automation − human_steps_after_automation)/human_steps_before_automation` per workflow_type |
| Automation Value per Customer | `sum(hours_saved_estimate × customer_hourly_cost_usd)` per user |
| Agent Reliability Score | `sum(workflow_success) / count(workflows)` per agent_id |
| DFE | `Δ MPI / Δ total_data_volume_tokens` between two T runs |
| DNEM | `1 + log(total_data_volume_tokens / initial_data_volume_tokens)` |

---

## 9. Logging checklist for engineer

1. **Per LLM/tool/retrieval call** → emit Layer R row with every §2 field. Never pre-aggregate cost or latency.
2. **Per session end** → emit Layer S row; link children via `root_request_id`/`session_id`.
3. **Daily batch** → materialize Layer U from Layer R + billing system.
4. **Every train/eval** → Layer T run with dataset lineage and evaluation scores, both with and without synthetic variants.
5. **Track configuration** (Layer C) as experiment tags or a versioned config table: routing thresholds, MPI/ADS/VDS/DQS weights, pricing tiers, risk discount, capacity cost.
6. **Hash inputs and outputs** on R so consistency/drift evals are possible without storing raw PII.
7. **Never drop the distribution.** Log raw values; compute percentiles downstream. Averages are lies.

---

## 10. Open questions raised by the source docs (flag before shipping)

- `UI & Interaction Metrics` list ends with a trailing dash — confirm whether additional UI metrics (e.g., proactive-nudge acceptance rate, modality-switch rate) should be added; the fields in §2.8 already support them.
- Business docs ask: what is the unit of value pricing scales with? The `revenue_attributable_to_output_usd` field depends on this decision.
- Confirm how `cost_concurrency_provision_usd` is attributed per call (flat share vs. peak-weighted) — affects fully-loaded cost.
- Confirm PII-scrubbing boundary for `intent_text` before logging.
