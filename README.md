# 🤖 GAgent-Skill-p1: Agent Platform Agent Runtime Deployment & Skill Composition

Welcome to the **GAgent-Skill-p1** repository! This package represents **Part 1** of our Agentic Mesh architecture. It contains both the deployable Python backend agent code and its three associated agentic skills.

This project is built using the **Google Agent Development Kit (ADK)** and is optimized to deploy and run seamlessly on the **Agent Platform Agent Runtime** (formerly Reasoning Engines). 

---

## 📂 Package Directory Structure

```
GAgent-skill-p1/
├── app/                        # 🤖 Deployable Python ADK Agent Code
│   ├── app_utils/              # Tracing, types, and closed requirements
│   │   ├── .requirements.txt   # Locked python container dependencies
│   │   ├── telemetry.py        # Telemetry and logging configuration
│   │   └── typing.py           # Struct models for user feedback
│   ├── agent.py                # Main agent logic (Gemini, Dataplex, and Charting MCPs)
│   └── agent_runtime_app.py    # Official Agent Platform Agent Runtime entrypoint
├── skills/                     # 🧭 The 3 custom, modular Agentic Skills
│   ├── gcp-auth/                 # 🔑 Skill 1: GCP Authentication Skill
│   │   ├── SKILL.md              # Instructions for token generation
│   │   └── references/
│   │       └── gcp-auth-context.md # Shell commands & Python programmatic token helper
│   ├── a2a-protocol/             # 💬 Skill 2: JSON-RPC 2.0 A2A Communication Standard
│   │   ├── SKILL.md              # Payload, session context, and text/data parts instructions
│   │   └── references/
│   │       └── a2a-payload-context.md # Nested JSON payload schemas and httpx dispatcher
│   └── knowledge-catalog-agent/  # 📖 Skill 3: Master Agentic Mesh Composition Skill
│       └── SKILL.md              # Instructions on composing auth & protocol to query backend
├── pyproject.toml              # Project dependencies, build targets, and metadata
├── agents-cli-manifest.yaml    # Unified deployment manifest
├── install_skills.sh           # 🚀 Customization installer script for Antigravity Workspace
├── AGENTS.md                   # Local customization routing guidelines
├── ARCHITECTURE_DIAGRAM.md     # 📐 Complete system architecture & sequence flow charts
├── MEDIUM_ARTICLE.md           # 📰 Deep-dive technical article draft
├── .gitignore                  # Local files exclusion rules
└── README.md                   # This documentation guide
```

---

## 📖 Additional Resources & Documentation

We have provided highly detailed system diagrams, guides, and drafts for team alignment:
*   📐 **[Architecture and Sequence Flows](./ARCHITECTURE_DIAGRAM.md)**: Mermaid charts representing multi-turn queries, session memory persistence, and telemetry pipeline sequences.
*   📰 **[Deep-Dive Technical Article](./MEDIUM_ARTICLE.md)**: A complete ready-to-publish Medium post outlining the business case, development setup, and serverless design advantages.
*   🔑 **[GCP Authentication Skill Specs](./skills/gcp-auth/SKILL.md)**: Inner technical guidelines on credential retrieval.
*   💬 **[A2A Protocol Schema Specs](./skills/a2a-protocol/SKILL.md)**: Schema structures and Python dispatch blueprints.
*   📖 **[Knowledge Catalog Skill Specs](./skills/knowledge-catalog-agent/SKILL.md)**: Runbook rules mapping target resource configurations and semantic schemas.

---

## 🔑 Required Google Cloud IAM Roles

To deploy and execute the agent successfully, ensure the following Identity and Access Management (IAM) configurations are active in your Google Cloud Project:

### 1. For the Deploying Identity (User or CI/CD Service Account)
The identity executing `agents-cli deploy` requires:
*   **`roles/aiplatform.admin`** – To create, update, and manage the Reasoning Engine container deployment.
*   **`roles/storage.objectAdmin`** – To stage package code source files inside the deployment Cloud Storage bucket.
*   **`roles/iam.serviceAccountUser`** – To attach the runtime service account to the deployed container.

