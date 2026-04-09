# LLM Hosting Options Comparison (EU/Germany Focus)

## Purpose

This document compares six ways to host/use LLMs for organizations in Germany, especially conservative manufacturing companies with strong requirements around confidentiality, legal certainty, and vendor trust.

Compared options:

1. Direct US providers (OpenAI, Anthropic APIs)
2. Mistral as EU provider
3. Hyperscalers with EU locations (Azure OpenAI, Google Vertex AI)
4. German managed model platform (IONOS AI Model Hub)
5. German rented GPU server (example: Hetzner dedicated GPU)
6. Own hardware (on-prem/self-hosted)

---

## Method And Assumptions

## What is list-priced vs estimated

- **List-priced**: Public token/API rates where available from official provider pages.
- **Estimated**: Ops labor, power, cooling, storage, integration, compliance overhead, and effective throughput on self-hosted GPUs.
- **Important**: API/model prices can change. Use this as a decision baseline, then refresh numbers before procurement.

## Monthly demand scenarios (normalized)

- **Pilot**: 20M input tokens + 5M output tokens / month
- **Rollout**: 200M input + 50M output / month
- **Enterprise**: 1,000M input + 250M output / month

Output/Input ratio is fixed at 0.25 to keep all options comparable.

## Performance and throughput assumptions

- **Pilot target**: 5-15 concurrent users, interactive latency usually acceptable up to ~4-8 seconds per answer.
- **Rollout target**: 30-80 concurrent users, stable p95 latency expected in the 2-5 second range.
- **Enterprise target**: 150+ concurrent users, predictable p95 latency and capacity buffers required.
- Throughput comparisons depend on:
  - model size and reasoning depth
  - provider-side capacity controls/rate limits
  - token generation speed (tokens/sec)
  - architecture choices (streaming, batching, caching, RAG chunk size)
- For self-hosted options, practical throughput is mainly an engineering result (serving stack, quantization, GPU memory fit, autoscaling).

## Cost formulas

- **Token-based services**  
Monthly Cost = (InputTokens / 1M * InputPricePer1M) + (OutputTokens / 1M * OutputPricePer1M) + PlatformOverhead
- **Rented GPU server**  
Monthly Cost = ServerRent + Storage/Backup + OpsLabor + (Optional standby GPU for HA)
- **Own hardware (on-prem)**  
Monthly Cost = AmortizedCapex + PowerAndCooling + DatacenterSpace + OpsLabor + SparePartsAndSupport

## Representative rates used for comparison

These are representative anchors for side-by-side comparison, not contractual quotes:

- **Premium US API class**: EUR 8 input / 1M + EUR 24 output / 1M
- **Mistral mid/high class**: EUR 2 input / 1M + EUR 6 output / 1M
- **Hyperscaler hosted frontier class (EU region)**: EUR 10 input / 1M + EUR 30 output / 1M
- **IONOS model hub classes**: taken from published model tiers and sample rates on the public page
  - Standard: EUR 0.15 / 1M in + EUR 0.15 / 1M out
  - Mid: EUR 0.65 / 1M in + EUR 0.65 / 1M out
  - High: EUR 1.75 / 1M in + EUR 1.75 / 1M out

---

## Option 1: Direct US Providers (OpenAI, Anthropic APIs)

## Model selection and power

- Strongest access to latest frontier models and ecosystem features.
- Fast release cadence, broad tooling, strong quality for reasoning/coding.
- Best for maximum model capability and quickest prototype-to-production path.

## Performance and throughput

- Very strong default latency/throughput for managed API usage.
- Often best burst handling due to large provider capacity pools.
- Real-world throughput can still be constrained by account-level rate limits and model-tier quotas.

## Cost profile (scenario math)

Using representative premium API class (EUR 8 in / EUR 24 out):

- **Pilot**: 20 * 8 + 5 * 24 = **EUR 280/month**
- **Rollout**: 200 * 8 + 50 * 24 = **EUR 2,800/month**
- **Enterprise**: 1,000 * 8 + 250 * 24 = **EUR 14,000/month**

