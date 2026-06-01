# PeopleConnectHub Specification, Requirements, and Feature Set

## Source Documents Reviewed

- `NexusV2_Docs/CONVERSATION_SYSTEM_ARCHITECTURE.md`
- `NexusV2_Docs/NexusConnectHub.md`
- `NexusV2_Docs/SYSTEM_ARCHITECTURE.md`
- `NexusV2_Docs/API_DESIGN.md`
- `NexusV2_Docs/EVENT_ARCHITECTURE.md`
- `NexusV2_Docs/PROJECT_VISION.md`
- `NexusV2_Docs/01 - SettingsHub/01 - SettingsHub FEATURE_REQUIREMENT.md`
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

PeopleConnectHub is the standalone communication hub for external contacts.

It replaces the idea of PeopleConnect as only a dashboard tab or NexusConnect subsection. It is the operational center for:

- WhatsApp/WAHA live message synchronization.
- Contact conversations.
- Manual replies from Hedra.
- AI-drafted replies.
- Agent-sent replies when policy allows.
- Message delivery tracking.
- Contact-specific rules, notes, context, memories, and tasks.
- Conversation analysis: topic, intent, tone, sentiment, emotional baseline, and tone mirroring.

PeopleConnectHub must read from and write to the Nexus database as the source of truth. The frontend must not depend on direct WAHA reads for normal operation.

## Core Principles

- PeopleConnectHub is its own first-class hub.
- The database is the source of truth for contacts, conversations, sessions, messages, and delivery state.
- WAHA is an integration provider, not the source of truth for UI state.
- WAHA data must be synchronized by both webhooks and scheduled reconciliation jobs.
- ContactHub owns contact identity and Contact360 profile data.
- PeopleConnectHub owns operational external conversation state and delivery workflows.
- AI replies must go through AgentsHub and AiModelsHub.
- Reply modes must be explicit: manual, copilot, autopilot.
- Contact-specific reply settings override global PeopleConnect settings.
- Long-running sync, import, analysis, and send operations must run through queues.
- All important operations must be logged and broadcast in realtime.
- No external memory services are allowed.

## Hub Boundary

### PeopleConnectHub Owns

- External contact conversation UI.
- Conversation/session/message operational records.
- WhatsApp/WAHA live sync orchestration.
- Outgoing message queue and delivery status.
- Incoming message processing state.
- Conversation header analytics.
- Message filters and search.
- Conversation-specific logs.
- Agent reply status per conversation.
- Manual/copilot/autopilot reply surface.

### PeopleConnectHub Does Not Own

- Canonical contact identity. Owned by ContactHub.
- Deep contact profile intelligence. Owned by ContactHub, with PeopleConnect contributing message evidence.
- AI provider/model registry. Owned by AiModelsHub.
- Agent definitions and tools. Owned by AgentsHub.
- Durable tasks. Owned by TasksHub.
- Workflows. Owned by WorkflowsHub.
- System credential vault. Owned by SettingsHub.
- Global logs/audit storage. Owned by LogsHub.

## Key Concepts

### Contact Conversation

Every contact has one canonical PeopleConnect conversation. This conversation is divided by dates and sessions.

### Session

A session is a time-bounded segment inside a contact conversation.

Rules:

- A session auto-closes when two hours pass after the last message.
- A new session opens when the next message arrives after closure.
- Session boundaries must be visible in the message panel.
- Sessions are used for summarization, analysis, task linking, and context assembly.

### Message

A message belongs to a session and has metadata about sender, source, delivery, topic, intent, tone, sentiment, and AI context.

Sender types:

- `user`: Hedra/manual user.
- `contact`: external contact.
- `agent`: AI agent/Souly/automation.
- `system`: system event or status line.

### LiveMsgs

LiveMsgs is the WAHA synchronization and delivery subsystem inside PeopleConnectHub.

Responsibilities:

- Detect and save new WhatsApp contacts.
- Detect and save new WhatsApp conversations.
- Detect and save new WhatsApp messages.
- Update delivery/read acknowledgements.
- Maintain pending outgoing messages.
- Reconcile missed webhooks through scheduled polling.
- Broadcast changes to the UI in realtime.

