# Hub Implementation Fix And Completion Plan

## Source Document

- `NexusV2_Docs/HUB_IMPLEMENTATION_REVIEW_2026-05-30.md`

## Goal

Fix, correct, and complete the implemented Nexus hubs so they become reliable, testable, API-first, and aligned with the new Nexus principles.

This plan covers:

- AiProviderHub / AIModelsHub
- SettingsHub
- AgentsHub
- WorkflowsHub
- TasksHub
- SchedulerHub
- ProactiveAIHub
- ContactsHub stabilization

## Execution Rules

- Fix backend test infrastructure first.
- Do P0 blockers before adding new hub features.
- Keep each hub's API contract synchronized with frontend usage.
- Do not expose simulated behavior as complete behavior.
- Use hub service boundaries instead of direct cross-hub database writes.
- Route AI work through AiProviderHub / AIModelsHub / AgentsHub.
- Queue and log long-running work.
- Add tests with every fix.

## Phase 0 - Stabilize Test And Runtime Baseline

### Objectives

Make the backend test suite trustworthy enough to validate hub fixes.

### Tasks

- [ ] Review `.env.testing`, `phpunit.xml`, database connection settings, and test database name.
- [ ] Ensure the test database is isolated from development data.
- [ ] Fix migration order and duplicate-table/drop-table issues.
- [ ] Verify `migrations` table creation in tests.
- [ ] Ensure foreign-key constraints do not break refresh/reset.
- [ ] Run targeted smoke tests after reset:
  - [ ] `ContactsHubTest`
  - [ ] `AiProviderTest`
  - [ ] `TaskCrudTest`
  - [ ] `SettingsHubAdminControllerTest`
  - [ ] `AgentsHubTest`
- [ ] Add a small CI-style script or documented command set for hub smoke tests.

### Exit Criteria

- Targeted backend tests start from a clean database.
- Failures represent real application behavior, not database reset corruption.

## Phase 1 - P0 Runtime Crash Fixes

### 1. AgentsHub MCP Pivot Relationship

Problem:

- `Agent::mcpServers()` lets Laravel infer `m_c_p_server_id`.
- Migration uses `mcp_server_id`.

Tasks:

- [ ] Update the relationship to specify pivot keys explicitly.
- [ ] Add a model relationship test.
- [ ] Add an agent show endpoint test that loads MCP servers.

Done when:

- Agent detail no longer throws an unknown-column error.

### 2. AgentsHub Async Job Dispatch

Problem:

- `AgentExecutionService::runAsync()` dispatches `ExecuteAgentTaskJob` with agent ID, input, and trace ID.
- `ExecuteAgentTaskJob` expects an `AgentTask`.

Tasks:

- [ ] Decide whether async execution should create an `AgentTask` first or use a dedicated agent execution job.
- [ ] Update dispatch signature.
- [ ] Persist execution trace ID and input safely.
- [ ] Add async execution test.
- [ ] Add failed-job behavior test.

Done when:

- Async agent execution dispatches and runs without constructor errors.

### 3. TasksHub Logs Endpoint Fatal

Problem:

- `TaskController::logs()` references `$request` without receiving it.
- It references `$this->taskLogService` without injecting it.

Tasks:

- [ ] Inject `TaskLogService`.
- [ ] Add `Request $request` to the method signature.
- [ ] Update `TaskLogService::getLogs()` to read persisted `task_logs`.
- [ ] Add logs endpoint test.

Done when:

- `GET /api/v1/tasks/{task}/logs` returns persisted logs.

### 4. AiProviderHub Auth Placeholder Replacement

Problem:

- Default auth format uses `{key}`.
- Runtime replacement supports only `{KEY}` and `{API_KEY}`.

Tasks:

- [ ] Support `{key}`, `{KEY}`, `{api_key}`, and `{API_KEY}`.
- [ ] Add unit tests for auth header rendering.
- [ ] Re-run `AiProviderTest`.

Done when:

- Provider auth headers render correctly and sync-models no longer fails because of placeholder mismatch.

### 5. Register Missing Event Provider

Problem:

- `EventServiceProvider` exists but is not registered in `bootstrap/providers.php`.

Tasks:

- [ ] Register the event provider or move required event bindings into a registered provider.
- [ ] Verify task, workflow, and broadcast events are booted.
- [ ] Add a test proving task status update dispatches expected behavior.

Done when:

- Model and domain events fire in tests and runtime.

