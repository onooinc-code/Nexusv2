# Nexus Backend - Comprehensive Architecture Analysis

## Executive Summary

Nexus is a sophisticated Laravel 11 application designed to manage intelligent contact relationships, conversations, AI agents, workflows, and comprehensive memory management. The architecture follows enterprise patterns with clear separation of concerns, event-driven processing, and multi-channel communication capabilities.

**Tech Stack:**
- Framework: Laravel 11.31
- Language: PHP 8.2+
- Queue: Database-based (Redis-capable) with Horizon monitoring
- Real-time: Laravel Reverb for WebSocket communication
- Authentication: Laravel Sanctum (API tokens)
- Cache/Memory: Redis (Predis client)

---

## 1. DIRECTORY STRUCTURE & PURPOSE

### **app/Models** - Data Models & Relationships
Central to the application, defining all database entities and their relationships.

**Key Models:**

| Model | Purpose | Relationships |
|-------|---------|---------------|
| **User** | Authentication & authorization | Owns contacts, logs, settings |
| **Contact** | Individual/entity representation | Conversations, notes, tags, rules, memories, identifiers, relationships, preferences |
| **Conversation** | Multi-party communication thread | Contact, Topic, Messages, Sessions |
| **Message** | Individual message in conversation | Conversation (single-sided) |
| **Topic** | Subject categorization | Conversations |
| **Memory** | Episodic knowledge storage | Contact, Conversation |
| **Agent** | AI agent definition | Tools, Skills, Tasks |
| **AgentTask** | Task execution unit | Agent, Workflow, TaskSteps |
| **AgentTool** | Callable agent capability | Agent |
| **AgentSkill** | Agent expertise module | Agent |
| **Workflow** | Multi-step automation | Tasks, Steps |
| **AIModel** | AI model metadata | Providers, Capabilities |
| **AIProvider** | LLM provider config | Models, API Keys |
| **ApiKey** | Encrypted API credentials | AIProvider |
| **ContactIdentifier** | Multi-type contact lookup | Contact (email, phone, external_id) |
| **ContactRelationship** | Contact-to-contact links | Contact |
| **ContactRule** | Conditional contact behavior | Contact |
| **ContactNote** | Annotated contact information | Contact, User |
| **ContactTag** | Contact categorization | Contact |
| **ContactCustomField** | Extensible contact attributes | Contact |
| **ContactAlias** | Alternative contact names | Contact |
| **ContactPreference** | Communication preferences | Contact |
| **NotificationLog** | Notification dispatch tracking | Contact, Template |
| **NotificationTemplate** | Notification message formats | - |
| **ConversationSession** | Session instance in conversation | Conversation |
| **Log** | Application event logging | - |
| **SystemLog** | System-level audit trails | - |
| **UsageLog** | Feature/API usage tracking | - |
| **IntentRouting** | AI request intent mapping | - |
| **SchedulerJob** | Scheduled task definitions | - |
| **Setting** | Global application settings | - |

**Base Model Pattern:**
All models extend `BaseModel` which provides:
- Automatic UUID generation
- JSON column support (metadata, attributes, settings, config)
- Common scopes: `byStatus()`, `active()`, `inactive()`
- Consistent timestamp handling
- JSON attribute helpers

**Key Design Patterns:**
- **Soft Deletes**: Contact model uses soft deletes for data preservation
- **JSON Columns**: Flexible metadata storage (contacts, conversations, agents, workflows)
- **Enum-like Constants**: Status/type constants on models (Agent::TYPE_REFLECTION, Contact::TYPE_CLIENT, etc.)
- **Polymorphic Relationships**: Messages support multiple sender types

---

### **app/Http/Controllers** - API Request Handlers

**Controller Hierarchy & Responsibilities:**

```
Controllers/
├── AuthController
│   ├── login() → Token-based authentication
│   ├── register() → New user creation
│   ├── verifyToken() → Token validation
│   ├── logout() → Token revocation
│   └── refreshToken() → Token rotation
│
├── ContactController
│   ├── index() → Paginated contact listing with search/filter
│   ├── store() → Contact creation with idempotency
│   ├── import() → Bulk contact import
│   ├── export() → Bulk contact export
│   ├── getMemory() → Contact's memory retrieval
│   ├── getRules() → Contact's automation rules
│   ├── timeline() → Contact activity timeline
│   ├── getAnalytics() → Contact analytics
│   ├── merge() → Duplicate contact merging
│   ├── enrich() → Data enrichment
│   └── erase() → GDPR-compliant deletion
│
├── ContactIdentifierController
│   └── Nested resource routes for managing contact identifiers
│
├── ContactRelationshipController
│   └── Nested resource routes for contact relationships
│
├── ContactPreferenceController
│   └── Communication preference management
│
├── ContactAliasController
│   └── Alternative contact name management
│
├── ContactNoteController
│   └── Annotated note management
│
├── ConversationController
│   ├── resource routes (CRUD)
│   ├── getMessages() → Message history
│   └── sendMessage() → Message dispatch
│
├── AgentController
│   ├── index() → List with filtering by type/status
│   ├── store() → Agent creation
│   ├── show() → Agent details with configuration
│   ├── update() → Agent modification
│   ├── execute() → Agent execution trigger
│   └── getStatus() → Execution status
│
├── WorkflowController
│   ├── resource routes
│   ├── getTemplates() → Workflow templates
│   ├── execute() → Workflow execution
│   └── getProgress() → Execution progress
│
├── TaskController
│   ├── resource routes
│   ├── getStats() → Task statistics
│   ├── getActive() → Active task listing
│   ├── getQueueStats() → Queue metrics
│   ├── getRoutingStats() → Routing analytics
│   ├── cancel() → Task cancellation
│   ├── pause() → Task suspension
│   └── resume() → Task resumption
│
├── AiModelController
│   ├── Model CRUD operations
│   ├── execute() → Single model execution
│   ├── executeWithFallback() → Fallback chain execution
│   ├── selectModel() → Model selection
│   ├── optimizeCost() → Cost-optimized routing
│   ├── routeByQuality() → Quality-optimized routing
│   ├── routeBySpeed() → Speed-optimized routing
│   ├── providers() → Available provider listing
│   ├── keyPoolStatus() → API key pool health
│   ├── keyHealth() → Individual key status
│   ├── rateLimitStatus() → Rate limit tracking
│   └── budgetStatus() → Budget tracking
│
├── AiProviderController
│   ├── store() → Provider registration
│   ├── test() → Provider connectivity test
│   └── syncModels() → Model list sync
│
├── AiRequestController
│   ├── getRoutingMatrix() → Intent routing rules
│   ├── routeIntent() → Intent routing update
│   └── handleRequest() → Request routing
│
├── MemoryController
│   ├── resource routes
│   ├── search() → Semantic memory search
│   └── indexMemory() → Memory indexing
│
├── NotificationController
│   ├── Templates: CRUD
│   ├── Logs: listing and retry
│   └── send() → Notification dispatch
│
├── WorkflowController
│   └── Automation workflow management
│
├── SchedulerController
│   └── Scheduler job management
│
├── DashboardController
│   └── Dashboard data aggregation
│
├── ProfileController
│   └── User profile management
│
├── SettingController
│   └── Global setting management
│
├── LogController
│   └── Application log retrieval
│
├── StatsController
│   ├── usage() → Feature usage statistics
│   └── dashboard() → Dashboard metrics
│
├── ProactiveAIController
│   └── Proactive AI triggers and actions
│
├── WebhookController
│   └── handleWahaWebhook() → WhatsApp integration
│
├── Admin/
│   ├── DlqController (Dead Letter Queue management)
│   └── Other admin operations
│
└── Monitoring/
    ├── HealthController (System health checks)
    └── MetricsController (Performance metrics)
```

