
## 3. SettingsHub UI_Design_Layout (Frontend - Next.js 15)

### 3.1 Layout & Navigation
The `SettingsHub` uses a two-pane layout:
*   **Left Pane (Sidebar Menu):** Vertical navigation tabs (General, Integrations, Health & Diagnostics, Database Seeds, Advanced).
*   **Right Pane (Content Area):** Displays the selected configuration forms using `NxGlassCard` wrappers.

### 3.2 State Management (Zustand: `useSettingsStore`)
*   **State:**
    *   `settings`: Record<string, any>
    *   `healthStatus`: Record<string, 'healthy' | 'unhealthy' | 'checking'>
    *   `isSaving`: boolean
*   **Actions:**
    *   `fetchSettings()`
    *   `updateSettings(payload: Record<string, any>)` - Optimistic UI update, reverts on API error.
    *   `fetchHealthStatus()`
    *   `triggerSystemSeeds()`

### 3.3 UI Components & UX Flow
*   **General Tab:**
    *   Forms utilizing `NxInput` for text variables and `NxSwitch` for boolean toggles.
*   **Integrations Tab:**
    *   Inputs for WAHA Endpoint, Neo4j Credentials, Pinecone API Key.
    *   Uses a custom `NxSecretInput` (masks characters as asterisks, with a "reveal" eye icon).
*   **Health & Diagnostics Tab:**
    *   A grid of `NxStatusBadge` components.
    *   Green dot + "Operational" for healthy, Red dot + "Offline" for unhealthy.
    *   Includes a "Refresh Health Check" `NxActionButton`.
*   **Database Seeds Tab:**
    *   A warning banner explaining that running seeds will reset missing system constants (Contact Types, Memory Types).
    *   A primary `NxActionButton` labeled "Run System Seeds" that triggers a confirmation `NxModal` before executing.
*   **Advanced Tab (Danger Zone):**
    *   Red-themed `NxGlassCard`.
    *   "Global Agent Pause" `NxSwitch` to instantly kill all outbound AI communications.

---