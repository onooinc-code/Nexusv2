# ContactHub Full Implementation Plan

## Source Documents

- `NexusV2_Docs/06 - ContactHub/ContactHub_SPEC_REQUIREMENTS_FEATURES.md`
- `NexusV2_Docs/HUB_IMPLEMENTATION_REVIEW_2026-05-30.md`

## Goal

Build the full ContactHub vNext described in the new spec: contact identity, message imports, WhatsApp/Facebook conversations, AI-backed profile intelligence, reply modes, memory maintenance, relationships, privacy flows, analytics, and hub integrations.

ContactHub must remain internal-memory only:

- MySQL for durable structured data.
- Redis for queues, cache, locks, and realtime state.
- Pinecone for approved vector search and embeddings.
- Future MemoryHub for long-term memory ownership when available.
- No external memory services.

## Delivery Strategy

Build ContactHub in safe layers. Each phase should ship with migrations, backend services, API tests, frontend API client updates, UI, logging, and at least one complete happy-path verification.

Do not expose UI controls for capabilities that are still stubs. If a backend feature is not ready, the frontend should show disabled or unavailable states rather than pretending the workflow is live.

## Phase 0 - Stabilize Current ContactsHub

### Objectives

- Keep existing ContactsHub behavior working.
- Add the minimum foundation needed for vNext without breaking current routes.
- Create reliable baseline tests before adding imports and AI workflows.

### Backend Tasks

- [ ] Re-run `ContactsHubTest` and keep it green.
- [ ] Add smoke tests for contact list, create, update, show, delete, merge, analytics, and enrichment routes.
- [ ] Review existing Contact models, migrations, controllers, resources, and services.
- [ ] Document the current contact API request/response shapes.
- [ ] Add missing API resources where controllers return raw model structures.
- [ ] Normalize contact fields needed by cards:
  - [ ] `display_name`
  - [ ] `alternate_name`
  - [ ] `contact_type`
  - [ ] `gender`
  - [ ] `primary_phone`
  - [ ] `whatsapp_number`
  - [ ] `primary_identifier`
  - [ ] `tags`
  - [ ] `reply_mode_override`
  - [ ] `profile_confidence`
  - [ ] `memory_freshness`
  - [ ] `last_interaction_at`
- [ ] Add safe defaults for existing contacts.
- [ ] Add indexes for common contact filters and lookups.

### Frontend Tasks

- [ ] Review existing ContactsHub list and detail pages.
- [ ] Add a typed ContactHub API client layer if not already centralized.
- [ ] Align frontend contact types with backend resources.
- [ ] Update card props to support new fields without requiring the new features yet.
- [ ] Keep current tabs working.

### Tests And Verification

- [ ] Backend ContactsHub tests pass.
- [ ] Frontend build passes.
- [ ] Contact create/update from UI still works.
- [ ] Existing contact detail tabs still render.

### Exit Criteria

- Current ContactsHub is stable.
- The API shape for vNext fields is agreed and tested.
- No message import, AI analysis, or memory maintenance UI is exposed as live unless implemented.

## Phase 1 - Data Model Foundation

### Objectives

Add the durable schema for message import, source channels, AI findings, memory versions, reply rules, and audit trails.

### Migrations

- [ ] `contact_channels`
- [ ] `contact_identifiers`
- [ ] `contact_aliases`
- [ ] `contact_message_threads`
- [ ] `contact_messages`
- [ ] `contact_import_batches`
- [ ] `contact_analysis_runs`
- [ ] `contact_analysis_findings`
- [ ] `contact_memories`
- [ ] `contact_memory_versions`
- [ ] `contact_memory_maintenance_runs`
- [ ] `contact_relationships`
- [ ] `contact_preferences`
- [ ] `contact_reply_rules`
- [ ] `contact_topics`
- [ ] `contact_topic_mentions`
- [ ] `contact_profile_snapshots`
- [ ] `contact_audit_events`

