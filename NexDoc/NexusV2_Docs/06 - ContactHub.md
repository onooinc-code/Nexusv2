# 06 - ContactHub

## Overview
ContactHub functions as the intelligence relational database. It stores detailed profiles, communication histories, and generated insights for external entities or users.

## Architecture & Integration
- **Next.js App Router:** `/app/contacts`
- **State Management:** Interfaces with the `/v1/contacts` API endpoints for CRUD operations.
- **UI Components:** Extensive use of `NxContactCard3D`, `NxTable`, and `NxRelationTimeline`.

## Key Features
- **3D Profile Views:** Immersive contact cards highlighting key attributes.
- **Relationship Mapping:** Visualizing connections between different contacts and associated agent workflows.
- **AI Synthesis:** Generating summaries of past interactions using background Gemini models.
