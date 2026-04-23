# MLflow Metrics Reference — Knowlestry Platform

Consolidated list of metrics to log via MLflow, extracted from:
- `business/Knowlestry Analytics`
- `business/UI & Interaction Metrics`

Organized by domain. Each section names the metric, its formula (where given in source), and a short note on what it captures.

---

## Guiding principles (from Knowlestry Analytics)

- AI costs are variable, behavioral, and compounding.
- Variance (not averages) breaks systems.
- Pricing is a system control mechanism, not just monetization.

Metrics must therefore:
- Capture distributions, not averages.
- Reflect user-behavior → cost causality.
- Track system-complexity layers, not just tokens.

---

## A. Business Metrics (Pricing + Unit Economics)

### Top-priority business metrics
- p95 cost per request
- Contribution margin per user segment
- Retry amplification factor
- Peak concurrency cost
- Heavy user cost concentration (%)
- Customer Acquisition Cost (CAC) Decay Rate — `CAC_t = CAC_(t-1) × (1 - Flywheel Gain Rate)`

### Pricing Model Effectiveness (hybrid pricing)
- % users exceeding included quota
- Subsidization ratio (heavy vs light users)

### Revenue Metrics (behavior-driven)
- Revenue per user (ARPU) — logged as distribution, not just average
- Revenue per workflow
- Overage revenue % (hybrid pricing)
- Revenue elasticity vs usage
- Revenue per cost unit (per 1k tokens / per workflow)

### Risk & Sustainability
- p95 cost vs price (unit-economics safety margin)
- Worst-day profitability
- Concurrency shock resilience
- Cost growth rate vs revenue growth rate

### User Behavior Economics
- Cost per user vs revenue per user (by segment)
- Heavy-user profitability
- Exploration vs production usage ratio
- Retry-driven usage (%)
- "Waste" usage (low-value interactions)

### Margin Metrics
- Gross margin (%)
- Contribution margin per user segment
- Margin by percentile (p50 vs p95 users)
- Margin under peak load

### COGS breakdown (fully-loaded cost per request)
- Inference cost
- Retrieval cost
- Orchestration cost
- Retry cost
- Concurrency provisioning cost
- Monitoring & evaluation cost

### Practical business metric groups (summary buckets)
- Economics: fully-loaded cost/request, revenue/request, contribution margin (p50/p95)
- Risk: cost variance (p95/p50 ratio), retry amplification factor, peak concurrency cost
- Behavior: cost-per-user distribution, heavy-user impact (% cost from top 5%), exploration vs production usage
- System Efficiency: calls per workflow, context size growth, model routing efficiency
- Stability: success rate, retry rate, latency under load

---

## B. Technical Metrics (System + Model Level)

### Cost & Inference Efficiency
- Cost per request (avg, p90, p95)
- Cost per successful outcome
- Tokens per request (input / output split)
- Context size growth rate (%)
- Model routing distribution (% cheap vs expensive models)
- Cost per workflow (not per call)

### Variance & Tail Risk (CRITICAL)
- Cost variance (std dev / coefficient of variation)
- p95 / p99 cost ratio vs median
- Worst-case cost per user / session
- Retry amplification factor — `total calls ÷ initial requests`
- Heavy-user cost concentration (%) — e.g. top 5% users = X% of cost

### Orchestration & Workflow Complexity
- Calls per user action
- Retry rate (%)
- Fallback rate to larger models (%)
- Workflow depth (steps per request)
- Latency per step + total latency

### Retrieval & Context Efficiency
- Retrieval hit rate (useful vs unused context)
- Average retrieved tokens vs actually used tokens
- Context bloat ratio
- Cost per retrieval operation
- Latency added by retrieval

### Concurrency & Infrastructure
- Peak concurrent requests
- Concurrency utilization (%)
- Cost per peak vs average load
- Queue time / wait time
- Overprovisioning cost (%)

### Quality, Reliability & Stability
- Success rate / task completion rate
- Error rate / hallucination rate
- Retry-induced success rate
- Consistency score (same input → same output)
- Guardrail trigger rate

### Monitoring & Evaluation Overhead
- Cost of evaluation per request
- Logging / storage cost per interaction
- Human-in-the-loop rate (%)
- Model drift detection frequency

---

## C. Valuation / Scenario-Modeling Metrics

### Data Flywheel (3–5 year scenarios)
- Data Flywheel Efficiency — `DFE = % Improvement in Model Performance / % Increase in Data Volume`
- Model Performance Index — `MPI = w1*Accuracy + w2*Latency Score + w3*Cost Efficiency Score` (normalize 0–1 or 0–100)
- CAC Decay Rate (see above)
- Data Network Effect Multiplier — `DNEM = 1 + log(Total Data / Initial Data)`

### Cost Per Inference (CPI) modeling — AI-native COGS
- CPI — `(Compute Cost + Model Licensing + Infrastructure Overhead) / # Inferences`
- Cost per Token — `Total Compute Cost / Total Tokens Processed`
- Value per Token (VPT) — `Revenue Attributable to Output / Tokens Used`
- Gross Margin per Inference — `Revenue_per_inference − CPI`
- Blended CPI with Cascading — `(%Small × Cost_small) + (%Medium × Cost_medium) + (%Large × Cost_large)`
- Routing Accuracy

