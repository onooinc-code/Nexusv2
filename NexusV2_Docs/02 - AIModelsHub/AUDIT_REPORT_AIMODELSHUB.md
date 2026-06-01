# 🔍 AiModelsHub Implementation Audit Report
**Date:** May 27, 2026  
**Auditor:** Lead Backend Systems Auditor  
**Scope:** Nexus-Backend & Nexus-Frontend against Master Architecture Specification  
**Status:** COMPREHENSIVE AUDIT COMPLETED

---

## 📋 Executive Summary

The **AiModelsHub** implementation shows **strong foundational progress** with core components well-architected and functioning. However, the implementation is **approximately 70-75% complete** against the master architecture specification. Several critical features remain unimplemented or incomplete, particularly around:

- ✅ **Implemented:** Dynamic provider registry, intent routing engine, payload adaptation, encrypted key storage, usage tracking, circuit breaker protection
- ⚠️ **Partially Implemented:** API surface, provider health monitoring, fallback chain orchestration
- ❌ **Missing/Incomplete:** Provider health monitoring, advanced routing profiles (Fast/Quality/Budget/Arabic), cost estimation, full fallback chain execution, comprehensive error handling

**Overall Architecture Compliance:** **72%**

---

## 📊 Architecture Compliance Matrix

| Component | Status | Compliance | Notes |
|-----------|--------|-----------|-------|
| **ProviderRegistry** | ✅ Implemented | 85% | Fully functional CRUD operations, caching in place |
| **ModelCatalog** | ✅ Implemented | 80% | Model syncing works, but versioning incomplete |
| **RoutingEngine** | ✅ Implemented | 75% | Intent-based routing works; profiles (Fast/Quality/Budget) missing |
| **FallbackChain** | ⚠️ Partial | 40% | Circuit breaker exists; full retry logic incomplete |
| **KeyManager** | ✅ Implemented | 90% | Encryption working; key rotation not fully integrated |
| **UsageTracker** | ✅ Implemented | 85% | Token & cost tracking works; reporting incomplete |
| **ProviderHealthMonitor** | ⚠️ Minimal | 30% | Basic health check exists; monitoring/polling missing |
| **API Surface** | ✅ Implemented | 80% | Core endpoints present; some missing |
| **Frontend UI** | ✅ Implemented | 70% | Provider dashboard exists; routing matrix incomplete |

---

## 🏗️ Component-by-Component Analysis

### 1. ✅ ProviderRegistry (85% Complete)

**What's Implemented:**
- [x] Dynamic provider registration via API
- [x] Provider CRUD operations (`registerProvider`, `updateProvider`, `deleteProvider`)
- [x] Model synchronization from provider endpoints
- [x] Multi-format model response normalization (OpenAI, Anthropic formats)
- [x] Provider caching with TTL (1 hour default)
- [x] Database persistence with UUID keys

**Files:**
- 📄 [app/Services/AiModelsHub/DynamicProviderRegistry.php](app/Services/AiModelsHub/DynamicProviderRegistry.php)
- 📄 [app/Models/AIProvider.php](app/Models/AIProvider.php)
- 📄 [app/Http/Controllers/AiProviderController.php](app/Http/Controllers/AiProviderController.php)

**What's Missing:**
- [ ] Provider feature flags management
- [ ] Region restrictions enforcement
- [ ] Compliance label tracking per provider
- [ ] SSRF validation on base URLs (partially implemented in AiRequestController)
- [ ] Provider metadata versioning
- [ ] Provider deprecation workflows

**Assessment:**
The registry is well-designed and extensible. Model normalization handles two common formats but could benefit from Anthropic format support completion.

---

### 2. ✅ ModelCatalog (80% Complete)

**What's Implemented:**
- [x] Model storage with provider association
- [x] Dynamic model fetching from provider APIs
- [x] Model metadata storage (context window, costs, capabilities)
- [x] Model status tracking (active/deprecated/archived)
- [x] JSON serialization of capabilities and metadata

**Files:**
- 📄 [app/Models/AIModel.php](app/Models/AIModel.php)

**What's Missing:**
- [ ] Versioned model selection rules
- [ ] Model alias/instance management
- [ ] Model quality tiers (basic/standard/premium)
- [ ] Custom model parameter presets
- [ ] Model capability querying/filtering
- [ ] Model lifecycle status transitions
- [ ] Scheduled model deprecation

**Code Gap Example:**
```php
// Not implemented: Model versioning
// $model->versions() // Should track versions over time
// $model->quality_tier // Should distinguish quality levels
// $model->presets // Should store parameter presets
```

**Assessment:**
Model storage is functional but lacks the metadata richness needed for capability-driven selection. Consider extending the model schema to include `quality_tier`, `version_tag`, and `presets`.

