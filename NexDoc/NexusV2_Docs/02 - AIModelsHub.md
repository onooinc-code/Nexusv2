# 02 - AIModelsHub

## Overview
The AIModelsHub is the intelligence monitoring center. It acts as the dashboard for tracking Large Language Model (LLM) utilization, health, and latency metrics across the Nexus ecosystem.

## Architecture & Integration
- **Next.js App Router:** `/app/ai-models`
- **State Management:** `useAppStore` (Zustand) is used to track overall LLM requests and token budgets.
- **UI Components:** Leverages `DashboardChart.tsx`, `NxModelSelector`, and `NxMetricCard`.

## Key Features
- **Latency Monitoring:** Tracks Time to First Byte (TTFB) and processing times for `gemini-3.5-flash` and `gemini-3.1-pro-preview`.
- **Token Budgeting:** Visualizes token usage for different active AI models.
- **Provider Status:** Displays real-time operational status (Online/Degraded) for various API providers.
