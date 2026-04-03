# Pricing thoughts

## Assumptions

Currently, we plan with three auto-research processes per year.
We assume one user request calls 8 agents and 1 LLM.

## Step 1: Initalization

A customer with roughly 15 GB of data will need:

- 100m input tokens, roughly 2.50€/m
- 100m output tokens, roughly 15€/m
- 100m embedding model tokens, roughly 3€/m

This results in a cost of ~2050€.

## Auto-Research

An auto-research process will be started 30 days after the data was intially loaded.
Auto research means the system tries to improve the data based on Knowlestry Intelligence.

We expect the same processing cost as the initialization, plus addition costs for Knowlestry Intelligence.

Since there is no information on costs at this point, we assume factor 2 and calculate costs 4100€ for 15 GB of data.

## Costs of user interaction

### Traffic costs

Assuming a customer with 15 GB has 200 users, generating 30 questions a day, which results in 6000 requests per day.

A user question may contain 10 sentences. With an average of 5-6 characters per word the incoming message might contain 800-1200 characters.
UTF-8 has 1 byte per character, which results in ~1KB per user message

A LLM might respond 2-5x longer then the question, which could result in ~3KB per response.

With 6000 messages roughly 24 MB of traffice are consumed every day.

### LLM traffic

The system might send enriched questions to an LLM. 
Using chat history, RAG chunks, prompts, or other data a request can be between 20-40 KB.
When the response stays the same and we assume 30 KB as input, the traffic would be 180MB per day.

### Internal traffic

Internal traffic is hard to calculate at this point; however, if agents pass 8 calls per request, and the payload is 25 KB request and 25 reply, a single call might cause 50 KB of traffic.

Internal traffic might result in 400 KB per request, which results into 2.4 GB/day based on 6000 requests.

### Traffic per month

Traffic from user to system, and system to LLM could be roughly 204 MB/day, which results to ~6.2 GB/month.

Internal traffic adds ~72 GB/month.

### Max traffic

Assuming traffic of 500 KB per request and 5 servers with a max traffic capacity of 20 TB, a loadbalanced setup migth serve around 1.3m requests per day.

Excluded are calls to the database.

### Optimizations

To avoid repeated copy of message for performance and traffic reasons, 
specific databases (like Redis) can be used to pass conversation IDs around and let agents read only what they need.
The planned monitoring database could serve as such a storage.

## Server specifics

- Ingress: Spring API/Chat, loadbalanced
- Workers: 8 agents, grouped on worker machines
- Data: Postgres, Mevius setup

Asumptions:

6,000 requests/day = 0.07 requests/second average
100,000 requests/day = 1.16 requests/second average
1,000,000 requests/day = 11.6 requests/second average

Expectations:

- LLM calls can be long
- Passing from agent to agent may sum up
- Bursts during work hours

### Hetzner pricing

- LB11 ~ 5 €
- LB21 ~ 10 €
- LB31 ~ 20 €
- CPX21 ~ 8–10 €
- CPX31 ~ 15–20 €
- CPX41 ~ 25–35 €
- CPX51 ~ 40–60 €
- CCX (dedicated CPU) ~ 40–120 €
- Dedicated AX server ~ 60–120 €

### Small Setup

6000 requests/day:

- 1x LB11
- 2x app nodes for Spring chat/API (CPX21–31)
- 2x worker nodes for the agent runtime (CPX31)
- 1x database node (CPX31–41)
- optional 1x small Redis node (CPX21)
- Monitoring (Postgres on same or small extra node)
- ArangoDB (Graph): 3xCPX31

Milvus block
- 3x CPX31 nodes for a small K3s/Kubernetes Milvus cluster

Monitoring / Dashboard
- Grafana + Prometheus (shared node or small CPX21)

Estimated monthly cost:
- Load balancer: ~5 €
- App nodes: ~30–40 €
- Worker nodes: ~30–40 €
- Database: ~20–35 €
- Redis: ~10 €
- Milvus cluster: ~45–60 €
- Monitoring/dashboard: ~10–15 €
- ArangoDB: ~60 – 85 €

Base: ~210 – 285 €
+ buffer (traffic, storage, spikes): ~50 €

Total: ~265 – 335 € / month

#### Medium

100.000 requests/day:

- 1x LB21 or LB31
- 3x app nodes (CPX31–41)
- 3x to 4x worker nodes (CPX41)
- 1x dedicated DB node (CCX class)
- 1x Redis/queue node (CPX31)
- 3x ArangoDB nodes (CPX41)

Milvus block
- 3x to 5x CPX41 nodes for the Milvus cluster

Monitoring / Dashboard
- Dedicated monitoring node (CPX21–31)
- Grafana + Prometheus + logging (Loki/ELK-lite)

