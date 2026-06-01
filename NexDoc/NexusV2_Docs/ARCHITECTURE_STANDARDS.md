# Architecture Standards

## Core Principles
1. **Separation of Concerns:** The Next.js frontend is strictly decoupled from the Laravel/PHP backend.
2. **Component-Driven Design:** UI is broken down into reusable `Nx` prefixed components.
3. **Client-Side State Bias:** Utilizing Zustand for robust client-side state, hydrated with `localStorage`.
4. **Mocked Previews:** As indicated in API documentation, external fetch routes are mocked/proxied in client interfaces for preview functionality.

## Tech Stack
- **Framework:** Next.js 15+ (App Router)
- **Language:** TypeScript 5+
- **Styling:** Tailwind CSS (v4) with PostCSS
- **State:** Zustand 5.x
- **Animations:** framer-motion (Motion 12.x)

## Directory Structure Strategy
- `/app`: Route definitions and entry points.
- `/components`: Reusable UI.
- `/lib`: Core utilities, API clients, and auth logic.
- `/store`: Global state definitions.
