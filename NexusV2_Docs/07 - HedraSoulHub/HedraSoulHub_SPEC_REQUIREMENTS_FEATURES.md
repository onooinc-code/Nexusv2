# HedraSoulHub Specification, Requirements, and Feature Set

## Source Documents Reviewed

- `NexusV2_Docs/CONVERSATION_SYSTEM_ARCHITECTURE.md`
- `NexusV2_Docs/NexusConnectHub.md`
- `NexusV2_Docs/SYSTEM_ARCHITECTURE.md`
- `NexusV2_Docs/API_DESIGN.md`
- `NexusV2_Docs/EVENT_ARCHITECTURE.md`
- `NexusV2_Docs/PROJECT_VISION.md`
- `NexusV2_Docs/02 - AIModelsHub/01 - AIModelsHub.md`
- `NexusV2_Docs/03 - AgentsHub/AgentsHub.md`
- `NexusV2_Docs/04 -TasksHub/TaskHub.md`
- `NexusV2_Docs/05 - WorkflowHub/WorkflowsHub FEATURE_REQUIREMENT .md`
- `NexusV2_Docs/06 - ContactHub/ContactHub_SPEC_REQUIREMENTS_FEATURES.md`
- `Nexus-backend/Docs/First_Version_Docs/09-CONVERSATION_INTERFACE.md`
- `Nexus-backend/Docs/First_Version_Docs/04-DATA_FLOW.md`
- `Nexus-backend/Docs/First_Version_Docs/03-BUSINESS_RULES.md`
- User notes from the latest HedraSoul / PeopleConnect brief.

## Purpose

HedraSoulHub is the private communication, command, oversight, and personality-management hub between Hedra and Souly.

It must become a standalone first-class hub, not a dashboard widget and not a sub-area of NexusConnect. Its job is to give Hedra a dedicated place to:

- Talk privately with Souly.
- Mention contacts, tasks, workflows, memories, and system objects.
- Ask Souly to execute work.
- Approve or reject risky work.
- Monitor task, agent, workflow, memory, and system activity.
- Edit Souly's system instructions, persona, model, tools, and safety mode.
- Manage Hedra's own profile, clone sources, memories, facts, and preferences.
- Receive system notifications, escalations, approvals, and emergency alerts.

HedraSoulHub is the human-in-the-loop control room for Nexus.

## Core Principles

- HedraSoulHub is private. It is for Hedra and Souly only.
- HedraSoulHub is not PeopleConnect. It does not manage external contact conversations as its primary surface.
- HedraSoulHub can mention contacts and open contact context, but ContactHub remains the source of truth for contacts.
- HedraSoulHub can execute tasks and workflows, but TasksHub and WorkflowsHub own execution lifecycle.
- HedraSoulHub can configure Souly, but AgentsHub owns agent definitions and AiModelsHub owns model routing.
- HedraSoulHub can inspect and manage memory, but MemoryHub-ready internal storage remains the memory authority.
- No external memory services are allowed. Use MySQL, Redis, Pinecone, and the future MemoryHub.
- Long-running actions must be queued, logged, observable, and cancelable where possible.
- Risky or irreversible actions require explicit approval.
- Every AI action must include traceability: prompt source, model, agent, context, tools, result, confidence, and logs.

## Hub Boundary

### HedraSoulHub Owns

- Private Hedra <-> Souly conversation sessions.
- Souly command center UI.
- Approval inbox for agent/workflow/task actions.
- System notifications and escalation presentation.
- Hedra profile editor.
- Hedra clone source management.
- Souly instruction and behavior-control interface.
- Private context snapshots assembled for HedraSoul conversations.
- HedraSoul-specific conversation analytics.
- User-facing audit for Souly decisions and actions.

### HedraSoulHub Does Not Own