**Key Architectural Patterns:**
- **Dependency Injection**: Constructor injection of services
- **Idempotency**: X-Idempotency-Key header support (Contact creation)
- **Validation**: Form request validation with custom rules
- **Pagination**: Default 20 items per page, customizable
- **Status Codes**: RESTful HTTP codes (201 for creation, 422 for validation)
- **Query Filtering**: Dynamic query building based on request parameters

---

### **app/Services** - Business Logic Orchestration

Services provide the core business logic, separated from controllers for testability and reusability.

**Service Architecture:**

```
Services/
├── AGENT MANAGEMENT
│   ├── AgentConfigurationService
│   │   ├── load(Agent) → Load merged config
│   │   ├── get/set() → Individual setting access
│   │   ├── update() → Bulk config update
│   │   ├── reset() → Reset to defaults
│   │   └── validate() → Config validation
│   │
│   ├── AgentLifecycleService
│   │   ├── initialize() → Setup agent execution
│   │   ├── start() → Begin execution
│   │   ├── complete() → Mark successful completion
│   │   └── fail() → Handle execution failure
│   │
│   ├── AgentRegistry
│   │   ├── register(type, class) → Register agent type
│   │   ├── resolve(Agent) → Get agent instance
│   │   ├── all() → List all types
│   │   └── clearCache() → Clear singleton cache
│   │
│   ├── AgentSkillLibrary
│   │   └── Manage agent skills and capabilities
│   │
│   ├── AgentToolExecutor
│   │   └── Execute agent tool/capability
│   │
│   └── AgentToolRegistry
│       └── Register and manage available tools
│
├── WORKFLOW MANAGEMENT
│   ├── WorkflowExecutor
│   │   ├── execute(Workflow, context) → Execute workflow
│   │   ├── executeStep() → Single step execution
│   │   ├── retryStep() → Step retry logic
│   │   └── Returns: success, iterations, logs
│   │
│   ├── WorkflowValidationService
│   │   ├── validateStep() → Validate step config
│   │   └── validateWorkflow() → Full workflow validation
│   │
│   └── WorkflowErrorHandler
│       ├── handleStepFailure() → Error handling logic
│       └── determine: retry, abort, continue
│
├── TASK MANAGEMENT
│   ├── TaskQueueService
│   │   └── Queue task dispatch and monitoring
│   │
│   ├── TaskRoutingService
│   │   └── Route tasks to appropriate handlers
│   │
│   ├── TaskLogService
│   │   └── Log task execution details
│   │
│   └── TaskRetryService
│       └── Manage task retries and backoff
│
├── MEMORY SYSTEM
│   ├── MemoryRouter
│   │   └── Route memory to appropriate storage type
│   │
│   ├── EpisodicMemoryService
│   │   └── Event-based memory storage
│   │
│   ├── SemanticMemoryService
│   │   └── Meaning-based memory storage
│   │
│   ├── StructuredMemoryService
│   │   └── Fact-based memory storage
│   │
│   ├── GraphMemoryService
│   │   └── Relationship-based memory storage
│   │
│   ├── WorkingMemoryService
│   │   └── Transient execution context
│   │
│   ├── MemorySummaryService
│   │   └── Memory aggregation and summarization
│   │
│   └── MemoryMaintenanceService
│       ├── Expiration handling
│       ├── Consolidation
│       └── Cleanup
│
├── MESSAGING & NOTIFICATIONS
│   ├── NotificationService
│   │   ├── send() → Dispatch notification
│   │   ├── sendEmail() → Email channel
│   │   ├── sendSms() → SMS channel (Twilio)
│   │   ├── sendWhatsApp() → WhatsApp channel
│   │   └── sendPush() → Push notification channel
│   │
│   └── ContactHubService
│       ├── createContact() → Contact creation
│       ├── mergeContacts() → Duplicate resolution
│       ├── enrichContact() → Data enrichment
│       └── eraseContact() → GDPR deletion
│
├── AI/LLM MANAGEMENT
│   ├── AI/OpenAIProvider
│   │   ├── generateText() → Text generation
│   │   ├── chatCompletion() → Chat API
│   │   ├── loadModelsFromDatabase() → Model sync
│   │   └── validateRequest() → Input validation
│   │
│   ├── AI/GoogleGeminiProvider
│   │   └── Similar interface to OpenAI
│   │
│   ├── AI/AnthropicProvider
│   │   └── Claude model integration
│   │
│   ├── AI/GroqProvider
│   │   └── Groq API integration
│   │
│   ├── AiModelsHub/ModelSelector
│   │   ├── selectByCapability() → Find by feature
│   │   ├── selectBySpeed() → Fastest model
│   │   └── selectByCost() → Cheapest model
│   │
│   ├── AiModelsHub/CostOptimizer
│   │   ├── estimateCost() → Cost prediction
│   │   └── optimizeRoute() → Cost minimization
│   │
│   ├── AiModelsHub/FallbackChainService
│   │   ├── buildChain() → Create fallback chain
│   │   └── execute() → Try models in sequence
│   │
│   ├── AiModelsHub/ApiKeyRotationService
│   │   ├── rotateKey() → Change active key
│   │   └── markExpired() → Mark as expired
│   │
│   ├── AiModelsHub/ApiKeyPool
│   │   ├── register() → Add API key
│   │   ├── getHealthStatus() → Key health check
│   │   └── selectBestKey() → Pick optimal key
│   │
│   ├── AiModelsHub/ApiKeyHealthService
│   │   └── Check API key validity and limits
│   │
│   ├── AiModelsHub/RateLimitService
│   │   └── Track and enforce rate limits
│   │
│   ├── AiModelsHub/QualityRouter
│   │   └── Route by quality metrics (accuracy, coherence)
│   │
│   └── AiModelsHub/SpeedRouter
│       └── Route by latency/speed metrics
│
├── MESSAGE ROUTING
│   ├── Routing/MessageRouter
│   │   └── Route incoming messages
│   │
│   ├── Routing/TaskRouter
│   │   └── Route tasks to handlers
│   │
│   ├── Routing/ToneRouter
│   │   └── Route by emotional/tonal analysis
│   │
│   └── Routing/MemoryRouter
│       └── Route to appropriate memory system
│
├── PIPELINE PROCESSING
│   ├── Pipelines/ContextAssemblyPipeline
│   │   └── Build execution context
│   │
│   ├── Pipelines/MemoryExtractionPipeline
│   │   └── Extract and process memories
│   │
│   ├── Pipelines/ResponseDeliveryPipeline
│   │   └── Format and deliver responses
│   │
│   ├── Pipelines/PipelineErrorHandler
│   │   └── Handle pipeline failures
│   │
│   └── Pipelines/PipelineMonitor
│       └── Monitor pipeline performance
│
├── PROACTIVE AI
│   ├── Proactive/
│   │   └── Proactive behavior triggers
│   │
└── UTILITY SERVICES
    ├── LogService
    │   ├── info/warning/error() → Log events
    │   └── Supports channel-specific logging
    │
    ├── AlertService
    │   └── Alert generation and dispatch
    │
    ├── CircuitBreakerService
    │   └── Fault tolerance pattern implementation
    │
    ├── IdempotencyService
    │   └── Idempotent request handling
    │
    ├── RelationshipGraphService
    │   └── Contact relationship analysis
    │
    ├── PreferenceExtractionService
    │   └── Extract contact preferences
    │
    ├── EmotionBaselineService
    │   └── Emotional tone analysis
    │
    ├── MCPIntegrationService
    │   └── MCP (Model Context Protocol) integration
    │
    ├── SettingCacheService
    │   └── Settings caching layer
    │
    └── Mem0Integration.php
        └── Mem0 memory platform integration
```

