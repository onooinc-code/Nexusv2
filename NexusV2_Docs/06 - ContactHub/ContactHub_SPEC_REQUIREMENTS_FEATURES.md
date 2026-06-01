# ContactHub Specification, Requirements, and Feature Set

## Purpose

ContactHub is the Nexus source of truth for people, organizations, identities, relationships, conversations, and relationship intelligence.

It should answer:

- Who is this person or entity?
- Where did we communicate with them?
- What do we know, and what evidence supports it?
- What tone, preferences, boundaries, memories, and rules should Nexus respect?
- Should Nexus reply manually, as a copilot, or autonomously?
- Which memory and profile facts are fresh, stale, conflicting, or unsafe to use?

ContactHub must not use external memory services. It should persist operational data in MySQL, use Redis for cache/queues/realtime state, use Pinecone only for approved vector search/semantic retrieval, and be ready to delegate durable memory ownership to the future MemoryHub.

## Core Principles

- API-first. Every UI feature must have a clear backend route, request shape, response shape, and test.
- Evidence-based intelligence. AI-created facts need source messages, confidence, timestamps, and version history.
- Human control by default. Autonomous behavior must be explicit, visible, revocable, and auditable.
- Internal memory only. No third-party memory APIs.
- Hub boundaries. ContactHub owns contact profiles and contact intelligence; AiModelsHub/AgentsHub own AI execution; SettingsHub owns settings; LogsHub owns audit/log visibility; NotificationHub owns notifications.
- Queue long tasks. Imports, analysis, memory rebuilds, dedupe, and embedding sync must run as jobs with progress events.
- Privacy first. Import, erase, merge, export, and retention flows must be first-class.

## Key Concepts

### Contact

A canonical person, organization, lead, customer, friend, family member, supplier, internal teammate, bot, or unknown entity.

### Identifier

A source-specific identity handle such as:

- Phone number
- WhatsApp number
- Facebook profile ID
- Messenger thread ID
- Email
- Username
- External CRM ID
- Device/contact-book ID

### Channel

A communication surface such as WhatsApp, Facebook, Messenger, email, SMS, phone, web chat, or manual notes.

### Message

An imported or synced communication unit with source, sender, timestamp, body, attachments metadata, language, direction, and thread context.

### Contact360 Profile

The assembled view of identity, channels, aliases, relationships, preferences, emotional baseline, tone, topics, memories, rules, analytics, and audit history.

### ContactPersona

An AI-assisted but evidence-backed profile that describes stable communication traits, interests, boundaries, relationship context, and interaction patterns.

### ContactTalkSpecs

Operational reply guidance, such as preferred language, formality, message length, emoji tolerance, directness, greeting style, topics to avoid, response-time expectations, and escalation rules.

### Emotional Baseline

A longitudinal estimate of the contact's usual emotional range, derived from messages over time, not a single message or note.

### Reply Mode

The mode controlling how Nexus may respond:

- `manual`: Nexus never replies automatically.
- `copilot`: Nexus drafts replies and waits for user approval.
- `autopilot`: Nexus can reply automatically within configured rules, confidence thresholds, and safety limits.

Reply mode must exist globally and per contact. Per-contact override wins over global default.

### Memory Maintenance

Administrative and AI-assisted operations that rebuild, prune, dedupe, validate, export, erase, or re-embed contact memory.

## Functional Requirements

### 1. Contact Identity And Canonicalization

ContactHub must support:

- Create, read, update, archive, restore, and delete contacts.
- Soft delete and privacy erase.
- Merge contacts with conflict review.
- Split incorrectly merged contacts.
- Multiple identifiers per contact.
- Multiple aliases and alternate names.
- Contact type classification.
- Gender field with configurable values and unknown/prefer-not-set support.
- Primary channel and preferred channel.
- Confidence score for identity resolution.
- Duplicate detection by phone, WhatsApp, email, Facebook ID, normalized name, and semantic similarity.

Required contact fields:

- Display name
- Alternate name
- Contact type
- Gender
- Primary phone
- WhatsApp number
- Email
- Main identifier
- Tags
- Reply mode override
- Preferred language
- Timezone
- Notes summary
- Profile confidence
- Last interaction timestamp
- Data retention state