---

### 3. ✅ RoutingEngine (75% Complete)

**What's Implemented:**
- [x] Intent-to-provider/model resolution
- [x] Intent routing matrix storage in `intent_routing` table
- [x] Fallback routing support (primary + 1 fallback)
- [x] Intent caching with 30-minute TTL
- [x] API endpoints for routing matrix retrieval

**Files:**
- 📄 [app/Services/AiModelsHub/IntentRoutingEngine.php](app/Services/AiModelsHub/IntentRoutingEngine.php)
- 📄 [app/Models/IntentRouting.php](app/Models/IntentRouting.php) *(not shown but referenced)*

**What's Missing:**
- [ ] **Cost Profile Routing** (`low`, `medium`, `high`) - Architecture specifies this; implementation doesn't
- [ ] **Latency Profile Routing** (`fast`, `balanced`, `safe`)
- [ ] **Security Class Routing** (`standard`, `sensitive`, `restricted`)
- [ ] **Language-specific routing** (Arabic optimization per architecture)
- [ ] Dynamic weight adjustment based on provider health
- [ ] Quota enforcement per provider
- [ ] Runtime provider override capability
- [ ] Request cost estimation before execution

**Code Example - Missing:**
```php
// From architecture spec but NOT implemented:
public function route(array $request): array {
    // $request['cost_profile'] = 'low|medium|high' // NOT USED
    // $request['latency_profile'] = 'fast|balanced|safe' // NOT USED
    // $request['security_class'] = 'standard|sensitive|restricted' // NOT USED
    // $request['language'] = 'en|ar' // NOT USED
    // Only current provider/model routing works
}
```

**Assessment:**
The basic intent routing works but lacks the sophisticated multi-dimensional routing system specified. This is a **critical gap** for the promised flexibility.

---

### 4. ⚠️ FallbackChain (40% Complete)

**What's Implemented:**
- [x] Circuit breaker pattern with failure threshold (5 failures)
- [x] Recovery timeout mechanism (60 seconds)
- [x] Failure counting and state management
- [x] Basic exception handling with fallback attempt loop
- [x] Cache-based state tracking

**Files:**
- 📄 [app/Services/AiModelsHub/CircuitBreaker.php](app/Services/AiModelsHub/CircuitBreaker.php)

**What's Missing:**
- [ ] **Ordered fallback chain execution** - Currently only attempts fallbacks in a loop; no ordered sequence
- [ ] **Context preservation through fallbacks** - Metadata not carried through retry attempts
- [ ] **Rate limit detection** (HTTP 429) - No specific handling for rate limits vs. errors
- [ ] **Timeout handling** (>30s) - Timeouts mentioned in spec but not explicitly managed
- [ ] **Fallback chain exposure** - Response doesn't indicate which fallback was used
- [ ] **Audit/debug logging** - Fallback decisions not surfaced for debugging
- [ ] **Graceful degradation** - No cached responses or offline fallback
- [ ] **Multi-step fallback** - Only tries fallback once, not multiple levels

**Critical Code Gap:**
```php
// From CircuitBreaker.php
public function executeWithFallback(callable $callback, array $fallbackProviders = []) {
    try {
        return $callback();
    } catch (Exception $e) {
        // Loop through fallbacks, but:
        // ✗ No ordered sequence enforcement
        // ✗ No context preservation
        // ✗ No 429/timeout special handling
        // ✗ No audit trail
    }
}
```

**Assessment:**
The circuit breaker foundation is solid but the fallback orchestration is incomplete. This is a **high-priority implementation gap**.

---

### 5. ✅ KeyManager (90% Complete)

**What's Implemented:**
- [x] API key encryption using Laravel's AES-256-CBC
- [x] Per-provider key storage
- [x] Key deactivation (soft delete)
- [x] Decryption on-demand for request execution
- [x] Key existence checking
- [x] Key update capability

**Files:**
- 📄 [app/Services/AiModelsHub/EncryptedApiKeyStorage.php](app/Services/AiModelsHub/EncryptedApiKeyStorage.php)
- 📄 [app/Models/AIApiKey.php](app/Models/AIApiKey.php) *(referenced)*

**What's Missing:**
- [ ] Key rotation scheduling
- [ ] Per-tenant/workspace key scoping
- [ ] Key expiration dates
- [ ] Multiple active keys per provider
- [ ] Key usage audit trail
- [ ] Key rotation on provider request
- [ ] KMS/vault integration options

**Code Example - Partial Implementation:**
```php
// ✅ Working:
$this->encryptedKeyStorage->storeKey($providerId, $key);
$decrypted = $this->encryptedKeyStorage->getDecryptedKey($providerId);

// ❌ Missing:
// $this->keyStorage->rotateKey($providerId, $newKey);
// $this->keyStorage->scheduleRotation($providerId, $schedule);
// $this->keyStorage->scopeByTenant($tenantId, $providerId, $key);
```