Explicit cross-option cost factors at the same token volume:

- vs Mistral representative class: US premium API is **4.00x more expensive** (Mistral is **4.00x cheaper**).
- vs hyperscaler frontier class in EU: US premium API is **1.25x cheaper** (hyperscaler is **1.25x more expensive**).
- vs IONOS Standard tier: US premium API is **74.67x more expensive**.
- vs IONOS Mid tier: US premium API is **17.23x more expensive**.
- vs IONOS High tier: US premium API is **6.40x more expensive**.

Additional typical cost factors:

- Guardrails/observability/proxy tooling
- Prompt caching and batch mode (can reduce cost)
- Integration and governance workload

## Legal data protection (GDPR, trade secrets)

- GDPR compliance is possible via contracts and technical controls.
- Key legal concern is international transfer and access-risk perception (Schrems II context, lawful access concerns).
- For high-value trade secrets, procurement often requests stronger evidence and stricter contractual language.

## Trust and convincing conservative German manufacturing

- Technically strong, but often harder to sell internally when strict "EU-only control" is expected.
- Usually requires a robust legal package (DPA/SCCs, transfer impact assessment, data minimization architecture).

---

## Option 2: Mistral (European Provider)

## Model selection and power

- Broad modern portfolio with strong practical quality.
- Usually below absolute frontier peak in some categories, but often very competitive for enterprise use cases.
- Clear fit for organizations wanting a European provider profile.

## Performance and throughput

- Generally good interactive performance for mainstream enterprise workloads.
- Throughput headroom depends on selected model tier and commercial plan limits.
- Not always equal to absolute top-end frontier throughput under extreme peak load.

## Cost profile (scenario math)

Using representative Mistral class (EUR 2 in / EUR 6 out):

- **Pilot**: 20 * 2 + 5 * 6 = **EUR 70/month**
- **Rollout**: 200 * 2 + 50 * 6 = **EUR 700/month**
- **Enterprise**: 1,000 * 2 + 250 * 6 = **EUR 3,500/month**

Explicit cost factor vs Option 1 (US premium API) at same volume:

- Mistral is **4.00x cheaper** (US premium API is **4.00x more expensive**).

## Legal data protection (GDPR, trade secrets)

- Favorable legal and governance posture as an EU-headquartered provider.
- Still needs full vendor due diligence (subprocessors, support access, retention defaults, incident process).

## Trust and convincing conservative German manufacturing

- Typically easier to position than US-only options due to European governance perception.
- Works well where "strong EU posture" is required, while keeping managed API convenience.

---

## Option 3: Hyperscalers In EU (Azure OpenAI, Google Vertex AI)

## Model selection and power

- Access to high-end models plus enterprise cloud ecosystem.
- Strong operational maturity (IAM, networking, logging, policy controls).
- Good balance when company already runs on Azure/GCP.

## Performance and throughput

- Strong enterprise-grade scaling options (regional deployments, provisioned capacity).
- Good option when predictable throughput SLAs are required and cloud architecture is mature.
- Latency varies by region/model/deployment mode; provisioned capacity usually improves consistency.

## Cost profile (scenario math)

Using representative hyperscaler hosted frontier class (EUR 10 in / EUR 30 out):

- **Pilot**: 20 * 10 + 5 * 30 = **EUR 350/month**
- **Rollout**: 200 * 10 + 50 * 30 = **EUR 3,500/month**
- **Enterprise**: 1,000 * 10 + 250 * 30 = **EUR 17,500/month**

Explicit cost factor vs Option 1 (US premium API) at same volume:

- Hyperscaler frontier class is **1.25x more expensive** (US premium API is **1.25x cheaper**).

Extra factors:

- Egress/network and managed security tooling
- Provisioned throughput reservations for predictable latency
- Potential discount via batch/committed usage