## Phase 2 - TasksHub Contract And Lifecycle Corrections

### Objectives

Make TasksHub consistent across backend, frontend, events, logs, and workflow integrations.

### Backend Tasks

- [ ] Standardize date field on `due_date`.
- [ ] Optionally accept `due_at` as a deprecated alias.
- [ ] Standardize priority contract:
  - [ ] either numeric `0..10`
  - [ ] or enum `low|medium|high|urgent`
- [ ] Standardize status lifecycle.
- [ ] Update controller validation.
- [ ] Update model constants.
- [ ] Update task factories.
- [ ] Update API resources.
- [ ] Import `Illuminate\Validation\ValidationException` where needed.
- [ ] Replace `Route::resource('tasks')` with `Route::apiResource('tasks')` or exclude `create` and `edit`.
- [ ] Fix task status event detection from `isDirty()` to `wasChanged()` after update.
- [ ] Add task transition service if status rules are non-trivial.

### Frontend Tasks

- [ ] Update task API client to send the backend's canonical priority format.
- [ ] Send `due_date`.
- [ ] Use backend update/delete endpoints instead of local-only behavior.
- [ ] Align UI filters with canonical statuses.

### Tests

- [ ] Task create test.
- [ ] Task update test.
- [ ] Task delete test.
- [ ] Task logs test.
- [ ] Task status transition test.
- [ ] Task event dispatch test.
- [ ] Frontend build.

### Exit Criteria

- Task creation works from frontend.
- Task logs persist across request/job boundaries.
- Task events fire.
- Task routes are API-only.

## Phase 3 - AiProviderHub / AIModelsHub Completion

### Objectives

Make AI provider management and generation reliable enough for AgentsHub, WorkflowsHub, ContactHub, and ProactiveAIHub.

### Provider Registry Tasks

- [ ] Fix auth placeholder replacement.
- [ ] Validate provider credentials before auto-sync.
- [ ] Add provider draft/inactive state for missing credentials.
- [ ] Add provider capability metadata:
  - [ ] chat endpoint
  - [ ] model list endpoint
  - [ ] auth style
  - [ ] request mapper
  - [ ] response mapper
  - [ ] streaming support
  - [ ] tool-call support

### Provider Adapter Tasks

- [ ] Add OpenAI-compatible adapter.
- [ ] Add Gemini adapter.
- [ ] Add fallback REST adapter only for explicitly compatible providers.
- [ ] Parse provider-specific errors into a common format.
- [ ] Add retry/backoff for safe transient failures.

### API Tasks

- [ ] Fix sync-models 500 failure.
- [ ] Add health check tests.
- [ ] Add provider sync tests using fake HTTP responses.
- [ ] Add generation tests for OpenAI-compatible and Gemini-compatible payloads.

### Frontend Tasks

- [ ] Show provider state: active, inactive, draft, failing.
- [ ] Show credential-required state.
- [ ] Show sync status and last error.
- [ ] Prevent "ready" UI when provider sync/generation is failing.

### Exit Criteria

- AI provider sync is test-covered.
- Text generation works through at least one OpenAI-compatible provider and Gemini-compatible provider.
- Downstream hubs can rely on a stable AI gateway.

## Phase 4 - AgentsHub Real Execution

### Objectives

Move AgentsHub from simulated paths to reliable real execution with traces, tools, MCP, and async jobs.

### Backend Tasks

- [ ] Fix MCP server relationship.
- [ ] Fix async execution dispatch.
- [ ] Separate simulation, dry-run, and real execution services.
- [ ] Implement real execution through AiModelsHub.
- [ ] Persist:
  - [ ] input
  - [ ] output
  - [ ] trace ID
  - [ ] model/provider
  - [ ] tool calls
  - [ ] MCP calls
  - [ ] token/cost metadata
  - [ ] error details
- [ ] Add timeout handling.
- [ ] Add cancellation support if queue/runtime allows it.
- [ ] Add authorization tests.

### Frontend Tasks

- [ ] Label simulation clearly.
- [ ] Show execution state.
- [ ] Show trace/log details.
- [ ] Show failed execution details.

### Tests

- [ ] Agent show with MCP servers.
- [ ] Agent sync execution with fake provider.
- [ ] Agent async execution.
- [ ] Agent execution failure.
- [ ] Agent trace persistence.

### Exit Criteria

- AgentsHub can execute real AI tasks and provide trustworthy traces to other hubs.

## Phase 5 - WorkflowsHub Completion

