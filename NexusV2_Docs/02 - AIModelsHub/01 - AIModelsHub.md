
# 🧠 AIModelsHub - Master Feature Requirement Document (v2.0)

## 1. Executive Summary & Philosophy
The **AIModelsHub** is the 100% dynamic, centralized orchestration gateway for all AI workloads within the Nexus Cognitive Digital Twin Platform. 

**The Golden Rule (Legacy Cleanup Mandate):** The entire Nexus codebase MUST be completely cleansed of any old, hardcoded AI provider SDKs (e.g., fixed `openai-php` or Google Gemini SDKs). All AI requests—whether for memory extraction, chat replies, or summarization—must route dynamically through this hub using native HTTP clients. 

This hub eliminates vendor lock-in, ensures zero-latency switching between providers, enforces capability-driven routing (Fast/Quality/Budget/Arabic), manages secure API keys, orchestrates fallbacks, and tracks every cent spent on AI inference.

---

## 2. Scope & Core Responsibilities
*   **Provider Discovery & Selection:** Dynamically onboarding AI companies and syncing their available models.
*   **Model Catalog & Instance Configuration:** Crafting specific, parameter-tuned "Instances" from raw models.
*   **Intelligent Request Routing:** Matching system intents (Tasks) to the optimal model based on cost, latency, security, and language (e.g., Arabic optimization).
*   **Fallback Orchestration:** Implementing resilient, soft-failover chains across multiple providers to guarantee 100% uptime.
*   **Key Lifecycle Management:** Securely storing, scoping, and rotating API credentials.
*   **Cost & Telemetry Tracking:** Capturing token usage, latency, and exact USD costs per request.

---

## 3. Core Architectural Modules (Service Layer)

The AIModelsHub is powered by 7 distinct, decoupled backend components:

### 3.1 ProviderRegistry
*   Registers available providers and supported model families.
*   Exposes provider capabilities, health status, availability, and latency profiles.
*   Manages feature flags, region restrictions, and compliance labels per provider.

### 3.2 ModelCatalog
*   Maintains provider-agnostic model profiles and quality tiers.
*   Supports custom model aliases (Instances) and usage policies.
*   Enables versioned model selection rules.

### 3.3 RoutingEngine
*   Evaluates incoming request attributes: `intent`, `cost_profile`, `latency_profile`, `security_class`, and `language` (e.g., Arabic processing).
*   Consults provider weights, quotas, and dynamic routing rules.
*   Routes the request to the optimal Provider/Model pair unless explicitly overridden.

### 3.4 FallbackChain
*   Defines ordered fallback sequences (e.g., Try GPT-4o -> Fallback to Claude-3.5 -> Fallback to Gemini-1.5).
*   Retries requests gracefully on timeouts, 429 Rate Limits, or 500 Server Errors.
*   Preserves request context and metadata throughout the fallback attempts without failing the background job.

