# 06 - Event Architecture

Purpose
- Define event types, schemas, delivery guarantees, versioning, and operational practices for cross-hub communication.

Principles
- Events are facts (immutable) representing state changes or notable occurrences.
- Prefer events for cross-hub notifications; REST for point-to-point requests.
- Ensure idempotent consumers, schema versioning, and durable delivery.

Event delivery models
- At-least-once: default for most consumers (use retries and idempotency to handle duplicates).
- Exactly-once (logical): achieved by combining idempotent processing + deduplication via event id tracking or transactional outbox.
- Fire-and-forget webhooks: use signed payloads, retries, and DLQ for failed deliveries.

Event schema (recommended minimal envelope)

```json
{
  "id": "uuid-v4",
  "type": "string",            
  "version": 1,
  "timestamp": "2026-05-16T12:34:56Z",
  "source": { "hub": "ContactsHub", "instance": "contacts-01" },
  "payload": { },
  "metadata": { "trace_id": "uuid", "schema_version": 1 }
}
```

Common event types (examples)
- `contact.created`, `contact.updated`, `contact.deleted`
- `memory.created`, `memory.updated`, `memory.deleted`
- `task.created`, `task.updated`, `task.completed`, `task.failed`
- `model.requested`, `model.response` (for auditing)

Schema evolution & versioning
- Use `version` at event level. Consumers should ignore unknown fields and validate via JSON Schema.
- When changing payloads, increment `version` and publish changelog in hub `openapi.json` / schema registry.

Delivery infrastructure
- Broker choices: Kafka for scale and replayability; RabbitMQ for simpler patterns; Redis Streams for lightweight deployments.
- WebhookHub: delivers events to external systems with signing, retry, and backoff.

Outbox pattern (recommended for cross-service consistency)
- Write domain change and an outbox row in the same DB transaction.
- Outbox worker reads pending rows, publishes to broker, and marks `published_at` on success.

DLQ & poison message handling
- Configure dead-letter topics/queues for messages that fail after N retries.
- Persist original event and diagnostic metadata to `dead_letter_events` with a human-review link in `LogsHub`.

Consumer best practices
- Idempotency: store `event_id` processed set (with TTL) or persist last processed offset per partition.
- Schema validation: use JSON Schema/Avro to validate and reject malformed events early.
- Backpressure: consumers should manage concurrency and pause consumption when downstream is congested.

Security
- Sign events using service keys (HMAC) for webhook consumers; use mTLS for in-cluster broker clients.
- Avoid embedding secrets in payloads; include references (ids) instead.

Observability
- Emit metrics: event publish rate, consumer lag, retry counts, DLQ counts.
- Trace: propagate `trace_id` and include in event metadata for end-to-end traces.

Sample event (memory.created)

```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "type": "memory.created",
  "version": 1,
  "timestamp": "2026-05-16T12:34:56Z",
  "source": { "hub": "MemoryHub", "instance": "memory-01" },
  "payload": {
    "memory_id": "m-123",
    "contact_id": "c-456",
    "type": "belief",
    "content": { "belief": "prefers_morning_calls" },
    "confidence": 0.92
  },
  "metadata": { "trace_id": "t-789", "schema_version": 1 }
}
```

Operational runbook (events)
- Consumer lag increase: scale consumers, check broker retention and partitioning.
- Rapid DLQ growth: inspect common error, run schema validator against failing events, and apply remediation.
- Event duplication reports: validate consumer deduplication store and investigate producer retries.

Testing strategy
- Contract tests: publisher/consumer contract checks using schema registry.
- Chaos tests: simulate broker partitions and consumer failures to verify retries and DLQ behavior.

Next steps
- Add per-event JSON Schema files under `02-ARCHITECTURE/schemas/` and generate `openapi`/event docs.
# 06 - Event Architecture

Event Principles:
- Events are facts about the system (immutable) and include provenance and schema version.
- Favor events for cross-hub notifications (e.g., contact.updated, memory.created, task.completed).

Event Schema (minimal):
- `{ "id": "uuid", "type": "string", "version": "1", "timestamp": "iso8601", "payload": {...}, "source": {"hub":"ContactsHub","instance":"host:port"} }`

Delivery pattern:
- Use a durable broker (Kafka/RabbitMQ) for high-throughput events; for lightweight setups, use webhooks with retry and ack semantics.
- Consumers must be idempotent; use event id tracking to avoid double-processing.

Event versioning & evolution:
- Include `version` at the event level; create migration adapters for consumers when changing payload shapes.

Monitoring:
- Track event lag, consumer group offsets, and failed-events queue for human review.