### Reply Mode

Reply behavior can be global or contact-specific.

Modes:

- `manual`: Hedra writes/sends manually.
- `copilot`: agents draft replies for Hedra approval.
- `autopilot`: agents can send replies if rules, confidence, and safety checks pass.

Contact-specific settings override the global default.

## Functional Requirements

### 1. Standalone Hub Shell

PeopleConnectHub must be available as a standalone route and navigation item.

Required areas:

- Topbar.
- Conversation sidebar.
- Dynamic conversation header.
- Message panel.
- Composer.
- Right/context drawer or modals.
- LiveMsgs modal.
- Queue/progress indicators.

### 2. LiveMsgs Management

PeopleConnectHub must include a LiveMsgs modal and status system.

Topbar LiveMsgs button:

- Opens LiveMsgs modal.
- Shows WAHA connection status light.
- Shows sync state:
  - connected
  - disconnected
  - syncing
  - degraded
  - error
- Shows last sync time.
- Shows webhook health.
- Shows scheduled polling health.

LiveMsgs modal sections:

- WAHA connection state.
- Active WAHA session.
- Last webhook received.
- Last scheduled sync.
- New contacts found.
- New conversations found.
- New messages found.
- Pending outgoing queue.
- Failed sends.
- Failed imports.
- Manual sync now.
- Reconcile gaps.
- Retry failed sends.
- View raw provider event.
- Diagnostics.

### 3. WAHA Synchronization

PeopleConnectHub must save any new WhatsApp contacts, conversations, sessions, and messages into the database immediately.

Synchronization methods:

1. Scheduled polling:
   - Runs every hour by default.
   - Checks WAHA API for new contacts.
   - Checks WAHA API for new conversations.
   - Checks WAHA API for new messages.
   - Inserts any missing records into the database.
   - Reconciles ack/delivery states.

2. Webhook ingestion:
   - WAHA sends message, ack, contact, and state events.
   - Backend validates the webhook.
   - Backend normalizes payloads.
   - Backend writes records to the database.
   - Backend dispatches processing jobs.
   - Backend broadcasts UI updates.

Required sync flow:

1. Receive or fetch WAHA contact/message data.
2. Extract `whatsapp_id` and WhatsApp number.
3. Search ContactHub/contact identifiers.
4. If contact does not exist, create a new contact.
5. If no name is available, use the WhatsApp number as display name.
6. Ensure the contact has one canonical PeopleConnect conversation.
7. Ensure an open session exists; if last message is older than two hours, close old session and open a new one.
8. Insert the message into the session.
9. Dedupe by WAHA message ID and message hash.
10. Analyze message metadata asynchronously.
11. Broadcast contact/conversation/message changes.

### 4. Database As Source Of Truth

The PeopleConnect UI must load conversations, messages, statuses, and counters from the Nexus database.

Rules:

- Frontend never calls WAHA directly for normal state.
- WAHA provider state is shown through backend health/sync APIs.
- Outgoing messages are saved first, then sent by queue worker.
- Incoming messages are saved first, then analyzed and routed.
- Realtime UI updates come from database-backed events.

### 5. Topbar Requirements

Topbar must include:

- LiveMsgs button with WAHA status light.
- Global reply mode segmented control:
  - Manual
  - Copilot
  - Autopilot
- Note that the global mode applies only when the contact has no custom override.
- Pending outgoing messages button/counter.
- Pending outgoing status color:
  - none
  - queued
  - sending
  - failed
  - delayed
- Incoming save indicator showing new messages/conversations being persisted.
- Search entry point.
- Filters entry point.
- Queue health.
- Sync now.
- Settings shortcut.

Topbar stats:

- Active conversations.
- Unread conversations.
- New messages saving.
- Pending outgoing messages.
- Failed sends.
- WAHA status.
- Agent replies active.
- Autopilot contacts count.

### 6. Conversation Sidebar

The sidebar lists contact conversations.