### Model Requirements

- [ ] Every AI-derived fact has source evidence, confidence, actor, and timestamps.
- [ ] Every imported message has source metadata and dedupe hash.
- [ ] Every import has a batch record.
- [ ] Every memory update is versioned.
- [ ] Every privacy operation is auditable.
- [ ] Every message source supports rollback by import batch.

### Services

- [ ] Create `ContactProfileAssembler`.
- [ ] Create `ContactIdentityResolver`.
- [ ] Create `ContactAuditService`.
- [ ] Create `ContactPrivacyService`.
- [ ] Create `ContactAnalyticsService`.

### Tests And Verification

- [ ] Migration test on clean database.
- [ ] Model relationship tests.
- [ ] Factory coverage for each new model.
- [ ] Audit event write/read test.

### Exit Criteria

- Schema supports all planned workflows.
- Fact/version/evidence data can be stored without AI or imports yet.

## Phase 2 - Contact Cards And Topbar Controls

### Objectives

Expose the new ContactHub operational surface: richer cards, global reply mode, memory maintenance entry point, import entry point, stats, and queue status.

### Backend Tasks

- [ ] Add `GET /api/v1/contacts/stats`.
- [ ] Add reply-mode settings read/write routes:
  - [ ] `GET /api/v1/contacts/reply-mode`
  - [ ] `PATCH /api/v1/contacts/reply-mode`
  - [ ] `PATCH /api/v1/contacts/{contact}/reply-mode`
- [ ] Add a stats service that returns:
  - [ ] total contacts
  - [ ] active contacts
  - [ ] new imported messages
  - [ ] pending analysis runs
  - [ ] stale memory count
  - [ ] identity conflict count
  - [ ] autonomous reply enabled count
  - [ ] failed imports/analysis jobs
- [ ] Log global and per-contact reply-mode changes.

### Frontend Tasks

- [ ] Add topbar stats strip.
- [ ] Add Global Reply Mode segmented control:
  - [ ] Manual
  - [ ] Copilot
  - [ ] Autopilot
- [ ] Add warning state for global Autopilot.
- [ ] Add Import button with source menu.
- [ ] Add Batch Analyze button.
- [ ] Add Memory Maintenance button.
- [ ] Add queue/progress indicator shell.
- [ ] Update contact cards to show:
  - [ ] WhatsApp number
  - [ ] contact type
  - [ ] gender badge
  - [ ] identifier
  - [ ] tags
  - [ ] reply mode
  - [ ] override indicator
  - [ ] last interaction
  - [ ] emotional baseline chip
  - [ ] profile confidence
  - [ ] memory freshness
  - [ ] conflicts
  - [ ] quick actions

### Tests And Verification

- [ ] Backend stats API test.
- [ ] Backend reply-mode API test.
- [ ] Frontend build passes.
- [ ] Cards fit on desktop and mobile.
- [ ] Reply-mode changes persist and audit.

### Exit Criteria

- ContactHub main page shows real operational state.
- Reply mode is controllable globally and per contact.

## Phase 3 - WhatsApp And Facebook Import Pipeline

### Objectives

Import message history from WhatsApp and Facebook JSON/TXT exports with preview, commit, dedupe, rollback, and progress.

Note : Review the whatsapp api documentations first :
NexusV2_Docs\waha-api.json

### Backend Services

- [ ] Create `ContactImportPipeline`.
- [ ] Create `ContactMessageNormalizer`.
- [ ] Create `WhatsAppImportParser`.
- [ ] Create `FacebookImportParser`.
- [ ] Create `ContactImportPreviewService`.
- [ ] Create `ContactImportRollbackService`.

### Jobs

- [ ] `ImportContactMessagesJob`
- [ ] `NormalizeContactImportBatchJob`
- [ ] `ResolveContactImportIdentitiesJob`
- [ ] `RollbackContactImportBatchJob`