### Objectives

Make workflows actually execute across agent, task, action, and wait steps with resumability.

### Backend Tasks

- [ ] Standardize workflow step result contract:
  - [ ] `status`
  - [ ] `output`
  - [ ] `trace_id`
  - [ ] `error`
- [ ] Update agent step dispatcher to return `output`.
- [ ] Update interpreter variable merge logic.
- [ ] Implement task completion resume bridge.
- [ ] Store workflow/task correlation data.
- [ ] On task completion, resume workflow with task output.
- [ ] Replace action-step stubs with real executors or mark unsupported.
- [ ] Keep code-step disabled unless a safe sandbox exists.
- [ ] Derive progress from runtime execution logs.
- [ ] Add pause/resume/cancel behavior tests.

### Frontend Tasks

- [ ] Show unsupported step types as disabled.
- [ ] Show execution progress from runtime logs.
- [ ] Show waiting-for-task state.
- [ ] Link workflow run to created tasks.

### Tests

- [ ] Workflow with agent step.
- [ ] Workflow with task step.
- [ ] Task completes and workflow resumes.
- [ ] Failed step records error.
- [ ] Progress updates during execution.

### Exit Criteria

- A workflow can start, pause on a task, resume on completion, and finish with correct outputs.

## Phase 6 - SettingsHub Safety And Data Shape

### Objectives

Harden SettingsHub so it is safe to use as the configuration backbone for the other hubs.

### Backend Tasks

- [ ] Fix arbitrary API proxy SSRF risk:
  - [ ] block private IPs
  - [ ] block loopback
  - [ ] block link-local
  - [ ] block metadata endpoints
  - [ ] require allowlist where possible
  - [ ] remove broad `withoutVerifying()`
- [ ] Decide and implement one setting value storage pattern:
  - [ ] raw value with explicit casting
  - [ ] or JSON envelope
- [ ] Add tests for string, bool, integer, JSON, and encrypted values.
- [ ] Standardize credential key naming.
- [ ] Add migration/normalizer for existing credential keys if needed.
- [ ] Complete Workspace support or remove workspace references until WorkspaceHub exists.
- [ ] Fix SettingsHub admin tests after test DB stabilization.

### Frontend Tasks

- [ ] Show validation errors from settings update routes.
- [ ] Show credential stored/empty state without leaking values.
- [ ] Hide workspace controls if Workspace support is not complete.

### Tests

- [ ] Setting value cast tests.
- [ ] Credential encryption tests.
- [ ] Proxy SSRF guard tests.
- [ ] Workspace validation tests or removal tests.

### Exit Criteria

- SettingsHub stores values predictably and cannot be used as an unsafe arbitrary network proxy.

## Phase 7 - SchedulerHub Real Execution

### Objectives

Turn SchedulerHub from CRUD plus simulated worker into real scheduled execution.

### Backend Tasks

- [ ] Compute initial `next_run_at` on create/update.
- [ ] Validate cron expression and timezone.
- [ ] Separate schedule status from run status.
- [ ] Add run records/table if not present.
- [ ] Implement executor types:
  - [ ] command
  - [ ] queued job
  - [ ] webhook with SSRF protection
  - [ ] workflow trigger
  - [ ] agent trigger
  - [ ] ContactHub maintenance trigger
- [ ] Persist run duration, output, and errors.
- [ ] Add retry/backoff policy.
- [ ] Add concurrency locks to avoid duplicate runs.

### Frontend Tasks

- [ ] Show next run.
- [ ] Show last run.
- [ ] Show run history.
- [ ] Show failed runs and errors.
- [ ] Disable unsupported schedule types.

### Tests

- [ ] Schedule create computes next run.
- [ ] Due schedule dispatches correct executor.
- [ ] Failed run is recorded.
- [ ] Unsupported type fails clearly.
- [ ] Duplicate worker run does not double-execute.

### Exit Criteria

- SchedulerHub can execute real scheduled work and report results.

## Phase 8 - ProactiveAIHub Real Rule Evaluation

### Objectives

Make proactive rules evaluate real events and execute actions through owned hub contracts.

### Backend Tasks

- [ ] Keep current rule parser as deterministic fallback.
- [ ] Add AI-assisted parsing through AgentsHub/AiModelsHub.
- [ ] Add Arabic and multilingual parsing support through AI path.
- [ ] Define supported triggers:
  - [ ] time
  - [ ] contact message received
  - [ ] contact profile changed
  - [ ] task status changed
  - [ ] workflow event
  - [ ] scheduler event