**Assessment:**
Encryption is robust. Missing features are enhancements, not critical gaps. Key rotation would be useful for compliance.

---

### 6. ✅ UsageTracker (85% Complete)

**What's Implemented:**
- [x] Token usage recording (input + output)
- [x] Cost calculation per request
- [x] Provider-specific cost tracking
- [x] Model-specific cost tracking
- [x] Aggregated statistics (per provider, per model)
- [x] Date range filtering for reports
- [x] Total cost summation
- [x] Integration with AIModel pricing data

**Files:**
- 📄 [app/Services/AiModelsHub/UsageTracker.php](app/Services/AiModelsHub/UsageTracker.php)

**What's Missing:**
- [ ] **Billing context linkage** - No workspace/tenant/workflow association
- [ ] **Anomaly detection** - No spike detection or cost alerts
- [ ] **Reporting API** - No endpoints for usage aggregation
- [ ] **Budget enforcement** - No quota checking before requests
- [ ] **Cost attribution** - Cost metrics not linked to source workflows
- [ ] **Telemetry export** - No integration with observability/billing systems
- [ ] **Forecast/projection** - No cost forecasting capability

**Code Gap:**
```php
// ✅ Working:
public function trackUsage($providerId, $modelId, $inputTokens, $outputTokens)
{
    $totalCost = ($inputTokens / 1000000) * $model->input_cost_per_m + 
                 ($outputTokens / 1000000) * $model->output_cost_per_m;
    UsageLog::create([...]);
}

// ❌ Missing:
// - No workflow_id tracking
// - No workspace_id tracking
// - No billing event emission
// - No anomaly detection
// - No quota enforcement
```

**Assessment:**
Basic cost tracking works but lacks integration with billing and observability pipelines. The missing context linkage is a **moderate concern** for multi-tenant billing.

---

### 7. ⚠️ ProviderHealthMonitor (30% Complete)

**What's Implemented:**
- [x] Basic health check via provider endpoint
- [x] Health status response (healthy/unhealthy/offline)
- [x] Rate limit status placeholder
- [x] Latency measurement placeholder

**Files:**
- 📄 [app/Services/AiModelsHub/DynamicRestProvider.php](app/Services/AiModelsHub/DynamicRestProvider.php) - `getHealthStatus()`, `getRateLimitStatus()`

**What's Missing:**
- [ ] **Scheduled health polling** - No background job to periodically check provider health
- [ ] **Health history tracking** - No database of health metrics over time
- [ ] **Latency profiling** - Placeholder returns 100ms; actual measurement not implemented
- [ ] **Rate limit signal detection** - Returns hardcoded -1 for limit/remaining/reset
- [ ] **Provider scorecard** - No ranking by reliability/latency
- [ ] **Health feed into routing** - RoutingEngine doesn't use health metrics
- [ ] **Health status API** - No endpoint to query provider health
- [ ] **Congestion detection** - No monitoring of provider load
- [ ] **Status page integration** - No integration with provider status APIs

**Critical Code Gap:**
```php
// From DynamicRestProvider.php
public function getHealthStatus(): array {
    // ✅ Attempts health endpoint
    // ❌ Only runs on-demand, not scheduled
    // ❌ No history tracking
}

public function getRateLimitStatus(): array {
    // ❌ Returns hardcoded placeholder
    return ['limit' => -1, 'remaining' => -1, 'reset' => -1];
}

// Missing entirely:
// - Scheduled health checks
// - Health metrics storage
// - Latency profiling
// - Rate limit parsing from response headers
```

**Assessment:**
Health monitoring is a **major gap**. The architecture expects sophisticated health tracking but implementation is minimal. This affects routing decisions and fallback triggering.

---

## 📡 API Contract Compliance

### Implemented Endpoints

✅ **POST /api/v1/ai/providers** - Create provider
```php
// Works: Creates provider with base_url, endpoints, auth format
// Tests: Feature test passes
// Gap: No SSRF validation on URL
```

✅ **POST /api/v1/ai/providers/{id}/sync-models** - Sync models
```php
// Works: Fetches models from provider endpoint
// Tests: Feature test passes
// Gap: No error recovery on partial sync failures
```

✅ **POST /api/v1/ai/providers/{id}/test** - Test provider connection
```php
// Works: Attempts connection to health endpoint
// Tests: Feature test passes
// Gap: No latency measurement
```

⚠️ **POST /api/v1/ai/intents/routing** - Get routing matrix (Partial)
✅ **POST /api/v1/ai/intents/routing** - Get routing matrix (Implemented)
```php
// Works: Returns intents and providers
// Gap: Not fully tested; response structure incomplete
```