- Contact profile canonical data. Owned by ContactHub.
- External contact conversations. Owned by PeopleConnectHub and ContactHub message records.
- Agent registry, tools, skills, personas. Owned by AgentsHub.
- AI provider/model registry. Owned by AiModelsHub.
- Durable task state. Owned by TasksHub.
- Workflow definitions and executions. Owned by WorkflowsHub.
- System settings vault. Owned by SettingsHub.
- Notifications delivery infrastructure. Owned by NotificationHub / LogsHub as available.

## Key Concepts

### Hedra

The primary human user and final authority for approvals, identity, privacy, personality, and autonomous behavior.

### Souly

The private AI companion/operator representing Hedra inside Nexus. Souly can chat, reason, draft, summarize, plan, trigger tasks, monitor systems, and ask for approval.

### HedraSoul Session

A private session between Hedra and Souly. Unlike PeopleConnect, this is not tied to an external contact conversation. It may reference contacts, memories, tasks, workflows, or system events.

### Command

An instruction from Hedra that may produce one of several outcomes:

- Direct answer.
- Draft.
- Task creation.
- Workflow execution.
- Memory update.
- Contact mention/update request.
- System setting change request.
- Approval request.

### Mention

A structured reference inside a HedraSoul message to a Nexus object:

- `@contact`
- `@task`
- `@workflow`
- `@agent`
- `@memory`
- `@provider`
- `@conversation`
- `@setting`
- `@schedule`

Mentions must resolve to safe object references and must not cause hidden data access without permission.

### Approval Gate

A human-in-the-loop checkpoint requiring Hedra to approve, reject, edit, defer, or escalate an action.

### Hedra Clone Profile

The structured set of sources, facts, memories, writing samples, values, preferences, voice, boundaries, and style rules used to make Souly consistent with Hedra.

### Souly System Instruction

The versioned instruction set that controls Souly's behavior, boundaries, tone, autonomy, and tool usage.

## Functional Requirements

### 1. Private Hedra <-> Souly Conversation

HedraSoulHub must provide a dedicated private chat surface for Hedra and Souly.

Required features:

- One default active private conversation stream.
- Optional named sessions for projects, planning, debugging, memory review, and system operations.
- Session search.
- Session archive/restore.
- Message threading.
- Rich markdown rendering.
- Code blocks.
- File and attachment references.
- Mentions for contacts, tasks, workflows, agents, settings, memories, and providers.
- Streaming response state.
- Regenerate response.
- Edit and resend before committing downstream actions.
- Context preview before execution.
- Prompt and model trace viewer.
- Message-level intent, topic, tone, and sentiment metadata.
- Conversation summaries.
- Token and cost metadata.

### 2. Command Parsing And Action Routing

Souly must understand whether a message is a question, command, draft request, memory update, contact action, task request, workflow request, or system-control request.

Command outcomes:

- Answer only.
- Create draft.
- Create task.
- Execute agent.
- Start workflow.
- Schedule work.
- Open approval request.
- Update Hedra profile.
- Suggest memory update.
- Suggest setting change.
- Notify Hedra of system state.

Routing requirements:

- Low-risk read-only actions can execute directly.
- Medium-risk write actions should show a preview.
- High-risk actions require approval.
- External outgoing messages require approval unless the active autonomy policy permits them.
- System-wide setting changes require explicit confirmation.
- Irreversible privacy actions require danger-zone confirmation.

### 3. Mention System

HedraSoulHub must support object mentions in the composer.

Mention types:

- Contacts from ContactHub.
- Conversations from PeopleConnectHub.
- Tasks from TasksHub.
- Workflows from WorkflowsHub.
- Agents from AgentsHub.
- Memories from MemoryHub-ready internal memory.
- AI providers/models from AiModelsHub.
- Schedules from SchedulerHub.
- Logs/events from LogsHub.
- Settings from SettingsHub.

Mention requirements:

- Searchable autocomplete.
- Keyboard navigation.
- Permission-aware results.
- Object preview card.
- Resolved object ID stored in message metadata.
- Mentioned context visible in context preview.
- Ability to remove a mention from prompt context.
- Audit when a sensitive object is injected.

