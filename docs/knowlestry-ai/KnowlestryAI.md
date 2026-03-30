# Knowlestry AI

Knowlestry AI is a knowledge orchestration engine
that transforms raw enterprise data into structured, task-oriented workflows.
Suggested by data but governed by customers, it enables prediction, system understanding, and operational insight.
It helps support decision-making, troubleshooting, and process improvement.

It is, in short, an adaptive knowledge operating system—
a system that adapts to domain knowledge.

Adaptive means the system can instantiate and configure agents 
within predefined templates without manual intervention.

## Data

All knowledge is based on data.
Knowlestry AI uses customer data, whether structured or unstructured.
When delivered to the Knowlestry AI system, it will store the data in its raw form in a secure, isolated environment.

## Agent fleet

Inside the Knowlestry landscape, we differentiate between these kinds of agents:

1. proto agents
2. adaptive agents
3. customer agents
4. interaction agents

Proto agents are built-in and deterministic, developed by Knowlestry AI.
They may use LLMs for classification and analysis, but operate within
predefined logic and constraints.

Adaptive agents can execute scripts created by a proto agent or execute Knowkens. They are like a sandbox and operate within clear boundaries of the authorization system. Adaptive agents may execute customer Knowkens, but they are not specifically built for customers.

Customer agents are custom agents created by Knowlestry for the customer. They provide additional tasks. Customer agents know customer data and are specifically built for the customers.

Interaction agents are designed to communicate with the customer. They connect to customer agents or adaptive agents on behalf of the customer.

## Stakeholders

On onboarding, every organisation needs to create accounts for its employees and define stakeholders for various outcomes. It is recommended to define an "admin stakeholder" who receives requests that the Knowlestry system cannot assign to a specific person. 
The "admin stakeholder" will also define which data a stakeholder can see.

## System Components

### Knowlestry Processor

The Knowledge Processor consists of three components:

1. Data Sources
2. Connectors
3. Knowledge Structuring Agents

#### Data Source

Data sources can be of any kind. In the first stage, Knowlestry will use open-source datasets and industrial standards to feed from. In the later stage, human data like support tickets, work orders, or specifications will be used. At a later stage, machine data, including time series and historical data, will be fed into the system. 

Data sources are artifacts that already exist and are not technical components of our system. 

#### Connectors

Connectors are technical systems that Knowlestry provides. We distinguish between two different kinds of connectors:

1. Pull data connector
2. Push data connector

The pull data connector is used for batch connections only. It's a good way to connect to Jira, to file systems, to relational databases, and all that kind of thing. Pull data connectors will connect to their data sources on a regular basis and attempt to identify delta datasets. 

Push data connectors are used for real-time and batch services. While pull data is like a cron job running on Knowlestry servers, push data needs to be actively pushed from the customer site. Usually, push data connectors are Kafka streams, SKS queues, and so on. 

All connectors write received data to customer-specific queues. For Open Source datasets or industrial standards, Knowlestry Requeue will be used. A customer can have one or more queues, depending on the data source type. 

#### Knowledge structuring agents

Currently, two knowledge structuring agents are deployed:

1. Textual Knowledge Structuring Agent
2. Machine Data Knowledge Structuring Agent

Both Agents are proto-agents clearly defined by a Knowlestry.

While the textual version of this agent will process textual knowledge such as tickets and specifications, the machine data agent will process machine data. Both have very similar features and are built on top of the same framework.

The agents will both clean text or data, create semantic triples, and insert them into the vector and GraphDB.

#### Rulebook

Finally, a rule book will be created or updated.
The rulebook is a central artifact that stores interpretations of relations. It is deterministic.

It will be created from:

- predefined rules set by the customer
- statistics (from the knowledge processor)
- user feedback

For example, when heat and a specific area are related, the rulebook knows it is bad to have too much heat. The rule could look like:

    IF temperature > 80c THEN risk

The rulebook will also be stored in the Knowledge hub.
If it changes, the Knowken proposer is notified to propose new potential Knowkens.

The rulebook is created from data (errors happen when the temperature is too high; errors are bad; rule: a high temperature is bad).
User feedback may also lead to new rules. When customer agents cannot complete their tasks and require feedback, customer responses may end up in the rulebook as well.

### Self-Discovery
// TODO THIS IS UNCLEAR
// DEFINE: whawt is the output?

The self-discovery component is a learning component that trains our AI models. It is a controlled training and analysis pipeline.

