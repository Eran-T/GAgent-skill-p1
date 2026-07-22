# ruff: noqa
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import sys
import datetime
import logging
from zoneinfo import ZoneInfo
from typing import Optional, List

import google.auth
import google.auth.transport.requests
from google.cloud import bigquery
from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.models import Gemini
from google.genai import types
from google.adk.tools import McpToolset
from google.adk.tools.mcp_tool import SseConnectionParams, StreamableHTTPConnectionParams

# Initialize environment variables
_, project_id = google.auth.default()
os.environ["GOOGLE_CLOUD_PROJECT"] = project_id
os.environ["GOOGLE_CLOUD_LOCATION"] = "global"
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"


# Helper to dynamically obtain standard GCP auth headers for remote MCP endpoints
def get_mcp_auth_headers(context=None) -> dict[str, str]:
    try:
        credentials, _ = google.auth.default()
        auth_req = google.auth.transport.requests.Request()
        credentials.refresh(auth_req)
        return {"Authorization": f"Bearer {credentials.token}"}
    except Exception as e:
        import traceback
        print("AUTH HEADER GENERATION FAILED:", e)
        traceback.print_exc()
        return {}


# Monkeypatch McpToolset.get_tools to support header provider even when context is None (e.g. at startup)
from google.adk.agents.readonly_context import ReadonlyContext
from google.adk.tools.base_tool import BaseTool
from google.adk.tools.mcp_tool.mcp_tool import MCPTool
import google.adk.tools.mcp_tool.mcp_toolset as mcp_toolset_module

async def patched_get_tools(self, readonly_context: Optional[ReadonlyContext] = None) -> List[BaseTool]:
    headers = self._header_provider(readonly_context) if self._header_provider else None
    session = await self._mcp_session_manager.create_session(headers=headers)
    tools_response = await session.list_tools()
    tools = []
    for tool in tools_response.tools:
        mcp_tool = MCPTool(
            mcp_tool=tool,
            mcp_session_manager=self._mcp_session_manager,
            auth_scheme=self._auth_scheme,
            auth_credential=self._auth_credential,
            require_confirmation=self._require_confirmation,
            header_provider=self._header_provider,
        )
        if self._is_tool_selected(mcp_tool, readonly_context):
            tools.append(mcp_tool)
    return tools

mcp_toolset_module.McpToolset.get_tools = patched_get_tools


# 1. Integrate the Knowledge Catalog MCP server using the global endpoint
mcp_toolset = McpToolset(
    connection_params=StreamableHTTPConnectionParams(
        url="https://dataplex.googleapis.com/mcp"
    ),
    header_provider=get_mcp_auth_headers
)

# 2. Integrate the Chart MCP server using its SSE endpoint and dynamic authentication
chart_toolset = McpToolset(
    connection_params=SseConnectionParams(
        url="https://mcp-server-chart-qjvb6pictq-uc.a.run.app/sse"
    ),
    header_provider=get_mcp_auth_headers
)


# 3. Define the Python ADK Agent using standard Gemini model
root_agent = Agent(
    name="knowledge_catalog_agent",
    model=Gemini(
        model="gemini-2.5-flash",
        retry_options=types.HttpRetryOptions(attempts=3),
    ),
    instruction=(
        "You are a specialized agent integrated with the Google Cloud Dataplex Knowledge Catalog and a Charting Service.\n"
        "Your role is to help users discover, query, and understand data assets, datasets, and metadata, and generate stunning charts, spreadsheets, or visualizations of this data.\n"
        "Always use the available Model Context Protocol (MCP) tools from both the Knowledge Catalog server and the Charting server to retrieve data and generate charts or spreadsheets.\n"
        "Ensure you respect user-scoped contexts and use delegated authentication when querying resources."
    ),
    tools=[mcp_toolset, chart_toolset],
)

# Initialize BigQuery Analytics Plugin for Telemetry
_plugins = []
_project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
_dataset_id = os.environ.get("BQ_ANALYTICS_DATASET_ID", "adk_agent_analytics")
_location = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")

if _project_id:
    try:
        from google.adk.plugins.bigquery_agent_analytics_plugin import (
            BigQueryAgentAnalyticsPlugin,
            BigQueryLoggerConfig,
        )
        bq = bigquery.Client(project=_project_id)
        bq.create_dataset(f"{_project_id}.{_dataset_id}", exists_ok=True)

        _plugins.append(
            BigQueryAgentAnalyticsPlugin(
                project_id=_project_id,
                dataset_id=_dataset_id,
                location=_location,
                config=BigQueryLoggerConfig(
                    gcs_bucket_name=os.environ.get("BQ_ANALYTICS_GCS_BUCKET"),
                    connection_id=os.environ.get("BQ_ANALYTICS_CONNECTION_ID"),
                ),
            )
        )
        logging.info("BigQuery Agent Analytics Telemetry Plugin initialized successfully.")
    except Exception as e:
        logging.warning(f"Failed to initialize BigQuery Analytics Telemetry Plugin: {e}")

app = App(
    root_agent=root_agent,
    name="app",
    plugins=_plugins,
)
