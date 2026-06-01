# Nexus V2 TaskHub Implementation - Remaining Tasks

## Backend Tasks Remaining

### 1. Task Scheduling Service (Phase 2)
- [ ] Create `app/Services/TaskSchedulingService.php`
- [ ] Create `app/Console/Commands/EvaluateScheduledTasks.php`
- [ ] Update `app/Console/Kernel.php` to register the scheduler command
- [ ] Implement cron-based recurring tasks functionality
- [ ] Implement one-time task scheduling

### 2. Rate Limiting & Concurrency (Phase 4)
- [ ] Create `app/Http/Middleware/TaskRateLimiting.php`
- [ ] Add rate limiting middleware to task routes in routes/api.php
- [ ] Enhance TaskExecutionService with backpressure logic
- [ ] Implement progressive backoff (60s/180s/300s) based on queue load

### 3. Dead Letter Queue (Phase 4)
- [ ] Create `app/Models/DeadLetterTask.php`
- [ ] Create migration: `[timestamp]_create_dead_letter_tasks_table.php`
- [ ] Create `app/Services/DeadLetterQueueService.php`
- [ ] Create `app/Http/Controllers/Admin/DLQController.php`
- [ ] Add DLQ routes to routes/api.php
- [ ] Implement automatic DLQ movement for repeatedly failing tasks

### 4. API Refinements (Phase 3)
- [ ] Create `app/Http/Requests/CreateTaskRequest.php`
- [ ] Create `app/Http/Requests/UpdateTaskRequest.php`
- [ ] Create `app/Http/Resources/TaskResource.php`
- [ ] Create `app/Http/Resources/TaskCollection.php`
- [ ] Create `app/DTOs/TaskLogDTO.php`
- [ ] Update TaskController to use Request validation and Resources

### 5. Testing Suite (Phase 4)
- [ ] Create `tests/Unit/Services/TaskManagementServiceTest.php`
- [ ] Create `tests/Unit/Services/TaskExecutionServiceTest.php`
- [ ] Create `tests/Unit/Jobs/ExecuteAgentTaskJobTest.php`
- [ ] Create `tests/Feature/TaskApiTest.php`
- [ ] Create `tests/Feature/TaskExecutionTest.php`
- [ ] Create `tests/Feature/TaskEventsTest.php`
- [ ] Create `tests/Performance/TaskBenchmark.php`

## Frontend Tasks Remaining

### 1. TypeScript Types (Phase 3)
- [ ] Update `Nexus-Frontend/types/index.ts`:
  - Add `type: 'manual' | 'agent' | 'system'` to Task interface
  - Add `contact_id?: string` to Task interface
  - Add `conversation_id?: string` to Task interface
  - Add `payload_data?: Record<string, any>` to Task interface
  - Add `result_data?: Record<string, any>` to Task interface
  - Update status type to include all 6 states: `'todo' | 'in-progress' | 'blocked' | 'completed' | 'failed' | 'cancelled'`
  - Update priority type to match backend integer mapping or keep string with conversion

### 2. State Management Updates (Phase 3)
- [ ] Update `Nexus-Frontend/store/index.ts`:
  - Extend Task interface usage in store
  - Update hydrateTasks() to map new fields from API
  - Update createTask() to handle new fields
  - Add new task actions:
    - executeTask(id: string): Promise<void>
    - getTaskLogs(id: string, limit?: number): Promise<any[]>
    - updateTaskStatus(id: string, status: Task['status']): void
    - getTasksByType(type: string): Promise<Task[]>
    - getTaskStatsByType(): Promise<any>

### 3. Components Creation (Phase 3)
- [ ] Create `Nexus-Frontend/components/NxTaskModal.tsx`:
  - Full create/edit modal with type selection (manual/agent/system)
  - Form fields for all new task properties
  - Validation and submission handling
  - Integration with store for optimistic updates

- [ ] Create `Nexus-Frontend/components/NxTaskExecutionLog.tsx`:
  - Real-time log terminal display
  - Subscription to task-specific logs via WebSocket
  - Auto-scroll functionality
  - Clear logs button
  - Log level filtering

### 4. WebSocket Integration (Phase 3)
- [ ] Create `Nexus-Frontend/hooks/useReverbChannel.ts`:
  - Custom hook for subscribing to Reverb channels
  - Handle task-specific events (task.{id})
  - Handle global task events (tasks channel)
  - Automatic cleanup on unmount
  - Error handling and reconnection logic

### 5. Tasks Page Integration (Phase 3)
- [ ] Update `Nexus-Frontend/app/tasks/page.tsx`:
  - Replace NxDrawer with NxTaskModal for task creation/editing
  - Add sidebar/task details panel showing NxTaskExecutionLog when task is selected
  - Add kanban/table toggle view
  - Implement task type filtering
  - Add task statistics display
  - Implement real-time updates via Reverb hook
  - Add manual execute task button
  - Add task logs viewing capability

## Infrastructure Tasks

### 1. Queue Worker Setup
- [ ] Configure supervisor for Horizon agent-tasks queue
- [ ] Test queue processing with sample tasks
- [ ] Monitor job processing and retry behavior

### 2. Event Broadcasting
- [ ] Test that TaskCompletedEvent, TaskFailedEvent, TaskStatusChangedEvent are properly broadcast
- [ ] Verify frontend receives and handles these events
- [ ] Test WebSocket connections and event delivery

### 3. Environment Configuration
- [ ] Verify Redis is properly configured and running
- [ ] Verify Horizon is running and processing agent-tasks queue
- [ ] Check logs for any errors

## Implementation Order Recommendation

1. **Complete Backend Services First**:
   - Task Scheduling Service
   - Rate Limiting Middleware
   - Dead Letter Queue Implementation
   - API Refactoring (Requests/Resources)
   - Testing Suite

2. **Then Frontend Implementation**:
   - TypeScript type updates
   - Store updates
   - Component creation (Modal, Log)
   - WebSocket hook
   - Tasks page integration

3. **Finally Infrastructure and Testing**:
   - Queue worker configuration
   - Event broadcasting tests
   - Performance optimizations
   - Final QA and bug fixing

## Estimated Time Remaining: 3-4 weeks
- Backend services: 1 week
- Frontend implementation: 1-2 weeks
- Infrastructure and testing: 1 week