### 3.5 KeyManager
*   Stores provider credentials securely in an encrypted database vault (via Laravel's Encrypted Casts or KMS).
*   Handles runtime decryption only when the HTTP request is firing.
*   Supports key rotation, retiring, and per-tenant/provider key scoping.

### 3.6 UsageTracker
*   Records exact request costs, prompt tokens, completion tokens, and duration (latency).
*   Links usage to specific workflows, workspaces, and system tasks.
*   Emits telemetry events for billing, anomaly detection, and quota enforcement.

### 3.7 ProviderHealthMonitor
*   Polls provider health endpoints, status APIs, and tracks active rate-limit signals.
*   Maintains provider scorecards for latency, reliability, and network congestion.
*   Automatically feeds health metrics into the RoutingEngine to skip degraded providers.

---

## 4. Functional Requirements & Features

### 4.1 Provider Onboarding & Management
A dynamic UI/Backend flow to introduce new AI companies to Nexus without touching code.
*   **Input Form:** Provider Name, Base URL, Fetch Models Endpoint, Generate Text Endpoint, Test Link/Connection Endpoint, Auth Header Format (e.g., `Bearer {KEY}` or `x-api-key: {KEY}`).
*   **Onboarding Action:** Upon clicking "Save", the system MUST:
    1. Validate the API key against the "Test Link/Connection Endpoint".
    2. Hit the "Fetch Models Endpoint" to download the array of available AI models.
    3. Persist the Provider and the Auto-Discovered models into the database.

### 4.2 AI Model Instance Configuration
Creating usable "Agents/Instances" from the raw fetched models.
*   **Instance Crafting Form:** 
    *   Instance Name (e.g., "Deep Arabic Reasoner").
    *   Select Provider (Dropdown).
    *   Select Model (Dropdown populated from synced models).
    *   Model Settings: Temperature, Max Tokens, Top P, Frequency Penalty.
    *   Activation Status Toggle.

### 4.3 Jobs Config & Task Routing (Intent Mapping)
The bridge between Nexus operations and AI Instances.
*   **System Intents (Tasks):** Predefined Nexus workflows requiring AI, such as: `text_completion`, `text_summarization`, `Memory_Extraction`, `Intent_Detection`, `PeopleConnect_Chat_Reply`, `Contact_Analysis`.
*   **Routing Interface:** A UI matrix where the user selects which "AI Model Instance" executes which "Task".
*   **Routing Profiles:** Ability to route based on strategy:
    *   *Fast:* Lowest latency instance.
    *   *Quality:* Highest parameter instance.
    *   *Budget:* Lowest cost-per-token instance.
    *   *Arabic:* Instance explicitly prompted or fine-tuned for Arabic language nuances.

### 4.4 Caching & Cost Optimization
*   **Semantic Caching:** Identical prompts (especially in background jobs like recurring summarization) should hit a Redis cache layer before triggering a paid API request.
*   **Token Optimization:** Truncating large contexts intelligently before sending them to the routing engine to preserve budget.

---

## 5. API Contracts (Backend)

### `POST /v1/ai-models/route` (The Core Execution Endpoint)
The single entry point for all Nexus hubs to request AI processing.
**Request Body:**
*   `intent`: string (e.g., `Memory_Extraction`)
*   `workspace_id`: string
*   `input_type`: string
*   `messages/features`: array
*   `cost_profile`: enum (`low`, `medium`, `high`)
*   `latency_profile`: enum (`fast`, `balanced`, `safe`)
*   `security_class`: enum (`standard`, `sensitive`, `restricted`)
*   `provider_override` (optional)
*   `model_override` (optional)

**Response:**
*   `provider_id`, `model_id`, `endpoint`, `expected_cost`, `fallback_chain_used`, `generated_text/data`.

### `POST /v1/ai-models/usage` (Internal Telemetry Webhook)
Called asynchronously by the Routing Engine after a request completes.
**Request Body:**
*   `request_id`, `provider_id`, `model_id`, `workflow_id`, `token_usage_object`, `cost_usd`, `duration_ms`, `status`.

### `GET /v1/ai-models/providers`
**Response:**
*   Array of provider metadata, current `health_status`, and `supported_models`. (API keys are STRICTLY omitted from this response).

---

## 6. Frontend UI & Dashboard (Next.js)

The AIModelsHub will feature a sophisticated Next.js interface, comprising the following sections:

### 6.1 Global Topbar
*   Quick action buttons: "Add Provider", "Create Instance", "Global Sync Models".
*   Current estimated daily cost badge.

### 6.2 Management Interfaces
*   **Providers Grid:** Cards showing Provider logos, connection health badges, and "Sync Models" buttons.
*   **Instances Table:** Detailed list of all active/inactive instances, showing their assigned underlying model and hyperparameters.
*   **Task Routing Matrix:** A dynamic table mapping System Intents to Primary and Fallback instances.

### 6.3 Testing Playground
*   A dedicated manual testing interface.
*   Left pane: Select Instance, tweak override settings (temperature/tokens).
*   Right pane: A chat/prompt interface to fire requests and instantly view the raw response, token consumption, and latency (ms) before deploying the instance to production tasks.

### 6.4 Reports & Analytics Dashboard
*   **Visualizations:** Time-series charts for API key usage, Model consumption distribution (Pie charts), and Request success/failure rates.
*   **Cost Tracking:** Aggregated telemetry showing exact USD spend per workflow, workspace, and provider.

---

## 7. Security & Resilience Compliance


*   **Graceful Degradation:** If external providers suffer global outages, the FallbackChain must automatically attempt to route to local/fallback models (e.g., self-hosted Ollama) or gracefully pause the Nexus background jobs without crashing the system.
*   **Auditability:** Every configuration change (adding a provider, changing a routing rule) is logged in the `LogsHub`.

---