Each item must show:

- Contact name or phone fallback.
- WhatsApp number.
- Last message time.
- Last message preview.
- Unread badge.
- Channel icon.
- Reply mode indicator.
- Agent status indicator.
- Failed delivery indicator where applicable.
- Pinned/VIP indicator.

Sidebar features:

- Search by name, number, message, tag.
- Filter by unread.
- Filter by reply mode.
- Filter by channel.
- Filter by failed sends.
- Filter by agent active.
- Sort by last activity.
- Sort by priority.
- Group by channel/status/date.

### 7. Dynamic Conversation Header

The header changes based on the selected conversation.

Required header fields:

- Current topic.
- Latest intent.
- Latest emotional baseline.
- Latest tone mirroring.
- Latest sentiment analysis.
- Message count.
- Topic count.
- Animated/log ticker showing background processing for this conversation.
- Current agent reply status.
- Contact reply mode.
- WAHA delivery state.

Required header actions:

- Open contact profile.
- Open contact rules modal.
- Open contact notes modal.
- Open last assembled context modal.
- Open extracted memories modal.
- Open contact tasks modal.
- Search messages.
- Filter by tag.
- Filter by intent.
- Filter by emotional baseline.
- Filter by tone mirroring.
- Filter by sentiment analysis.
- Searchable topic dropdown.
- Jump to first message for selected topic.
- Date filter.

### 8. Message Panel

The message panel must improve the current conversation UI.

Requirements:

- Auto-scroll to latest message.
- Virtualized list for long conversations.
- Date separators before the first message of each date.
- Date separators after the final message of each date where visually useful.
- Session separators.
- Distinct color/style by sender type:
  - user
  - contact
  - agent
  - system
- Delivery status per outgoing message.
- Retry failed message.
- Show edited/deleted markers where applicable.
- Attachment rendering.
- WhatsApp formatting support.
- Message grouping by sender/time.
- Thread/reply references where supported.

Message toolbar:

- Intent.
- Topic.
- Tone.
- Sentiment.
- Emotional baseline snapshot.
- Tone mirroring note.
- Tags.
- Extracted memory count.
- Linked tasks.
- Context snapshot.
- Raw provider payload for admin/debug.
- Copy.
- Reply.
- Forward/draft.
- Create task.
- Add note.
- Save memory.

### 9. Composer And Sending

Composer requirements:

- Send as Hedra.
- Ask agent to draft.
- Send approved agent draft.
- Schedule send.
- Attach files.
- Use templates/macros.
- Insert contact variables.
- Show active reply mode.
- Show whether message will be manual, copilot, or autopilot.
- Warn if WAHA disconnected.
- Save draft if send fails.

Outgoing flow:

1. Hedra or agent creates outbound message.
2. Message is saved to database with `pending` or `queued` status.
3. `DispatchWahaMessageJob` sends through WAHA.
4. WAHA result updates message status.
5. Reverb broadcasts status update.
6. Failure creates retryable error and optional task/notification.

### 10. Agent Reply Modes

PeopleConnectHub must support agent replies while preserving human control.

Global mode:

- Manual.
- Copilot.
- Autopilot.

Contact override:

- If set, contact override wins.
- UI must show override clearly.
- Contact override can be edited from header or ContactHub profile.

Copilot requirements:

- Agent drafts reply.
- Hedra can edit.
- Hedra approves send.
- Draft stores context and trace.

Autopilot requirements:

- Only works when enabled globally or for contact.
- Must respect contact rules.
- Must respect quiet hours.
- Must respect max replies per contact.
- Must respect confidence threshold.
- Must block sensitive topics unless approved.
- Must block if contact identity confidence is low.
- Must block if memory is stale/conflicted.
- Must log every generated and sent reply.

### 11. Contact Rules Modal

Rules modal must show and manage rules for the selected contact.

Features:

- List active rules.
- Add rule.
- Edit rule.
- Delete/deactivate rule.
- Show source/evidence.
- Show AI-suggested rules awaiting approval.
- Show conflicts.
- Show audit history.

