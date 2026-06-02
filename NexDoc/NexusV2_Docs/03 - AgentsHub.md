# 03 - AgentsHub

## Overview
The AgentsHub is the core command center for instantiating, modifying, and monitoring autonomous agents. It handles agent personas, capabilities, and real-time execution states.

## Architecture & Integration
- **Next.js App Router:** `/app/agents`
- **State Management:** Complex interactions via the `agents` and `personas` slices in Zustand (`/store/index.ts`).
- **Real-Time Updates:** Receives agent status broadcasts via Laravel Echo / Reverb WebSockets.

## Key Features
- **Agent Lifecycle Management:** Start, pause, or quarantine agents.
- **Persona Configuration:** Define unique system prompts and traits.
- **UI Tracking:** Uses `NxAgentCard`, `NxAgentStatusOrb`, and `NxAgentBadge` to represent agent health and activity.
