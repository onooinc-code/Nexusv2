# Event Architecture

## Real-Time WebSockets
The event architecture is heavily dependent on WebSocket connections to provide a reactive user experience.

- **Channels:** Private channels are used for secure communication.
- **Listeners:** Components use custom hooks (e.g., `useWebSocket.ts`) or `RealTimeJobListener.tsx` at the `RootLayout` level to listen globally.
- **Payloads:** Event payloads are standardized JSON structures containing event type, status, and related data IDs.

## Client-Side Event Bus
- Zustand acts as a pseudo-event bus for state updates across disparate components. Actions defined in the store trigger reactivity in subscribed components.
