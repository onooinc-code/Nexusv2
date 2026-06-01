# AgentsHub Visual Architecture & UI Design

This document provides visual diagrams and UI specifications for the AgentsHub implementation, illustrating how the backend architecture, execution flows, and frontend UI components interact.

## 1. System Architecture & Hub Integrations

The AgentsHub acts as the central orchestration engine. It does not execute LLMs directly; instead, it compiles the necessary context (Persona, Tools, API Keys) and interfaces with the broader Nexus ecosystem.

```mermaid
graph TD
    subgraph Frontend [Nexus Frontend - Next.js]
        UI[AgentsHub UI]
        State[Zustand Store]
        UI <--> State
    end

    subgraph AgentsHub [AgentsHub Backend - Laravel]
        Controller[Agent Controller]
        ExecService[Agent Execution Service]
        Persona[Persona Service]
        MCP[MCP Integration Service]
        DB[(Agents Database)]
        
        Controller --> ExecService
        Controller --> Persona
        Controller --> MCP
        ExecService --> DB
        Persona --> DB
        MCP --> DB
    end

    subgraph ExternalHubs [Nexus Ecosystem]
        AIModels[AIModelsHub]
        Settings[SettingsHub]
        Logs[LogsHub]
        Workflows[WorkflowsHub]
    end

    State <-->|REST / WebSocket| Controller
    ExecService -->|Fetch API Keys| Settings
    ExecService -->|Execute LLM Call| AIModels
    ExecService -->|Queue Async Task| Workflows
    ExecService -->|Push Traces| Logs
```

## 2. Agent Execution Flow

The Execution Flow handles both Synchronous (immediate response) and Asynchronous (background processing) modes.

```mermaid
sequenceDiagram
    participant User
    participant ExecService as AgentExecutionService
    participant Settings as SettingsHub
    participant AIModels as AIModelsHub
    participant Logs as LogsHub
    participant Workflows as WorkflowsHub

    User->>ExecService: POST /run {input, mode}
    
    ExecService->>ExecService: Load Agent & Persona
    ExecService->>ExecService: Attach Allowed Tools
    
    ExecService->>Settings: Fetch Tool API Keys
    Settings-->>ExecService: Return Decrypted Keys
    
    ExecService->>ExecService: Compile Execution Context
    
    alt Mode == "sync"
        ExecService->>AIModels: Execute LLM (Prompt + Tools)
        AIModels-->>ExecService: Return Result
        ExecService->>Logs: Push Execution Trace
        ExecService-->>User: 200 OK (Result)
    else Mode == "async"
        ExecService->>Workflows: Dispatch ExecuteAgentTaskJob
        Workflows-->>ExecService: Return Task ID
        ExecService-->>User: 202 Accepted (Task ID)
        
        Note over Workflows, AIModels: Background Processing
        Workflows->>AIModels: Execute LLM
        Workflows->>Logs: Push Trace
        Workflows->>User: WebSocket Event (agent.completed)
    end
```

## 3. Database Entity Relationship

```mermaid
erDiagram
    users ||--o{ agents : owns
    agent_personas ||--o{ agents : defines
    agents ||--o{ agent_runtime_logs : generates
    agents ||--o{ agent_tasks : executes

    agents {
        uuid id PK
        uuid owner_id FK
        uuid persona_id FK
        string name
        boolean is_system
        string status "active | inactive | quarantined"
        json skills "array of skill IDs"
        json tools "array of tool IDs"
    }

    agent_personas {
        uuid id PK
        string name
        text system_prompt
        json tone_preferences
    }

    mcp_servers {
        uuid id PK
        string name
        enum type "local | remote"
        json connection_config
        string status
    }

    agent_runtime_logs {
        uuid id PK
        uuid agent_id FK
        uuid task_id
        uuid trace_id
        string step
        json input
        json output
        int duration_ms
    }
```

## 4. Frontend UI Layout (Next.js)

The AgentsHub UI is a multi-tab interface built with `NxTabs`.

> [!TIP]
> **Design Philosophy**: Use rich aesthetics with glassmorphism, dynamic animations on state changes (e.g., executing agent pulsing), and deep dark modes.

````carousel
```mermaid
%% Slide 1: Main Dashboard Layout
block-beta
    columns 1
    Header["Nexus Header (Breadcrumbs, Profile)"]
    block:MainLayout
        columns 5
        Sidebar["Hub Sidebar Navigation"]:1
        block:Content
            columns 1
            Tabs["NxTabs (Registry | Personas | Skills | Tools | MCP | Sandbox)"]
            Grid["NxDataGrid: Agent Cards (Status, Type, Name)"]
        end:4
    end
```
<!-- slide -->
```mermaid
%% Slide 2: Sandbox / Playground Layout
block-beta
    columns 1
    Header["Sandbox Header - Select Agent & Mode"]
    block:SplitScreen
        columns 2
        InputArea["Left: NxTextArea (Mock Inputs, JSON config)"]
        OutputArea["Right: NxChatBubble (Thoughts, Tool Calls, Final Output)"]
    end
```
````

### Key UI Components

1.  **`NxAgentCard`**: Displays the agent's avatar, name, operational status badge (e.g., Green for Active, Red for Quarantined), and a lock icon if `is_system` is true.
2.  **`NxDrawer` (Agent Editor)**: Sliding panel from the right to edit the agent's properties, assign a persona, and toggle skills/tools.
3.  **`NxChatBubble`**: Used in the Sandbox to render streaming thoughts, tool invocations (with collapsible JSON data), and the final result.
4.  **Simulation Playground**: A split-screen layout for testing agents safely with mocked tool responses.
