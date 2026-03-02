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
Knowlestry AI uses customer data, which can be structured or unstructured.
When delivered to the Knowlestry AI system, the data will be stored in its raw form in a secure, isolated environment.

From there, several agents, known as the Knowledge Hub, will work with it.

Inside the Knowledge Hub, we differentiate between:

1. proto-agents
2. adaptive agents
3. chat agents

## Stakeholders

On onboarding, every organisation needs to create accounts for its employees and define stakeholders for various outcomes. It is recommended to define an "admin stakeholder" who receives requests that the Knowlestry system cannot assign to a specific person. 
The "admin stakeholder" will also define which data a stakeholder can see.

## The Knowledge Hub

### proto-agents

proto-agents are built-in and deterministic, developed by Knowlestry AI.
They may use LLMs for classification and analysis, but operate within
predefined logic and constraints.

There are two different kinds of proto-agents:

1. Data agents
2. Orchestration agents
3. Evaluating agents

Data agents would take the data and try to make sense of it, building semantic units.
These units are first the smallest possible units and will be grouped 
to grow into bigger chunks in a second step, as they see fit.
We call this "schema detection."
Data agent results are usually stored in customer-specific databases.

Orchestration agents are started after the data agent has completed the job.
They try to identify the kind of data that was stored in the databases 
and think about potential agents that make sense for the customer. 
Once they have decided on that, they are orchestrating customized agents based on blueprints, 
the adaptive agents. 

Evaluating agents are investigating whether the adaptive agents are successful.
Evaluation criteria are predefined within the boundaries of adaptive agent templates.
They re-trigger agent generation or ask questions to the customer if they 
find any. Their job is to find problems and unresolved situations. 

proto-agents will run regularly and can decide:

- which agent is refreshed
- when an agent needs to be refreshed
- how often adaptive agents are running

proto-agents also receive notifications from chat agents, creating a continuous feedback loop for customers and allows the system to adjust when new data becomes available dynamically.

proto-agents do not train LLM models.

#### Adaptive agent templates 

Adaptive agent templates are predefined templates of how a new agent can look.
They define clear boundaries within the authorization system, what an agent can do,
and what should be resolved. Templates are:

 - Failure monitoring
 - Trend detection
 - Correlation analysis
 - Predictive forecasting
 - Documentation summarization
 - Efficiency comparison

Templates define agent behavior, data scope, and execution pattern. 
The Knowledge Hub uses LLMs to configure or parameterize these templates, not to generate arbitrary system logic.

Knowlestry AI will introduce new templates through updates.

#### Autonomous agent creation

If a proto-agent can safely decide to create an adaptive agent, it will instantiate the agent.
Safe creations are limited to predefined adaptive agent templates and do not introduce new task categories or system topology.
They include anomaly detection or failure monitoring.

#### Input-led agent creation

If a proto-agent cannot decide whether to create an adaptive agent, it will send a chat message to the admin stakeholder.
The proto-agent will ask questions about the creation of the adaptive agent.
This is the case when the data doesn't make sense or differs significantly.
The admin stakeholder will need to respond to these questions, 
and the replies will be stored in the database.

If necessary, the proto-agent will instantiate a new adaptive agent based on approved adaptive agent templates.

### Adaptive Agents

Adaptive agents are running like cron jobs in the background.
They operate like microservices, working in a sandbox on small, specified tasks.
Adaptive agents execute within a controlled runtime environment managed by the Knowledge Hub.
Based on the decisions of proto-agents, adaptive agents are designed to complete specific tasks.

Tasks can include:

- from a list of tickets, what is important data to write to a manual
- what are the recurring problems of a system
- predicting when an industrial line might fall
- notifying when an industrial system is inefficient compared to another
- predicting the load on helpdesk centers and how efficient the work is

In short, adaptive agents:

- predict (event-driven)
- monitor (event-driven)
- improve (documentation, event-driven)
- notify (event-driven)
- report (regularly)

Adaptive agents are visible within the customer's organization and can be turned on or off.
They can be changed using the chat agents. 

### Chat Agents 

Chat Agents are replying to customer messages. 

They are subject to a very strict authorization system. 
Before they can reply, they need to check with a firewall-like system if they are allowed to respond with the specific data. 

Chat agents can access other chats within the same company if the stakeholders have permission.

Chat agents view and analyse data that adaptive or proto-agents prepared.
Customers can use chat agents to ask proto-agents to change adaptive agents.

## Learning cycle

When new data or user input prompts proto agents to analyse and adapt, it is called a "learning cycle." 
A learning cycle adjusts configurations and instantiates adaptive agents from approved templates. It does not modify the proto-agent logic or create new template categories.

## Role of LLMs

The agentic system is the most visible system to our customers. 
If referred to a Knowlestry AI, it will mostly refer to the group of agents 
that work and interact with each other. 
We may or may not add specific AIs apart from LLMs; however, LLM's are a component, but do not define the architecture.
Knowlestry AI is LLM agnostic.

## Logging / Audits

All adaptive agent instantiations, configuration changes, evaluation outcomes, and learning cycles are logged and versioned.
Admin stakeholders have visibility into these changes and can roll back configurations to previous states.

