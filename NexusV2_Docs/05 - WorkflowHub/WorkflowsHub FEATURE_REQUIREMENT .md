# ⚙️ WorkflowsHub - Master Documentation Suite (v2.0)

## Document 1: FEATURE_REQUIREMENT & BUSINESS LOGIC

### 1.1 Executive Summary
The `WorkflowsHub` is the ultimate orchestration engine of the Nexus platform. It abstracts complex business processes into reusable, declarative workflow patterns. It connects AI models, memory extraction, contact notifications, and external API integrations into a coherent execution fabric. It supports autonomous execution, scheduled operations, and human-in-the-loop approval gates.

### 1.2 Workflow Classification & Immutability
1.  **Immutable System Workflows:** Hardcoded, baseline workflows necessary for system survival (e.g., `ContextAssemblyPipeline`, `WeeklyMemoryPruning`, `ContactDataEnrichment`). Users cannot delete these but can modify their schedules or variables.
2.  **Custom Technical Workflows:** User-defined JSON/Code-driven sequences with complex branching, conditions, and API hooks.
3.  **Custom Object Workflows:** UI-driven, drag-and-drop assembled sequences designed for non-technical execution (e.g., "Send Onboarding Email -> Wait 2 days -> Analyze Reply -> Create Task").

### 1.3 Execution Triggers
Workflows can be initiated via multiple vectors:
*   **Manual/On-Demand:** Triggered via the Nexus UI by the user or an Agent.
*   **Scheduled (Time-based):** Utilizing the `SchedulerHub` for Cron-like recurring tasks (e.g., daily summaries).
*   **Event-Driven:** Automatically triggered by internal Nexus events (e.g., `ContactCreated`, `MessageReceived`).
*   **Webhook (External):** Triggered by an incoming HTTP payload from a third-party service.

### 1.4 Step Types (The Building Blocks)
A workflow consists of a sequence of Nodes/Steps:
*   `Action`: Calls another Hub (e.g., `AiModelsHub` for text generation).
*   `Task`: Creates a task in `TasksHub` and assigns it to an Agent or Human.
*   `Decision`: Conditional branching (If X == Y, go to Node A, else Node B).
*   `Parallel`: Forks execution to run multiple steps concurrently.
*   `Wait`: Pauses execution until a specific time or event occurs.
*   `Loop`: Iterates over a collection (e.g., summarizing an array of 10 messages).
*   `Code`: Executes a sandboxed script snippet.
*   `Compensate`: A rollback step executed if a downstream step fails.

### 1.5 Execution Patterns & Human-in-the-Loop
*   **Planner-based Execution:** Agents from the `AgentsHub` can dynamically *generate* a one-off workflow to solve a complex user prompt, effectively coding their own execution path.
*   **Approval Gates (Human-in-the-Loop):** A workflow can hit a "Wait for Approval" step. The workflow is serialized, paused, and sends an interactive notification to `HedraSoul`. Upon Hedra's click (Approve/Deny), the workflow resumes.

---

## Document 2: ARCHITECTURE & BACKEND SPECIFICATION (Laravel 11)

### 2.1 Database Schema (MySQL)
*   **`workflows` Table:**
    *   `id` (UUID, Primary)
    *   `name` (VARCHAR)
    *   `description` (TEXT)
    *   `is_system` (BOOLEAN) - Protects from deletion.
    *   `status` (VARCHAR) - draft, active, archived.
    *   `trigger_config` (JSON) - e.g., type: cron, expression: 0 0 * * *
*   **`workflow_versions` Table:** (For audit and rollback)
    *   `id` (UUID)
    *   `workflow_id` (UUID)
    *   `definition` (JSON) - The actual steps and DAG (Directed Acyclic Graph) structure.
*   **`workflow_executions` Table:**
    *   `id` (UUID)
    *   `workflow_version_id` (UUID)
    *   `trigger_source` (VARCHAR)
    *   `status` (VARCHAR) - pending, running, paused, completed, failed, cancelled.
    *   `runtime_state` (JSON) - Persisted variables and execution context.
*   **`workflow_step_logs` Table:** (Linked to `LogsHub`)
    *   `execution_id` (UUID)
    *   `step_id` (VARCHAR)
    *   `status` (VARCHAR)
    *   `output` (JSON)
    *   `duration_ms` (INT)