**Key Design Patterns:**
- **Service Locator**: Services injected via constructor
- **Single Responsibility**: Each service handles one concern
- **Provider Pattern**: Multiple AI provider implementations
- **Chain of Responsibility**: Fallback chains for resilience
- **Pipeline Pattern**: Processing pipelines for complex operations
- **Router Pattern**: Dynamic routing of messages/tasks

---

### **app/Agents** - Intelligent Agent Types

Represents different agent architectures and execution strategies:

```
Agents/
├── ReflectionAgent
│   ├── Self-analyzing agent
│   ├── Reflects on decisions and results
│   └── Improves through iteration
│
├── TeamAgent
│   ├── Multi-agent coordination
│   ├── Delegates to specialized agents
│   └── Aggregates results
│
├── AutonomousAgent
│   ├── Independent task execution
│   ├── Self-directed with max_execution_time limit
│   ├── Iteration-based loop (1-10 iterations typically)
│   ├── Can signal completion or stop
│   └── Returns: success, iterations, execution log
│
├── SpecializedAgent
│   ├── Domain-specific expertise
│   ├── Focused task execution
│   └── High accuracy in narrow domains
│
└── SupervisorAgent
    ├── Orchestrates multiple agents
    ├── Manages workflow execution
    ├── Handles error recovery
    └── Aggregates and validates results
```

**Execution Pattern:**
```php
$agent = Agent::find($id);
$lifecycle->initialize($agent);  // Set to RUNNING
$result = $agent->execute($context);
if ($result['success']) {
    $lifecycle->complete($agent);  // Set to COMPLETED
} else {
    $lifecycle->fail($agent, $error);  // Set to ERROR
}
```

---

### **app/Jobs** - Background Queue Jobs

Asynchronous task processing using Laravel's queue system:

```
Jobs/
├── BaseJob (Abstract)
│   ├── logJobStart()
│   ├── logJobComplete()
│   ├── logJobFailure()
│   ├── idempotency key support
│   ├── circuit breaker integration
│   └── Retry configuration: $tries, $timeout, $backoff
│
├── ExecuteAiModelJob
│   ├── Queue: llm-inference
│   ├── Timeout: 600s
│   ├── Tries: 3
│   ├── Executes LLM with specific provider/model
│   ├── Fires: AiModelExecutionCompleted event
│   ├── Idempotency: "execute_ai_model:{user}:{execution_id}"
│   └── Returns: success, duration_ms, result
│
├── ProcessAiInferenceJob
│   ├── Process AI model output
│   └── Post-processing and validation
│
├── ExtractMemoryJob
│   ├── Extract memories from content
│   ├── Parse and structure data
│   └── Store in memory system
│
├── SaveToPineconeJob
│   ├── Vector database storage
│   ├── Pinecone integration
│   └── Semantic search enablement
│
├── VectorizeMemoryJob
│   ├── Generate vector embeddings
│   ├── Prepare for semantic search
│   └── Store in vector database
│
├── SyncMemoryJob
│   ├── Synchronize memory across systems
│   ├── Update graph and semantic memory
│   └── Maintain consistency
│
└── TestJob
    └── Test job for queue system
```

**Queue Configuration:**
- **Driver**: Database-based (configurable to Redis, SQS)
- **Default Connection**: `database`
- **Retry After**: 90 seconds
- **Custom Queues**: 
  - `llm-inference` (AI model execution)
  - `messages` (Message processing)
  - `memory` (Memory operations)
  - `default` (Other jobs)

**Job Lifecycle:**
```
Dispatch → Queued → Processing → Complete/Failed
                        ↓
                    Retry (if fails)
```

---

### **app/Listeners** - Event Handlers

Event-driven architecture for decoupled processing:

```
Listeners/
├── ProcessContactCreated
│   ├── Triggered: ContactCreated event
│   ├── Actions: Initialize contact memory
│   └── Dispatch: Memory extraction job
│
├── ProcessMessageReceived
│   ├── Triggered: MessageReceived event
│   ├── Queued: true (messages queue)
│   ├── Actions: Extract and index memory
│   └── Handled via background jobs
│
├── ContactMessageReceivedListener
│   ├── Contact-specific message handling
│   ├── Preference checks
│   └── Notification triggers
│
├── IndexMemory
│   ├── Triggered: MemoryIndexed event
│   ├── Actions: Index in semantic database
│   └── Enable vector search
│
├── LogWorkflowStarted
│   ├── Log workflow initiation
│   └── Audit trail
│
├── LogWorkflowStepCompleted
│   ├── Log individual step completion
│   └── Track progress
│
├── LogWorkflowCompleted
│   ├── Log workflow completion
│   ├── Update statistics
│   └── Trigger notifications
│
├── LogJobFailed
│   ├── Log job failures
│   ├── Alert on repeated failures
│   └── Dead letter queue handling
│
└── NotifyJobFailed
    ├── Send notifications on job failure
    ├── Alert appropriate parties
    └── Incident tracking
```

**Event System Architecture:**
- **Broadcast Events**: Real-time updates via Reverb
- **Queued Listeners**: Async processing where appropriate
- **Event Payload**: Carries necessary context for handlers

---

### **app/Repositories** - Data Access Layer

Abstraction over Eloquent ORM:

```
Repositories/
└── MemoryRepository
    ├── findByContact()
    ├── findByConversation()
    ├── searchBySemantic()
    ├── store()
    └── update()
```

**Note**: Repository pattern lightly used; mostly direct Eloquent queries in services and controllers.

---

### **app/Policies** - Authorization Rules

Role-based and permission-based authorization:

```
Policies/
└── SessionPolicy
    ├── view()
    ├── create()
    ├── update()
    └── delete()
```

---

### **app/Hubs** - Feature Hubs

Aggregate related functionality:

```
Hubs/
└── AIModelsHub.php
    ├── Manages AI model selection
    ├── Provider coordination
    ├── Cost and speed optimization
    ├── API key management
    └── Rate limiting
```

---

### **app/Integrations** - External Service Integration

```
Integrations/
└── Mem0Integration.php
    ├── Mem0 memory platform
    ├── External memory persistence
    ├── Sync and retrieval
    └── Cross-system memory sharing
```

---

### **app/Console/Commands** - Artisan Commands

```
Console/Commands/
├── MonitorReverbHealth
│   └── Monitor WebSocket health
│
├── ProactiveSchedulerCommand
│   └── Trigger proactive AI actions
│
└── SchedulerWorker
    └── Scheduled job worker
```

---

### **config/** - Application Configuration

**Key Configuration Files:**

1. **auth.php** - Authentication Configuration
   - Guard: Session (web), API (Sanctum)
   - Provider: Eloquent User model
   - No password reset (token-based auth)

2. **queue.php** - Queue Configuration
   - Default: database
   - Supports: Redis, SQS, Beanstalkd
   - Retry after: 90 seconds

3. **app.php** - Application Settings
   - Debug mode: Configurable
   - Environment: production/development
   - Name: "Nexus"

4. **broadcasting.php** - Real-time Configuration
   - Driver: Reverb
   - WebSocket server configuration
   - Broadcasting channel auth

5. **cache.php** - Caching Configuration
   - Default: file/redis
   - TTL settings

6. **database.php** - Database Configuration
   - Default: mysql
   - Multi-connection support

7. **horizon.php** - Queue Monitoring
   - Horizon dashboard configuration
   - Job monitoring

8. **reverb.php** - WebSocket Configuration
   - Reverb server settings
   - Real-time broadcast configuration

---

### **database/migrations/** - Schema Evolution

**Migration Timeline (Newest to Oldest):**