## Legal data protection (GDPR, trade secrets)

- EU regions and data-boundary options improve compliance posture.
- Corporate control remains US-based; legal perception risk can remain for conservative buyers.
- Contract detail and tenant architecture are critical for legal defensibility.

## Trust and convincing conservative German manufacturing

- Often acceptable when existing enterprise cloud relationship exists.
- Still may require additional legal/works-council communication on sovereign-control limits.

---

## Option 4: German Managed Model Platform (IONOS AI Model Hub)

## Model selection and power

- Curated model selection, strong fit for practical business workloads.
- Less likely to expose every newest frontier model immediately.
- OpenAI-compatible API lowers migration cost.

## Performance and throughput

- Usually strong enough for internal copilots, document QA, and business workflow automation.
- Throughput is tied to available model classes and platform capacity management.
- For highly latency-sensitive, very high-QPS use cases, validate load-test results before scaling decisions.

## Cost profile (scenario math from public tier rates)

### Standard tier (EUR 0.15 in / EUR 0.15 out)

- **Pilot**: 20 * 0.15 + 5 * 0.15 = **EUR 3.75/month**
- **Rollout**: 200 * 0.15 + 50 * 0.15 = **EUR 37.50/month**
- **Enterprise**: 1,000 * 0.15 + 250 * 0.15 = **EUR 187.50/month**

Explicit cost factor vs Option 1 (US premium API) at same volume:

- IONOS Standard tier is **74.67x cheaper** (US premium API is **74.67x more expensive**).

### Mid tier (EUR 0.65 in / EUR 0.65 out)

- **Pilot**: **EUR 16.25/month**
- **Rollout**: **EUR 162.50/month**
- **Enterprise**: **EUR 812.50/month**

Explicit cost factor vs Option 1 (US premium API) at same volume:

- IONOS Mid tier is **17.23x cheaper** (US premium API is **17.23x more expensive**).

### High tier (EUR 1.75 in / EUR 1.75 out)

- **Pilot**: **EUR 43.75/month**
- **Rollout**: **EUR 437.50/month**
- **Enterprise**: **EUR 2,187.50/month**

Explicit cost factor vs Option 1 (US premium API) at same volume:

- IONOS High tier is **6.40x cheaper** (US premium API is **6.40x more expensive**).

## Legal data protection (GDPR, trade secrets)

- Strong sovereign/EU positioning in messaging and hosting posture.
- Attractive for teams requiring "German/EU-controlled" narrative and lower transfer-risk complexity.

## Trust and convincing conservative German manufacturing

- Usually one of the easiest options to justify to legal/procurement/works council.
- High trust for data locality and control story, especially for sensitive internal knowledge bases.

---

## Option 5: German Rented GPU Hardware (Hetzner Dedicated GPU Example)

## Model selection and power

- Full flexibility: run open-source models, tune quantization, control serving stack.
- Performance depends on model size, quantization, and throughput engineering.
- No built-in managed LLM convenience; requires strong MLOps/platform work.

## Performance and throughput

- Can deliver high throughput if model fits GPU memory well and serving is optimized.
- Performance is highly sensitive to batching strategy, quantization, and scheduler configuration.
- Single-node setups have clear ceiling; horizontal scaling adds architecture complexity.

## Cost profile (formula-based estimate)

For a dedicated server like Hetzner GEX131 class:

- Monthly server rent: **EUR 1,068.62/month** (given scenario)
- Ops labor (platform + ML + on-call): **P_ops**
- Backup/storage/network/security tools: **P_misc**

Monthly total (single production node):

- **C_gpu_rental = 1,068.62 + P_ops + P_misc**  (EUR/month)

High-availability setup (active + warm standby):

- **C_gpu_ha = 2 * 1,068.62 + P_ops + P_misc**  (EUR/month)

Practical interpretation:

- Usually higher fixed monthly baseline than API for pilots.
- With this fixed rent level, cost-efficiency requires very high and stable utilization and low ops overhead.
- Break-even depends on achieved tokens/sec, utilization, and total operational overhead.

## Legal data protection (GDPR, trade secrets)

- Strong data control because you own the stack/configuration.
- Legal quality depends on your implementation quality (access control, logging, deletion, key management).
- Best option for strict trade-secret separation when engineered properly.

## Trust and convincing conservative German manufacturing

- Strong trust argument if architecture is clean and auditable.
- Requires proof of operational maturity; otherwise risk shifts from vendor to your own team.

---

## Option 6: Own Hardware (On-Prem Self-Hosted LLM)

## Model selection and power

- Maximum sovereignty and customization.
- Potentially lower effective cost at scale for stable workloads.
- Highest complexity and delivery risk.

## Performance and throughput

- Potentially excellent throughput for stable, predictable workloads after tuning.
- Best-case performance requires dedicated platform engineering and capacity planning.
- Without strong ops maturity, latency variance and incidents can outweigh sovereignty benefits.

## Cost profile (TCO estimate model)

Monthly TCO:

- **AmortizedCapex**: (HardwarePurchase / 36 to 60 months)
- **PowerAndCooling**: IT load * PUE * energy price
- **DatacenterSpace**: rack/room allocation
- **OpsLabor**: platform, ML infra, SRE, security
- **Support/Spare**: maintenance contracts, replacements

Formula:

- **C_onprem = AmortizedCapex + PowerAndCooling + DatacenterSpace + OpsLabor + Support/Spare**

Practical interpretation:

- Rarely best for pilot economics.
- Often attractive for high-volume, predictable, long-lived workloads with very strict confidentiality.

## Legal data protection (GDPR, trade secrets)

- Strongest control over processing and data lifecycle.
- Simplifies the "no third-party processor for inference" argument in sensitive settings.
- Requires internal governance and auditability to realize legal benefit.

## Trust and convincing conservative German manufacturing

- Usually strongest persuasion power for strict sovereignty requirements.
- Procurement confidence is high if ISO/TISAX-style controls and documented processes exist.

---

## Side-By-Side Summary Matrix


| Option                     | Model Power Ceiling | Performance/Throughput Potential | Cost At Low Volume      | Cost At High Volume       | GDPR/Trade-Secret Posture       | US-Independence Perception | Adoption Friction |
| -------------------------- | ------------------- | -------------------------------- | ----------------------- | ------------------------- | ------------------------------- | -------------------------- | ----------------- |
| US APIs (OpenAI/Anthropic) | Very High           | Very High                         | Medium                  | High                      | Medium (contract-heavy)         | Low                        | Low               |
| Mistral (EU)               | High                | High                              | Low-Medium              | Medium                    | High                            | Medium-High                | Low               |
| Azure/GCP in EU            | Very High           | Very High                         | Medium-High             | High                      | Medium-High                     | Medium                     | Medium            |
| IONOS AI Model Hub         | Medium-High         | Medium-High                       | Very Low-Low            | Low-Medium                | High                            | High                       | Very Low          |
| Hetzner GPU rental         | Medium-High to High | Medium to Very High (ops-dependent) | High (fixed)         | Medium-High (still fixed-cost heavy) | High (implementation-dependent) | High                       | High              |
| Own on-prem hardware       | Medium-High to High | Medium to Very High (ops-dependent) | Very High (capex + ops) | Low-Medium (at scale)   | Very High                       | Very High                  | Very High         |


---

## Detailed Scenario Calculation: Hetzner GPU (GPT-OSS-120B) vs Google Cloud API (Gemini 2.5 Flash-Lite)

This section uses your concrete scenario assumptions:

- Hetzner GPU server can run `gpt-oss-120b`.
- `canirun.ai` estimate for this setup: about **21 output tokens/second**.
- Hetzner server base rent: **EUR 1,068.62/month**.
- Google API pricing for Gemini 2.5 Flash-Lite class:
  - **USD 0.15 / 1M input tokens**
  - **USD 0.40 / 1M output tokens**