- [ ] Add event listeners that evaluate matching rules.
- [ ] Execute notify actions through NotificationHub or its service contract.
- [ ] Execute reply actions through ContactHub reply rules and approval safety.
- [ ] Execute workflow actions through WorkflowsHub.
- [ ] Execute task actions through TasksHub.
- [ ] Add approval queue for risky actions.
- [ ] Log every evaluation and action.

### Frontend Tasks

- [ ] Show parser confidence.
- [ ] Show rule trigger/action preview.
- [ ] Show approval-required state.
- [ ] Show evaluation history.
- [ ] Show action run history.

### Tests

- [ ] Rule parser fallback test.
- [ ] AI parser fake-provider test.
- [ ] Contact message event triggers rule test.
- [ ] Notify action uses service contract test.
- [ ] Reply action respects ContactHub reply mode test.
- [ ] Approval-required test.

### Exit Criteria

- ProactiveAIHub can safely react to events and route actions through the correct hubs.

## Phase 9 - ContactsHub Stabilization Before vNext

### Objectives

Prepare ContactsHub for the full implementation plan without breaking current behavior.

### Backend Tasks

- [ ] Keep `ContactsHubTest` green.
- [ ] Add missing field support for vNext card/profile fields.
- [ ] Add import/analysis/memory-maintenance route shells only when backend behavior exists.
- [ ] Replace heuristic-only enrichment labels with clear "basic" status until AI analysis is implemented.
- [ ] Ensure no external memory services are used.

### Frontend Tasks

- [ ] Preserve existing contact tabs.
- [ ] Add disabled states for planned vNext controls if backend is not ready.
- [ ] Avoid showing simulated AI/memory behavior as complete.

### Exit Criteria

- ContactsHub is stable and ready for the dedicated ContactHub implementation plan.

## Phase 10 - Frontend Contract Alignment

### Objectives

Make every hub page call the backend with the correct API shape and show true capability states.

### Tasks

- [ ] Create or consolidate typed API clients for each hub.
- [ ] Remove local-only update/delete behavior where backend endpoints exist.
- [ ] Align route names and payload fields.
- [ ] Add frontend validation matching backend rules.
- [ ] Add loading, empty, error, and permission-disabled states.
- [ ] Add API error display for validation failures.
- [ ] Re-run frontend build after each hub contract change.

### Hub Checks

- [ ] ContactsHub.
- [ ] TasksHub.
- [ ] AgentsHub.
- [ ] WorkflowsHub.
- [ ] SchedulerHub.
- [ ] SettingsHub.
- [ ] AiProviderHub / AIModelsHub.
- [ ] ProactiveAIHub.

### Exit Criteria

- Frontend can perform the documented main workflow for each implemented hub.

## Phase 11 - Documentation And Acceptance

### Documentation Tasks

- [ ] Update hub docs after fixes.
- [ ] Update API route docs.
- [ ] Update frontend capability notes.
- [ ] Mark unsupported or future features clearly.
- [ ] Add troubleshooting notes for queues, Reverb, Horizon, Redis, MySQL, and Pinecone.

### Final Verification Matrix

- [ ] Backend targeted tests pass.
- [ ] Frontend build passes.
- [ ] AiProviderHub can sync and generate.
- [ ] SettingsHub stores and encrypts settings safely.
- [ ] AgentsHub can execute real async and sync tasks.
- [ ] TasksHub CRUD/log/events work.
- [ ] WorkflowsHub can pause and resume through task completion.
- [ ] SchedulerHub executes real work.
- [ ] ProactiveAIHub evaluates event rules and executes actions through hub contracts.
- [ ] ContactsHub baseline remains green.

## Recommended Work Order

1. Stabilize test database.
2. Fix P0 runtime crashes:
   - AgentsHub MCP pivot.
   - AgentsHub async job dispatch.
   - TasksHub logs endpoint.
   - AI provider auth placeholders.
   - Event provider registration.
3. Correct TasksHub frontend/backend contract.
4. Complete AiProviderHub provider adapters.
5. Complete AgentsHub real execution.
6. Complete workflow resume bridge.
7. Harden SettingsHub.
8. Implement SchedulerHub real execution.
9. Implement ProactiveAIHub event/action bridge.
10. Stabilize ContactsHub for vNext.
11. Start full ContactHub implementation plan.