### 4. Souly Control Surface

HedraSoulHub must provide direct controls for Souly.

Controls:

- Change active AI model or model strategy.
- Change Souly system instruction version.
- Change active persona profile.
- Change autonomy mode.
- Change tool permissions.
- Toggle memory access.
- Toggle contact access.
- Toggle task execution access.
- Toggle workflow execution access.
- Toggle external messaging permissions.
- Quarantine Souly.
- Pause all autonomous actions.
- Reset active context.
- Run simulation/dry-run.

Autonomy modes:

- `chat_only`: Souly answers but cannot take actions.
- `copilot`: Souly drafts and suggests actions but waits for approval.
- `operator`: Souly can execute approved low-risk tasks.
- `autopilot_limited`: Souly can execute pre-approved workflows under policy limits.
- `emergency_paused`: all autonomous execution is blocked.

### 5. System Instruction Management

HedraSoulHub must expose a safe editor for Souly instructions.

Requirements:

- Versioned instruction records.
- Draft, active, archived states.
- Diff viewer between versions.
- Rollback.
- Test prompt sandbox.
- Model compatibility notes.
- Safety validation before activation.
- Linked change reason.
- Audit log.
- Approval required when instruction changes expand autonomy.

Instruction sections:

- Identity.
- Values.
- Tone.
- Boundaries.
- Tool-use policy.
- Contact-reply policy.
- Privacy policy.
- Approval policy.
- Memory-use policy.
- Emergency behavior.

### 6. AI Model And Routing Controls

HedraSoulHub must allow Hedra to select or override the model used by Souly without bypassing AiModelsHub.

Requirements:

- Show active model instance.
- Show routing profile: fast, quality, budget, Arabic, balanced.
- Allow per-session override.
- Allow per-command override.
- Show estimated cost before expensive actions.
- Show provider health.
- Show fallback chain used.
- Record model and provider on every response.
- Never store provider keys in HedraSoulHub.

### 7. Hedra Clone Source Management

HedraSoulHub must manage sources used to shape the Hedra clone profile.

Source types:

- Direct facts.
- Personal notes.
- Writing samples.
- Past messages.
- Voice/tone examples.
- Values and principles.
- Work preferences.
- Boundaries.
- Decision examples.
- Approved replies.
- Rejected replies and corrections.
- Documents.
- Imported memories.

Source requirements:

- Add/edit/archive/delete sources.
- Source confidence.
- Source type.
- Source sensitivity.
- Source freshness.
- Source provenance.
- Source usage scope:
  - private HedraSoul only
  - PeopleConnect replies
  - task execution
  - workflow planning
  - memory analysis
- Source validation status.
- Conflict detection.
- Version history.

### 8. Hedra Facts And Memories

HedraSoulHub must allow adding and managing memories, facts, details, and information about Hedra.

Memory types:

- Working memory.
- Episodic memory.
- Semantic memory.
- Structured memory.
- Graph memory.
- Preference memory.
- Tone/style memory.
- Decision memory.
- Boundary memory.
- Correction memory.

Requirements:

- Create memory manually.
- Suggest memory from conversation.
- Review pending memory.
- Approve/reject memory.
- Edit memory.
- Version memory.
- Mark memory as sensitive.
- Mark memory as private-only.
- Recalculate confidence.
- Link memory to evidence.
- Search memories.
- Rebuild embeddings.
- Prune stale memories.
- Resolve conflicts.
- Export Hedra memory.
- Erase selected memory.

### 9. Task Monitoring And Execution

HedraSoulHub must be able to create, monitor, approve, and inspect tasks.

Task features:

- Create task from chat command.
- Mention a task.
- Attach context to task.
- Assign task to agent.
- Assign task to Hedra.
- Monitor live task state.
- Show task logs inline.
- Show agent trace.
- Retry failed task.
- Cancel task.
- Approve blocked task.
- Convert message to task.
- Convert task result back into chat summary.