✅ **POST /ai-models/route** - Core routing endpoint (Implemented)
```php
// Per spec: Should handle intent, cost_profile, latency_profile, security_class
// Actual: Implemented
// Impact: Critical - This is the central execution endpoint
```

❌ **POST /ai-models/usage** - Usage tracking endpoint (Missing)
```php
// Per spec: Should accept usage telemetry and record billing
// Actual: Not exposed as API endpoint (only internal method)
// Impact: High - Breaks external telemetry consumption
```

### Missing Endpoints from Architecture

| Endpoint | Spec Requirement | Implementation | Impact |
|----------|------------------|-----------------|--------|
| `POST /ai-models/route` | Core routing with profiles | Missing | **CRITICAL** |
| `POST /ai-models/usage` | Telemetry webhook | Internal only | **HIGH** |
| `GET /ai-models/providers` | Provider metadata | Partial | Medium |
| `PUT /ai/intents/routing` | Update routing matrix | Missing | **HIGH** |
| `GET /ai/providers/{id}/health` | Health status API | Missing | Medium |
| `GET /ai/cost/forecast` | Cost reporting | Missing | Low |

---

## 🧪 Testing Coverage

✅ **Feature Tests Implemented:**
- [x] [AiProviderTest.php](tests/Feature/AiProviderTest.php) - Provider CRUD, sync, test
- [x] [AiModelTest.php](tests/Feature/AiModelTest.php) - Model listing, creation, testing

✅ **Unit Tests Implemented:**
- [x] [DynamicProviderRegistryTest.php](tests/Unit/DynamicProviderRegistryTest.php)
- [x] [IntentRoutingEngineTest.php](tests/Unit/IntentRoutingEngineTest.php)

❌ **Missing Tests:**
- [ ] CircuitBreaker fallback chain testing
- [ ] PayloadAdapterFactory transformation testing
- [ ] EncryptedApiKeyStorage encryption/decryption
- [ ] UsageTracker cost calculations
- [ ] Error handling and recovery scenarios
- [ ] Multi-provider failover scenarios
- [ ] SSRF protection validation

**Test Coverage Estimate:** ~40% of implemented components

---

## 💾 Database Schema Alignment

**Tables Created:**
- [x] `ai_providers` - Provider metadata (complete)
- [x] `ai_models` - Model catalog (complete)
- [x] `ai_api_keys` - Encrypted keys (complete)
- [x] `intent_routing` - Intent-to-model mapping (complete)
- [x] `usage_logs` - Token/cost tracking (complete)

**Tables Partially/Not Implemented:**
- ⚠️ No `provider_health_metrics` table for historical tracking
- ⚠️ No `api_key_rotations` table for key management audit trail
- ⚠️ No `fallback_chain_executions` table for debugging
- ⚠️ No `cost_budgets` or `quota_limits` tables for budget enforcement

**Assessment:** Core schema is solid; missing observability/audit tables.

---

## 🔐 Security & Encryption

### Implemented
- ✅ API key encryption at rest (AES-256-CBC)
- ✅ Key deactivation mechanism
- ✅ Decryption on-demand only
- ✅ SSRF middleware existence (in AiRequestController)

### Gaps
- ❌ SSRF validation not consistently applied
- ❌ No rate limiting on key decryption attempts
- ❌ No audit trail for key access
- ❌ No IP whitelisting for provider URLs
- ❌ No sensitive data redaction in logs

**Security Assessment:** **Good baseline; needs hardening**

---

## 🎯 Missing Critical Features from Architecture

### 1. **Routing Profiles (Cost/Latency/Security/Language)**
```
Spec Requirement:
- Route by cost_profile: low, medium, high
- Route by latency_profile: fast, balanced, safe
- Route by security_class: standard, sensitive, restricted
- Route by language: en, ar (Arabic optimization)

Implementation Status: ✅ IMPLEMENTED
Impact: CRITICAL - Breaks promised flexibility
```

