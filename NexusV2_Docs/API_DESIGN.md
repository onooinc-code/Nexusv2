# 05 - API Design (OpenAPI snippets & conventions)

Principles
- RESTful, versioned, discoverable APIs with consistent success/error envelopes.
- Small payloads, cursor pagination, idempotency for writes, and clear schema versions.

Common headers
- `Authorization: Bearer <token>`
- `X-Trace-Id: <uuid>`
- `X-Idempotency-Key: <string>` (for write endpoints)
- `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

Common response envelopes
- Success:
  ```json
  { "data": <any>, "meta": { "timestamp": "iso", "schema_version": "1" } }
  ```
- Error:
  ```json
  { "errors": [{ "code": "ERR_INVALID_INPUT", "message": "...", "details": {...} }], "meta": {...} }
  ```

OpenAPI (YAML) snippets

Memory search:

```yaml
paths:
  /api/v1/memory/search:
    post:
      summary: Semantic memory search
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                query:
                  type: string
                vector:
                  type: array
                  items:
                    type: number
                top_k:
                  type: integer
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SearchResponse'
components:
  schemas:
    SearchResponse:
      type: object
      properties:
        data:
          type: array
          items:
            type: object
            properties:
              id: { type: string }
              score: { type: number }
              snippet: { type: string }
        meta: { type: object }
```

Task creation (idempotent):

```yaml
paths:
  /api/v1/tasks:
    post:
      summary: Create or enqueue a task
      parameters:
        - name: X-Idempotency-Key
          in: header
          required: false
      requestBody: { ... }
      responses:
        '202': { description: Accepted }
```

Pagination
- Use cursor-based pagination: `?limit=50&cursor=eyJvZmZzZXQiOjEwMH0=`. Include `meta.next_cursor`.

Security
- OAuth2 for external clients; JWT/mTLS for service-to-service. Scope-based RBAC.

Idempotency & retries
- Persist `idempotency_key` with response; repeat requests return stored response.

Rate limiting
- API Gateway enforces per-key quotas and returns `429` with `Retry-After` header.

Best practices
- Provide `openapi.json` for each hub at `/api/v1/{hub}/openapi.json`.
- Include `schema_version` in event payloads and responses for forward/backward compatibility.

Example cURL (memory search):

```bash
curl -X POST 'https://api.example.com/api/v1/memory/search' \
  -H 'Authorization: Bearer $TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"query":"meeting notes", "top_k":5}'
```
# 05 - API Design

Conventions:
- Use RESTful resources with clear nouns, HTTP verbs for actions, and consistent status codes.
- Versioning: Path-based (`/api/v1/`), bump major for breaking changes.
- Authentication: JWT for internal clients, OAuth2 for external integrations.

Request & Response:
- All responses: `{ data: any, meta?: object, errors?: array }`.
- Errors standard: `{ code: string, message: string, details?: object }`.

Pagination & Filtering:
- Use cursor-based pagination for large sets: `?limit=50&cursor=abc123`.
- Support filter and sort via query params: `?filter[status]=open&sort=-created_at`.

Idempotency:
- POST endpoints that create resources should accept `Idempotency-Key` and return the same resource for repeated requests.

Rate limiting & Throttling:
- Gate at the API gateway per client key; expose `X-RateLimit-*` headers.

Security:
- Validate inputs server-side, enforce field-level encryption for sensitive data, and scrub provider keys from logs.

Example endpoint spec (Memory search):
- `POST /api/v1/memory/search`
- Body: `{ query: string, top_k?: number, filters?: object, vector?: number[] }`
- Response: `{ data: [{ id, score, source, snippet }], meta: { took_ms } }`