Task state visibility:

- Todo.
- In progress.
- Blocked.
- Waiting approval.
- Completed.
- Failed.
- Cancelled.

### 10. Workflow Approval And Monitoring

HedraSoulHub must be the approval surface for workflows that pause for human decision.

Approval modal requirements:

- Workflow name.
- Trigger source.
- Current step.
- Requested action.
- Inputs.
- Expected side effects.
- Risk level.
- Cost estimate.
- Context used.
- Agent reasoning summary.
- Approve.
- Reject.
- Edit and approve.
- Defer.
- Open full workflow.
- View logs.

Workflow monitoring:

- Live execution timeline.
- Step status.
- Variables snapshot.
- Waiting-for-approval state.
- Failure alerts.
- Compensation actions.

### 11. System Notifications And Escalations

HedraSoulHub must receive and organize system notifications.

Notification types:

- Agent failure.
- Workflow approval request.
- Task blocked.
- Provider outage.
- WAHA disconnected.
- Message send failure.
- Memory conflict.
- Contact identity conflict.
- Scheduler failure.
- Security warning.
- Autopilot safety block.
- Cost anomaly.
- System health alert.

Notification requirements:

- Priority levels.
- Read/unread.
- Snooze.
- Dismiss.
- Convert to task.
- Open related object.
- Action buttons.
- Realtime updates.
- Audit trail.

### 12. Context Preview And Inspection

Before Souly answers or acts, Hedra must be able to inspect what context was assembled.

Context preview includes:

- System instruction version.
- Active persona.
- Active model.
- Session summary.
- Last messages.
- Mentioned objects.
- Injected memories.
- Hedra profile facts.
- Contact facts if mentioned.
- Rules.
- Tool permissions.
- Token estimate.
- Risk classification.

Requirements:

- Open preview from message header.
- Open preview before executing a command.
- Copy/debug context for admins.
- Hide sensitive values by default.
- Show why each context item was included.
- Remove optional context items before sending.

### 13. Memory Inspection And Maintenance

HedraSoulHub must include a memory inspection area focused on Hedra/Souly memory.

Operations:

- Review recently extracted memories.
- Review pending memories.
- Review conflicts.
- Search memories.
- Recompute embeddings.
- Rebuild Hedra profile context.
- Prune stale memory.
- Mark memory private.
- Mark memory allowed for PeopleConnect.
- Rollback memory version.
- Export memory.
- Erase memory.

### 14. Souly Decision And Reasoning Trace

Every meaningful Souly action must be inspectable.

Trace fields:

- Trace ID.
- User message.
- Parsed intent.
- Selected action.
- Model/provider.
- Agent/persona.
- System instruction version.
- Context snapshot ID.
- Tools invoked.
- Tasks/workflows created.
- Approval decision.
- Final output.
- Cost.
- Duration.
- Errors.

### 15. Private Conversation Analytics

HedraSoulHub analytics:

- Total private sessions.
- Task commands created from chat.
- Approval requests by status.
- Souly response latency.
- Model usage and cost.
- Memory updates accepted/rejected.
- Most-mentioned contacts/tasks/workflows.
- Autonomy mode changes.
- System notifications by severity.
- Failed actions and retries.

## Shared Conversation Core Requirements

HedraSoulHub and PeopleConnectHub should use a shared conversation architecture while applying different ownership rules.

### Conversation Structure

For PeopleConnect, every contact has one canonical conversation. For HedraSoul, Hedra has one default private Souly conversation plus optional named private sessions.

Shared entities:

- Conversation.
- Session.
- Message.
- Topic.
- Message analysis.
- Context snapshot.
- Delivery state.
- Processing log.

### Session Rules

- A session is a time-bounded segment inside a conversation.
- A session auto-closes when two hours pass after the last message.
- A new session opens when the next message arrives after closure.
- Sessions can also be manually archived or renamed.
- Session boundaries must be visible in the UI.