Estimated monthly cost

- Load balancer: ~10–20 €
- App nodes: ~60–120 €
- Worker nodes: ~100–160 €
- Database (CCX): ~50–100 €
- Redis: ~15–25 €
- Milvus cluster: ~100–175 €
- Monitoring: ~15–25 €
- ArangoDB: ~100 – 150 €

Base: ~450 – 750 €
+ buffer (storage, traffic, scaling headroom): ~100–150 €

Total: ~550 – 900 € / month

### Large setup

1.000.000 requests/day:

- 1x LB31 (or 2 for redundancy / traffic split)
- 4x to 6x app nodes (CPX41–51)
- 6x to 10x worker nodes (CPX41–51)
- 1x dedicated DB primary (AX or large CCX)
- 1x dedicated DB replica
- 1x to 2x Redis/queue nodes
- 3x to 5x ArangoDB nodes (CPX41–51)

Milvus block
- 5x to 7x worker nodes for the Milvus Kubernetes cluster (CPX41 / CCX mix)

Monitoring / Dashboard
- Dedicated monitoring stack
- Grafana + Prometheus + Loki/ELK
- possibly separate logging storage node

Estimated monthly cost
- Load balancer(s): ~20–40 €
- App nodes: ~150–300 €
- Worker nodes: ~250–600 €
- Database primary (dedicated): ~60–120 €
- Database replica: ~60–120 €
- Redis: ~30–60 €
- Milvus cluster: ~200–400 €
- Monitoring stack: ~40–80 €
- ArangoDB: ~170 – 400 €

Base: ~970 – 2,100 €
+ buffer (traffic, storage growth, redundancy): ~200–400 €

Total: ~1200 – 2500 € / month

## Rough estimate of price per request

The dominant factor fo cost is LLM usage with adding 0.02-0.04€ per request.
Infrastructure decreases with scale, down to 0.001-0.002€

A request to Knowlestry causes a cost of roughly 0.025-0.045€.

## Possible pricing per customer
TODO: Update: personal reinrechnen
TODO: Jeder request benötigt mehrere LLM calls (1 Agent = LLM call, günstiger Modelle, die Endantwort kmmt vom teueren MOdell)

(includes costs + )

Platform fee (base subscription for hosting, infra, monitoring):

- Small: 300-500 € / month, 10 users included, 4k requests per month
- Medium: 1000-1500 € / month, 30 users included, 20k requests per month
- Large: 2500-4500 € / month, 100 users included, 60k requests per month

Extra requests: 0.07€

Initilization:

3000 – 6000 € per 15 GB dataset

Research cycle:

"Continous improvement" included:

- Small: 1/year
- Medium: 2/year
- Large: 3/year

Extra cycle: 1000€ per GB

## TODO

=120000*1,5*10 = 1.8 
10 Personen x 1600 Produktivstunden = ca ~112€/Stunde/pro Person = 1.792.000€ (Personalkosten)
15 Personen x 1600 Produktivstunden = 2.688.000€ (Personalkosten)

// Kosten / Requests * Tag
=2680000/(100000*200) = 0,134


Elena = CEO/Sales
Stefan = KI Overlord/Ingestion/Knowledge Hub
Kiryll = Ingestion/Knowledge Hub
Ruslan = Intelligence
Lok Tung = Intelligence/Trainings Data
Christian = System Arch/Security
Person 1 = MCP/A2A

Person 3 = System Arch/Security
Person 4 = Application/Connector
Person 2 = Customizing/MCP/A2A

(Student) Felix = Tech. Marketing/Webseite/Automatisierung (Hubspot)
(Extern) Alexander = Kommunikation
1/2 Person = Marketing


Initiales Investment in Knowlestry Intelligence:
4.000.000€ over 2 years
Maintenance/Optimizing ~500.000/year

Initiales Investment in Knowlestry Platform:
4.100.000€ over 2 years

Regelmäßig
- LLM calls = 2.000.000€/Year
- Cursor = 600€

Dev (einmalig)
- Hardware = 45000€
- Yubikeys = 1500€

Maintenance:

Development Infrastructur ~10000/year
Maintenance/Optimizing ~30000/year



tagessatz 1600
welche aufgaben müssten wie gemacht werden?
maintenance aufgaben
user pflege, monitor by user



Edit by Elena: 
AI pricing must be coumpunded differntly: https://www.productmanagement.ai/p/the-ai-product-pricing-masterclass
Variance > averages
Behavior > users
Workflows > requests
Peak > mean
System dynamics > static KPIs
human resources
customizing
integration aufwand

kosten für das aufsetzen von so einem system