### 2. Contact Cards

The ContactsHub list/grid cards should show useful operational data without opening the profile.

Card requirements:

- Contact name.
- Alternate name or nickname.
- Avatar or initials.
- Contact type badge.
- Gender badge or icon where configured.
- WhatsApp number.
- Primary phone.
- Main identifier or source handle.
- Tags.
- Preferred channel.
- Reply mode state: Manual, Copilot, or Autopilot.
- Per-contact reply override indicator.
- Last interaction time.
- Emotional baseline chip.
- AI profile confidence.
- Memory freshness indicator.
- Open conflicts indicator.
- Quick actions:
  - Open profile.
  - Start AI analysis.
  - Import messages.
  - View conversations.
  - Edit reply mode.
  - Merge.
  - Archive.

The card must remain compact and scannable. It should not become a mini profile page.

### 3. ContactsHub Topbar

The ContactsHub main topbar should expose hub-level operations:

- Search.
- Filters.
- View mode.
- Add contact.
- Import.
- Batch analyze.
- Memory Maintenance.
- Global Reply Mode.
- Queue/progress indicator.

Topbar stats:

- Total contacts.
- Active contacts.
- New imported messages.
- Pending analysis runs.
- Contacts with stale memory.
- Contacts with identity conflicts.
- Contacts with autonomous reply enabled.
- Failed imports or analysis jobs.

Global Reply Mode control:

- Segmented control: Manual, Copilot, Autopilot.
- Visible warning when Autopilot is enabled globally.
- Counter for contacts overriding the global mode.
- Audit log entry when changed.

### 4. Contact Profile Layout

The Contact360 detail screen should include:

- Header with name, aliases, avatar, type, gender, tags, confidence, and last interaction.
- Channel strip with WhatsApp, Facebook, email, phone, and other identifiers.
- Reply mode control with effective mode and override mode.
- AI profile summary.
- Memory freshness and conflict indicators.
- Quick actions: import, analyze, maintain memory, merge, export, erase.

Required tabs:

- Overview
- Conversations
- WhatsApp
- Facebook
- Notes
- Memories
- Rules
- Relationships
- Preferences
- Identifiers & Aliases
- Topics
- Timeline
- Analytics
- Tasks & Workflows
- Audit & Versions

### 5. Conversations And Message Imports

ContactHub must import and normalize message history.

Supported import sources:

- WhatsApp JSON.
- WhatsApp TXT export.
- Facebook JSON.
- Facebook TXT export where available.
- Manual paste/import.
- Future connector-based sync.

Import requirements:

- Import preview before commit.
- Source selection.
- Contact matching preview.
- New contact creation for unmatched participants.
- Timezone handling.
- Language detection.
- Attachment metadata preservation where possible.
- Duplicate detection.
- Thread reconstruction.
- Error report with row/message numbers.
- Import batch record.
- Queue progress.
- Ability to rollback an import batch.

Message fields:

- Contact ID.
- Channel.
- Source.
- External message ID where available.
- Thread ID.
- Sender identifier.
- Direction: inbound, outbound, system, unknown.
- Body.
- Timestamp.
- Language.
- Attachments metadata.
- Raw source metadata.
- Import batch ID.
- Hash for dedupe.

### 6. Source-Specific Message Views

The Contact360 profile should include source-specific message views.

WhatsApp tab:

- Message timeline.
- Search.
- Date range filter.
- Sender filter.
- Attachment filter.
- Import WhatsApp export.
- Re-run WhatsApp analysis.
- Open raw import batch.

Facebook tab:

- Message timeline.
- Thread selector.
- Search.
- Date range filter.
- Import Facebook export.
- Re-run Facebook analysis.
- Open raw import batch.

Conversations tab:

- Unified cross-channel timeline.
- Group by thread, channel, topic, or date.
- AI-generated conversation summaries.
- Extracted decisions, promises, preferences, and open loops.

### 7. AI Analysis

ContactHub must support explicit AI analysis runs.

Analysis modal options:

- Source: all messages, WhatsApp, Facebook, notes, selected date range, selected import batch.
- Mode: preview only, write suggestions, auto-apply safe facts.
- Model/agent selection through AiProviderHub / AgentsHub.
- Confidence threshold.
- Language preference.
- Include or exclude outbound user messages.
- Extract topics.
- Extract preferences.
- Extract relationships.
- Extract sentiment and emotional baseline.
- Extract ContactPersona.
- Extract ContactTalkSpecs.
- Generate memory updates.
- Generate reply rules.
- Detect conflicts.

Analysis outputs:

- Summary.
- Extracted facts.
- Evidence message references.
- Confidence score.
- Suggested profile updates.
- Suggested memory updates.
- Suggested reply rules.
- Conflict list.
- Safety flags.
- Cost/token metadata.
- Trace ID.

AI analysis must not directly call external AI providers from ContactHub. It must use AgentsHub/AiModelsHub.

### 8. Emotional Baseline And Tone Mirroring

ContactHub should compute a longitudinal emotional baseline from real messages and notes.

Baseline inputs:

- Message sentiment over time.
- Conversation intensity.
- Topic sensitivity.
- Response cadence.
- Language and style.
- Contact-specific positive/negative markers.

Outputs:

- Baseline sentiment range.
- Recent deviation.
- Common mood markers.
- Sensitive topics.
- Preferred tone.
- Escalation warning when a reply may be emotionally mismatched.

Tone mirroring should produce operational guidance, not fake intimacy. It should help Nexus avoid sounding wrong, too formal, too casual, too long, too short, or too emotionally flat.

### 9. ContactPersona And ContactTalkSpecs

ContactPersona should include:

- Relationship context.
- Stable interests.
- Work/personal context.
- Communication style.
- Boundaries.
- Important dates or recurring patterns.
- Trust level.
- Known sensitivities.

ContactTalkSpecs should include:

- Preferred language.
- Formality.
- Directness.
- Message length.
- Greeting/closing style.
- Emoji/sticker tolerance.
- Humor tolerance.
- Response speed expectation.
- Best channel.
- Topics to avoid.
- Required approval conditions.

Every generated field must include:

- Source evidence.
- Confidence.
- Created by.
- Created at.
- Last validated at.

### 10. Reply Modes And Rules

Reply behavior must be controllable at global and contact levels.

Global settings:

- Default reply mode.
- Allowed channels for autopilot.
- Quiet hours.
- Max replies per contact per day.
- Confidence threshold.
- Sensitive-topic approval requirement.
- New-contact approval requirement.
- Unknown-identity approval requirement.

Per-contact settings:

- Reply mode override.
- Channel-specific mode.
- Allowed topics.
- Blocked topics.
- Required approval triggers.
- Max daily autonomous replies.
- Escalation contacts or workflows.

Autopilot safety requirements:

- Always log generated drafts and sent replies.
- Require approval below confidence threshold.
- Require approval for sensitive topics.
- Require approval when profile memory is stale or conflicted.
- Require approval when identity confidence is low.
- Provide one-click disable per contact.

### 11. Memory Maintenance

The Memory Maintenance modal should support hub-wide and contact-specific operations.

Operations:

- Rebuild profile memory.
- Recompute embeddings.
- Dedupe contacts.
- Re-run identity resolution.
- Recalculate emotional baselines.
- Recalculate ContactPersona.
- Recalculate ContactTalkSpecs.
- Detect stale memories.
- Detect conflicting facts.
- Prune low-confidence memories.
- Archive old raw imports based on retention settings.
- Export contact memory.
- Privacy erase contact memory.
- Roll back an analysis run.
- Inspect queue health.

Modal requirements:

- Scope selector: all contacts, selected contacts, one contact, import batch, stale only, conflicted only.
- Dry-run mode.
- Estimated cost and duration.
- Job progress.
- Result summary.
- Error list.
- Audit log link.

### 12. Relationships

ContactHub should model relationships between contacts.

Relationship types:

- Family
- Friend
- Coworker
- Customer
- Vendor
- Manager
- Reports to
- Organization member
- Unknown/custom

Relationship fields:

- Source contact.
- Target contact.
- Relationship type.
- Direction.
- Strength.
- Evidence.
- Confidence.
- Start/end dates where known.
- Notes.

Relationships should be visible in:

- Contact profile.
- Relationship graph.
- AI analysis suggestions.
- Workflow/proactive condition builders.

### 13. Preferences And Rules

Contact preferences should include:

- Language.
- Timezone.
- Preferred channel.
- Do-not-contact windows.
- Topic preferences.
- Privacy preferences.
- Reply style preferences.
- Notification preferences.

Rules should include:

- User-defined rules.
- AI-suggested rules awaiting approval.
- Source/evidence.
- Active/inactive state.
- Rule conflict detection.
- Audit history.

### 14. Topics And Insights

ContactHub should extract and track topics over time:

- Frequently discussed topics.
- Recent topics.
- Sensitive topics.
- Open loops.
- Promises or commitments.
- Questions awaiting reply.
- Decisions.
- Follow-up opportunities.

Topic records should link back to source messages and analysis runs.

### 15. Timeline And Audit

The timeline should show:

- Contact created/updated.
- Identifier added/removed.
- Message import batches.
- Analysis runs.
- Memory maintenance runs.
- Reply mode changes.
- Rule changes.
- Merge/split events.
- Privacy export/erase events.
- Notes.
- Workflow/task/proactive events related to the contact.

Audit must include:

- Actor.
- Timestamp.
- Before/after where appropriate.
- Source IP/device where available.
- Trace ID.

### 16. Analytics

ContactHub analytics should include:

- Contact count by type.
- Active/inactive contacts.
- Contacts by channel.
- Contacts by reply mode.
- Contacts with stale memory.
- Contacts with identity conflicts.
- Message volume by channel.
- Import success/failure rate.
- Analysis cost and duration.
- Autopilot suggestions, approvals, sends, and blocks.
- Sentiment trend distribution.

### 17. Privacy, Export, And Erasure

ContactHub must support:

- Export contact profile.
- Export raw messages.
- Export AI-derived facts.
- Export audit history where permitted.
- Erase contact personal data.
- Erase imported messages.
- Erase vectors/embeddings.
- Erase AI-derived facts.
- Retain legal/audit tombstones where required.

Every erase operation must be queued, logged, and verifiable.

## Backend Modules

Recommended services:

- `ContactProfileAssembler`
- `ContactIdentityResolver`
- `ContactImportPipeline`
- `ContactMessageNormalizer`
- `ContactIntelligenceExtractionPipeline`
- `ContactMemoryMaintenancePipeline`
- `ContactRelationshipGraphBuilder`
- `ContactReplyModeService`
- `ContactPromptContextBuilder`
- `ContactPrivacyService`
- `ContactAnalyticsService`

Recommended jobs:

- `ImportContactMessagesJob`
- `NormalizeContactImportBatchJob`
- `AnalyzeContactMessagesJob`
- `RebuildContactMemoryJob`
- `RecomputeContactEmbeddingsJob`
- `ResolveContactDuplicatesJob`
- `RecalculateContactBaselineJob`
- `ExportContactDataJob`
- `EraseContactDataJob`

Recommended events:

- `ContactCreated`
- `ContactUpdated`
- `ContactMerged`
- `ContactImportStarted`
- `ContactImportCompleted`
- `ContactAnalysisStarted`
- `ContactAnalysisCompleted`
- `ContactMemoryMaintenanceStarted`
- `ContactMemoryMaintenanceCompleted`
- `ContactReplyModeChanged`
- `ContactMessageImported`
- `ContactIdentityConflictDetected`

## Data Model Additions

Keep the existing contacts foundation, then add or extend:

- `contact_channels`
- `contact_identifiers`
- `contact_aliases`
- `contact_messages`
- `contact_message_threads`
- `contact_import_batches`
- `contact_analysis_runs`
- `contact_analysis_findings`
- `contact_memories`
- `contact_memory_versions`
- `contact_memory_maintenance_runs`
- `contact_relationships`
- `contact_preferences`
- `contact_reply_rules`
- `contact_topics`
- `contact_topic_mentions`
- `contact_profile_snapshots`
- `contact_audit_events`

Important schema conventions:

- Store raw imported payload metadata separately from normalized message fields.
- Add source hashes for dedupe.
- Add confidence and evidence references to AI-derived records.
- Add `created_by_type`, `created_by_id`, or equivalent actor metadata for human/AI/system changes.
- Add soft deletes where user recovery matters.
- Use hard erasure workflows for privacy requests.

## API Requirements

Keep existing `/api/v1/contacts` routes for compatibility. Add ContactHub-specific capabilities under the same prefix unless a future route namespace is chosen.

Core:

- `GET /api/v1/contacts`
- `POST /api/v1/contacts`
- `GET /api/v1/contacts/{contact}`
- `PATCH /api/v1/contacts/{contact}`
- `DELETE /api/v1/contacts/{contact}`
- `POST /api/v1/contacts/{contact}/archive`
- `POST /api/v1/contacts/{contact}/restore`

Stats and dashboard:

- `GET /api/v1/contacts/stats`
- `GET /api/v1/contacts/analytics`
- `GET /api/v1/contacts/conflicts`
- `GET /api/v1/contacts/stale-memory`

Imports:

- `POST /api/v1/contacts/import/whatsapp`
- `POST /api/v1/contacts/import/facebook`
- `POST /api/v1/contacts/import/preview`
- `GET /api/v1/contacts/imports`
- `GET /api/v1/contacts/imports/{batch}`
- `POST /api/v1/contacts/imports/{batch}/rollback`

Messages:

- `GET /api/v1/contacts/{contact}/messages`
- `GET /api/v1/contacts/{contact}/messages/whatsapp`
- `GET /api/v1/contacts/{contact}/messages/facebook`
- `GET /api/v1/contacts/{contact}/threads`
- `GET /api/v1/contacts/{contact}/threads/{thread}`

AI analysis:

- `POST /api/v1/contacts/{contact}/analysis-runs`
- `GET /api/v1/contacts/{contact}/analysis-runs`
- `GET /api/v1/contacts/{contact}/analysis-runs/{run}`
- `POST /api/v1/contacts/analysis-runs/batch`
- `POST /api/v1/contacts/analysis-runs/{run}/apply`
- `POST /api/v1/contacts/analysis-runs/{run}/rollback`

Memory maintenance:

- `POST /api/v1/contacts/{contact}/memory-maintenance`
- `POST /api/v1/contacts/memory-maintenance`
- `GET /api/v1/contacts/memory-maintenance/runs`
- `GET /api/v1/contacts/memory-maintenance/runs/{run}`

Reply mode:

- `GET /api/v1/contacts/reply-mode`
- `PATCH /api/v1/contacts/reply-mode`
- `PATCH /api/v1/contacts/{contact}/reply-mode`
- `GET /api/v1/contacts/{contact}/reply-rules`
- `POST /api/v1/contacts/{contact}/reply-rules`
- `PATCH /api/v1/contacts/{contact}/reply-rules/{rule}`
- `DELETE /api/v1/contacts/{contact}/reply-rules/{rule}`

Profile intelligence:

- `GET /api/v1/contacts/{contact}/intelligence`
- `GET /api/v1/contacts/{contact}/persona`
- `GET /api/v1/contacts/{contact}/talk-specs`
- `GET /api/v1/contacts/{contact}/emotional-baseline`
- `GET /api/v1/contacts/{contact}/topics`

Privacy:

- `POST /api/v1/contacts/{contact}/export`
- `POST /api/v1/contacts/{contact}/erase`
- `GET /api/v1/contacts/{contact}/audit`

## Frontend Requirements

### ContactsHub Main Page

Must include:

- Dense operational topbar.
- Global Reply Mode segmented control.
- Memory Maintenance button.
- Import button with WhatsApp/Facebook options.
- Batch Analyze button.
- Search and filters.
- Stats strip.
- Queue/progress drawer.
- Grid/list/table view.
- Contact cards with the fields listed above.

### Import Modal

Must include:

- Source selector: WhatsApp, Facebook, manual, other.
- File upload.
- Paste text area.
- Preview step.
- Contact matching step.
- Import options.
- Queue progress step.
- Result summary.

### AI Analysis Modal

Must include:

- Scope selector.
- Source selector.
- Model/agent selector.
- Analysis options.
- Dry-run option.
- Confidence threshold.
- Cost estimate.
- Run progress.
- Findings review.
- Apply/ignore/rollback actions.

