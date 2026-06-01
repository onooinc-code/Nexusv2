 
# 🤖 AgentsHub - Master Documentation Suite (v2.0)

## Document 1: FEATURE_REQUIREMENT & BUSINESS LOGIC

### 1.1 Executive Summary
The `AgentsHub` is the central orchestration and lifecycle management center for all autonomous and semi-autonomous AI agents within the Nexus platform. It acts as the "Workforce" layer. While the `AIModelsHub` provides the raw brainpower (the models), the `AgentsHub` provides the **Identity, Skills, Tools, and Context** for these models to execute real-world tasks. 

### 1.2 Agent Archetypes & Classification
Agents are categorized by their operational mode:
1.  **Autonomous Agents:** Operate independently based on triggers (e.g., auto-replying to a contact based on rules).
2.  **Team/Collaborative Agents:** Work in pipelines where Agent A extracts data, and Agent B drafts a response.
3.  **Supervisor Agents:** Monitor the outputs of other agents to ensure quality, tone alignment, and factual accuracy before final execution.

### 1.3 Immutable System Agents (Mandatory Core Rule)
The system requires a set of **Default System Agents** (e.g., `MemoryExtractorAgent`, `IntentAnalyzerAgent`, `ContactReplyAgent`).
*   **Immutability:** These agents CANNOT be deleted by the user, as core Nexus Hubs (MemoryHub, PeopleConnect) rely on them for background processing.
*   **Customizability:** While undeletable, users CAN edit their Personas, attached Tools, and Skills to tune their behavior.

### 4.4 Core Modules (The 4 Pillars of AgentsHub)
1.  **Persona Module:** Manages the system instructions, tone preferences, and character traits of an agent. Users can view, create, and assign Personas.
2.  **Skills Module:** Manages predefined capabilities or "Skill Bundles" (e.g., "Data Summarization", "Code Analysis", "Empathy Drafting").
3.  **Tools Module:** Manages external connectors (APIs, Web search, DB querying). Displays available tools, usage logs, and allows adding new custom tools.
4.  **MCP Servers (Model Context Protocol):** A dedicated interface to monitor, add, edit, and delete MCP servers. This standardizes how agents securely access local or remote file systems, databases, and enterprise APIs.

---

## Document 2: ARCHITECTURE & BACKEND SPECIFICATION (Laravel 11)

### 2.1 Database Schema (MySQL)
*   **`agent_personas` Table:** `{id, name, description, system_prompt, tone_preferences, created_at}`
*   **`agent_skills` Table:** `{id, name, description, capabilities_json, created_at}`
*   **`agent_tools` Table:** `{id, name, description, auth_config, endpoint, created_at}`
*   **`mcp_servers` Table:** `{id, name, type (local/remote), connection_config_json, status, created_at}`
*   **`agents` Table:**
    *   `id` (UUID, Primary)
    *   `name` (VARCHAR)
    *   `owner_id` (UUID, Foreign Key)
    *   `is_system` (BOOLEAN) - Protects from deletion.
    *   `persona_id` (UUID, Foreign Key)
    *   `skills` (JSON) - Array of skill IDs.
    *   `tools` (JSON) - Array of tool IDs.
    *   `status` (VARCHAR) - active, inactive, quarantined.
*   **`agent_runtime_logs` Table:**
    *   `id` (UUID)
    *   `agent_id` (UUID)
    *   `task_id` (UUID)
    *   `trace_id` (UUID)
    *   `step` (VARCHAR)
    *   `input` (JSON)
    *   `output` (JSON)
    *   `duration_ms` (INT)

### 2.2 Core Services & Logic
*   **`AgentsHubService`:** Handles CRUD operations, versioning, and lifecycle hooks (activate/deactivate).
*   **`AgentExecutionService`:** Prepares the agent's sandbox. It fetches credentials from `SettingsHub`, attaches authorized tools, compiles the Persona prompt, and sends the execution request to the `AIModelsHub`.
*   **`MCPIntegrationService`:** Manages connections to MCP servers, enabling agents to dynamically read/write to defined external contexts safely.

### 2.3 Background Jobs & Events
*   **Events:** `agent.registered`, `agent.updated`, `agent.started`, `agent.step.completed`, `agent.completed`, `agent.failed`. (Events are published to an outbox for reliable delivery).
*   **Jobs:** `ExecuteAgentTaskJob`. For asynchronous runs, the job is queued via `WorkflowsHub` routing.