### API Routes

- [ ] `POST /api/v1/contacts/import/preview`
- [ ] `POST /api/v1/contacts/import/whatsapp`
- [ ] `POST /api/v1/contacts/import/facebook`
- [ ] `GET /api/v1/contacts/imports`
- [ ] `GET /api/v1/contacts/imports/{batch}`
- [ ] `POST /api/v1/contacts/imports/{batch}/rollback`

### Import Capabilities

- [ ] WhatsApp TXT parser.
- [ ] WhatsApp JSON parser.
- [ ] Facebook JSON parser.
- [ ] Facebook TXT parser where export format is available.
- [ ] Manual paste fallback.
- [ ] Timezone handling.
- [ ] Language detection placeholder or service.
- [ ] Duplicate detection by source ID and hash.
- [ ] Contact matching preview.
- [ ] New contact creation for unmatched participants.
- [ ] Attachment metadata preservation.
- [ ] Thread reconstruction.
- [ ] Error report with row/message numbers.

### Frontend Tasks

- [ ] Build Import modal.
- [ ] Add source selector.
- [ ] Add file upload.
- [ ] Add paste text area.
- [ ] Add preview step.
- [ ] Add contact matching step.
- [ ] Add import options.
- [ ] Add queue progress step.
- [ ] Add result summary.
- [ ] Add import-batch detail drawer or modal.
- [ ] Add rollback action.

### Tests And Verification

- [ ] Unit tests for WhatsApp TXT parsing.
- [ ] Unit tests for WhatsApp JSON parsing.
- [ ] Unit tests for Facebook JSON parsing.
- [ ] Unit tests for duplicate detection.
- [ ] Feature test for preview.
- [ ] Feature test for commit.
- [ ] Feature test for rollback.
- [ ] Queue job test for large import.

### Exit Criteria

- User can import WhatsApp and Facebook histories safely.
- Imports are observable, reversible, and deduped.

## Phase 4 - Conversations And Message Views

### Objectives

Expose source-specific and unified message history inside the Contact360 profile.

### Backend Routes

- [ ] `GET /api/v1/contacts/{contact}/messages`
- [ ] `GET /api/v1/contacts/{contact}/messages/whatsapp`
- [ ] `GET /api/v1/contacts/{contact}/messages/facebook`
- [ ] `GET /api/v1/contacts/{contact}/threads`
- [ ] `GET /api/v1/contacts/{contact}/threads/{thread}`

### Backend Tasks

- [ ] Add message filters:
  - [ ] source
  - [ ] channel
  - [ ] date range
  - [ ] sender
  - [ ] direction
  - [ ] attachment presence
  - [ ] language
  - [ ] search query
- [ ] Add pagination and cursor support.
- [ ] Add thread summaries.
- [ ] Update contact `last_interaction_at` from messages.

### Frontend Tasks

- [ ] Add Conversations tab.
- [ ] Add WhatsApp tab.
- [ ] Add Facebook tab.
- [ ] Add thread selector.
- [ ] Add message search.
- [ ] Add date filters.
- [ ] Add source filters.
- [ ] Add sender filters.
- [ ] Add import batch link.
- [ ] Add raw source metadata modal for admin/debug users.

### Tests And Verification

- [ ] Backend message list tests.
- [ ] Backend source-specific route tests.
- [ ] Frontend render tests or manual responsive verification.
- [ ] Pagination works on large message sets.

### Exit Criteria

- Users can inspect imported messages by channel and in a unified conversation view.

## Phase 5 - AI Analysis Runs

### Objectives

Analyze messages and notes through AgentsHub/AiModelsHub to create evidence-backed ContactPersona, ContactTalkSpecs, emotional baseline, topics, preferences, relationships, and memory suggestions.

### Dependency Gate

Before this phase is considered complete:

- [ ] AiProviderHub auth header bug is fixed.
- [ ] Gemini/OpenAI-compatible provider adapters are reliable.
- [ ] AgentsHub real execution path is available.
- [ ] Agent async job dispatch is fixed.

### Backend Services

- [ ] Create `ContactIntelligenceExtractionPipeline`.
- [ ] Create `ContactAnalysisPromptBuilder`.
- [ ] Create `ContactAnalysisFindingWriter`.
- [ ] Create `ContactProfileSuggestionService`.
- [ ] Create `ContactTopicExtractionService`.
- [ ] Create `ContactBaselineCalculator`.

### Jobs

- [ ] `AnalyzeContactMessagesJob`
- [ ] `ApplyContactAnalysisFindingsJob`
- [ ] `RollbackContactAnalysisRunJob`

### API Routes

- [ ] `POST /api/v1/contacts/{contact}/analysis-runs`
- [ ] `GET /api/v1/contacts/{contact}/analysis-runs`
- [ ] `GET /api/v1/contacts/{contact}/analysis-runs/{run}`
- [ ] `POST /api/v1/contacts/analysis-runs/batch`
- [ ] `POST /api/v1/contacts/analysis-runs/{run}/apply`
- [ ] `POST /api/v1/contacts/analysis-runs/{run}/rollback`
- [ ] `GET /api/v1/contacts/{contact}/intelligence`
- [ ] `GET /api/v1/contacts/{contact}/persona`
- [ ] `GET /api/v1/contacts/{contact}/talk-specs`
- [ ] `GET /api/v1/contacts/{contact}/emotional-baseline`
- [ ] `GET /api/v1/contacts/{contact}/topics`

### Analysis Outputs

- [ ] Summary.
- [ ] ContactPersona.
- [ ] ContactTalkSpecs.
- [ ] Emotional baseline.
- [ ] Tone guidance.
- [ ] Preferences.
- [ ] Topics.
- [ ] Relationships.
- [ ] Memories.
- [ ] Reply-rule suggestions.
- [ ] Conflict list.
- [ ] Safety flags.
- [ ] Evidence references.
- [ ] Confidence scores.
- [ ] Trace ID.
- [ ] Cost/token metadata.

### Frontend Tasks

- [ ] Build AI Analysis modal.
- [ ] Add source selector.
- [ ] Add scope selector.
- [ ] Add date-range selector.
- [ ] Add model/agent selector.
- [ ] Add analysis option checkboxes.
- [ ] Add dry-run mode.
- [ ] Add confidence threshold.
- [ ] Add cost estimate.
- [ ] Add progress state.
- [ ] Add findings review.
- [ ] Add apply/ignore/rollback actions.
- [ ] Add intelligence panels in Contact360.

### Tests And Verification

- [ ] Fake-provider analysis test.
- [ ] Analysis run creation test.
- [ ] Analysis finding evidence test.
- [ ] Apply findings test.
- [ ] Rollback findings test.
- [ ] Failed AI call recovery test.
- [ ] Frontend build passes.

### Exit Criteria

- Contact intelligence is generated through the hub AI stack.
- Every generated fact has evidence and confidence.
- Users can review and apply/rollback AI findings.

## Phase 6 - Memory Maintenance

### Objectives

Add hub-wide and contact-specific maintenance for memory, profile facts, embeddings, duplicates, stale data, conflicts, exports, and erasure.

### Backend Services

- [ ] Create `ContactMemoryMaintenancePipeline`.
- [ ] Create `ContactMemoryFreshnessService`.
- [ ] Create `ContactMemoryConflictDetector`.
- [ ] Create `ContactEmbeddingSyncService`.
- [ ] Create `ContactDuplicateResolver`.
- [ ] Create `ContactMemoryExportService`.
- [ ] Create `ContactMemoryEraseService`.

### Jobs

