
### 3.1 Hub Layout & Navigation
The `AIModelsHub` follows a sophisticated multi-tab layout using a left-aligned vertical `NxNavRail` or top-aligned `NxTabs`.
*   **Tabs:** Dashboard (Telemetry), Providers, Instances, Task Routing, Testing Playground.

### 3.2 Tab Breakdown & Component Usage

**1. Dashboard (Telemetry & Analytics):**
*   **UI:** Top row of `NxMetricCard` showing (Total Tokens Today, Average Latency, Total Requests, Error Rate).
*   **Charts:** `NxLineChart` for API usage over time (Prompt vs. Completion tokens). `NxPieChart` for usage distribution across instances.
*   **Data Grid:** `NxDataGrid` showing the latest 100 telemetry logs (Timestamp, Task, Instance, Tokens, Latency, Status).

**2. Providers Management:**
*   **UI:** A grid of `NxGlassCard`. Each card represents a Provider with its logo, status (Active/Offline), and a "Sync Models" `NxActionButton`.
*   **Add Provider Flow:** An `NxModal` containing a stepper:
    *   Step 1: Provider Details (Name, Base URL, Chat Endpoint).
    *   Step 2: Authentication (Header Format, Encrypted `NxSecretInput` for API Key).
    *   Step 3: Test Connection & Fetch Models.

**3. Instances Configuration:**
*   **UI:** Table or list view of all created Instances.
*   **Add/Edit Form:** Uses `NxInput` (Name), `NxSelect` (Provider -> Model dependency dropdowns), `NxSlider` (Temperature 0.0 to 2.0), `NxInput` (Max Tokens).

**4. Task Routing (Job Config):**
*   **UI:** A structured `NxTable`.
*   **Columns:** Task Name (e.g., `Belief Auto-Update`), Description, Assigned Instance (`NxSelect`), Fallback Instance (`NxSelect`).
*   **UX:** Changing a dropdown immediately patches the backend API (Optimistic UI update) and shows an `NxToast` confirmation.

**5. Testing Playground:**
*   **UI:** A split-pane layout. Left side: Select an Instance. Right side: A simplified Chat UI (`NxChatBubble`, `NxChatInput`) to test the model's exact response and latency before assigning it to a live production task.

### 3.3 State Management (Zustand: `useAiModelsStore`)
*   **State:** `providers`, `models`, `instances`, `jobRoutes`, `telemetryStats`.
*   **Actions:** `fetchProviders()`, `addProvider(payload)`, `syncModels(providerId)`, `createInstance(payload)`, `updateJobRoute(taskName, instanceId)`.