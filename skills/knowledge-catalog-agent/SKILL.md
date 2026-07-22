---
name: knowledge-catalog-agent
description: Detailed semantic context, setup instructions, and deployment specifications for the Dataplex Knowledge Catalog & Charting Agent on Agent Platform Agent Runtime.
---

# Dataplex Knowledge Catalog & Charting Agent

This skill defines the semantic context, domain boundaries, capabilities, and setup instructions for the **Knowledge Catalog Agent** running on the **Agent Platform Agent Runtime**.

---

## 1. Active Cloud Target Configuration
These properties should be updated dynamically depending on your active deployment parameters:
*   **Project ID:** `<PROJECT_ID>`
*   **Region:** `<LOCATION>`
*   **Resource Name:** `projects/<PROJECT_NUMBER>/locations/<LOCATION>/reasoningEngines/<ENGINE_ID>`

---

## 2. Required IAM Permissions

For this agent and its tools to execute correctly at runtime, the container's **Runtime Service Account** must hold the following Google Cloud roles:
1.  **`roles/aiplatform.user`** – Grants access to run inferences on Gemini models via Vertex AI GenAI.
2.  **`roles/mcp.toolUser`** – **CRITICAL.** Grants credentials permission to communicate with and invoke tools on Google Cloud's managed MCP servers (e.g. `https://dataplex.googleapis.com/mcp`).
3.  **`roles/dataplex.metadataReader`** & **`roles/dataplex.viewer`** – Enables searching and retrieving metadata assets from the Dataplex Knowledge Catalog.
4.  **`roles/bigquery.dataEditor`** & **`roles/bigquery.user`** – Allows writing interaction and instrumentation metrics to BigQuery tables.
5.  **`roles/storage.objectCreator`** – Allows uploading execution logging artifacts and telemetry payloads to Cloud Storage.

---

## 3. Agent Core Capabilities & Semantic Domain

This agent is integrated with Google Cloud Dataplex (Knowledge Catalog) and a custom Charting service via Model Context Protocol (MCP) toolsets. It serves as your main entry point for:
1.  **Metadata Discovery & Search:** Searching and listing data assets, datasets, databases, and tables across the organization.
2.  **Schema Audits:** Discovering table fields, descriptions, data types, and annotations.
3.  **Visualization & Reporting:** Generating charts, spreadsheets, or visualizations based on catalog and database query results.

### Connected MCP Server Capabilities:
*   **Dataplex Server:** Exposes tools like `search_entries`, `list_data_assets`, and `get_data_asset` to discover assets.
*   **Charting Server:** Exposes tools to generate data visual representations and compile performance sheets.

---

## 4. Expected Interaction Patterns & Queries

When formulating queries for the remote agent, craft them to target the following semantic operations:

*   **Asset Queries:** `"Find any tables or databases matching 'campaign_performance'."`
*   **Schema Audits:** `"List the schema fields and data types for the table 'visdemo.campaign_performance'."`
*   **Integrated Charting:** `"Retrieve the 'forecasting_sticker_sales' campaign data and generate a ROAS performance chart."`

---

## 5. Efficient Execution Blueprint
To query this agent efficiently:
1.  Read this file to understand the **Project details**, **Query patterns**, and **IAM permission configurations** required.
2.  Import the generic execution functions from the **`gcp-agent-client`** skill.
3.  Write and execute a single scratch script containing the Agent Client initialized with the `Resource Name` and `Project ID` defined above.