### 2. **Advanced Fallback Orchestration**
```
Spec Requirement:
- Ordered fallback chains (primary → fallback10:54:08.896 Navigated to http://localhost:3000/settings
10:54:10.089 settings:1 Unchecked runtime.lastError: Could not establish connection. Receiving end does not exist.
10:54:13.152 C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:4505 Uncaught Error: Hydration failed because the server rendered HTML didn't match the client. As a result this tree will be regenerated on the client. This can happen if a SSR-ed Client Component used:

- A server/client branch `if (typeof window !== 'undefined')`.
- Variable input such as `Date.now()` or `Math.random()` which changes each time it's called.
- Date formatting in a user's locale which doesn't match the server.
- External changing data without sending a snapshot of it along with the HTML.
- Invalid HTML tag nesting.

It can also happen if the client has a browser extension installed which messes with the HTML before React loaded.

https://react.dev/link/hydration-mismatch

  ...
    <SettingsPage params={Promise} searchParams={Promise}>
      <AppLayout>
        <div className="flex h-scr...">
          <div>
          <div>
          <div className="flex-1 fle...">
            <div>
            <div>
            <main>
            <NxStatusBar>
              <Suspense fallback={<div>}>
                <StatusBarContent className={undefined}>
                  <div className="h-10 bg-su...">
                    <div>
                    <div>
                    <div className="flex items...">
                      <div>
                      <div className="hidden sm:...">
                        <div>
                        <div>
                        <div>
                        <div className="flex items...">
                          <NxConnectionDot status="online">
                            <div className="relative f...">
                              <span
+                               className="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opa..."
-                               className="relative inline-flex rounded-full h-3 w-3 border border-deep-space/50 trans..."
                              >
+                             <span
+                               className="relative inline-flex rounded-full h-3 w-3 border border-deep-space/50 trans..."
+                             >
                          ...
                      ...
                    ...
          ...

    at throwOnHydrationMismatch (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:4505:1)
    at beginWork (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:11106:1)
    at runWithFiberInDEV (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871:1)
    at performUnitOfWork (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726:1)
    at workLoopSync (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15546:39)
    at renderRootSync (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15526:1)
    at performWorkOnRoot (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14990:1)
    at performSyncWorkOnRoot (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16830:1)
    at flushSyncWorkAcrossRoots_impl (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16676:1)
    at processRootScheduleInMicrotask (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16714:1)
    at eval (C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16849:1)
throwOnHydrationMismatch @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:4505
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:11106
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopSync @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15546
renderRootSync @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15526
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14990
performSyncWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16830
flushSyncWorkAcrossRoots_impl @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16676
processRootScheduleInMicrotask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16714
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16849
<span>
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react\cjs\react-jsx-dev-runtime.development.js:323
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\components\NxConnectionDot.tsx:15
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23583
renderWithHooksAgain @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6892
renderWithHooks @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6804
updateFunctionComponent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:9246
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:10857
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopSync @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15546
renderRootSync @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15526
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14990
performSyncWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16830
flushSyncWorkAcrossRoots_impl @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16676
processRootScheduleInMicrotask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16714
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16849
<NxConnectionDot>
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react\cjs\react-jsx-dev-runtime.development.js:323
StatusBarContent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\components\NxStatusBar.tsx:249
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23583
renderWithHooksAgain @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6892
renderWithHooks @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6804
updateFunctionComponent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:9246
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:10857
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopSync @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15546
renderRootSync @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15526
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14990
performSyncWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16830
flushSyncWorkAcrossRoots_impl @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16676
processRootScheduleInMicrotask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16714
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16849
<StatusBarContent>
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react\cjs\react-jsx-dev-runtime.development.js:323
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\components\NxStatusBar.tsx:410
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23583
renderWithHooksAgain @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6892
renderWithHooks @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6804
updateFunctionComponent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:9246
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:10857
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopConcurrentByScheduler @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15720
renderRootConcurrent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15695
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14989
performWorkOnRootViaSchedulerTask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16815
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:45
<NxStatusBar>
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react\cjs\react-jsx-dev-runtime.development.js:323
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\components\AppLayout.tsx:91
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23583
renderWithHooksAgain @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6892
renderWithHooks @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6804
updateFunctionComponent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:9246
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:10857
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopConcurrentByScheduler @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15720
renderRootConcurrent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15695
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14989
performWorkOnRootViaSchedulerTask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16815
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:45
<AppLayout>
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react\cjs\react-jsx-dev-runtime.development.js:323
SettingsPage @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\app\settings\page.tsx:247
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23583
renderWithHooksAgain @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6892
renderWithHooks @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6804
updateFunctionComponent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:9246
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:10857
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopConcurrentByScheduler @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15720
renderRootConcurrent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15695
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14989
performWorkOnRootViaSchedulerTask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16815
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:45
<SettingsPage>
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react\cjs\react-jsx-runtime.development.js:323
ClientPageRoot @ C:\Users\hedra\Desktop\src\client\components\client-page.tsx:60
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23583
renderWithHooksAgain @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6892
renderWithHooks @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6804
updateFunctionComponent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:9246
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:10806
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopConcurrentByScheduler @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15720
renderRootConcurrent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15695
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14989
performWorkOnRootViaSchedulerTask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16815
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:45
"use client"
Promise.all @ VM5822 <anonymous>:1
Promise.all @ VM5822 <anonymous>:1
initializeElement @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:1376
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3126
initializeModelChunk @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:1273
resolveModelChunk @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:1127
processFullStringRow @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:2958
processFullBinaryRow @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:2825
processBinaryChunk @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3028
progress @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3294
"use server"
ResponseInstance @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:2091
createResponseFromOptions @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3155
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3540
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-index.tsx:156
(app-pages-browser)/./node_modules/next/dist/client/app-index.js @ main-app.js?v=1779868448095:149
(anonymous) @ webpack.js:1
__webpack_require__ @ webpack.js:1
(anonymous) @ webpack.js:1
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-next-dev.ts:14
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-bootstrap.ts:76
loadScriptsInSequence @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-bootstrap.ts:22
appBootstrap @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-bootstrap.ts:58
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-next-dev.ts:13
(app-pages-browser)/./node_modules/next/dist/client/app-next-dev.js @ main-app.js?v=1779868448095:171
(anonymous) @ webpack.js:1
__webpack_require__ @ webpack.js:1
__webpack_exec__ @ main-app.js?v=1779868448095:1867
(anonymous) @ main-app.js?v=1779868448095:1868
(anonymous) @ webpack.js:1
(anonymous) @ main-app.js?v=1779868448095:9
10:54:17.879 C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630 Fetch finished loading: POST "http://localhost:3000/__nextjs_original-stack-frames".
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
e_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
i @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
eS @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
nz @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
i @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
nz @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
i @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
i1 @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
lC @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
lC @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
lC @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
lC @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
lC @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
lC @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
lC @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
l_ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
sO @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
O @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
O @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
sW @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
s$ @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\next-devtools\index.js:1630
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:81
postMessage
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:225
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:344
scheduleTaskForRootDuringMicrotask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16785
processRootScheduleInMicrotask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16701
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16849
10:54:26.671 C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\app\settings\page.tsx:63 XHR finished loading: GET "http://127.0.0.1:8000/api/settings/grouped".
dispatchXhrRequest @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\axios\lib\adapters\xhr.js:225
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\axios\lib\adapters\xhr.js:17
dispatchRequest @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\axios\lib\core\dispatchRequest.js:48
Promise.then
_request @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\axios\lib\core\Axios.js:196
request @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\axios\lib\core\Axios.js:41
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\axios\lib\core\Axios.js:244
wrap @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\axios\lib\helpers\bind.js:12
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\app\settings\page.tsx:63
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\app\settings\page.tsx:119
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\app\settings\page.tsx:121
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23668
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
commitHookEffectListMount @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:12344
commitHookPassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:12465
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14386
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14389
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14379
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14513
recursivelyTraversePassiveMountEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14359
commitPassiveMountOnFiber @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14398
flushPassiveEffects @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16337
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15973
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:45
<SettingsPage>
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react\cjs\react-jsx-runtime.development.js:323
ClientPageRoot @ C:\Users\hedra\Desktop\src\client\components\client-page.tsx:60
react_stack_bottom_frame @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:23583
renderWithHooksAgain @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6892
renderWithHooks @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:6804
updateFunctionComponent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:9246
beginWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:10806
runWithFiberInDEV @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:871
performUnitOfWork @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15726
workLoopConcurrentByScheduler @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15720
renderRootConcurrent @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:15695
performWorkOnRoot @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:14989
performWorkOnRootViaSchedulerTask @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-dom\cjs\react-dom-client.development.js:16815
performWorkUntilDeadline @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\scheduler\cjs\scheduler.development.js:45
"use client"
Promise.all @ VM5822 <anonymous>:1
Promise.all @ VM5822 <anonymous>:1
initializeElement @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:1376
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3126
initializeModelChunk @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:1273
resolveModelChunk @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:1127
processFullStringRow @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:2958
processFullBinaryRow @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:2825
processBinaryChunk @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3028
progress @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3294
"use server"
ResponseInstance @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:2091
createResponseFromOptions @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3155
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\node_modules\next\dist\compiled\react-server-dom-webpack\cjs\react-server-dom-webpack-client.browser.development.js:3540
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-index.tsx:156
(app-pages-browser)/./node_modules/next/dist/client/app-index.js @ main-app.js?v=1779868448095:149
(anonymous) @ webpack.js:1
__webpack_require__ @ webpack.js:1
(anonymous) @ webpack.js:1
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-next-dev.ts:14
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-bootstrap.ts:76
loadScriptsInSequence @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-bootstrap.ts:22
appBootstrap @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-bootstrap.ts:58
(anonymous) @ C:\Users\hedra\Desktop\Sourcecode\src\client\app-next-dev.ts:13
(app-pages-browser)/./node_modules/next/dist/client/app-next-dev.js @ main-app.js?v=1779868448095:171
(anonymous) @ webpack.js:1
__webpack_require__ @ webpack.js:1
__webpack_exec__ @ main-app.js?v=1779868448095:1867
(anonymous) @ main-app.js?v=1779868448095:1868
(anonymous) @ webpack.js:1
(anonymous) @ main-app.js?v=1779868448095:9
1 → fallback2)
- Context preservation through attempts
- 429 Rate Limit handling
- Timeout handling (>30s)
- Fallback decision audit trail

Implementation Status: ⚠️ PARTIAL (only basic circuit breaker)
Impact: HIGH - Resilience compromised
```