- [ ] `RebuildContactMemoryJob`
- [ ] `RecomputeContactEmbeddingsJob`
- [ ] `ResolveContactDuplicatesJob`
- [ ] `RecalculateContactBaselineJob`
- [ ] `DetectContactMemoryConflictsJob`
- [ ] `PruneContactMemoryJob`
- [ ] `ExportContactDataJob`
- [ ] `EraseContactDataJob`

### API Routes

- [ ] `POST /api/v1/contacts/{contact}/memory-maintenance`
- [ ] `POST /api/v1/contacts/memory-maintenance`
- [ ] `GET /api/v1/contacts/memory-maintenance/runs`
- [ ] `GET /api/v1/contacts/memory-maintenance/runs/{run}`
- [ ] `POST /api/v1/contacts/{contact}/export`
- [ ] `POST /api/v1/contacts/{contact}/erase`

### Maintenance Operations

- [ ] Rebuild profile memory.
- [ ] Recompute embeddings.
- [ ] Dedupe contacts.
- [ ] Re-run identity resolution.
- [ ] Recalculate emotional baselines.
- [ ] Recalculate ContactPersona.
- [ ] Recalculate ContactTalkSpecs.
- [ ] Detect stale memories.
- [ ] Detect conflicting facts.
- [ ] Prune low-confidence memories.
- [ ] Archive raw imports by retention policy.
- [ ] Export contact memory.
- [ ] Privacy erase contact memory.
- [ ] Roll back an analysis run.
- [ ] Inspect queue health.

### Frontend Tasks

- [ ] Build Memory Maintenance modal.
- [ ] Add scope selector.
- [ ] Add operation checkboxes.
- [ ] Add dry-run mode.
- [ ] Add estimate step.
- [ ] Add queue progress.
- [ ] Add result summary.
- [ ] Add errors/conflicts list.
- [ ] Add audit link.

### Tests And Verification

- [ ] Dry-run maintenance test.
- [ ] Committed maintenance test.
- [ ] Export test.
- [ ] Erase test.
- [ ] Embedding deletion/sync test where Pinecone is configured.
- [ ] Queue progress event test.

### Exit Criteria

- Users can safely inspect, rebuild, prune, export, and erase ContactHub memory.

## Phase 7 - Relationships, Preferences, Rules, And Topics

### Objectives

Complete the structured relationship intelligence layer.

### Backend Tasks

- [ ] Add relationship CRUD.
- [ ] Add preference CRUD.
- [ ] Add reply-rule CRUD.
- [ ] Add topic list and topic evidence routes.
- [ ] Add conflict detection for rules and preferences.
- [ ] Add AI-suggested relationship/reply-rule approval flow.

### Frontend Tasks

- [ ] Complete Relationships tab.
- [ ] Complete Preferences tab.
- [ ] Complete Rules tab.
- [ ] Complete Topics tab.
- [ ] Add evidence viewer.
- [ ] Add approve/reject controls for AI suggestions.

### Tests And Verification

- [ ] Relationship API tests.
- [ ] Preference API tests.
- [ ] Reply-rule API tests.
- [ ] Topic API tests.
- [ ] Conflict detection tests.

### Exit Criteria

- ContactHub can manage the structured facts used by reply and proactive logic.

## Phase 8 - Privacy, Audit, And Version History

### Objectives

Make ContactHub safe for real personal data.

### Backend Tasks

- [ ] Complete contact audit event model and service.
- [ ] Add `GET /api/v1/contacts/{contact}/audit`.
- [ ] Add profile snapshot creation on major AI/profile updates.
- [ ] Add version history for memories and generated facts.
- [ ] Add erase verification records.
- [ ] Add export bundle generation.
- [ ] Add permission checks for privacy actions.

### Frontend Tasks

- [ ] Add Audit & Versions tab.
- [ ] Add export action.
- [ ] Add erase action with confirmation.
- [ ] Add analysis rollback UI.
- [ ] Add memory version viewer.

### Tests And Verification