- Default org quota on Google Cloud: **2,000,000 tokens/minute**.
- Request mix for comparison: same 4:1 input:output ratio used in this document.

## 1) Throughput envelope

### Hetzner single-server output throughput

- Output throughput: 21 tok/s
- Output per minute: 21 * 60 = **1,260 tok/min**
- Output per month (30d, 100% utilization):  
  21 * 60 * 60 * 24 * 30 = **54,432,000 output tokens/month**

Using 4:1 input:output:
- Input/month at that load: 4 * 54,432,000 = **217,728,000 input tokens/month**
- Total/month: 54,432,000 + 217,728,000 = **272,160,000 total tokens/month**

### Google Cloud quota envelope

- Quota: 2,000,000 tok/min
- Per second equivalent: 2,000,000 / 60 = **33,333 tok/s total**

At 4:1 input:output:
- Output quota ceiling: 20% * 33,333 = **6,667 output tok/s**
- Input quota ceiling: 80% * 33,333 = **26,667 input tok/s**

Interpretation:
- Quota ceiling is about **317.48x higher** than 21 output tok/s (6,667 / 21).
- In this scenario, Google quota is not the bottleneck for the compared single-server load.

## 2) Token cost at equivalent workload

### Google API cost for "same monthly volume as Hetzner 21 tok/s"

Monthly volume from above:
- Input: 217.728M
- Output: 54.432M

Cost:
- Input: 217.728 * USD 0.15 = **USD 32.6592**
- Output: 54.432 * USD 0.40 = **USD 21.7728**
- Total: **USD 54.432/month**

Direct cost factor vs Hetzner base rent at same workload:

- Google API token cost (USD 54.432/month) is about **19.63x cheaper** than Hetzner base rent EUR 1,068.62/month.

Equivalent blended price at 4:1 mix:
- 0.8 * 0.15 + 0.2 * 0.40 = **USD 0.20 per 1M total tokens**

So:
- 272.16M total tokens * USD 0.20 / 1M = **USD 54.432/month**

### Google API cost at full quota consumption

- Max monthly tokens from 2M tok/min:  
  2,000,000 * 60 * 24 * 30 = **86,400,000,000 tokens/month**
- Cost at USD 0.20 / 1M blended:  
  86,400 * USD 0.20 = **USD 17,280/month**

## 3) Effective per-token economics for the Hetzner server

Let:
- `C_hetzner_all_in_month` = 1,068.62 + storage/backup + ops labor + security/tooling  (EUR/month)

Then:
- **Hetzner base-rent effective EUR/1M total tokens (no ops add-ons)**  
  = 1,068.62 / 272.16 = **EUR 3.93 per 1M total tokens**  (at 100% utilization and 21 tok/s output)
- **Hetzner all-in effective EUR/1M total tokens**  
  = C_hetzner_all_in_month / 272.16

Utilization sensitivity with fixed rent (no ops add-ons):
- At 100% of 21 tok/s envelope: **EUR 3.93 / 1M**
- At 50% utilization: **EUR 7.85 / 1M**
- At 25% utilization: **EUR 15.70 / 1M**
- At 10% utilization: **EUR 39.26 / 1M**

Break-even vs Google token price in this scenario:
- Google blended price = **USD 0.20 per 1M total tokens**
- Break-even all-in monthly cost for Hetzner at 21 tok/s:
  - 272.16 * 0.20 = **USD 54.43/month**

Interpretation:
- At a fixed server rent of EUR 1,068.62/month, Hetzner is already about **19.63x above** the USD 54.43/month break-even threshold before any ops costs.
- On pure token economics, this means Google API is decisively cheaper under these assumptions, even if we ignore additional self-hosting overhead.

## 4) Practical performance interpretation