### Memory Maintenance Modal

Must include:

- Scope selector.
- Operation checkboxes.
- Dry-run option.
- Queue progress.
- Result summary.
- Error/conflict list.

### Contact360 Detail Page

Must include the required tabs, source-specific message views, profile intelligence panels, reply mode controls, rule management, memory maintenance, and audit/version history.

## Integration Requirements

AiProviderHub / AIModelsHub:

- ContactHub must use AIModelsHub provider selection and capability metadata.
- No direct provider SDK/API calls inside ContactHub.

AgentsHub:

- ContactHub analysis should be runnable by a selected agent.
- Agent traces should link back to contact analysis runs.

TasksHub:

- ContactHub should create tasks for follow-ups, conflicts, approvals, and import errors.

WorkflowsHub:

- Contact events should be usable as workflow triggers.
- Workflow actions should be able to update contacts through ContactHub APIs.

SchedulerHub:

- Scheduled memory maintenance and periodic analysis should run through SchedulerHub.

ProactiveAIHub:

- Contact message events and reply rules should feed proactive rule evaluation.
- Proactive replies must respect ContactHub reply mode and safety rules.

LogsHub:

- Import, analysis, memory maintenance, reply mode changes, AI actions, erase/export, and merge/split operations must be logged.

SettingsHub:

- Global reply mode, import limits, retention settings, AI defaults, and privacy defaults must be configurable.

MemoryHub:

- When MemoryHub exists, ContactHub should delegate long-term memory storage and retrieval through it.
- Until then, ContactHub must keep memory data internal and structured for migration.

## Acceptance Criteria

ContactHub vNext is complete when:

- Existing ContactsHub tests still pass.
- Contact CRUD and detail UI work.
- WhatsApp JSON/TXT import works with preview, commit, duplicate detection, and rollback.
- Facebook JSON/TXT import works with preview, commit, duplicate detection, and rollback.
- Contact cards show WhatsApp number, type, gender, identifier, reply mode, memory freshness, and AI confidence.
- Contact profile includes Conversations, WhatsApp, Facebook, Memories, Rules, Topics, Audit, and Versions tabs.
- AI analysis runs through AgentsHub/AiModelsHub and stores evidence-backed findings.
- Memory Maintenance can run dry-run and committed jobs with progress events.
- Global and per-contact reply mode controls work and are audited.
- Autopilot cannot send replies when safety requirements fail.
- Erase/export flows cover contacts, messages, memories, embeddings, and AI-derived facts.
- Import, analysis, memory maintenance, and privacy jobs are queued and logged.
- API request/response contracts are covered by tests.
- Frontend API client matches backend validation exactly.

## Implementation Phases

### Phase 0 - Stabilize Existing Hub

- Keep current ContactsHub tests green.
- Add missing frontend/backend contract tests.
- Normalize current contact fields needed by cards and detail views.
- Add migration guards for safe rollout.

### Phase 1 - Message Import Foundation

- Add import batches, messages, threads, and channels.
- Implement WhatsApp TXT/JSON import.
- Implement Facebook JSON/TXT import.
- Add import preview and rollback.
- Add message tabs in the contact profile.

### Phase 2 - Reply Mode And UI Controls

- Add global reply mode setting.
- Add per-contact reply override.
- Add card-level reply mode display/control.
- Add audit logs and safety checks.

### Phase 3 - AI Analysis And Profile Intelligence

- Add analysis run model and jobs.
- Route analysis through AgentsHub/AiModelsHub.
- Generate ContactPersona, ContactTalkSpecs, emotional baseline, topics, and suggested memories.
- Add findings review and apply/rollback.

### Phase 4 - Memory Maintenance

- Add maintenance run model and jobs.
- Implement rebuild, prune, dedupe, re-embed, stale scan, conflict scan, export, and erase.
- Add global/contact maintenance modal.

### Phase 5 - Proactive And Workflow Integration

- Emit contact message and profile events.
- Allow workflows to trigger on ContactHub events.
- Connect ProactiveAIHub rules to reply modes and contact safety rules.
- Add approval queues and autonomous reply audit.

