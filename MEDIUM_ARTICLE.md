# Building Enterprise-Grade, Telemetry-Observed AI Agents with Google ADK and Agent Platform Agent Runtime

*How to orchestrate Google Cloud Dataplex catalogs, charting microservices, and stateful multi-turn session memory with robust, out-of-the-box BigQuery observability.*

---

## The Shift from Chatbots to Autonomous Enterprise Agents

We are moving past the era of generic, stateless LLM wrapper chatbots. In enterprise software development, modern GenAI systems must act as **autonomous agents**: they must be capable of discovering real-world schemas, querying metadata in real-time, executing visual analysis on the fly, maintaining context across multi-turn user conversations, and operating with robust telemetry under the hood.

Deploying these systems at scale, however, historically meant writing messy, custom container layers to handle routing, authentication, and state. 

Google’s new **Agent Development Kit (ADK)** and **Agent Platform Agent Runtime** have completely rewritten this paradigm. By providing a clean, modular framework, developers can scaffold, test, and deploy telemetry-observed, stateful agents onto Google Cloud's managed serverless runtime in minutes.

In this article, we’ll build a production-grade, stateful AI Agent integrated with **Google Dataplex Knowledge Catalog** and an **SSE Charting Service** via **Model Context Protocol (MCP)**, with real-time observability powered by **BigQuery**.

---

## The Architecture Layout

Our system consists of three main blocks operating under a secure, delegated credential chain:

1.  **The Client Layer (Agy / REST):** Dispatches standard JSON-RPC queries to our deployed Agent Runtime endpoint.
2.  **The Core Agent (google-adk):** A serverless Python container running on the Agent Platform. It coordinates model invocations, tool choices, and streams telemetry.
3.  **Model Context Protocol (MCP) Servers:** Standardized external tooling. The agent queries Google's Dataplex Catalog to discover database tables and contacts a secure, remote SSE server to draw high-performance charts.

```
       [ Client / Agy CLI ]
               │
               ▼ (v1/...:streamQuery)
   [ Agent Platform Agent Runtime (ADK) ] ──(Otel Stream)──► [ BigQuery Analytics ]
       │                      │
       ├─► [ Dataplex MCP ]   └─► [ Charting SSE MCP ]
       ▼                      ▼
  (Metadata Lookup)       (Chart Rendering)
```

---

## Core Feature 1: The Unified ADK App Setup

Standardizing on the `google-adk` framework means your agent logic is written using a clean, declarative class layout rather than ad-hoc server wrappers.

Here is how our core agent is initialized in Python, loading our two distinct MCP tools:

```python
import os
from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.models import Gemini
from google.adk.plugins import BigQueryAgentAnalyticsPlugin

# 1. Initialize our standard Gemini 2.5 Flash model
gemini_model = Gemini(
    model="gemini-2.5-flash"
)

# 2. Configure the BigQuery Observability Telemetry Plugin
telemetry_plugin = BigQueryAgentAnalyticsPlugin(
    dataset_id="adk_agent_analytics",
    table_id="invocation_logs"
)

# 3. Instantiate the unified ADK App loading our plugins and MCP tools
app = App(
    agents=[
        Agent(
            name="knowledge_catalog_agent",
            instructions=(
                "You are an elite business analyst. Your mission is to query "
                "the Dataplex catalog to locate relevant marketing campaign datasets, "
                "analyze campaign performance, and generate beautiful, high-quality "
                "visual performance charts using your charting MCP tool."
            ),
            model=gemini_model,
            mcp_servers=[
                "https://dataplex.googleapis.com/mcp",
                "https://mcp-server-chart-qjvb6pictq-uc.a.run.app/sse"
            ]
        )
    ],
    plugins=[telemetry_plugin]
)
```

---

## Core Feature 2: BigQuery Telemetry for Real-Time Observability

Production-level deployments require tracking exact costs, performance latency, and safety boundaries. By registering the `BigQueryAgentAnalyticsPlugin` directly into our `App`, every LLM invocation, tool activation, token usage count, and execution latency metric is intercepted and streamed directly into BigQuery.

Analytics dashboards can immediately query this data to display critical insights:
```sql
SELECT 
  timestamp,
  invocation_id,
  prompt_token_count,
  candidates_token_count,
  total_token_count
FROM `<PROJECT_ID>.adk_agent_analytics.invocation_logs`
ORDER BY timestamp DESC
LIMIT 10;
```

---

## Core Feature 3: Stateful Multi-Turn Session Memory

One of the most complex challenges in serverless architectures is keeping track of user thread context. Rather than loading the server container with state, our ADK agent delegates session persistence to the managed **Agent Platform Session Service**.

This enables a highly elegant **stateful execution flow**:

### Turn 1: Initialization
1.  The user sends an initial message without specifying a session ID.
2.  The container detects the omission and creates a secure session resource.
3.  The agent resolves the user's prompt by querying Dataplex and generating a campaign chart.
4.  The response returns a fresh `session_id` (e.g., `<SESSION_ID>`).

### Turn 2: Conversational Follow-up
1.  The user sends a follow-up query, specifying the `session_id` from Turn 1:
    ```json
    {
      "class_method": "query",
      "input": {
        "message": "Explain the ROAS calculation you used.",
        "user_id": "<USER_EMAIL>",
        "session_id": "<SESSION_ID>"
      }
    }
    ```
2.  The agent engine pulls the Turn 1 conversation thread from the database automatically.
3.  Gemini uses the previous context to deliver a perfect, contextual explanation of the campaigns identified in Turn 1, ensuring zero loss of state.

---

## Step-by-Step Walkthrough to Deploy the Package

### Step 1: Install the Google Agents CLI
First, install the unified `agents-cli` manager:
```bash
uv tool install google-agents-cli
```

### Step 2: Local Testing via Playground
Before committing to cloud deployments, run an interactive web sandbox environment locally:
```bash
agents-cli install
agents-cli playground
```
This launches a premium, local developer UI to test user prompts, view tool calls in real-time, and trace output schemas.

### Step 3: Serverless Deployment to Agent Runtime
When you're ready to deploy, run the deployment compiler command:
```bash
agents-cli deploy \
  --project=<PROJECT_ID> \
  --region=<LOCATION> \
  --no-confirm-project
```

Under the hood, `agents-cli` packages your directory dependencies from `pyproject.toml`, builds a secure Docker image, pushes it to your Artifact Registry, and creates a unified **Agent Platform Agent Runtime** resource:
```
✅ Deployment successful!
Agent Runtime ID: projects/<PROJECT_NUMBER>/locations/<LOCATION>/reasoningEngines/<ENGINE_ID>
```

---

## Conclusion: The Future of Serverless Enterprise Intelligence

By standardizing on **Google ADK** and **Agent Platform Agent Runtime**, enterprise engineering teams can stop worrying about boilerplate backend layers and focus purely on what matters: **building intelligent, secure, and observable agents**. 

With unified MCP tools, stateful session memory tracking, and BigQuery analytics running out-of-the-box, deploying reliable AI agents has never been more straightforward or production-ready.