- **Capacity/performance**: Google quota envelope is vastly larger than one 21 tok/s server; scaling is easier and faster with API quota/capacity management.
- **Capacity/performance factor**: Google output quota ceiling (6,667 tok/s) is **317.48x higher** than the Hetzner single-server output rate (21 tok/s).
- **Latency consistency**: A managed API generally offers better burst absorption; a single dedicated server can show higher jitter when utilization rises.
- **Control and sovereignty**: Hetzner/self-hosted still has strong control advantages (stack control, isolation), even if token economics are worse in this scenario.
- **Quality caveat**: "GPT-OSS-120B comparable to Gemini 2.5 Flash-Lite" should be validated on your tasks (manufacturing QA, coding, RAG faithfulness). Cost/performance only matters if quality passes acceptance thresholds.

## 5) Decision implication for this exact scenario

- If your assumptions hold (21 tok/s and Google USD 0.15/USD 0.40 with 2M tok/min quota), **Google API dominates on pure cost and throughput elasticity**.
- With EUR 1,068.62/month rent, choose Hetzner self-hosting mainly when sovereignty/control requirements outweigh about a **19.63x cost premium** (vs Google API token cost at equivalent workload) and higher ops complexity.

---

## Procurement And Works Council Convincing Checklist

- Clear data-flow map (what leaves ERP/MES/PLM and what never leaves).
- Contract package: DPA, subprocessors, retention, deletion, audit rights.
- Technical controls: encryption, key ownership, role-based access, logging.
- Legal memo on international transfer exposure and mitigations.
- Trade-secret classification model and prompt/data handling policy.
- Pilot evidence: red-team tests and hallucination risk controls.

---

## Recommendation Tree (Practical)

- **Priority: absolute best model quality and fastest feature velocity**
  - Start with direct frontier APIs (US providers) or hyperscalers in EU regions.
- **Priority: strong EU/German sovereignty story with managed operations**
  - Favor IONOS AI Model Hub or Mistral-first architecture.
- **Priority: strongest confidentiality and independence from non-EU control**
  - Move toward German dedicated GPU or own on-prem stack, if you can fund and staff operations.
- **Priority: lowest short-term cost for simple internal use cases**
  - Managed token services with low-price tiers (IONOS/Mistral classes) are usually the cheapest entry.

---

## Sources

- IONOS AI Model Hub (features and public token pricing examples):  
[https://cloud.ionos.de/managed/ai-model-hub](https://cloud.ionos.de/managed/ai-model-hub)
- Hetzner Dedicated GPU server example (GEX131):  
[https://www.hetzner.com/de/dedicated-rootserver/gex131/](https://www.hetzner.com/de/dedicated-rootserver/gex131/)
- OpenAI API pricing:  
[https://openai.com/api/pricing/](https://openai.com/api/pricing/)
- Anthropic Claude API pricing:  
[https://platform.claude.com/docs/en/about-claude/pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- Mistral pricing:  
[https://mistral.ai/pricing](https://mistral.ai/pricing)
- Azure OpenAI pricing and data residency references:  
[https://azure.microsoft.com/en-us/pricing/details/azure-openai/](https://azure.microsoft.com/en-us/pricing/details/azure-openai/)  
[https://azure.microsoft.com/en-us/explore/global-infrastructure/data-residency](https://azure.microsoft.com/en-us/explore/global-infrastructure/data-residency)
- Google Vertex AI pricing and locations:  
[https://cloud.google.com/vertex-ai/generative-ai/pricing](https://cloud.google.com/vertex-ai/generative-ai/pricing)  
[https://docs.cloud.google.com/vertex-ai/docs/general/locations](https://docs.cloud.google.com/vertex-ai/docs/general/locations)

## Notes

- Recalculate all token-based estimates before final vendor selection.
- For legally critical deployments, get an external legal review for transfer-impact and trade-secret protections.
- `canirun.ai` model/hardware feasibility reference (community estimate source):  
  [https://www.canirun.ai/](https://www.canirun.ai/)