### 2. For the Runtime Service Account
The service account assigned to the Agent Platform Agent Runtime container (specified during deploy or fallback to default Compute Engine SA) requires:
*   **`roles/aiplatform.user`** – To access and query Gemini models via Vertex AI GenAI APIs.
*   **`roles/mcp.toolUser`** – **CRITICAL.** Grants authorization to communicate with and execute tools on Google Cloud's managed MCP servers (such as `https://dataplex.googleapis.com/mcp`).
*   **`roles/dataplex.metadataReader`** – To search, view, and list assets inside the Dataplex Knowledge Catalog.
*   **`roles/bigquery.dataEditor`** & **`roles/bigquery.user`** – To write live interaction telemetry data to the BigQuery Analytics tables.
*   **`roles/storage.objectCreator`** – To upload conversation trace logs and OpenTelemetry artifacts to the configured Cloud Storage logging bucket.

---

## ⚡ Setup & Local Development Playground

First, configure your local environment and authenticate with Google Cloud:

```bash
# 1. Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# 2. Install the official Google Agents CLI
uv tool install google-agents-cli
```

### 🧭 Installing Agentic Skills into Antigravity
The custom skills included in this package can be registered into your Antigravity IDE (either locally to this workspace or globally for all projects) using the custom installer:

```bash
# Set script executable and run
chmod +x install_skills.sh
./install_skills.sh
```

### 💻 Running the Local Interactive Playground
Test the entire ADK application, tool triggers, and telemetry hooks interactively on your machine before pushing to production:

```bash
# Install local locked requirements
agents-cli install

# Launch the premium web-based development playground
agents-cli playground
```
This serves a local visual playground where you can directly interact with Gemini 2.5, monitor the execution logs of your connected MCP servers, and view the raw output of schema mappings.

---

## 🚢 Deploying the Agent to Google Cloud

When you're ready to make your agent public, deploy it dynamically to any Google Cloud project and location:

### Command Syntax:
```bash
agents-cli deploy \
  --project=YOUR_PROJECT_ID \
  --region=YOUR_LOCATION \
  --no-confirm-project
```

### What happens during deployment:
1.  **Dependency Gathering:** The CLI packages the `app/` folder and resolves its container requirements from `app/app_utils/.requirements.txt`.
2.  **Compilation & Packaging:** The agent code is packaged and containerized automatically.
3.  **Deployment:** The container is deployed to the **Agent Platform Agent Runtime** in your specified `--region`.
4.  **Retrieval of resource name:** Once successfully deployed, the CLI will output your live Resource URN:
    ```text
    Agent Runtime ID: projects/YOUR_PROJECT_NUMBER/locations/YOUR_LOCATION/reasoningEngines/YOUR_ENGINE_ID
    ```

---

## 🧭 The 3 Core Agentic Skills

### 1. `gcp-auth` (GCP Authentication)
Instructs local code generators and AI agents on how to generate dynamic Application Default Credentials (ADC) tokens.
*   **Purpose:** Ensures any API calls targeting remote GCP endpoints have an active Bearer Authorization token.
*   **Key Asset:** Provides a pure-python `google-auth` token helper to fetch access credentials without subprocess shell overhead.

### 2. `a2a-protocol` (Agent-to-Agent JSON-RPC 2.0 Standard)
Standardizes multi-agent communication by structuring standard JSON-RPC 2.0 requests over HTTP.
*   **Purpose:** Standardizes parameters like `contextId` (to preserve conversation session histories) and separates user instructions (`TextPart`) from authorization metadata (`DataPart`).
*   **Key Asset:** Includes a complete, copy-pasteable Python implementation to structure and dispatch HTTP POST queries.

### 3. `knowledge-catalog-agent` (Master Usage & Mesh Composition)
The master skill that orchestrates the overall agent-to-agent connection.
*   **Purpose:** Coordinates the composition of `gcp-auth` and `a2a-protocol` to query a remote Reasoning Engine and trigger backend GCP Dataplex/BigQuery tool execution.
*   **Directives:** Teaches the client agent how to map input arguments and prompt intent to standard Agent Platform endpoints.

---

## 📐 Secured Delegate Tool Execution Flow

```
   [ Local Client Agent ]
             │
             ├──► 1. Invokes gcp-auth (Get Access Token)
             ├──► 2. Invokes a2a-protocol (Structure JSON-RPC payload)
             │
             ▼ 3. POST /v1/projects/<PROJECT_ID>/locations/<LOCATION>/reasoningEngines/<ENGINE_ID>:query
   [ Agent Platform Agent Runtime ]
             │
             ▼ 4. Activates Dataplex MCP Client (with delegated Token)
   [ Google Dataplex Catalog ]
```