| File | Purpose |
|------|---------|
| 2026_05_24_233351_create_proactive_ai_tables.php | Proactive AI triggers and actions |
| 2026_05_24_080000_create_contacts_and_notifications_hubs_tables.php | Contact & Notification hubs |
| 2026_05_24_000000_create_scheduler_jobs_table.php | Scheduled job definitions |
| 2026_05_19_000005_create_usage_logs_table.php | API/feature usage tracking |
| 2026_05_19_000004_create_intent_routing_table.php | Intent-to-handler mapping |
| 2026_05_19_000003_create_ai_api_keys_table.php | Encrypted API keys |
| 2026_05_19_000002_update_ai_models_table.php | AI model enhancements |
| 2026_05_19_000001_create_ai_providers_table.php | AI provider configuration |
| 2026_05_17_151413_add_description_column_to_settings_table.php | Settings enhancement |
| 2026_05_17_150326_add_missing_columns_to_agent_tasks_table.php | Task table fix |
| 2026_05_17_150325_create_workflows_table.php | Workflow definitions |
| 2026_05_17_145955_add_missing_columns_to_agents_table.php | Agent table enhancement |
| 2026_05_17_100000_create_graph_memory_tables.php | Graph-based memory (relationships) |
| 2026_05_17_090000_create_structured_memories_table.php | Structured memory storage |
| 2026_05_17_080000_create_phase_02_database_models.php | Core models (contacts, messages, etc.) |
| 2026_05_17_080001_create_cache_table.php | Cache table for sessions |
| 2026_05_17_000000_create_users_table.php | User authentication |

**Schema Structure:**

The Phase 02 migration creates:
- `contacts` - Contact entities with identifiers and metadata
- `topics` - Conversation topics
- `conversations` - Multi-party threads
- `conversation_sessions` - Session instances
- `messages` - Individual messages with multi-channel support
- `contact_rules` - Automation rules
- `contact_notes` - Annotations
- `contact_tags` - Categorization
- `contact_custom_fields` - Extensibility
- `memories` - Knowledge storage with vectors
- `agents` - Agent definitions with execution tracking
- `agent_tools` - Tool/capability registry
- `agent_skills` - Skill definitions
- `agent_tasks` - Task execution units
- `task_steps` - Task step progression
- `workflows` - Automation workflows
- `ai_models` - LLM metadata
- `ai_providers` - LLM provider configuration
- `api_keys` - Encrypted API credentials
- `intent_routing` - Intent-to-model mapping
- `usage_logs` - Feature usage tracking

---

## 2. API ENDPOINTS STRUCTURE

### **Authentication Endpoints** (Public)
```
POST   /api/v1/login                      → Token-based login
POST   /api/v1/register                   → User registration
POST   /api/v1/verify-token               → Token verification
```

### **Health & Monitoring** (Public)
```
GET    /api/v1/health                     → Basic health check
GET    /api/v1/monitoring/health          → Detailed health
GET    /api/v1/monitoring/health/reverb   → WebSocket health
GET    /api/v1/monitoring/health/queue    → Queue health
GET    /api/v1/monitoring/metrics         → Performance metrics
GET    /api/v1/monitoring/metrics/websocket → WebSocket metrics
```

### **Webhooks** (Public)
```
POST   /api/v1/webhooks/waha              → WhatsApp WAHA integration
```

### **Contacts Hub** (Protected)
```
GET    /api/v1/contacts                   → List contacts (paginated)
POST   /api/v1/contacts                   → Create contact
GET    /api/v1/contacts/{id}              → Get contact details
PUT    /api/v1/contacts/{id}              → Update contact
DELETE /api/v1/contacts/{id}              → Delete contact

POST   /api/v1/contacts/import            → Bulk import
GET    /api/v1/contacts/export            → Bulk export
GET    /api/v1/contacts/{id}/memory       → Contact memories
GET    /api/v1/contacts/{id}/rules        → Contact rules
GET    /api/v1/contacts/{id}/timeline     → Activity timeline
GET    /api/v1/contacts/{id}/analytics    → Contact analytics
POST   /api/v1/contacts/{id}/merge        → Merge duplicates
DELETE /api/v1/contacts/{id}/erase        → GDPR erasure
POST   /api/v1/contacts/{id}/enrich       → Data enrichment

# Nested resources
GET    /api/v1/contacts/{contact}/identifiers
POST   /api/v1/contacts/{contact}/identifiers
GET    /api/v1/contacts/{contact}/relationships
POST   /api/v1/contacts/{contact}/relationships
GET    /api/v1/contacts/{contact}/preferences
POST   /api/v1/contacts/{contact}/preferences
GET    /api/v1/contacts/{contact}/aliases
POST   /api/v1/contacts/{contact}/aliases
GET    /api/v1/contacts/{contact}/notes
POST   /api/v1/contacts/{contact}/notes
```

### **Conversations Hub** (Protected)
```
GET    /api/v1/conversations              → List conversations
POST   /api/v1/conversations              → Create conversation
GET    /api/v1/conversations/{id}         → Get conversation
PUT    /api/v1/conversations/{id}         → Update conversation
DELETE /api/v1/conversations/{id}         → Delete conversation
GET    /api/v1/conversations/{id}/messages → Get message history
POST   /api/v1/conversations/{id}/send-message → Send message
```

### **Notifications Hub** (Protected)
```
GET    /api/v1/notifications/templates    → List templates
POST   /api/v1/notifications/templates    → Create template
GET    /api/v1/notifications/logs         → Notification logs
POST   /api/v1/notifications/send         → Send notification
POST   /api/v1/notifications/{id}/retry   → Retry notification
```

### **Agents Hub** (Protected)
```
GET    /api/v1/agents                     → List agents
POST   /api/v1/agents                     → Create agent
GET    /api/v1/agents/{id}                → Get agent
PUT    /api/v1/agents/{id}                → Update agent
DELETE /api/v1/agents/{id}                → Delete agent
POST   /api/v1/agents/{id}/execute        → Execute agent
GET    /api/v1/agents/{id}/status         → Get execution status
```

### **Workflows Hub** (Protected)
```
GET    /api/v1/workflows/templates        → Get templates
GET    /api/v1/workflows                  → List workflows
POST   /api/v1/workflows                  → Create workflow
GET    /api/v1/workflows/{id}             → Get workflow
PUT    /api/v1/workflows/{id}             → Update workflow
DELETE /api/v1/workflows/{id}             → Delete workflow
POST   /api/v1/workflows/{id}/execute     → Execute workflow
GET    /api/v1/workflows/{id}/progress    → Get execution progress
```

