# API Design

## RESTful Endpoints
The platform utilizes standard RESTful conventions served by the Laravel backend under the `/api/v1/` namespace.

- **GET /v1/resource:** List or read data. Wrap responses in `{ data: [...] }`.
- **POST /v1/resource:** Create new entities.
- **PUT /v1/resource/{id}:** Update existing entities.
- **DELETE /v1/resource/{id}:** Remove entities.

## API Client Configuration
- Axios is configured in `/lib/api/client.ts`.
- Includes interceptors for injecting Auth tokens and handling global error responses (e.g., triggering Toast notifications for 401s).

## Error Handling
- Standard HTTP status codes are respected.
- Rate limiting (429) triggers specific UI feedback.
- Abandoned/failed jobs are caught and displayed in the `GlobalJobMonitor`.
