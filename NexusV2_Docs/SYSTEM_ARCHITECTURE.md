# 01 - System Architecture

What:
- High-level architecture for Nexus: hub-based, API-first, event-driven, and layered components (Routers, Engines, Pipelines, Builders, Services).

Why:
- Provide a single reference for developers and architects to implement hubs, integrations, and non-functional requirements.

How (summary):
- Hubs expose REST APIs and consume events. All inter-hub communication uses authenticated HTTP APIs or a secure event bus.
- Core layers:
  - Edge/API Layer: Public APIs, authentication, rate limiting, request routing
  - Orchestration Layer: Hub Controllers, Routers, Engines
  - Processing Layer: Pipelines, Builders, AI Model adapters
  - Storage Layer: SQL (structured/episodic), Redis (working/hot cache), Pinecone (semantic vectors), Archive DB / S3 (cold storage)
  - Integration Layer: External AI providers, WAHA (WhatsApp), Email/SMS gateways, Third-party webhooks

Components & responsibilities:
- AgentsHub: Orchestrates agent behaviors, sequences tasks through WorkflowsHub and AiModelsHub.

-  MemoryHub: Read/write/update across memory types; provides semantic search endpoints.
  
- ContactsHub: CRUD and canonicalization for contact profiles and beliefs.

- AiModelsHub: Provider adaptors, model selection, prompt templates, usage accounting.

- WorkflowsAndTasksHub: Define, schedule, and run multi-step Pipelines and long-running tasks.

- SettingsHub: Feature flags, routing rules, provider priorities.

- LogsHub: Centralized audit, telemetry, and trace collection.

- Supporting hubs: WebhookHub, NotificationHub, SchedulerHub (stateless where possible).

Integration points:
- Auth: OAuth2 / JWT for service-to-service, RBAC for user-level access.
- Observability: OpenTelemetry traces, structured JSON logs, metrics pushed to Prometheus.

Non-functional targets:
- Latency: P95 < 2s for standard queries; async queues for heavy extraction.
- Availability: 99.9% target, design for horizontal scaling per hub.
- Scalability: Stateless API layer; stateful storage (Redis, MySQL, Pinecone) scaled independently.

Dependencies:
- MySQL (core schema), Redis, Pinecone, external AI providers, message broker (Kafka/RabbitMQ optional).