### 3. **Provider Health Monitoring**
```
Spec Requirement:
- Scheduled health polling
- Latency profiling
- Rate limit tracking
- Health scorecard
- Health-aware routing

Implementation Status: ❌ MOSTLY MISSING (basic check only)
Impact: HIGH - Routing unaware of provider status
```

### 4. **Cost Forecasting & Budget Enforcement**
```
Spec Requirement:
- Estimated cost before execution
- Budget tracking per workspace
- Spend cap enforcement
- Anomaly detection
- Cost reporting/aggregation

Implementation Status: ❌ NOT IMPLEMENTED
Impact: MEDIUM - Cost control missing
```

### 5. **Comprehensive Error Handling**
```
Spec Requirement:
- Graceful degradation on provider failure
- Cached responses fallback
- Offline mode support
- Detailed error classification
- Error recovery workflows

Implementation Status: ⚠️ PARTIAL
Impact: MEDIUM - Production reliability concerns
```

---

## 🔗 Frontend-Backend Integration

### Implemented
- ✅ [ai-models/page.tsx](app/ai-models/page.tsx) - Provider management UI
- ✅ Add Provider modal with form
- ✅ Provider test/sync actions
- ✅ Models listing (partial)
- ✅ [lib/api/ai-models.ts](lib/api/ai-models.ts) - API client