Rule examples:

- Never discuss pricing.
- Reply only during working hours.
- Always use Arabic.
- Keep replies short.
- Require approval for financial topics.
- Never send automatically.

### 12. Contact Notes Modal

Notes modal must show and manage notes for the selected contact.

Features:

- List notes.
- Add note.
- Edit note.
- Delete/archive note.
- Pin note.
- Convert message to note.
- Link note to message/session/topic.
- Mark sensitive.
- Suggest memory from note.

### 13. Context Modal

Context modal shows the last context assembled for AI reply or analysis.

Must include:

- Contact profile snapshot.
- Contact rules.
- Contact notes.
- Recent messages.
- Session summary.
- Topic summary.
- Relevant memories.
- Emotional baseline.
- Tone mirroring.
- Intent.
- Model/agent selected.
- Token estimate.
- Excluded context.
- Reason each context item was included.

### 14. Memories Modal

Memories modal shows memories extracted or used for the selected contact/conversation.

Features:

- Recently extracted memories.
- Memories injected into the latest prompt.
- Suggested memories awaiting approval.
- Conflicting memories.
- Memory confidence.
- Evidence messages.
- Approve/reject/edit memory.
- Open ContactHub memory maintenance.

### 15. Tasks Modal

Tasks modal shows tasks linked to the selected contact and conversation.

Features:

- Open tasks.
- Recently completed tasks.
- Failed tasks.
- Agent tasks.
- Follow-up tasks.
- Create task from conversation.
- Attach message/session/context to task.
- Open task logs.

### 16. Topic, Intent, Tone, And Sentiment Analysis

PeopleConnectHub must analyze message and conversation metadata.

Message-level analysis:

- Topic.
- Intent.
- Tone.
- Sentiment.
- Language.
- Urgency.
- Safety flags.
- Reply-needed flag.

Conversation-level analysis:

- Current topic.
- Topic history.
- Topic drift.
- Latest intent.
- Emotional baseline.
- Tone mirroring.
- Sentiment trend.
- Conversation summary.
- Open loops.
- Commitments.
- Follow-up suggestions.

### 17. Search And Filters

Search requirements:

- Full-text message search.
- Contact name/number search.
- Topic search.
- Tag search.
- Intent search.
- Date range.
- Sender type.
- Delivery status.
- Sentiment.
- Tone.
- Emotional baseline.
- Reply mode.
- Has task.
- Has extracted memory.

Topic dropdown:

- Searchable.
- Shows topic name, count, first date, latest date.
- Selecting topic jumps to the first message for that topic.
- Option to filter to that topic only.

### 18. Contact Profile Integration

PeopleConnectHub must integrate tightly with ContactHub.

Required actions:

- Open Contact360 profile.
- Display contact summary in header/right panel.
- Use ContactHub identifiers to resolve contacts.
- Write message evidence for ContactHub analysis.
- Respect contact reply mode override.
- Respect contact rules.
- Create ContactHub notes/memories through ContactHub APIs.
- Surface contact conflicts.

### 19. Background Processing Log

Each conversation should show a live log ticker or drawer for background processing.

Log events:

- Message saved.
- Session opened/closed.
- Intent analyzed.
- Topic detected.
- Context assembled.
- Agent drafting.
- Draft ready.
- Message queued.
- Message sent.
- Delivery ack received.
- Memory extracted.
- Task created.
- Rule blocked.
- Autopilot blocked.
- Error/retry.

## Shared Conversation Core Requirements

The same conversation architecture is used by PeopleConnectHub, ContactProfile views, and HedraSoulHub with different ownership rules.

### Canonical Contact Conversation

- Every contact has one canonical PeopleConnect conversation.
- That conversation is divided by dates.
- That conversation contains sessions.
- Sessions contain messages.
- ContactProfile can display the conversation, but PeopleConnectHub owns operational message handling.

### Session Lifecycle

- Open session exists while conversation is active.
- If two hours pass after the last message, the current session closes automatically.
- The next message opens a new session.
- Session boundaries must be visible in message panels.
- Sessions can be summarized independently.

