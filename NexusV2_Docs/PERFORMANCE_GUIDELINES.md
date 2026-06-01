# 07 - Performance Guidelines

## Purpose
Set performance expectations and rules for Nexus so the system remains responsive and scalable.

---

## 1. Performance Targets
- API response latency: < 2 seconds for 95% of requests
- Memory retrieval latency: < 500ms average
- Frontend first paint: < 1 second on modern devices
- Background task scheduling: < 5 second enqueue time

## 2. Caching Strategy
- Cache AI prompt templates and settings
- Cache contact profile metadata for fast lookup
- Use Redis for working memory and session data
- Use semantic caching to reduce repeated embedding operations

## 3. Query Optimization
- Use pagination on list endpoints
- Index frequently filtered columns
- Avoid N+1 queries with eager loading
- Use query projections for large datasets

## 4. Background Work
- Use queues for long-running processing
- Keep synchronous API calls fast by offloading heavy tasks
- Monitor queue latency and backlog
- Use job batching for memory consolidation and analytics

## 5. AI Efficiency
- Use smaller models for lightweight tasks
- Use prompt pruning and summarization for long contexts
- Cache identical prompt results where safe
- Select providers based on cost and latency

## 6. Frontend Performance
- Lazy-load non-critical components
- Use asset hashing and caching via Vite
- Optimize images and icons
- Minimize DOM complexity for chat views

## 7. Observability
- Track response times per endpoint and per hub
- Monitor memory and queue utilization
- Alert when key performance thresholds are breached
- Capture performance metrics in LogsHub and dashboard
