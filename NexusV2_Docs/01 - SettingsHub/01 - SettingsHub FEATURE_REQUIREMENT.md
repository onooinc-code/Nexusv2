
# ⚙️ SettingsHub - Master Documentation

## 1. SettingsHub FEATURE_REQUIREMENT

### 1.1 Overview

The `SettingsHub` is the centralized configuration and control panel for the Nexus Cognitive Digital Twin Platform. It is responsible for managing global system variables, third-party integration credentials (excluding dynamic AI models, which reside in AIModelsHub), system health monitoring, and global database seeding (default constants).

### 1.2 Core Capabilities & Features

*   **Global System Settings:** Manage core platform configurations such as default timezone, UI theme enforcement, and logging verbosity.
*   
*   **Third-Party Credentials Manager:** Securely store and update keys and webhook endpoints for external services like WAHA (WhatsApp API), Pinecone (Vector DB), and Neo4j (Graph DB).
*   
*   **System Health Dashboard:** Real-time ping and status checks for all critical infrastructure components (MySQL, Redis, Pinecone, Neo4j, WAHA).
*   
*   **Database Seed Manager:** A dedicated UI to trigger or re-run system constants seeders (e.g., Contact Types, Memory Types, Task Statuses). This ensures the platform's core lookup data is always intact without dropping existing user data (Upsert mechanism).
*   
*   **Global Emergency Controls (Advanced/Danger Zone):**
    *   *Global Agent Pause:* A master switch to instantly halt all AI agents from sending outgoing messages across the platform.
    *   *System Maintenance Mode:* Toggle the application into maintenance mode if required.