### Message Metadata

Every message supports:

- Sender type: `user`, `contact`, `agent`, `system`.
- Topic.
- Intent.
- Tone.
- Sentiment analysis.
- Emotional baseline snapshot.
- Tone mirroring snapshot.
- Tags.
- Delivery status.
- WAHA message ID.
- Source payload hash.
- Context snapshot ID.
- Agent/model trace ID.
- Attachments.
- Created at.
- Edited/deleted markers.

### Ingestion Pipeline

1. WAHA webhook or scheduled sync receives message/contact/conversation data.
2. Payload is validated and normalized.
3. Contact is resolved by WhatsApp ID and number.
4. Contact is created if missing.
5. One canonical conversation is resolved or created.
6. Open session is resolved or created.
7. Message is deduped and inserted.
8. Analysis job extracts topic, intent, tone, sentiment, and reply-needed state.
9. Routing policy decides manual/copilot/autopilot handling.
10. AI response/draft uses AgentsHub/AiModelsHub.
11. Message and status updates broadcast through Reverb.
12. LogsHub records trace/audit events.

## Backend Modules

Recommended services:

- `PeopleConnectConversationService`
- `PeopleConnectSessionService`
- `PeopleConnectMessageService`
- `LiveMsgsSyncService`
- `WahaWebhookIngestionService`
- `WahaPollingReconciliationService`
- `WahaMessageDispatcher`
- `PeopleConnectContactResolver`
- `PeopleConnectReplyModeService`
- `PeopleConnectContextAssembler`
- `PeopleConnectAnalysisService`
- `PeopleConnectAgentReplyService`
- `PeopleConnectSearchService`
- `PeopleConnectRealtimeBroadcaster`

Recommended jobs:

- `SyncWahaContactsJob`
- `SyncWahaConversationsJob`
- `SyncWahaMessagesJob`
- `ProcessWahaWebhookJob`
- `AnalyzePeopleConnectMessageJob`
- `AssemblePeopleConnectContextJob`
- `GenerateContactReplyDraftJob`
- `DispatchWahaMessageJob`
- `ReconcileWahaDeliveryStatusJob`
- `CloseInactivePeopleConnectSessionsJob`

Recommended events:

- `peopleconnect.contact.synced`
- `peopleconnect.conversation.created`
- `peopleconnect.session.opened`
- `peopleconnect.session.closed`
- `peopleconnect.message.received`
- `peopleconnect.message.saved`
- `peopleconnect.message.analyzed`
- `peopleconnect.reply.draft.created`
- `peopleconnect.message.queued`
- `peopleconnect.message.sent`
- `peopleconnect.message.delivered`
- `peopleconnect.message.read`
- `peopleconnect.message.failed`
- `peopleconnect.waha.connected`
- `peopleconnect.waha.disconnected`
- `peopleconnect.livemsgs.sync.started`
- `peopleconnect.livemsgs.sync.completed`
- `peopleconnect.autopilot.blocked`

## Data Model Requirements

Recommended tables:

- `peopleconnect_conversations`
- `peopleconnect_sessions`
- `peopleconnect_messages`
- `peopleconnect_message_analyses`
- `peopleconnect_message_tags`
- `peopleconnect_context_snapshots`
- `peopleconnect_reply_drafts`
- `peopleconnect_delivery_attempts`
- `peopleconnect_sync_runs`
- `peopleconnect_raw_provider_events`
- `peopleconnect_processing_logs`
- `peopleconnect_conversation_topics`
- `peopleconnect_reply_mode_overrides`

Core conversation fields:

- `id`
- `contact_id`
- `channel`
- `provider`
- `provider_conversation_id`
- `status`
- `last_message_at`
- `last_message_preview`
- `unread_count`
- `reply_mode_effective`
- `agent_status`

Core message fields:

- `id`
- `conversation_id`
- `session_id`
- `contact_id`
- `sender_type`
- `sender_id`
- `direction`
- `body`
- `body_format`
- `status`
- `provider`
- `waha_message_id`
- `provider_payload_hash`
- `topic_id`
- `intent`
- `tone`
- `sentiment`
- `emotional_baseline_snapshot`
- `tone_mirroring_snapshot`
- `context_snapshot_id`
- `trace_id`
- `sent_at`
- `delivered_at`
- `read_at`
- `failed_at`
- `error_message`

## API Requirements

Base prefix:

- `/api/v1/peopleconnect`

Conversations:

- `GET /api/v1/peopleconnect/conversations`
- `GET /api/v1/peopleconnect/conversations/{conversation}`
- `PATCH /api/v1/peopleconnect/conversations/{conversation}`
- `GET /api/v1/peopleconnect/conversations/{conversation}/header`
- `GET /api/v1/peopleconnect/conversations/{conversation}/logs`
- `GET /api/v1/peopleconnect/conversations/{conversation}/topics`
- `GET /api/v1/peopleconnect/conversations/{conversation}/context/latest`
- `GET /api/v1/peopleconnect/conversations/{conversation}/memories/latest`
- `GET /api/v1/peopleconnect/conversations/{conversation}/tasks`

Messages:

- `GET /api/v1/peopleconnect/conversations/{conversation}/messages`
- `POST /api/v1/peopleconnect/conversations/{conversation}/messages`
- `POST /api/v1/peopleconnect/messages/{message}/retry`
- `POST /api/v1/peopleconnect/messages/{message}/draft-reply`
- `POST /api/v1/peopleconnect/messages/{message}/create-task`
- `POST /api/v1/peopleconnect/messages/{message}/save-note`
- `POST /api/v1/peopleconnect/messages/{message}/save-memory`
- `GET /api/v1/peopleconnect/messages/{message}/trace`
- `GET /api/v1/peopleconnect/messages/{message}/raw-provider-event`

Sessions:

- `GET /api/v1/peopleconnect/conversations/{conversation}/sessions`
- `POST /api/v1/peopleconnect/conversations/{conversation}/sessions/close`
- `POST /api/v1/peopleconnect/conversations/{conversation}/sessions/reopen`

LiveMsgs and WAHA:

- `GET /api/v1/peopleconnect/livemsgs/status`
- `GET /api/v1/peopleconnect/livemsgs/sync-runs`
- `POST /api/v1/peopleconnect/livemsgs/sync-now`
- `POST /api/v1/peopleconnect/livemsgs/reconcile`
- `GET /api/v1/peopleconnect/livemsgs/pending-outgoing`
- `POST /api/v1/peopleconnect/livemsgs/retry-failed`
- `POST /api/v1/webhooks/waha`

Reply mode:

- `GET /api/v1/peopleconnect/reply-mode`
- `PATCH /api/v1/peopleconnect/reply-mode`
- `PATCH /api/v1/peopleconnect/conversations/{conversation}/reply-mode`

Rules and notes:

- `GET /api/v1/peopleconnect/conversations/{conversation}/rules`
- `POST /api/v1/peopleconnect/conversations/{conversation}/rules`
- `PATCH /api/v1/peopleconnect/rules/{rule}`
- `DELETE /api/v1/peopleconnect/rules/{rule}`
- `GET /api/v1/peopleconnect/conversations/{conversation}/notes`
- `POST /api/v1/peopleconnect/conversations/{conversation}/notes`
- `PATCH /api/v1/peopleconnect/notes/{note}`
- `DELETE /api/v1/peopleconnect/notes/{note}`

Search and filters:

- `GET /api/v1/peopleconnect/search`
- `GET /api/v1/peopleconnect/messages/search`
- `GET /api/v1/peopleconnect/filters/options`

Analytics:

- `GET /api/v1/peopleconnect/stats`
- `GET /api/v1/peopleconnect/analytics`

## Integration Requirements

### ContactHub

- Resolve contacts by WhatsApp ID and number.
- Create missing contacts when WAHA sync finds new people.
- Store WhatsApp number and identifiers.
- Respect contact reply-mode override.
- Read/write contact rules, notes, memories, and tasks through hub contracts.
- Provide message evidence for ContactHub analysis.