### 2.4 API Contract (Endpoints)
*   `POST /api/v1/agents` : Create/Upsert agent. Supports `X-Idempotency-Key`.
*   `GET /api/v1/agents` : List agents (filters: status, owner, tag).
*   `GET /api/v1/agents/{id}` : Retrieve metadata.
*   `POST /api/v1/agents/{id}/run` : Trigger agent.
    *   *Payload:* `{ input: object, mode: "sync" | "async" }`
    *   *Response:* 200 OK (Sync with result) OR 202 Accepted (Async with `task_id`).
*   `POST /api/v1/agents/{id}/simulate` : Sandbox endpoint with mocked tool responses to test expected actions without affecting production data.
*   `GET /api/v1/agents/{id}/tasks/{task_id}` : Get execution status.
*   `POST /api/v1/agents/{id}/tools` : Attach a tool with specific permissions.
*   `GET/POST/PUT/DELETE /api/v1/agents/mcp-servers` : Manage MCP configurations.

---

## Document 3: UI_DESIGN_LAYOUT & FRONTEND UX (Next.js 15)

### 3.1 Hub Layout & Navigation
The `AgentsHub` uses a multi-tab interface (`NxTabs`) within the main Hub layout.
*   **Tabs:** Agents Registry, Personas, Skills, Tools, MCP Servers, Analytics.

### 3.2 Tab Breakdown & Components
1.  **Agents Registry Tab:**
    *   **UI:** `NxDataGrid` or a grid of `NxAgentCard` components displaying Avatar, Name, Status (Active/Quarantined), and System Badge (if `is_system` is true).
    *   **UX:** Clicking an agent opens a detailed `NxDrawer` to edit its Persona, attach Skills/Tools, or disable it. Deletion is hidden/disabled for System Agents.
2.  **Persona & Skills Tabs:**
    *   **UI:** List views with "Add New" `NxModal`. Inputs include `NxInput` (Name) and large `NxTextArea` for prompt templates and slot variables.
3.  **Tools & MCP Servers Tabs:**
    *   **UI:** Table view showing Server/Tool Name, Status (Connected/Offline), and an `NxActionButton` to view Usage Logs.
    *   **UX:** Adding an MCP Server opens a modal requiring Connection Config (URL, Ports, Auth).
4.  **Simulation & Sandbox (Playground):**
    *   **UI:** A split-screen interface. Left side: Select Agent and inject mock inputs. Right side: `NxChatBubble` interface displaying the agent's thought process, tool invocations, and final output.

### 3.3 State Management (Zustand: `useAgentsStore`)
*   **State:** `agents`, `personas`, `skills`, `tools`, `mcpServers`, `activeTasks`.
*   **Actions:** `fetchAgents()`, `updateAgent(id, data)`, `runAgent(id, payload, mode)`, `simulateAgent(id, payload)`.

---

## Document 4: INTEGRATION, SECURITY & OPERATIONS

### 4.1 Hub Inter-Dependencies
*   **AIModelsHub Integration:** Agents do NOT execute LLM calls directly. They compile their Persona, Tools, and Inputs, and send them to the `UniversalAiGatewayService` in the `AIModelsHub`.
*   **SettingsHub Integration:** All API keys required by Agent Tools are fetched securely from the `SettingsHub` vault at runtime.
*   **LogsHub Integration:** Every step of an agent's reasoning (Trace ID, Step, Input, Output, Duration) is pushed to the `LogsHub` for complete auditability.
*   **WorkflowsHub Integration:** Asynchronous agent runs create a task in the queue managed by the `WorkflowsHub`.

### 4.2 Security & Operational Controls
*   **The Kill-Switch:** An emergency endpoint (`POST /api/v1/agents/{id}/quarantine`) that instantly halts a misbehaving agent, rejecting all its queued jobs and cutting off its tool access.
*   **Rate-Limiting:** Agent runs are rate-limited per-owner to prevent runaway loops and token exhaustion.
*   **Cost Estimation:** Before a sync run, the UI optionally queries the `AIModelsHub` for an estimated cost based on the Agent's configured model and historical token usage.
*   **Human Handoff (Escalation):** If an agent detects a failure or a high-risk intent it cannot resolve, it emits an `agent.failed` event with an `escalation` flag, notifying the user via the `HedraSoul` hub.
 