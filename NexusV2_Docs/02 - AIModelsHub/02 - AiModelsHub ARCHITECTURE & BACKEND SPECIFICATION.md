
### 2.1 Database Schema (MySQL)
We require highly structured relational tables to support the dynamic gateway.

*   **`ai_providers` Table:**
    *   `id` (UUID, Primary)
    *   `name` (VARCHAR) - e.g., "OpenAI"
    *   `base_url` (VARCHAR)
    *   `auth_header_name` (VARCHAR) - e.g., "Authorization"
    *   `auth_header_format` (VARCHAR) - e.g., "Bearer {KEY}"
    *   `api_key` (TEXT) - **Encrypted via Laravel `$casts`**
    *   `fetch_models_endpoint` (VARCHAR) - e.g., `/v1/models`
    *   `chat_endpoint` (VARCHAR) - e.g., `/v1/chat/completions`
    *   `is_active` (BOOLEAN)
*   **`ai_models` Table:**
    *   `id` (UUID, Primary)
    *   `provider_id` (UUID, Foreign Key)
    *   `model_identifier` (VARCHAR) - e.g., "gpt-4o"
    *   `context_window` (INT)
    *   `is_active` (BOOLEAN)
*   **`ai_instances` Table:**
    *   `id` (UUID, Primary)
    *   `model_id` (UUID, Foreign Key)
    *   `name` (VARCHAR) - e.g., "Creative Writer"
    *   `temperature` (FLOAT)
    *   `max_tokens` (INT)
    *   `default_system_prompt` (TEXT, Nullable)
*   **`ai_job_routes` Table:**
    *   `system_task_name` (VARCHAR, Primary/Unique) - e.g., `memory_extraction`
    *   `instance_id` (UUID, Foreign Key)
    *   `fallback_instance_id` (UUID, Foreign Key, Nullable) - Used if the primary fails.
*   **`ai_telemetry_logs` Table:** (Partitioned or indexed for high volume)
    *   `id` (UUID, Primary)
    *   `instance_id` (UUID, Foreign Key)
    *   `system_task_name` (VARCHAR)
    *   `prompt_tokens` (INT)
    *   `completion_tokens` (INT)
    *   `latency_ms` (INT)
    *   `status` (VARCHAR: success, failed, timeout)
    *   `error_message` (TEXT, Nullable)

### 2.2 Core Services (Single Responsibility Principle)
*   **`ProviderDiscoveryService`:** Handles testing connections and parsing the `/models` endpoint of various providers to populate the `ai_models` table.
*   **`UniversalAiGatewayService`:** 
    *   The single point of entry for all AI requests. 
    *   Method: `executeTask(string $taskName, array $messages, array $overrideConfig = [])`.
    *   Logic: Looks up the `$taskName` in `ai_job_routes`, gets the `ai_instance`, fetches the `ai_provider` credentials, decrypts the API key, formats the HTTP request using Laravel's `Http` facade, and sends it to the Provider's `chat_endpoint`.
*   **`TelemetryTrackingService`:** Listens to the response from `UniversalAiGatewayService`, calculates token usage/latency, and asynchronously writes to `ai_telemetry_logs` via a Redis Queue job to avoid blocking the main thread.

### 2.3 API Endpoints
*   `GET|POST|PUT|DELETE /api/v1/ai-hub/providers`
*   `POST /api/v1/ai-hub/providers/{id}/sync-models` (Triggers discovery)
*   `GET|POST|PUT|DELETE /api/v1/ai-hub/instances`
*   `GET|PATCH /api/v1/ai-hub/job-routes`
*   `GET /api/v1/ai-hub/telemetry` (Returns aggregated metrics for charts)
*   `POST /api/v1/ai-hub/test-instance` (Direct playground testing)