It uses publicly accessible data or data for which we have the rights.

It does not invent models, modifies the system, deploys agents directly.

// TODO what is actually the output of self-discovery? Stefan

When new data or user input prompts proto agents to analyse and adapt, it is called a "learning cycle." 

The learning cycle consists of these steps:

1. First, it's creating a training dataset and use cases that consist of textual descriptions, machine data, and labels.
2. Then it tries to create a rule keys file, which is then enriched with data from our current data stack, of course, only with data for which we have the right to do so.
3. If data is enriched, the training dataset will be recreated. When there is no more data to be enriched, the data receives a training classifier
4. A proto agent generates a script with rules to train the models in the model stack. It adjusts configurations.
5. The prototype instantiated an adaptive agent for training
6. A summary is sent to the Knowken proposer, where the proposer analyses for new ideas

### Model Stack

// TODO clarify with Stefan how Knowkens connect to these models?

The Model Stack is a clustered service that provides machine learning models for spezialised use cases.
Currently, gradient boosting is used.
They are trained on anonymous or synthetic data.
They are not trained on customer data unless a customer explicitly permits it.
The self-discovery environment trains models in the model stack.

The model stack offers APIs for training, model, prediction.

Customer-specific models or bring your own model will be provided in the future. 

### Knowledge Hub

The Knowledge Hub consists of an API layer, a firewall, GraphDBs, and VectorDBs. It's where Knowlestry relations and customer relations are stored, along with Knowlestry and customer data. It also contains rule books, which are the interpretation of relations, the so-called definition of the causal units.

All data requests, updates, and reads must go through the API. Direct access to databases is not permitted. The API ensures requests are routed through the authorization system. 

Customers may have one or many databases in the knowledge hub. 

Vector databases are also distinguished between organization, workspace, and user databases. 

### Knowlestry Platform

The Knowlestry Platform consists of two main components:

1. The execution layer
2. The agent's abilities

In the execution layer, the platform runs customer agents. They are built based on so-called templates. Customer agents are questioned by interaction agents, which also exist in the execution layer, that talk directly to the customer. 

#### Input-led agent creation

If a customer agent cannot handle a request based on the data, it will prompt the user with follow-up questions. Interaction agents will be used to chat with either the relevant user or the admin stakeholder.

If the user explains a question or provides solutions, the solutions will be stored in the rule book.

If new rules are added to the rulebook, the Knowken proposer will be asked whether there are any potential Knowkens to propose.

#### Agent description

An agent consists of the following parts:
1. UI
2. Action definition (Goal, plan, act, eval, response))
3. Routing
4. Log Memory
5. Tool/Ability
6. Data Source
7. Script

Agent abilities are specialized features that an agent can use or not use. 
The following abilities can be provided:

- Internet search
- LLM requests
- Knowlestry model stack requests
- Third-party API access 
- Reading of specialized data source 
- MCP
- Agent2Agent

### Knowkens

A Knowken is a deployable intelligence module.

An Knowken acts like an immutable, executable specification. 
It is deployed and executed inside an adaptive agent (execution container).
They can be executed like cron jobs in the background.
They might operate like microservices, running in a sandbox on small, specified tasks.

Knowkens are created only by the Knowken proposer and approved Knowkens are stored in the Knowken Registry.

They relate to the system like this:

- Self-Discovery or rulebook changes triggers the proposer.
- The Proposer packages Knowkens
- Registry versions Knowkens: the Knowken becomes immutable
- Adaptive agents execute Knowkens.

The Knowken Proposer receives a summary of data changes or input from the chat system. It evaluates patterns and suggests ideas for new Knowkens based on predefined templates.

Ideas are based on the following templates:

 - Failure monitoring
 - Trend detection
 - Correlation analysis
 - Predictive forecasting
 - Documentation summarization
 - Efficiency comparison

Creating a Knowkens may require many tokens and access to many databases. Therefore, it is potentially expensive. Since Knowkens follow a very specific format, they can be reused and rerun at any time.
Knowkens like a compiled version of intelligence, which makes it not only executable, but its execution can be repeated. 
Knowkens reduce repeated reasoning costs. They move forward from fully dynamic LLM reason to precompiled execution logic (prepared majority of the reasoning ahead of the execution: AOE).
Predictive Knowkens do not require LLM tokens at runtime.
Analytical tokens may use tokens for LLM summaries.

Lifecycle of a Knowken:

- New input causes the agent to think about a Knowken, which may result in an IDEA
- IDEA is proposed to the user
- When the IDEA is passed, the Knowken will be prepared (may result in many system calls)
- The PROPOSAL will be sent for confirmation or adaptation to the user
- When the user agrees, the PROPOSAL will become a KNOWKEN
- When the user no longer wishes to use the KNOWKEN, the status becomes RETIRED

A Knowken consists of:

- Input Schema
- Output Schema
- Evaluation metrics (record knowken precision and accuracy)
- Version metadata (who created it, when, version number)
- Execution schedule (like cron)
- Knowken Proposer / Knowken Registry

If a Knowken is of type PREDICTIVE, they additionally contain:

TODO STEFAN: What is the model file? Is it JSON? I read about Pickle, do we need to commit to one model file? Is this a risk?

- Model file (gradient boosting classifier -> must match the model stack)
- Feature schema definition (input data def, format, units, order)
- Threshold settings (alert with a threshold of 0.80 failures, warn at 0.6)

If a Knowken is of type ANALYTICAL, they additionally contain:

- deterministic query
- aggregation rules
- data scope definition (what data source are allowed?)

The process of a PREDICTIVE Knowken is like:

- Feature extraction
- Model inference (TODO: ask Stefan if this is correct)
- Threshold evaluation
- Event

The process of a ANALYTICAL Knowkn is:

- Query execution
- Aggregation of results
- Optional: LLM summary
- Report

Examples for Knowkens tasks:

- Generate me an extract of recurring tickets
- Predict when the helpdesk might face a bottleneck
- From a list of tickets, what is important data to write to a manual
- What are the recurring problems of a system
- Predicting when an industrial line might fall
- Notifying when an industrial system is inefficient compared to another
- Predicting the load on helpdesk centers and how efficient the work is

In short, Knowkens, running in adaptive agents:

- predict (event-driven)
- monitor (event-driven)
- improve (documentation, event-driven)
- notify (event-driven)
- report (regularly)

Once a Knowken is created, its data and status will be deployed to the Knowken registry. They can be installed, turned off, turned on, and rolled back.
The registry acts as a single source of truth for Knowken. It can validate them and sign them. 

When a new Knowken is proposed, it will not be automatically deployed and usable. The user needs to turn on the proposed Knowken actively. 

#### Marketplace

Later phases of the projects may see commercially used Knowkens shared via a controlled marketplace.

#### System independent

When Knowkens are defined as an open standard, other systems can use the same format. The registry could be sold, licensed, or even serve as a public registry, like Maven Central.
When such a standard is established, Knowkens are system independent, and the Knowlestry registry may serve as a reference implementation.
While the registry may even become open-sourced, the rest of the Knowlestry systems stay proprietary. 

#### Automated payment

Knowken can be paid in crypto tokens or other forms of credit. 

### Customer Access Point

Chat Agents are replying to customer messages. 
They are part of the Customer Access Point.

The Customer Access Point is the interface the user sees. It consists of a Next.js frontend and a Java backend server. Additionally, a database of user settings is available. 

The backend will connect directly to interaction agents. Once such a connection is established, the first information is how the chat should be configured. For example, are there specific questions to ask? How is the layout? What should be shown? The UI will be defined in the user interaction interface definition. 

In the future, there might be an additional way to access the agents via a specific API. It might be possible that users do not need to chat with the system, but can ask specific questions via the API. 

Chats are subject to a very strict authorization system. 
Before they can reply, they need to check with a firewall-like system if they are allowed to respond with the specific data. 

Chat agents can access other chats within the same company if the stakeholders have permission.

Chats can cause the system to propose new Knowkens.
It is possible to manage Knowkens via Chat when the permission is set to an admin stakeholder.

### Observer

The Observer is a log or monitor system. It stores all system-critical events that may be needed for audits, security, or customer billing. It will log the questions asked and monitor the costs specific to questions or agent calls. 

All adaptive agent instantiations, configuration changes, evaluation outcomes, and learning cycles are logged and versioned.

Admin stakeholders have visibility into these changes and can roll back configurations to previous states.

### Authorizer

The authorizer is part of many places in the system. It will always be requested when data is requested. 

## Role of LLMs

The agentic system is the most visible system to our customers. 
If referred to a Knowlestry AI, it will mostly refer to the group of agents 
that work and interact with each other. 
Knowlestry AI is LLM agnostic.
