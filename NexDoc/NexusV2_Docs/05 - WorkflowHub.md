# 05 - WorkflowHub

## Overview
WorkflowHub provides a visual canvas for designing distributed pipelines and linking multiple agents or tasks into cohesive automated processes.

## Architecture & Integration
- **Next.js App Router:** `/app/workflows`
- **State Management:** `useWorkflowsStore.ts` manages node positions, edge connections, and overall graph state.
- **UI Tools:** Implements `@xyflow/react` for node-based graph rendering, `NxWorkflowNode`, and `NxWorkflowCanvas`.

## Key Features
- **Drag-and-Drop Canvas:** Intuitive building of execution flows.
- **Event Triggers:** Define start conditions and data routing between steps.
- **Live Debugging:** Visual trace of data as it passes through the workflow graph.
