# 01 - SettingsHub

## Overview
SettingsHub serves as the central configuration matrix for the Nexus platform. It orchestrates user preferences, system-wide parameters, API integrations, and global theming.

## Architecture & Integration
- **Next.js App Router:** `/app/settings`
- **State Management:** Interacts with Zustand to persist global configurations and hydrate `localStorage`.
- **UI Components:** Utilizes `NxGlassCard`, `NxSwitch`, `NxInput`, `NxCommandBar`, and `ApiTesterPanel.tsx`.

## Key Features
- **API Management:** Testing and configuration of endpoints, particularly Gemini endpoints (e.g., `gemini-3.5-flash`).
- **Theme Controls:** Dark mode, light mode, and cosmic slate styling configuration via Next-Themes.
- **MCP Server Controls:** Registration, connection, and testing of external MCP (Model Context Protocol) servers.
