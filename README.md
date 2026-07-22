# 🌐 GAgent-Skill-p1: Dynamic Agent Mesh via Skill Composition

Welcome to the **GAgent-Skill-p1** repository! This package represents **Part 1** of our Agentic Mesh architecture. It outlines how a local client agent can discover, authenticate, and communicate securely with a remote reasoning engine deployed on Google Cloud Vertex AI Agent Runtime—by composing three modular agent skills.

Unlike Part 2 (which integrates dynamic lookup using a central GCP Agent Registry), **Part 1** focuses on explicit **Skill Composition** to orchestrate JSON-RPC 2.0 A2A protocol payloads and delegate standard Google Cloud permissions.

---

## 📂 Package Directory Structure

```
GAgent-skill-p1/
├── skills/
│   ├── gcp-auth/                 # 🔑 Skill 1: GCP Authentication Skill
│   │   ├── SKILL.md              # Instructions for token generation
│   │   └── references/
│   │       └── gcp-auth-context.md # Shell commands & Python programmatic token helper
│   ├── a2a-protocol/             # 💬 Skill 2: JSON-RPC 2.0 A2A Communication Standard
│   │   ├── SKILL.md              # Payload, session context, and text/data parts instructions
│   │   └── references/
│   │       └── a2a-payload-context.md # Nested JSON payload schemas and httpx dispatcher
│   └── knowledge-catalog/        # 📖 Skill 3: Master Agentic Mesh Composition Skill
│       └── SKILL.md              # Instructions on composing auth & protocol to query backend
├── .gitignore                    # Local files exclusion rules
└── README.md                     # This documentation guide
```

---

## 🧭 The 3 Core Agentic Skills

### 1. `gcp-auth` (GCP Authentication)
Instructs local code generators and AI agents on how to generate dynamic Application Default Credentials (ADC) tokens.
*   **Purpose:** Ensures any API calls targeting remote GCP end-points have an active Bearer Authorization token.
*   **Key Asset:** Provides a pure-python `google-auth` token helper to fetch access credentials without subprocess shell overhead.

### 2. `a2a-protocol` (Agent-to-Agent JSON-RPC 2.0 Standard)
Standardizes multi-agent communication by structuring standard JSON-RPC 2.0 requests over HTTP.
*   **Purpose:** Standardizes parameters like `contextId` (to preserve conversation session histories) and separates user instructions (`TextPart`) from authorization metadata (`DataPart`).
*   **Key Asset:** Includes a complete, copy-pasteable Python implementation to structure and dispatch HTTP POST queries.

### 3. `knowledge-catalog` (Master Usage & Mesh Composition)
The master skill that orchestrates the overall agent-to-agent connection.
*   **Purpose:** Coordinates the composition of `gcp-auth` and `a2a-protocol` to query a remote Reasoning Engine and trigger backend GCP Dataplex/BigQuery tool execution.
*   **Directives:** Teaches the client agent how to map input arguments and prompt intent to standard reasoning engine endpoints.

---

## 📐 Secured Delegate Tool Execution Flow

```
   [ Local Client Agent ]
             │
             ├──► 1. Invokes gcp-auth (Get Access Token)
             ├──► 2. Invokes a2a-protocol (Structure JSON-RPC payload)
             │
             ▼ 3. POST /v1/projects/<PROJECT_ID>/locations/<LOCATION>/reasoningEngines/<ENGINE_ID>:query
   [ Vertex AI Agent Runtime ]
             │
             ▼ 4. Activates Dataplex MCP Client (with delegated Token)
   [ Google Dataplex Catalog ]
```

---

## ⚡ Setup & Local Execution

### Step 1: Install Local Credentials
Configure standard GCP application authorization on your machine:
```bash
gcloud auth login
gcloud auth application-default login
```

### Step 2: Configure Environment Variables
Set your target Google Cloud project environment variables:
```bash
export GOOGLE_CLOUD_PROJECT="<PROJECT_ID>"
```

### Step 3: Run the A2A Dispatcher
Import and execute the dispatcher programmatically, supplying the generated Bearer Token and User metadata to communicate with your live reasoning engine instance in real-time.