### **Tasks Hub** (Protected)
```
GET    /api/v1/tasks/stats                → Task statistics
GET    /api/v1/tasks/active               → Active tasks
GET    /api/v1/tasks/queue-stats          → Queue statistics
GET    /api/v1/tasks/routing-stats        → Routing statistics
GET    /api/v1/tasks                      → List tasks
POST   /api/v1/tasks                      → Create task
GET    /api/v1/tasks/{id}                 → Get task
PUT    /api/v1/tasks/{id}                 → Update task
DELETE /api/v1/tasks/{id}                 → Delete task
POST   /api/v1/tasks/{id}/cancel          → Cancel task
POST   /api/v1/tasks/{id}/pause           → Pause task
POST   /api/v1/tasks/{id}/resume          → Resume task
```

### **Memory Hub** (Protected)
```
GET    /api/v1/memories/search            → Semantic search
POST   /api/v1/memories/{id}/index        → Index memory
GET    /api/v1/memories                   → List memories
POST   /api/v1/memories                   → Create memory
GET    /api/v1/memories/{id}              → Get memory
PUT    /api/v1/memories/{id}              → Update memory
DELETE /api/v1/memories/{id}              → Delete memory
```

### **AI Models Hub** (Protected)
```
POST   /api/v1/ai-models/execute                    → Execute single model
POST   /api/v1/ai-models/execute-with-fallback      → Fallback execution
POST   /api/v1/ai-models/select                     → Select model by criteria
POST   /api/v1/ai-models/optimize-cost              → Cost optimization
POST   /api/v1/ai-models/route-quality              → Quality-based routing
POST   /api/v1/ai-models/route-speed                → Speed-based routing
GET    /api/v1/ai-models/providers                  → List providers
GET    /api/v1/ai-models/key-pool                   → API key pool status
GET    /api/v1/ai-models/key-health                 → Key health check
GET    /api/v1/ai-models/rate-limits                → Rate limit status
GET    /api/v1/ai-models/rotation-schedule          → Key rotation schedule
POST   /api/v1/ai-models/rotate-expired             → Rotate expired keys
GET    /api/v1/ai-models/fallback-chain             → Fallback chain status
GET    /api/v1/ai-models/budget                     → Budget status
GET    /api/v1/ai-models                            → List models
POST   /api/v1/ai-models                            → Create model
GET    /api/v1/ai-models/{id}                       → Get model
PUT    /api/v1/ai-models/{id}                       → Update model
DELETE /api/v1/ai-models/{id}                       → Delete model
POST   /api/v1/ai-models/{id}/test                  → Test model
```

### **AI Providers Hub** (Protected)
```
POST   /api/v1/ai/providers                         → Register provider
POST   /api/v1/ai/providers/{id}/test               → Test provider
POST   /api/v1/ai/providers/{id}/sync-models        → Sync models
GET    /api/v1/ai/intents/routing                   → Get routing matrix
PUT    /api/v1/ai/intents/routing                   → Update routing
POST   /api/v1/ai/request                           → Handle AI request
```

### **Settings Hub** (Protected)
```
GET    /api/v1/settings                   → Get all settings
POST   /api/v1/settings                   → Create setting
GET    /api/v1/settings/{id}              → Get setting
PUT    /api/v1/settings/{id}              → Update setting
DELETE /api/v1/settings/{id}              → Delete setting
```

### **Statistics Hub** (Protected)
```
GET    /api/v1/stats/usage                → Feature usage
GET    /api/v1/stats/dashboard            → Dashboard metrics
```

### **Admin Endpoints** (Protected - Admin policy)
```
GET    /api/v1/admin/dlq                  → Dead letter queue
POST   /api/v1/admin/dlq/{id}/retry       → Retry DLQ message
DELETE /api/v1/admin/dlq/{id}             → Delete DLQ message
POST   /api/v1/admin/dlq/batch-retry      → Batch retry DLQ
```

---

## 3. AUTHENTICATION & AUTHORIZATION

### **Authentication Mechanism**

**Type**: Token-Based (Laravel Sanctum)

**Flow**:
```
User Credentials → Login → Generate Token → Client stores token
Client Request + Token → Request validated → Grant access
```

**Implementation**:
- **Controller**: `AuthController`
- **Model**: `User` (Authenticatable)
- **Trait**: `HasApiTokens` (from Sanctum)
- **Guard**: `sanctum` (for API routes)
- **Middleware**: `auth:sanctum` (on protected routes)

**Token Management**:
```php
$token = $user->createToken('auth-token')->plainTextToken;
// Token format: {$tokenId}|{$tokenHash}

// Verification
$request->user()  // Get authenticated user

// Revocation
$request->user()->currentAccessToken()->delete();
$request->user()->tokens()->delete();  // All tokens
```

### **Authorization Mechanisms**

**1. Policy-Based Authorization**
```php
Route::middleware(['can:viewDlq'])->group(function () {
    // Protected endpoints
});
```

**2. Middleware-Based Authorization**
```php
'middleware' => ['api', EnsureFrontendRequestsAreStateful::class, 'auth:sanctum']
```

**3. Request Validation**
```php
$request->validate(['key' => 'required', ...]);
```

---

## 4. QUEUE & BACKGROUND PROCESSING

### **Queue Architecture**

**Queue Driver**: Database-based (production-ready for Redis)

**Queue Types**:
| Queue | Purpose | Processor |
|-------|---------|-----------|
| `llm-inference` | AI model execution | ExecuteAiModelJob |
| `messages` | Message processing | ProcessMessageReceived |
| `memory` | Memory operations | ExtractMemoryJob, VectorizeMemoryJob |
| `default` | General jobs | Various |

### **Job Configuration**

