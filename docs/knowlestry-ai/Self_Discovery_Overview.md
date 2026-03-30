

# Problems

- Schema acts as a bridge between natural language representation of use cases and mathematical representation
- Metrics to measure the quality of a dataset
  - Distribution comparison:
    - Very objective mathematical way
    - Requires reference to compare to and schema
  - Language-based evaluation with LLM
    - No prerequisites
    - Highly subjective, meaningfulness not clear
  - Coverage scores
    - E.g., by industry by type of use case found in information about relevant customers, industries etc.
    - Scoring only possible in aspect that information is available for
- What are criteria for a good schema for machine data analysis use cases?
  - Representation power: All relevant information of the use cases is included in their schema representation
  - Compactness: The smaller the schema the better
- Metrics to measure the quality of a schema
  - Solution success rate, compress/reduce length with same classification quality
    - Measures based on relevance for actual application
    - Also enables systematic improvement of schema
    - Only measures quality of a mixture with other factors such as dataset and 
    - Whole training pipeline needed
  - NLP approach: iterate through a list of use cases, extract a list of facts for each of them with LLM, then count what percentage of these facts are contained in the schema representation
    - No prerequisites or dependencies
    - Only evaluates on pure quantity of information, does not take relevance into account
  - Measuring the size, e.g. with number of keys, possible values in total etc.
    + Easy and objective
    - Only size criteria, limited informative value without the representation power