- [ ] Audit event tests.
- [ ] Version history tests.
- [ ] Export bundle tests.
- [ ] Erase removes messages, facts, memories, vectors, and identifiers as required.

### Exit Criteria

- Every sensitive operation is auditable.
- Export and erasure workflows are complete and verified.

## Phase 9 - Hub Integrations

### Objectives

Connect ContactHub to the rest of Nexus without duplicating responsibilities.

### Required Integrations

- [ ] AiProviderHub / AIModelsHub for provider and model selection.
- [ ] AgentsHub for analysis execution and traceability.
- [ ] TasksHub for follow-ups, approval tasks, conflict tasks, and import error tasks.
- [ ] WorkflowsHub for contact-triggered workflows.
- [ ] SchedulerHub for scheduled maintenance and periodic analysis.
- [ ] ProactiveAIHub for contact-event rules.
- [ ] LogsHub for audit and system visibility.
- [ ] SettingsHub for reply mode, import limits, retention, AI defaults, and privacy defaults.
- [ ] MemoryHub when available.

### Integration Events

- [ ] `ContactCreated`
- [ ] `ContactUpdated`
- [ ] `ContactMerged`
- [ ] `ContactImportStarted`
- [ ] `ContactImportCompleted`
- [ ] `ContactAnalysisStarted`
- [ ] `ContactAnalysisCompleted`
- [ ] `ContactMemoryMaintenanceStarted`
- [ ] `ContactMemoryMaintenanceCompleted`
- [ ] `ContactReplyModeChanged`
- [ ] `ContactMessageImported`
- [ ] `ContactIdentityConflictDetected`

### Tests And Verification

- [ ] Event dispatch tests.
- [ ] Listener tests.
- [ ] Task creation from ContactHub event test.
- [ ] Workflow trigger smoke test.
- [ ] ProactiveAI rule evaluation smoke test.

### Exit Criteria

- ContactHub acts as a first-class Nexus hub and does not bypass other hub ownership boundaries.

## Phase 10 - Production Hardening

### Backend

- [ ] Add policies/authorization for all routes.
- [ ] Add rate limits for imports and AI analysis.
- [ ] Add file size limits.
- [ ] Add queue retry/backoff rules.
- [ ] Add idempotency keys for import and analysis actions.
- [ ] Add structured logs and trace IDs.
- [ ] Add cache invalidation strategy.
- [ ] Add performance indexes.
- [ ] Add background cleanup for abandoned import previews.

### Frontend

- [ ] Verify desktop and mobile layouts.
- [ ] Add empty states.
- [ ] Add loading states.
- [ ] Add error states.
- [ ] Add progress states.
- [ ] Add permission-disabled states.
- [ ] Add conflict and stale-memory indicators.

### Documentation

- [ ] Update API docs.
- [ ] Update feature docs.
- [ ] Update admin docs.
- [ ] Add import format examples.
- [ ] Add reply mode safety documentation.

### Exit Criteria

- ContactHub is reliable under large imports, slow AI calls, failed jobs, permission restrictions, and privacy operations.

## Final Acceptance Checklist

- [ ] Existing ContactsHub tests pass.
- [ ] New ContactHub feature tests pass.
- [ ] Frontend build passes.
- [ ] WhatsApp JSON/TXT import works.
- [ ] Facebook JSON/TXT import works.
- [ ] Import preview, commit, dedupe, and rollback work.
- [ ] Contact cards show new operational fields.
- [ ] Contact360 includes all required tabs.
- [ ] AI analysis runs through AgentsHub/AiModelsHub only.
- [ ] AI findings include evidence and confidence.
- [ ] Memory Maintenance supports dry-run and committed runs.
- [ ] Global and per-contact reply modes work.
- [ ] Autopilot obeys safety rules.
- [ ] Export and erase flows are complete.
- [ ] Queue progress and logs are visible.
- [ ] ContactHub emits and consumes expected events.
- [ ] Documentation is updated.