### Message Metadata

Each message should support:

- Sender type: `user`, `agent`, `contact`, `system`.
- Sender ID.
- Channel.
- Topic.
- Intent.
- Tone.
- Sentiment analysis.
- Emotional baseline snapshot.
- Context snapshot ID.
- Agent/model metadata.
- Delivery status.
- Token/cost metadata.
- Attachments.
- Mentions.
- Source payload metadata where applicable.

### Message Processing Pipeline

1. Ingest message.
2. Resolve conversation and active session.
3. Save message with pending/received state.
4. Analyze topic, intent, tone, and sentiment.
5. Assemble context from memories, rules, profile, and mentions.
6. Route to AgentsHub/AiModelsHub if AI response or action is needed.
7. Extract suggested memories and facts.
8. Create tasks/workflows/approvals if needed.
9. Persist response.
10. Broadcast updates through Reverb.
11. Log to LogsHub.

## UI Requirements

### Layout

HedraSoulHub should feel like a private operations cockpit rather than a generic chat page.

Recommended layout:

- Topbar: Souly status, model selector, autonomy mode, system health, notifications, emergency pause.
- Left pane: private sessions, approvals, pinned objects, recent commands.
- Center pane: Hedra <-> Souly conversation.
- Right pane: context, memories, task/workflow monitor, trace viewer.

### Topbar

Topbar controls:

- Souly online/offline/thinking/paused status.
- Active model and routing profile.
- Autonomy mode segmented control.
- System instruction version selector.
- Notification bell with severity count.
- Approval inbox count.
- Running tasks count.
- Failed actions count.
- Emergency pause button.

### Header For Active Session

Header contents:

- Session title.
- Current topic.
- Latest intent.
- Latest tone.
- Latest sentiment.
- Message count.
- Task count.
- Mention count.
- Running background log.
- Agent response state.
- Open context button.
- Open memories button.
- Open tasks button.
- Open approvals button.
- Open trace button.

### Message Panel

Requirements:

- Auto-scroll to latest message.
- Date separators.
- Session separators.
- Distinct colors for user, agent, and system messages.
- Toolbar under each message:
  - intent
  - topic
  - tone
  - sentiment
  - model
  - cost
  - trace
  - create task
  - save memory
  - mention object
  - copy
  - retry/regenerate
- Support streaming responses.
- Support pending action previews.
- Show approvals inline.

### Composer

Composer requirements:

- Text input.
- Rich markdown.
- Attachments.
- Mention autocomplete.
- Slash commands.
- Model override.
- Autonomy hint.
- Schedule command.
- Run as dry-run.
- Preview context before send.
- Create task directly.
- Start workflow directly.

Slash command examples:

- `/task`
- `/workflow`
- `/memory`
- `/remember`
- `/forget`
- `/model`
- `/persona`
- `/instruction`
- `/approve`
- `/pause`
- `/summarize`
- `/inspect-context`

## Backend Modules

Recommended services:

- `HedraSoulSessionService`
- `HedraSoulMessageService`
- `SoulyCommandRouter`
- `SoulyContextAssembler`
- `SoulyPromptBuilder`
- `SoulyInstructionVersionService`
- `SoulyModelControlService`
- `HedraCloneProfileService`
- `HedraMemoryService`
- `HedraMemoryMaintenanceService`
- `ApprovalInboxService`
- `SoulyActionPolicyService`
- `SoulyTraceService`
- `HedraSoulNotificationService`

Recommended jobs:

- `ProcessHedraSoulMessageJob`
- `AnalyzeHedraSoulMessageJob`
- `ExecuteSoulyCommandJob`
- `CreateHedraMemorySuggestionJob`
- `RebuildHedraCloneProfileJob`
- `RecomputeHedraMemoryEmbeddingsJob`
- `DispatchApprovalReminderJob`

Recommended events:

- `hedrasoul.message.created`
- `hedrasoul.message.processed`
- `hedrasoul.command.detected`
- `hedrasoul.command.executed`
- `hedrasoul.approval.requested`
- `hedrasoul.approval.approved`
- `hedrasoul.approval.rejected`
- `hedrasoul.instruction.changed`
- `hedrasoul.model.changed`
- `hedrasoul.memory.suggested`
- `hedrasoul.memory.approved`
- `hedrasoul.autonomy.changed`
- `hedrasoul.notification.created`

## Data Model Requirements

Recommended tables:

- `hedrasoul_sessions`
- `hedrasoul_messages`
- `hedrasoul_message_mentions`
- `hedrasoul_context_snapshots`
- `souly_instruction_versions`
- `souly_runtime_profiles`
- `souly_action_policies`
- `hedra_clone_sources`
- `hedra_profile_facts`
- `hedra_memory_suggestions`
- `hedra_memory_versions`
- `hedrasoul_approval_requests`
- `hedrasoul_notifications`
- `souly_action_traces`

Important fields:

- `trace_id`
- `context_snapshot_id`
- `agent_id`
- `model_instance_id`
- `instruction_version_id`
- `risk_level`
- `approval_status`
- `source_object_type`
- `source_object_id`
- `confidence`
- `evidence`
- `sensitivity`
- `visibility_scope`

## API Requirements

Base prefix:

- `/api/v1/hedrasoul`

Sessions and messages:

- `GET /api/v1/hedrasoul/sessions`
- `POST /api/v1/hedrasoul/sessions`
- `GET /api/v1/hedrasoul/sessions/{session}`
- `PATCH /api/v1/hedrasoul/sessions/{session}`
- `POST /api/v1/hedrasoul/sessions/{session}/archive`
- `GET /api/v1/hedrasoul/sessions/{session}/messages`
- `POST /api/v1/hedrasoul/sessions/{session}/messages`
- `POST /api/v1/hedrasoul/messages/{message}/regenerate`
- `GET /api/v1/hedrasoul/messages/{message}/trace`
- `GET /api/v1/hedrasoul/messages/{message}/context`

Souly control:

- `GET /api/v1/hedrasoul/souly/status`
- `PATCH /api/v1/hedrasoul/souly/autonomy`
- `PATCH /api/v1/hedrasoul/souly/model`
- `POST /api/v1/hedrasoul/souly/quarantine`
- `POST /api/v1/hedrasoul/souly/resume`
- `POST /api/v1/hedrasoul/souly/simulate`

Instructions:

- `GET /api/v1/hedrasoul/instructions`
- `POST /api/v1/hedrasoul/instructions`
- `GET /api/v1/hedrasoul/instructions/{version}`
- `PATCH /api/v1/hedrasoul/instructions/{version}`
- `POST /api/v1/hedrasoul/instructions/{version}/activate`
- `POST /api/v1/hedrasoul/instructions/{version}/rollback`
- `POST /api/v1/hedrasoul/instructions/{version}/test`

Hedra clone and memories:

- `GET /api/v1/hedrasoul/profile`
- `PATCH /api/v1/hedrasoul/profile`
- `GET /api/v1/hedrasoul/clone-sources`
- `POST /api/v1/hedrasoul/clone-sources`
- `PATCH /api/v1/hedrasoul/clone-sources/{source}`
- `DELETE /api/v1/hedrasoul/clone-sources/{source}`
- `GET /api/v1/hedrasoul/memories`
- `POST /api/v1/hedrasoul/memories`
- `PATCH /api/v1/hedrasoul/memories/{memory}`
- `POST /api/v1/hedrasoul/memories/{memory}/approve`
- `POST /api/v1/hedrasoul/memories/{memory}/reject`
- `POST /api/v1/hedrasoul/memory-maintenance`

Approvals and notifications:

- `GET /api/v1/hedrasoul/approvals`
- `GET /api/v1/hedrasoul/approvals/{approval}`
- `POST /api/v1/hedrasoul/approvals/{approval}/approve`
- `POST /api/v1/hedrasoul/approvals/{approval}/reject`
- `POST /api/v1/hedrasoul/approvals/{approval}/defer`
- `GET /api/v1/hedrasoul/notifications`
- `POST /api/v1/hedrasoul/notifications/{notification}/read`
- `POST /api/v1/hedrasoul/notifications/{notification}/snooze`

Mentions and search:

- `GET /api/v1/hedrasoul/mentions/search`
- `POST /api/v1/hedrasoul/context/preview`
- `GET /api/v1/hedrasoul/search`

Analytics:

- `GET /api/v1/hedrasoul/analytics`
- `GET /api/v1/hedrasoul/usage`

## Integration Requirements

### AgentsHub

- Souly must be represented as a protected system agent or agent profile.
- HedraSoulHub can select and configure Souly through AgentsHub APIs.
- Souly commands execute through AgentsHub.
- Execution traces link back to HedraSoul messages.

### AiModelsHub

- Every model call goes through AiModelsHub.
- Model selection, provider health, fallback, cost, and usage are recorded.
- HedraSoulHub never stores provider credentials.

### TasksHub

- Commands can create tasks.
- Tasks can request approval through HedraSoulHub.
- Task state and logs are visible in HedraSoulHub.

### WorkflowsHub

- Workflows can be triggered from HedraSoulHub.
- Approval gates appear in HedraSoulHub.
- Failed workflows escalate to HedraSoulHub.

### ContactHub

- Mentions can inject contact context.
- HedraSoulHub can open Contact360.
- Contact memory writes must go through ContactHub/MemoryHub ownership.

### PeopleConnectHub

- HedraSoulHub can open a PeopleConnect conversation by mention.
- Souly can draft contact replies, but PeopleConnectHub owns external delivery.
- Approval requirements must respect PeopleConnect reply modes.

### SettingsHub

- Souly default model, autonomy policies, system instruction defaults, and notification rules are configurable.
- Dangerous settings changes require confirmation.

### SchedulerHub

- HedraSoulHub can schedule commands, summaries, reviews, and reminders.

### LogsHub

- All command, approval, instruction, model, memory, and system notification actions are logged.

## Security And Safety Requirements

- RBAC or owner-only access.
- Sensitive context redaction.
- PII masking in logs.
- Encrypted sensitive fields.
- Approval gates for risky actions.
- Emergency pause.
- Agent quarantine.
- Tool permission boundaries.
- No hidden external sends.
- No silent system instruction change.
- No direct provider key exposure.
- No direct cross-hub database writes.

Risk classification:

- `read`: can usually execute directly.
- `draft`: can produce output but not send.
- `write_low`: can save local non-sensitive state after preview.
- `write_medium`: requires approval or active operator policy.
- `external_send`: requires approval unless policy explicitly allows.
- `danger`: always requires confirmation and audit.

## Acceptance Criteria

HedraSoulHub is complete when:

- It exists as a standalone hub in navigation and API.
- Hedra can chat privately with Souly.
- Messages persist with session, topic, intent, tone, and sentiment metadata.
- The hub supports mentions for contacts, tasks, workflows, agents, memories, settings, and providers.
- Hedra can preview assembled context.
- Souly can create tasks and workflow approval requests through hub contracts.
- Hedra can approve/reject/defer actions from an approval inbox.
- Hedra can edit Souly system instructions with versioning and rollback.
- Hedra can change Souly model/routing profile through AiModelsHub.
- Hedra can manage clone sources, facts, memories, and memory suggestions.
- Running tasks, workflows, and agent actions are visible with logs.
- System notifications and escalations appear in realtime.
- Emergency pause and Souly quarantine work.
- All AI calls go through AgentsHub/AiModelsHub.
- No external memory service is used.
- Backend feature tests cover the main flows.
- Frontend build passes and the UI reflects true capability state.