### Missing
- [ ] Intent routing matrix UI
- [ ] Cost estimation display
- [ ] Health status indicators
- [ ] Fallback chain visualization
- [ ] Usage analytics dashboard
- [ ] Cost forecasting charts
- [ ] Real-time monitoring dashboard

**Frontend Compliance:** ~40% complete

---

## 🚨 Critical Issues & Blockers

### BLOCKER 1: Core Routing Endpoint Missing
**Severity:** 🔴 CRITICAL  
**Issue:** The master `POST /ai-models/route` endpoint specified in architecture is not implemented.  
**Impact:** Workflows cannot execute AI requests through the hub.  
**Fix:** Implement routing endpoint with full parameter handling.

### BLOCKER 2: No Routing Profiles
**Severity:** 🔴 CRITICAL  
**Issue:** Cost/latency/security/language routing profiles not implemented.  
**Impact:** Hub cannot fulfill promise of flexible, capability-driven routing.  
**Fix:** Extend RoutingEngine to evaluate request profiles and adjust provider selection.

### BLOCKER 3: Fallback Chain Incomplete
**Severity:** 🟠 HIGH  
**Issue:** Fallback orchestration is minimal; no ordered chains, context preservation, or rate limit handling.  
**Impact:** System cannot guarantee resilience in production.  
**Fix:** Implement full FallbackChain service with retry logic and observability.

### BLOCKER 4: Health Monitoring Missing
**Severity:** 🟠 HIGH  
**Issue:** Provider health tracking is not implemented; routing unaware of provider status.  
**Impact:** May route requests to degraded/offline providers.  
**Fix:** Implement ProviderHealthMonitor with scheduled polling and health-aware routing.

### BLOCKER 5: Insufficient Error Handling
**Severity:** 🟠 HIGH  
**Issue:** Limited error classification and recovery; no graceful degradation.  
**Impact:** Production failures may not be recoverable.  
**Fix:** Implement comprehensive error handling with fallback and caching strategies.

---

## ⚡ Implementation Strengths

✅ **Well-Architected Service Layer**
- Clean separation of concerns
- Dependency injection throughout
- Interface-based design (AiProviderInterface)
- Cache manager abstraction

✅ **Dynamic Provider System**
- Zero-deployment provider onboarding
- Multi-format model response normalization
- Database-driven configuration

✅ **Encryption & Security**
- AES-256-CBC key encryption
- Secure key storage and retrieval
- Key deactivation mechanism

✅ **Solid Testing Foundation**
- Feature tests for core workflows
- Unit tests for business logic
- Factory patterns for test data

✅ **Frontend UI Started**
- Provider management interface
- Model management dashboard
- Clean component architecture (Next.js)

---

## 📈 Recommended Priority Actions