### HedraSoulHub

- Escalate approvals, failures, risky replies, and system alerts to HedraSoulHub.
- Let HedraSoulHub open a selected PeopleConnect conversation.
- Use HedraSoulHub approval decisions for blocked agent replies.

### AgentsHub

- Generate reply drafts.
- Execute contact reply agents.
- Analyze messages.
- Provide traces for each agent action.
- Respect agent quarantine and global pause.

### AiModelsHub

- Route all AI generation and analysis calls.
- Use `PeopleConnect_Chat_Reply`, `Intent_Detection`, `Memory_Extraction`, `Contact_Analysis`, and summarization intents.
- Track usage and cost.

### TasksHub

- Create follow-up tasks from messages.
- Link tasks to contact and conversation.
- Show task logs inside conversation.
- Use task status events to update UI.

### WorkflowsHub

- Trigger workflows from message received, reply needed, failed send, new contact, or high-risk intent.
- Allow workflow steps to create drafts or send messages through PeopleConnectHub.

### SchedulerHub

- Run hourly WAHA reconciliation.
- Close inactive sessions.
- Send scheduled messages.
- Run daily summaries and cleanup jobs.

### SettingsHub

- Store WAHA endpoint and credentials.
- Store global reply mode defaults.
- Store quiet hours, limits, sync interval, and delivery retry policy.
- Store health thresholds.

### LogsHub

- Log sync runs, webhooks, message sends, delivery attempts, analysis runs, agent replies, blocks, approvals, and errors.

## Security And Safety Requirements

- Validate WAHA webhook signatures or shared secret.
- Use idempotency keys for inbound events and outgoing sends.
- Dedupe by provider message ID and hash.
- Never log raw secrets.
- Mask PII in logs.
- Encrypt sensitive message/source payload fields where required.
- Add SSRF protection for webhook/provider configuration.
- Enforce reply-mode safety.
- Require approval for sensitive topics unless explicitly allowed.
- Rate-limit outgoing messages per contact.
- Support emergency global agent pause.
- Support contact-level autopilot disable.

## Realtime Requirements

Broadcast updates for:

- New contact synced.
- New conversation created.
- New message received.
- Message saved.
- Message analyzed.
- Reply draft ready.
- Message queued.
- Message sending.
- Message sent.
- Message delivered.
- Message read.
- Message failed.
- WAHA connected/disconnected.
- Sync started/completed.
- Pending outgoing count changed.
- Agent status changed.
- Conversation log entry created.

## Acceptance Criteria

PeopleConnectHub is complete when:

- It exists as a standalone hub in navigation and API.
- The UI reads conversations/messages from the database, not directly from WAHA.
- WAHA webhook ingestion creates contacts, conversations, sessions, and messages.
- Scheduled hourly WAHA reconciliation creates missing contacts, conversations, and messages.
- Every contact has one canonical conversation.
- Sessions auto-close after two hours of inactivity.
- New messages after session closure open a new session.
- The topbar includes LiveMsgs, WAHA status, reply mode, pending outgoing count, and incoming save indicator.
- The selected conversation header shows topic, latest intent, emotional baseline, tone mirroring, sentiment, counts, background log, and agent status.
- The sidebar shows contact name/phone, number, last message time, preview, and unread badge.
- The message panel auto-scrolls, shows date/session separators, sender colors, delivery state, and message toolbar metadata.
- Rules, notes, context, memories, and tasks modals work for the selected contact/conversation.
- Global reply mode and contact override work.
- Copilot drafts require approval before sending.
- Autopilot sends only when all safety rules pass.
- Pending outgoing messages are queued, sent, retried, and visibly tracked.
- Incoming and outgoing updates broadcast in realtime.
- AI analysis and drafting go through AgentsHub/AiModelsHub.
- Contact data flows through ContactHub.
- Logs and traces are recorded.
- Backend tests cover sync, webhook, session, message, reply mode, and send flows.
- Frontend build passes and no simulated capability is presented as complete.

