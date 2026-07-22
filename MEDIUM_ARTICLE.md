# Your IDE Can Now Query Your Entire Data Catalog — Here's the 3-Skill Trick Google Doesn't Advertise

### How I turned a local coding assistant into a secure client for a Gemini-powered Dataplex agent running on Google Cloud — with zero service-account keys.

---

Every AI coding assistant on the market is brilliant at one thing: reasoning over the files in front of it. Ask it about your codebase and it shines. Ask it *"which BigQuery table holds our campaign performance data, and can you chart last quarter's ROAS?"* and it falls apart — because that knowledge doesn't live in your repo. It lives in **Dataplex**, behind IAM, behind an API your assistant has never heard of.

**GAgent-Skill-p1** fixes that. It's a small but opinionated package that does two things at once:

1. **Deploys** a Gemini + Dataplex + Charting agent to Google Cloud's **Agent Platform Agent Runtime** (the service formerly known as Reasoning Engines).
2. **Teaches your local coding assistant** — OpenCode, Claude-compatible tools, Antigravity, whatever you use — how to securely *call* that deployed agent through three modular "skills."

The result: you type a plain-English data question into your IDE, and behind the scenes your assistant authenticates to Google Cloud, formats a JSON-RPC 2.0 message, ships it to a stateful agent on GCP, and streams back a metadata answer *and* a rendered chart.

Let's break down why this architecture is genuinely clever — and how to run it yourself.

---

## The core idea: an "Agentic Mesh"

Most agent tutorials give you a monolith: one model, one prompt, one process. This package embraces a **mesh** instead. There are two agents:

- A **backend agent** (stateful, powerful, permissioned) that lives on GCP and owns the connection to Dataplex and a charting service.
- A **client agent** (your local IDE assistant) that owns *nothing* except the instructions for how to talk to the backend.

```
   [ Local IDE Coding Assistant ]
             │
             ├──► 1. Loads customization skills (.agents/skills/*)
             ├──► 2. Uses gcp-auth to fetch a delegated ADC token
             ├──► 3. Uses a2a-protocol to structure the JSON-RPC 2.0 payload
             │
             ▼ 4. POSTs to the deployed Agent Platform URN
   [ Agent Platform Agent Runtime (GCP) ]
             │
             ▼ 5. Runs Dataplex Catalog search / chart generation
   [ Result streamed back to the IDE assistant ]
```

Why is this better than just giving your local assistant Dataplex credentials directly?

- **Security boundary.** Your laptop never holds a service-account key. It uses a short-lived, delegated OAuth token.
- **Statefulness.** The backend agent remembers conversation context across turns via the managed Session Service. Your local tool stays stateless.
- **Reusability.** *Any* MCP-aware coding tool can consume the same deployed agent. The skills are vendor-neutral.

---

## Part 1: The backend agent (60 lines that do a lot)

The deployable agent is built on the **Google Agent Development Kit (ADK)**. The interesting part isn't the model config — it's how it wires up **two managed MCP (Model Context Protocol) servers** with dynamic authentication.

```python
import google.auth
import google.auth.transport.requests
from google.adk.agents import Agent
from google.adk.models import Gemini
from google.adk.tools import McpToolset
from google.adk.tools.mcp_tool import SseConnectionParams, StreamableHTTPConnectionParams
from google.genai import types


# Dynamically mint a GCP auth header for every remote MCP call.
def get_mcp_auth_headers(context=None) -> dict[str, str]:
    credentials, _ = google.auth.default()
    auth_req = google.auth.transport.requests.Request()
    credentials.refresh(auth_req)
    return {"Authorization": f"Bearer {credentials.token}"}


# 1. Google's managed Dataplex Knowledge Catalog MCP server
mcp_toolset = McpToolset(
    connection_params=StreamableHTTPConnectionParams(
        url="https://dataplex.googleapis.com/mcp"
    ),
    header_provider=get_mcp_auth_headers,
)

# 2. A charting MCP server on Cloud Run (SSE transport)
chart_toolset = McpToolset(
    connection_params=SseConnectionParams(
        url="https://mcp-server-chart-...run.app/sse"
    ),
    header_provider=get_mcp_auth_headers,
)

# 3. The agent itself
root_agent = Agent(
    name="knowledge_catalog_agent",
    model=Gemini(
        model="gemini-2.5-flash",
        retry_options=types.HttpRetryOptions(attempts=3),
    ),
    instruction=(
        "You are a specialized agent integrated with the Google Cloud Dataplex "
        "Knowledge Catalog and a Charting Service. Help users discover, query, "
        "and understand data assets and generate charts of that data. Always use "
        "the available MCP tools and respect user-scoped, delegated authentication."
    ),
    tools=[mcp_toolset, chart_toolset],
)
```

**The takeaway:** `header_provider=get_mcp_auth_headers` is the whole trick. Instead of baking a static key into the container, ADC (Application Default Credentials) mints a fresh bearer token on *every* tool call. No keys on disk, no keys in the image, no keys to rotate.

### Built-in observability, for free

The package also snaps in BigQuery telemetry with a few lines — every model invocation, token count, and tool call gets streamed to a BigQuery dataset:

```python
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin, BigQueryLoggerConfig,
)

plugin = BigQueryAgentAnalyticsPlugin(
    project_id=project_id,
    dataset_id="adk_agent_analytics",
    location="us-central1",
    config=BigQueryLoggerConfig(
        gcs_bucket_name=os.environ.get("BQ_ANALYTICS_GCS_BUCKET"),
    ),
)
```

You get production-grade cost and latency dashboards without instrumenting anything by hand.

---

## Part 2: The three skills (the actual innovation)