**Base Job Pattern**:
```php
class SomeJob extends BaseJob {
    public $queue = 'queue-name';
    public int $timeout = 300;      // 5 minutes
    public int $tries = 3;          // Retry 3 times
    public int $maxExceptions = 3;  // Exception limit
    
    public function __construct(...) {
        $this->idempotencyKey = "unique:key";
    }
    
    public function handle() {
        if ($this->isProcessed()) {
            return;  // Skip if already processed
        }
        // Do work...
        $this->markAsProcessed($payload);
    }
}
```

### **Monitoring**

**Horizon Dashboard**: `/horizon`
- Real-time job monitoring
- Failed job inspection
- Job retry interface
- Queue metrics

**Health Monitoring**: `/api/v1/monitoring/health/queue`

---

## 5. EVENT SYSTEM

### **Events Published**

| Event | Triggers | Listeners |
|-------|----------|-----------|
| `ContactCreated` | Contact.created | ProcessContactCreated |
| `ContactUpdated` | Contact.updated | - |
| `ContactDeleted` | Contact.deleted | - |
| `ContactMerged` | Contacts merged | - |
| `MessageReceived` | Message incoming | ProcessMessageReceived |
| `MessageSent` | Message sent | - |
| `MessageCompleted` | Message delivery | - |
| `AiModelExecutionCompleted` | LLM execution finishes | Store result |
| `MemoryIndexed` | Memory stored | IndexMemory listener |
| `MemoryVectorized` | Memory vectorized | - |
| `MemoriesExtracted` | Memories extracted | - |
| `WorkflowStarted` | Workflow begins | LogWorkflowStarted |
| `WorkflowStepCompleted` | Step finishes | LogWorkflowStepCompleted |
| `WorkflowCompleted` | Workflow finishes | LogWorkflowCompleted |
| `AgentExecuted` | Agent finishes | Store result |
| `JobFailedEvent` | Job fails | LogJobFailed, NotifyJobFailed |
| `TokenStreamed` | Token generation | - |
| `BatchProgressUpdated` | Batch progress | - |

### **Event Broadcasting**

**Technology**: Laravel Reverb (WebSocket)

**Broadcast Events**:
```php
class SomeBroadcastEvent extends BroadcastableEvent {
    public function broadcastOn() {
        return new Channel('notifications');
    }
}
```

---

## 6. REAL-TIME COMMUNICATION

**Technology**: Laravel Reverb

**Features**:
- WebSocket server for real-time updates
- Broadcast channel authentication
- Presence channels (online status)
- Private channels (user-specific)

**Health Monitoring**: `/api/v1/monitoring/health/reverb`

---

## 7. DATABASE RELATIONSHIPS DIAGRAM

```
User (1)
├── (1:N) Contacts
│   ├── (1:N) Conversations
│   │   ├── (1:N) Messages
│   │   └── (1:N) Sessions
│   ├── (1:N) ContactIdentifiers
│   ├── (1:N) ContactRelationships
│   ├── (1:N) ContactRules
│   ├── (1:N) ContactNotes
│   ├── (1:N) ContactTags
│   ├── (1:N) ContactCustomFields
│   ├── (1:N) ContactAliases
│   ├── (1:N) ContactPreferences
│   ├── (1:N) Memories
│   └── (1:N) NotificationLogs

Topic (1)
└── (1:N) Conversations

Conversation (1)
├── (1:N) Messages
└── (1:N) Sessions

Agent (1)
├── (1:N) AgentTools
├── (1:N) AgentSkills
└── (1:N) AgentTasks

Workflow (1)
└── (1:N) AgentTasks

AIProvider (1)
└── (1:N) AIModels

NotificationTemplate (1)
└── (1:N) NotificationLogs

Memory
└── (Optional) Contact & Conversation references
```

---

## 8. DESIGN PATTERNS USED

### **Architectural Patterns**

1. **MVC (Model-View-Controller)**
   - Models: Eloquent models
   - Views: Not used (API-only)
   - Controllers: Request handlers

2. **Repository Pattern** (Light)
   - Abstraction over Eloquent
   - MemoryRepository example
   - Most operations use direct Eloquent

3. **Service Layer Pattern**
   - Business logic in services
   - Controllers delegate to services
   - Services handle complexity

4. **Provider Pattern**
   - Multiple AI provider implementations
   - Pluggable provider system
   - Fallback chains

5. **Observer/Event Pattern**
   - Event-driven architecture
   - Decoupled listeners
   - Async processing

6. **Pipeline Pattern**
   - Complex processing flows
   - MemoryExtractionPipeline
   - ResponseDeliveryPipeline

7. **Strategy Pattern**
   - Different routing strategies
   - ModelSelector with multiple strategies
   - CostOptimizer vs QualityRouter

8. **Facade Pattern**
   - Simplified API access
   - LogService, NotificationService

9. **Registry Pattern**
   - AgentRegistry
   - AgentToolRegistry
   - Provider registration

10. **Circuit Breaker Pattern**
    - CircuitBreakerService
    - Fault tolerance
    - API key rotation

11. **Idempotency Pattern**
    - X-Idempotency-Key header
    - Contact creation
    - Job execution

12. **Factory Pattern**
    - Model factories for testing
    - Provider instantiation

---

## 9. DATA FLOW EXAMPLES

### **Example 1: Contact Creation Flow**
```
POST /api/v1/contacts
    ↓
ContactController::store()
    ↓
Validate request data
    ↓
Check idempotency key
    ↓
Find by identifiers (if exists)
    ↓
Create or update contact
    ↓
Fire ContactCreated event
    ↓
ProcessContactCreated listener
    ↓
Dispatch ExtractMemoryJob
    ↓
Job processes background
    ↓
Return 201 Created
```

### **Example 2: AI Model Execution Flow**
```
POST /api/v1/ai-models/execute
    ↓
AiModelController::execute()
    ↓
Dispatch ExecuteAiModelJob
    ↓
Job queued (llm-inference)
    ↓
Worker processes job
    ↓
Resolve provider (OpenAI, Gemini, etc.)
    ↓
Execute LLM call
    ↓
Fire AiModelExecutionCompleted event
    ↓
Return result
```

