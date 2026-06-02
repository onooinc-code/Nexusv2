# System Architecture

The Nexus platform employs a distributed client-server architecture with real-time capabilities.

## Frontend (NexusNext)
- Hosted independently, built with Next.js App Router.
- Manages view rendering, user interactions, and local state caching via Zustand.

## Backend (NexusCore)
- Laravel-based API layer.
- Handles persistent storage, authentication (Sanctum), and heavy compute tasks.

## Real-Time Layer
- Laravel Reverb (or Pusher) manages WebSockets.
- Frontend uses Laravel Echo to subscribe to channels like `conversation.{id}` and `job.{id}`.

## AI Integration Layer
- Interacts with Google Gemini APIs (`gemini-3.5-flash`, `gemini-3.1-pro-preview`).
- Routing may occur directly from client for speed (with local keys) or proxied through the backend for security and logging.