### 2.2 Core Service Layer (Strict SRP)
*   **`WorkflowRegistry`:** Validates the JSON schema of a workflow, manages versioning, and feature flags.
*   **`WorkflowInterpreter`:** The core engine. Traverses the DAG, evaluates `Decision` steps, and formats inputs for the `TaskDispatcher`.
*   **`StateManager`:** Handles the serialization and deserialization of the `runtime_state`. Crucial for pausing a workflow (Approval Gate) and resuming it days later without blocking Redis queue workers.
*   **`TaskDispatcher`:** Routes the current step to the respective Hub adapter (e.g., firing a WAHA message, calling the `MemoryHub`).
*   **`ErrorHandler`:** Evaluates `retryable` vs `terminal` failures. Executes `Compensate` (rollback) flows if defined.

### 2.3 API Contract
*   `POST /api/v1/workflows` : Create a workflow.
*   `POST /api/v1/workflows/{id}/execute` : Trigger a workflow manually.
    *   *Payload:* `{ run_mode: "sync|async", input_payload: {} }`
*   `POST /api/v1/workflows/executions/{id}/resume` : Resume a paused workflow (e.g., after human approval).
*   `POST /api/v1/workflows/executions/{id}/cancel` : Abort execution.
*   `GET /api/v1/workflows/executions/{id}` : Get live execution state and history.

---

## Document 3: UI_DESIGN_LAYOUT & FRONTEND UX (Next.js 15)

### 3.1 Hub Layout & Navigation
The `WorkflowsHub` features a sophisticated, full-screen canvas interface.
*   **Sidebar (Left):** Library of Draggable Nodes (Actions, Conditions, Triggers, System Tasks).
*   **Main Area:** The Infinite Canvas (using libraries like React Flow) to drag, drop, and connect `NxWorkflowNode` components.
*   **Sidebar (Right):** Node Configuration Panel (opens when a node is clicked) and the "Live Loader/Tracer" panel.

### 3.2 UI Components
*   **`NxWorkflowNode`:** A visual card on the canvas showing the step icon, name, and connection ports (Input/Output). Changes border color based on status (Gray = Pending, Blue = Running, Green = Success, Red = Failed, Orange = Paused).
*   **`NxExecutionTracer`:** A terminal-like slide-over panel. When a workflow is running asynchronously, it listens to Laravel Reverb WebSockets and prints real-time logs ("Step 1 started... Step 1 done...").
*   **`NxApprovalGateModal`:** A specific modal triggered in `HedraSoul` when a workflow halts, showing the context and "Approve" / "Reject" buttons.

### 3.3 State Management (Zustand: `useWorkflowsStore`)
*   **State:** `workflows`, `activeExecutions`, `canvasNodes`, `canvasEdges`.
*   **Actions:** `fetchWorkflows()`, `saveWorkflow(nodes, edges)`, `executeWorkflow(id)`, `cancelExecution(id)`.

---

## Document 4: INTEGRATION, SECURITY & OPERATIONS

### 4.1 Cross-Hub Orchestration (Dependencies)
*   **TasksHub Dependency:** A workflow step can be "Create Task". The workflow creates the task and goes into `paused` state. Once the task in `TasksHub` is marked as `Completed`, an event wakes up the `StateManager` to resume the workflow.
*   **AIModelsHub Dependency:** Whenever a step requires summarization or generation, the `TaskDispatcher` securely calls the `UniversalAiGatewayService` without leaking API keys to the workflow definition.
*   **LogsHub Integration:** The `WorkflowTracer` emits structured events (`workflow.started`, `step.completed`, `workflow.failed`). The `LogsHub` securely stores these for compliance and debugging.

### 4.2 Error Handling & Resilience Strategies
If a step fails, the `ErrorHandler` takes over:
1.  **Immediate Retry:** Used for network glitches (retry 3 times instantly).
2.  **Delayed Backoff:** Pushed back to the Redis queue to retry after 5, 15, then 60 minutes (useful for rate-limit 429 errors from AI models).
3.  **Compensation (Undo):** If a workflow created a Contact in Step 1, but failed in Step 3, the Compensation logic triggers Step 1's undo method (e.g., Soft Delete the contact) to prevent orphaned data.
4.  **Escalation:** If unrecoverable, the workflow fails, emitting an `Emergency` log to `HedraSoul`.

### 4.3 Governance & Security
*   **PolicyGuard:** Before executing a workflow, `PolicyGuard` checks if the tenant/user has the budget (token limits) and permissions to execute the requested steps.
*   **Infinite Loop Protection:** The engine tracks the execution depth. If a `Loop` step iterates more than the defined maximum (e.g., 1000 times), the workflow is forcefully killed to prevent server crash (OOM).