### **Example 3: Workflow Execution Flow**
```
POST /api/v1/workflows/{id}/execute
    ↓
WorkflowController::execute()
    ↓
WorkflowExecutor::execute()
    ↓
Validate workflow steps
    ↓
Set workflow status to RUNNING
    ↓
For each step:
    ├── Validate step
    ├── Execute step
    ├── Handle errors
    ├── Fire WorkflowStepCompleted
    └── Continue or retry
    ↓
Fire WorkflowCompleted event
    ↓
Update workflow status
    ↓
Return execution results
```

### **Example 4: Message Receipt and Processing Flow**
```
Incoming message (WhatsApp)
    ↓
POST /api/v1/webhooks/waha
    ↓
WebhookController::handleWahaWebhook()
    ↓
Create message record
    ↓
Fire MessageReceived event
    ↓
ProcessMessageReceived listener (queued)
    ↓
Dispatch ExtractMemoryJob
    ↓
Dispatch IndexMemory job
    ↓
Broadcast via Reverb (real-time UI)
    ↓
Background jobs process memory
```

---

## 10. CONFIGURATION & ENVIRONMENT

### **Key Environment Variables**

```env
APP_NAME=Nexus
APP_ENV=production
APP_DEBUG=false
APP_URL=https://nexus.example.com

DB_CONNECTION=mysql
DB_HOST=localhost
DB_DATABASE=nexus
DB_USERNAME=root
DB_PASSWORD=***

QUEUE_CONNECTION=database
QUEUE_DRIVER=database
DB_QUEUE_TABLE=jobs

CACHE_DRIVER=redis
REDIS_HOST=localhost
REDIS_PORT=6379

SANCTUM_STATEFUL_DOMAINS=localhost:3000,nexus.example.com

BROADCAST_DRIVER=reverb
REVERB_APP_ID=nexus
REVERB_APP_KEY=***
REVERB_CLUSTER=mt1
REVERB_HOST=127.0.0.1
REVERB_PORT=8080

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525

GEMINI_API_KEY=***
OPENAI_API_KEY=***
ANTHROPIC_API_KEY=***
GROQ_API_KEY=***
```

---

## 11. PERFORMANCE CONSIDERATIONS

### **Optimization Strategies**

1. **Database**
   - Indexing on: phone, email, type, is_active
   - Pagination with 20-item default
   - Query eager loading via `with()`

2. **Caching**
   - Redis for session/cache
   - SettingCacheService for settings
   - Query result caching

3. **Queue Processing**
   - Long-running tasks (AI calls: 600s timeout)
   - Async memory extraction
   - Background event processing

4. **API Design**
   - Pagination for list endpoints
   - Filtering and search optimization
   - Idempotency for safety

5. **Vector Search**
   - Pinecone integration
   - Semantic memory indexing
   - Efficient vector queries

---

## 12. SECURITY CONSIDERATIONS

### **Authentication & Authorization**
- ✅ Laravel Sanctum token-based authentication
- ✅ Password hashing (bcrypt)
- ✅ CORS middleware configuration
- ✅ Policy-based authorization

### **Data Protection**
- ✅ Soft deletes for data preservation
- ✅ Encrypted API key storage (EncryptedApiKeyStorage)
- ✅ GDPR compliance (Contact erase endpoint)
- ✅ Audit logging (SystemLog, ActivityLog)

### **API Security**
- ✅ Validation on all inputs
- ✅ Rate limiting (RateLimitService)
- ✅ SSRF protection middleware
- ✅ Idempotency support

### **Job Security**
- ✅ Retry limits to prevent infinite loops
- ✅ Timeout enforcement
- ✅ Dead letter queue handling
- ✅ Failed job notifications

---

## 13. FUTURE EXTENSIBILITY

### **Plug-in Points**

1. **New Agent Types**
   ```php
   // Register in AgentRegistry
   $registry->register('custom-agent', CustomAgent::class);
   ```

2. **New AI Providers**
   ```php
   // Implement AiProviderInterface
   class CustomProvider implements AiProviderInterface { ... }
   ```

3. **New Notification Channels**
   ```php
   // Add case in NotificationService::send()
   NotificationTemplate::CHANNEL_SLACK => $this->sendSlack($notification),
   ```

4. **New Event Listeners**
   ```php
   // Register in EventServiceProvider
   SomeEvent::class => [NewListener::class],
   ```

5. **New Routers**
   ```php
   // Implement routing strategy
   class CustomRouter { ... }
   ```

---

## 14. DEPLOYMENT ARCHITECTURE

### **Components**

- **Web Server**: Laravel artisan serve / Apache / Nginx
- **Queue Worker**: `php artisan queue:listen`
- **Cache**: Redis server
- **Database**: MySQL
- **WebSocket**: Reverb server
- **Monitoring**: Horizon (queue monitoring)

### **Typical Setup**

```
Internet → Load Balancer
    ↓
+---+---------+---+
|   |         |   |
API API       API
Workers: Queue Processing
    ↓
Redis ← Caching
    ↓
MySQL ← Data Storage
    ↓
Reverb ← WebSocket
```

---

## SUMMARY TABLE

| Aspect | Technology | Details |
|--------|-----------|---------|
| **Framework** | Laravel 11.31 | PHP 8.2+ |
| **Authentication** | Sanctum | Token-based, stateless |
| **Database** | MySQL | Eloquent ORM |
| **Queue** | Database/Redis | Background jobs |
| **Cache** | Redis | Session & app cache |
| **Real-time** | Reverb | WebSocket server |
| **Monitoring** | Horizon | Queue dashboard |
| **Testing** | PHPUnit | Unit & feature tests |
| **Code Quality** | Pint | PHP linter |

---

**Architecture Version**: 2026-05-25
**Last Updated**: May 25, 2026
**Status**: Production-Ready