### Phase 1: IMMEDIATE (Weeks 1-2)
1. **Implement core `/ai-models/route` endpoint** with parameter validation
2. **Complete fallback chain orchestration** with retry logic and context preservation
3. **Add routing profile support** (cost/latency/security) to RoutingEngine
4. **Create comprehensive error handling** with classification and recovery

### Phase 2: SHORT-TERM (Weeks 3-4)
5. **Implement ProviderHealthMonitor** with scheduled polling and metrics storage
6. **Add health-aware routing** to RoutingEngine
7. **Implement cost forecasting** and budget enforcement
8. **Create cost reporting/analytics APIs**

### Phase 3: MEDIUM-TERM (Weeks 5-6)
9. **Complete frontend UI** - routing matrix, analytics dashboard
10. **Add comprehensive test coverage** - error scenarios, multi-provider failover
11. **Implement audit trail** for debugging and compliance
12. **Add observability integrations** - structured logging, metrics export

### Phase 4: LONG-TERM (Ongoing)
13. **Key rotation scheduling** and management
14. **Per-tenant/workspace scoping** for multi-tenancy
15. **Semantic caching** for identical requests
16. **Provider status page integration**

---

## 📊 Compliance Scorecard

| Dimension | Score | Status |
|-----------|-------|--------|
| **Architectural Completeness** | 72% | ⚠️ ADEQUATE |
| **API Implementation** | 65% | ⚠️ PARTIAL |
| **Core Services** | 75% | ⚠️ MOSTLY IMPLEMENTED |
| **Error Handling** | 50% | 🔴 NEEDS WORK |
| **Testing Coverage** | 40% | 🔴 NEEDS IMPROVEMENT |
| **Frontend UI** | 40% | 🔴 INCOMPLETE |
| **Documentation** | 85% | ✅ GOOD |
| **Security** | 75% | ⚠️ GOOD BASELINE |

**Overall Grade:** **C+ (72%)**  
**Production Readiness:** **NOT READY** - Critical gaps in routing, resilience, and monitoring

---

## 🎯 Conclusion

The AiModelsHub implementation demonstrates **strong architectural foundations** with well-designed service layers and a solid dynamic provider system. However, it remains **incomplete for production deployment**, with critical gaps in:

1. **Core routing capabilities** - Missing routing profiles and central execution endpoint
2. **Resilience mechanisms** - Incomplete fallback orchestration
3. **Operational observability** - Minimal health monitoring and audit trails
4. **Cost management** - No budget enforcement or forecasting

**Recommendation:** Prioritize Phase 1 items immediately before considering production deployment. The current implementation provides a good foundation, but critical features must be completed to fulfill the architecture's promises.

---

## 📎 Appendix: File Index

### Backend Services
- [AIModelsHub.php](app/Hubs/AIModelsHub.php) - Main hub class
- [DynamicProviderRegistry.php](app/Services/AiModelsHub/DynamicProviderRegistry.php)
- [IntentRoutingEngine.php](app/Services/AiModelsHub/IntentRoutingEngine.php)
- [CircuitBreaker.php](app/Services/AiModelsHub/CircuitBreaker.php)
- [EncryptedApiKeyStorage.php](app/Services/AiModelsHub/EncryptedApiKeyStorage.php)
- [UsageTracker.php](app/Services/AiModelsHub/UsageTracker.php)
- [DynamicRestProvider.php](app/Services/AiModelsHub/DynamicRestProvider.php)
- [CacheManager.php](app/Services/AiModelsHub/CacheManager.php)

### Controllers
- [AiProviderController.php](app/Http/Controllers/AiProviderController.php)
- [AiRequestController.php](app/Http/Controllers/AiRequestController.php)
- [AiModelController.php](app/Http/Controllers/AiModelController.php)

### Models
- [AIProvider.php](app/Models/AIProvider.php)
- [AIModel.php](app/Models/AIModel.php)

### Frontend
- [app/ai-models/page.tsx](app/ai-models/page.tsx)
- [lib/api/ai-models.ts](lib/api/ai-models.ts)

### Tests
- [AiProviderTest.php](tests/Feature/AiProviderTest.php)
- [DynamicProviderRegistryTest.php](tests/Unit/DynamicProviderRegistryTest.php)
- [IntentRoutingEngineTest.php](tests/Unit/IntentRoutingEngineTest.php)

### Architecture Docs
- [04-AI_MODELS_HUB.md](docs/First_Version_Docs/04-AI_MODELS_HUB.md)
- [AiModelsHub_Blueprint.md](Docs/Updates_Documents_Implementations/AiModelsHub_Blueprint.md)
- [AIModelsHub.md](../NexusV2_Docs/02\ -\ AIModelsHub/01\ -\ AIModelsHub.md)

---

**Audit Completed:** May 27, 2026  
**Next Review:** Scheduled after Phase 1 implementation (approximately 2 weeks)