### Synthetic Data Modeling
- Synthetic Data Cost Ratio — `SDCR = Synthetic Data Cost / Total Training Data Cost`
- Data Coverage Ratio — `(Real + Synthetic) / Total Required Data`
- Performance Lift from Synthetic Data — `(Perf_with_synth − Perf_without) / Perf_without`
- Cost Efficiency of Synthetic Data — `Synthetic Data Cost / Performance Improvement (%)`
- Real-to-Synthetic data ratio
- Data Quality Score — `DQS = w1*Realism + w2*Diversity + w3*Label Accuracy`

### Regulatory / Risk Adjustments
- Risk-Adjusted Revenue — `Projected Revenue × (1 − Risk Discount)`
- Compliance Cost Ratio — `Compliance Costs / Revenue`
- Regulatory Exposure Score — `RES = w1*Data Sensitivity + w2*Geographic Exposure + w3*Model Risk Level`
- Expected Regulatory Impact — `Probability of Regulation Event × Impact (Revenue Loss or Cost Increase)`
- Adjusted Gross Margin — `(Revenue × (1 − Risk Discount)) − (COGS + Compliance Costs)`

### Agentic AI Metrics (product-sophistication premium)
- Agentic Depth Score — `ADS = w1*Task Autonomy + w2*Workflow Repeatability + w3*Decision Complexity`
  - Task Autonomy = % tasks completed without human input
  - Workflow Repeatability = % tasks reusable across customers
  - Decision Complexity = multi-step reasoning capability
- Human-in-the-Loop Reduction Rate — `(Manual_before − Manual_after) / Manual_before`
- Automation Value per Customer — `hours saved × cost per hour`
- Agent Reliability Score — `successful task completions / total executions`
- Agentic Premium Factor — `Adjusted Multiple = Base Multiple × (1 + Agentic Premium)` (Weak 0–10%, Strong 20–50%+)

### Vertical AI / Context-Moat Metrics
- Vertical Depth Score — `VDS = w1*Domain-specific features % + w2*Custom workflows + w3*Industry integrations`
- Context Moat Strength — `CMS = Proprietary Data Volume × Data Uniqueness × Switching Cost`
- Data Exclusivity Ratio — `Proprietary Data / Total Data Used`
- Time-to-Replicate (months for a competitor to match the product)
- Vertical Premium Multiplier — `Base Valuation × (1 + Vertical Premium)` (horizontal baseline, deep vertical +25% to +100%)

### Technical Team Premium (valuation-level, not runtime-loggable)
- Team Premium Factor — `Final Valuation / Baseline Valuation` (strong team 2x–5x)
- Founder Signal Score — `FSS = w1*Research pedigree + w2*Prior exits + w3*Relevant domain expertise`
- Execution Credibility Index — `ECI = (Shipped Products + Revenue Traction + Hiring Quality) / Time`
- Talent Density Ratio — `# Senior Engineers / Total Team Size`
- Hiring Magnetism Score — `Inbound candidates / Total hires`

---

## D. UI & Interaction Metrics

Intent-driven interaction metrics (from `UI & Interaction Metrics`):

- Intent Capture Rate (ICR) — `# sessions with natural-language goal input / total sessions`
- Intent Success Rate (ISR) — `# intents completed successfully / total intents submitted` (task completed without manual correction)
- Time-to-Intent Completion (TIC) — `avg(time from intent submission → task completion)`
- Steps per Outcome (SPO) — `avg(# interactions required to complete a task)`

Note: source list ends with a trailing dash, indicating the list was intended to continue — confirm with product whether more UI metrics should be added.

---

## E. Suggested MLflow Logging Layers

For implementation, the metrics above cleanly split into three layers:

### 1. Per-request (params, tags, metrics on every inference call)
- Request ID, session ID, user segment (tag)
- Model used, routing tier (small/medium/large) (tag)
- Input tokens, output tokens, total tokens
- Compute cost, retrieval cost, orchestration cost, retry cost
- Latency per step, total latency
- Retry count, fallback-to-larger-model flag
- Retrieval hit flag, retrieved tokens, used tokens
- Guardrail triggered flag, error type (if any)
- Success flag, HITL involved flag
- Natural-language intent present flag (for ICR)

### 2. Per-session / per-workflow aggregates
- Calls per workflow, workflow depth
- Steps per Outcome (SPO)
- Time-to-Intent Completion (TIC)
- Intent Success Rate (ISR) at session level
- Workflow cost (fully-loaded)
- Exploration-vs-production tag

### 3. Offline / roll-up (batch jobs over the MLflow log store)
- All percentile metrics (p50, p90, p95, p99 cost and latency)
- Cost variance / CV, retry amplification factor
- Heavy-user cost concentration
- Cost-per-user and revenue-per-user distributions
- Margin metrics (gross, contribution, by percentile, under peak load)
- DFE, MPI, CPI, Blended CPI, VPT
- CAC Decay, DNEM
- Synthetic-data metrics (SDCR, coverage, lift, DQS)
- Regulatory-adjusted revenue/margin
- Agentic, vertical, and team valuation scores

---

## Open questions (from source docs, still unresolved)

- What's our go-to-market motion?
- What's the unit of value our pricing can scale with?
- How do we determine a customer's willingness to pay?
- How do we design a pricing model that stays flexible and scalable without sticker shock?
- Which additional UI & Interaction metrics belong in the list (the source cuts off)?
