# 04 - TasksHub

## Overview
TasksHub is the objective tracker and pipeline manager. It lists user-defined goals and autonomous agent-generated subtasks.

## Architecture & Integration
- **Next.js App Router:** `/app/tasks`
- **State Management:** Synchronizes task status with the backend `/v1/tasks` endpoint.
- **Real-Time Integration:** Updates progress percentages and completions via the global job monitor.

## Key Features
- **Task Delegation:** Assign specific objectives to dedicated agent personas.
- **Progress Tracking:** Visual representation of task phases using `TransitionProgressBar.tsx` and `NxDataGrid`.
- **Execution Logs:** Detailed audit logs of agent actions per task.