A "skill" here is just a `SKILL.md` file with YAML frontmatter that any modern agentic tool can discover and load on demand. Three of them compose into a client:

### 🔑 Skill 1 — `gcp-auth`

Teaches the assistant to fetch a short-lived token, either programmatically or via the CLI:

```bash
gcloud auth print-access-token
```

Or in Python:

```python
import google.auth, google.auth.transport.requests

def get_active_access_token() -> str:
    credentials, _ = google.auth.default()
    credentials.refresh(google.auth.transport.requests.Request())
    return credentials.token
```

### 💬 Skill 2 — `a2a-protocol`

Teaches the assistant to build a JSON-RPC 2.0 `message/send` payload for the Agent-to-Agent (A2A) standard. Crucially — and this is a security detail the package gets *right* — **the bearer token goes only in the HTTP `Authorization` header, never in the request body**, because request bodies get persisted to trace logs.

```python
import httpx

def send_a2a_message(endpoint_url, token, prompt, user_id, session_id=None):
    headers = {
        "Authorization": f"Bearer {token}",   # token lives ONLY here
        "Content-Type": "application/json",
    }

    parts = [{"text": prompt}]
    if user_id:
        # identity travels in the body for memory recall — but never the token
        parts.append({"data": {"user_id": user_id}})

    payload = {
        "jsonrpc": "2.0",
        "id": "msg-unique-abc",
        "method": "message/send",
        "params": {"message": {"role": "user", "parts": parts}},
    }
    if session_id:
        payload["params"]["contextId"] = session_id

    resp = httpx.post(
        endpoint_url,
        json={"class_method": "query", "input": payload},
        headers=headers,
        timeout=60.0,
    )
    return resp.json()
```

The response carries back a `contextId` — persist it and pass it on the next turn to get **stateful, multi-turn conversations** with a backend that remembers what you asked before.

### 📖 Skill 3 — `knowledge-catalog-agent`

The orchestrator. It holds the deployed agent's target config (project, region, resource URN), the required IAM roles, the semantic domain, and the execution blueprint that stitches the other two skills together:

> 1. Load `gcp-auth` to get a token.
> 2. Load `a2a-protocol` to build the payload.
> 3. Send the request to the deployed Resource Name, authenticated with the token.

---

## Part 3: Running it end to end

### Prerequisites
- Python `>=3.11,<3.14`
- [`uv`](https://docs.astral.sh/uv/) (Astral's package manager)
- [`gcloud` CLI](https://cloud.google.com/sdk/docs/install), authenticated

### Authenticate and install the toolchain

```bash
gcloud auth login
gcloud auth application-default login
uv tool install google-agents-cli
```

### Install the skills into your assistant

The installer uses the vendor-neutral `.agents/` convention that OpenCode, Claude-compatible loaders, and Antigravity all understand:

```bash
./install_skills.sh --local     # ./.agents/   (this workspace)
./install_skills.sh --global    # ~/.agents/   (everywhere)
```

### Test locally, then deploy

```bash
# Local interactive playground
agents-cli install
agents-cli playground

# Ship it to Google Cloud
agents-cli deploy \
  --project=YOUR_PROJECT_ID \
  --region=us-central1 \
  --no-confirm-project
```

Deployment returns your live resource URN:

```text
Agent Runtime ID: projects/PROJECT_NUMBER/locations/us-central1/reasoningEngines/ENGINE_ID
```

Drop that URN into the `knowledge-catalog-agent` skill, and your IDE is now a client.

---

## What it feels like in practice

Once installed, you just... ask. The skills fire automatically:

- *"Find any tables or databases matching `campaign_performance`."*
- *"List the schema fields and data types for `visdemo.campaign_performance`."*
- *"Retrieve the `forecasting_sticker_sales` campaign data and generate a ROAS performance chart."*

Behind the scenes for that last one: your assistant grabs a token (`gcp-auth`), builds the JSON-RPC message (`a2a-protocol`), POSTs to the deployed agent, which calls Dataplex's `search_entries` tool, pipes the results into the charting MCP, streams back both a text summary and a `gs://` chart artifact — and logs the whole interaction to BigQuery.

---

## The IAM you actually need

No key files. Just roles on the **runtime service account**:

| Role | Why |
|------|-----|
| `roles/aiplatform.user` | Run Gemini via Vertex AI |
| `roles/mcp.toolUser` | **Critical** — call Google's managed MCP servers |
| `roles/dataplex.metadataReader` | Search the Knowledge Catalog |
| `roles/bigquery.dataEditor` + `roles/bigquery.user` | Write telemetry |
| `roles/storage.objectCreator` | Upload trace/chart artifacts |

---

## Why this pattern matters

We're watching the "agentic mesh" go from buzzword to buildable. The important shift this package demonstrates:

1. **Skills are the new SDK.** Instead of shipping a client library and hoping people integrate it, you ship a `SKILL.md` and *any* capable assistant can consume your service.
2. **Delegated auth beats key management.** ADC token negotiation makes the "no keys on the client" pattern trivial.
3. **The backend stays stateful so the client can stay dumb.** Session state lives in a managed service; your IDE just passes a `contextId`.

If you're building internal data agents on Google Cloud and want your whole team's coding tools to reach them securely, this is a blueprint worth stealing.

---

*The full package — deployable ADK agent, three composable skills, install script, and architecture diagrams — is on [GitHub](https://github.com/Eran-T/GAgent-skill-p1). Built on the [Google Agent Development Kit](https://google.github.io/agents-cli/) and Google Cloud's [managed MCP servers](https://cloud.google.com/blog/products/ai-machine-learning/google-managed-mcp-servers-are-available-for-everyone).*
