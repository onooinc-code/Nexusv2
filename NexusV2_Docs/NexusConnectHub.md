# NexusConnect Hub - Technical Specification

**Project**: Nexus V2
**Status**: Pending Review
**Target Location**: `NexusV2_Docs/NexusConnectHub.md`

## 1. Executive Summary

"NexusConnect" is a new central unified hub designed to serve as the migration bridge from the legacy "PeopleConnect" system to the advanced "Hedrasoul" ecosystem. This hub acts as the primary interface for:
- Interacting with the Personal AI Agent.
- Communicating with human Contacts seamlessly.
- Enabling and monitoring Agent-to-Contact interactions.
- Providing a consolidated module collection for full Nexus system management.

---

## 2. Hub Features and Functional Requirements

### 2.1 Migration Bridge (PeopleConnect -> Hedrasoul)
- **Data Mapping**: Seamlessly migrate legacy contacts and historical conversations from PeopleConnect.
- **Phased Rollout**: Allow parallel usage during the transition phase, ensuring no data loss.
- **Entity Resolution**: Deduplicate and enrich contact profiles using the new Hedrasoul intelligence engine.

### 2.2 Agent Interaction Protocols
- **Manual Oversight**: Real-time monitoring of AI interactions with contacts.
- **Copilot Mode**: Hédra can review, edit, or approve AI-generated drafts before they are dispatched.
- **Autonomous Mode**: Full agent autonomy based on defined rules and contact intelligence logic.
- **Handoff Mechanism**: Smooth transition from AI-driven to Human-driven communication without losing context.

### 2.3 System Management Modules
- **Contact Management**: Centralized address book with tagging, relationship graphing, and memory contexts.
- **Workflow & Task Oversight**: Visual dashboards for pending tasks and automated follow-ups.
- **AI Settings Configuration**: Toggles for AI model selection, persona tuning, and tone matching.

---

## 3. UI/UX and Component Specifications

### 3.1 Interface Layouts
- **Three-Pane Layout**:
  - **Left Sidebar**: Navigation (Contacts, AI Settings, Workflows) and active conversation list.
  - **Main Content Area**: Active chat/thread interface (Messages, Notes, Tasks).
  - **Right Sidebar (Context Pane)**: Contact profile intelligence, active Agent status, historical context, and sentiment baseline.

### 3.2 Component Architecture (Next.js 15)
- **`HubLayout`**: The outer shell providing state context (Zustand).
- **`AgentStatusWidget`**: Real-time indicator of the AI Agent's current activity (thinking, responding, idle).
- **`ThreadView`**: Highly performant virtualized list rendering conversations, supporting message types (user, agent, contact).
- **`ContextPanel`**: Displays structured, semantic, and episodic memories tied to the active contact.
- **`Composer`**: Unified input area allowing toggling between "Send as Hédra" and "Prompt AI Agent".

### 3.3 User Experience Flows
- **Real-time Indicators**: Typing indicators for Contacts and "Thinking" indicators for the AI.
- **Visual Distinction**: Messages sent by the AI Agent have a distinct visual style (e.g., subtle border or different background) compared to manual messages.
- **Error States**: Clear visual cues with "Retry" options for failed message dispatches.

---

## 4. Backend Architecture and Data Synchronization

To ensure high performance and reliability, the UI will strictly read from and write to the local database, serving as the single source of truth, rather than directly hitting the WAHA API.

### 4.1 Background Job Scheduler (WAHA API Polling)
A recurring background job will ensure synchronization with the WhatsApp engine.
- **Schedule**: Runs every hour.
- **Target API**: WAHA API (`http://156.67.27.156:3000/`)
- **Authentication**: Key: `key123`
- **Session ID**: `default`
- **Responsibilities**: Fetch missing/new Contacts, Conversations, and Messages to reconcile any gaps from missed webhooks.

### 4.2 Database Schema Architecture
The persistence layer (PostgreSQL) will encompass:
- **`Contacts`**: `id`, `waha_id`, `name`, `phone`, `metadata`, `engagement_score`.
- **`Topics`**: `id`, `name`, `description`, `created_at`.
- **`Conversations`**: `id`, `contact_id`, `topic_id`, `status`, `last_activity`.
- **`Sessions`**: `id`, `conversation_id`, `started_at`, `ended_at`.
- **`Messages`**: `id`, `conversation_id`, `sender_type` (user, agent, contact), `content`, `status` (pending, sent, failed, delivered), `waha_message_id`.

### 4.3 Real-time Data Architecture
- **Source of Truth**: The frontend UI subscribes exclusively to the Nexus database via Laravel Reverb (WebSockets).
- **Flow**: UI → Backend DB → Queue → WAHA API.
- **Benefit**: Ensures zero UI blocking and immediate state reflection for the user.

### 4.4 Asynchronous Messaging Workflow
Outgoing messages are processed via Laravel Queues.
1. **Creation**: Message is stored in the DB with status `pending`.
2. **Queueing**: A `DispatchWahaMessageJob` is dispatched.
3. **Execution**: The job calls the WAHA API.
4. **Update**: Upon WAHA API response, DB status updates to `sent` (or `failed`).
5. **Broadcast**: Laravel Reverb pushes the status update to the frontend.

### 4.5 Webhook Integration Strategy
To handle real-time incoming data:
- **Endpoint**: `/api/v1/webhooks/waha` receives events from WAHA.
- **Event Types**: Handles `message`, `message.ack`, and `state` events.
- **Processing**: 
  1. Validates payload.
  2. Updates DB (creates Contact/Message or updates Message status to `delivered`/`read`).
  3. Triggers standard incoming message pipelines (Memory extraction, AI Agent routing).
  4. Broadcasts updates via WebSockets to the UI.
