# 🤖 GAgent-Skill-p1: Agent Platform Agent Runtime Deployment & Client Consumption

Welcome to the **GAgent-Skill-p1** package! This repository represents **Part 1** of our Agentic Mesh architecture. It contains the deployable Python backend agent code, standard configuration manifests, and custom modular customization skills.

This project is built using the **Google Agent Development Kit (ADK)** and is optimized to deploy and run seamlessly on the **Agent Platform Agent Runtime** (formerly Reasoning Engines).

---

## 🎯 The Main Use Case: Consuming Deployed GCP Agents via Agentic Coding Tools

While the `agents-cli` toolchain manages packaging and registering your backend agent container to Google Cloud, the principal use case of this repository is **client-side consumption**. 

By packaging custom customization skills (`gcp-auth`, `a2a-protocol`, `knowledge-catalog-agent`) inside the `.agents/` folder, we equip **local agentic coding tools** (such as IDE assistants, Claude Code, or Antigravity) with the explicit instructions and sequence protocols required to consume and query your deployed GCP agents dynamically:

```
   [ Local IDE Coding Assistant ]
             │
             ├──► 1. Loads local customization skills (.agents/skills/*)
             ├──► 2. Uses gcp-auth to fetch delegated ADC token
             ├──► 3. Uses a2a-protocol to structure JSON-RPC 2.0 payload
             │
             ▼ 4. Sends POST request to deployed Agent Platform URN
   [ Agent Platform Agent Runtime (GCP) ]
             │
             ▼ 5. Runs Dataplex Catalog Search / Charting tool execution
   [ Output Result returned to IDE coding assistant ]
```

This interaction allows a local IDE assistant to acts as a secure, authenticated client that automatically delegates complex metadata queries and analytical tasks to your stateful business agent running securely on GCP.

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
│   ├── a2a-protocol/             # 💬 Skill 2: JSON-RPC 2.0 A2A Communication Standard
│   └── knowledge-catalog-agent/  # 📖 Skill 3: Master Agentic Mesh Composition Skill
├── pyproject.toml              # Project dependencies, build targets, and metadata
├── agents-cli-manifest.yaml    # Unified deployment manifest
├── install_skills.sh           # 🚀 Customization installer script for Antigravity Workspace
├── AGENTS.md                   # Local customization routing guidelines
├── ARCHITECTURE_DIAGRAM.md     # 📐 Complete system architecture & sequence flow charts
├── .gitignore                    # Local files exclusion rules
└── README.md                     # This documentation guide
```

---

## 🛠️ Google `agents-cli` Toolchain Context

The **[`agents-cli`](https://cloud.google.com/vertex-ai/docs)** is the unified CLI manager designed to streamline the lifecycle of ADK-based agents. It bridges local developer playgrounds with enterprise GCP cloud runtimes:

*   **`agents-cli install`**: Gathers and locks third-party python container packages inside `.venv` using Astral `uv`.
*   **`agents-cli playground`**: Launches a premium web UI on your local machine to test prompt responses, view active MCP tool schemas, and trace output JSONs before deploying.
*   **`agents-cli deploy`**: Automatically packages your backend agent, containerizes it, registers it to GCP Artifact Registry, and instantiates your live URN endpoint.

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
*   **`roles/mcp.toolUser`** – **CRITICAL.** Grants authorization to communicate with and execute tools on Google Cloud's managed MCP servers.
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

# Launch the local development playground
agents-cli playground
```

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

## 🔗 Additional References & Documentation

*   🛠️ **[`agents-cli`](https://cloud.google.com/vertex-ai/docs)**: Official developer reference documentation for the Google Agents Command Line Toolchain.
*   📖 **[`agent-registry/google-managed-mcps`](https://cloud.google.com/dataplex/docs)**: Reference architecture and connection guidelines for Google-managed Model Model Model Context Protocol (MCP) servers (e.g., Dataplex Knowledge Catalog).
*   📐 **[Architecture and Sequence Flows](./ARCHITECTURE_DIAGRAM.md)**: Mermaid charts representing multi-turn queries, session memory persistence, and telemetry pipeline sequences.
