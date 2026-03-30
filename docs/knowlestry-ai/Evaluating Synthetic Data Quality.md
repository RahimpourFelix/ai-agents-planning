# Evaluating Synthetic Data Quality

Synthetic data is composed of two primary parts:
* **A: Use Case Description** (Text)
* **B: Machine Data Simulation** (Data)

---

## Current Situation: Limited Real Data
*Challenge: Insufficient real-world data is available for benchmarking.*

**Modification:** When the synthetic description is generated, generate the proposed distribution simultaneously.

### Evaluate Description Quality (A)
* **Option I:** Independently prompt an LLM to act as a judge and assign a confidence score based on the likelihood of the description occurring in the real world.
* **Option II:** Generate this score concurrently with the description generation.

### Evaluate Data Quality (B)
* Assuming the description is accurate, apply statistical tests to verify if the simulation adheres to the proposed distribution.

---

## Future Situation: Sufficient Real Data Available
*Advantage: Real data distributions become available.*

**Ideally:** A structured schema of the real data (e.g., a tree structure) is developed.

### Evaluate Description Quality (A)
* Compare the schema of the synthetic description against real descriptions within the same or nearest schema clusters (e.g., using cosine similarity scores on vectorized schema component strings).

### Evaluate Data Quality (B)
* From the nearest cluster of real machine data in (A), identify the associated real machine data.
* Perform statistical tests comparing the synthetic dataset against the real dataset.
* *Optional:* Perform statistical tests on the distribution parameters.

---

## Actionable Next Steps
As an initial step, **Multivariate Normal distributions** can be utilized. Specifically for classification tasks, because the system will likely involve multiple states, a **Gaussian Mixture Model (GMM)** can be used.