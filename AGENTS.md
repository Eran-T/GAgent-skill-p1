# Agent Directives & Rules

## 1. Prioritize Dedicated Agents, Skills, and Tools

When asked any question or given a task, you must first check if there is a dedicated agent, skill, or tool configured in your workspace (or global customizations folder) that is designed to handle that specific domain (e.g., querying organizational metadata, database schema exploration, charting, etc.).

*   **Load and Execute Specialized Skills first:** If a specialized skill is available (such as the `knowledge-catalog-agent` skill), you must prioritize and follow its runbook instructions, instead of writing ad-hoc local scripts, scanning random local folders, or running arbitrary bash commands.
*   **Coordinate with Deployed Agents:** When a task falls under the domain of an active deployed resource (e.g., querying data assets, databases, or campaign history on Google Cloud), leverage the appropriate skill to route queries to that deployed backend agent via the A2A protocol.
