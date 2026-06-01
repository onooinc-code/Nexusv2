# TaskHub Remediation Guide - Phase 3
## API & Frontend Implementation (Weeks 5-6)

---

## PHASE 3 OBJECTIVES

1. **Complete API Specification** - Implement missing endpoints with proper DTOs
2. **Frontend Components** - Build NxTaskModal, NxTaskExecutionLog, advanced UI
3. **Real-Time Integration** - WebSocket support for live task updates
4. **Request/Response DTOs** - Standardized data structures

**Estimated Effort:** 35-45 hours  
**Timeline:** 2 weeks  
**Prerequisites:** Phase 1 & 2 completion

---

## 3.1 API Response DTOs

### Step 1: Create Task Response DTO

**File:** `app/Http/Requests/CreateTaskRequest.php`

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateTaskRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => 'required|in:manual,agent,system',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'priority' => 'nullable|integer|min:1|max:5',
            'due_at' => 'nullable|date|after:now',
            'agent_id' => 'nullable|exists:agents,id',
            'contact_id' => 'nullable|exists:contacts,id',
            'conversation_id' => 'nullable|exists:conversations,id',
            'workflow_id' => 'nullable|exists:workflows,id',
            'payload_data' => 'nullable|array',
            'metadata' => 'nullable|array',
        ];
    }

    public function messages(): array
    {
        return [
            'type.required' => 'Task type is required (manual, agent, or system)',
            'type.in' => 'Invalid task type. Must be manual, agent, or system',
            'title.required' => 'Task title is required',
            'agent_id.exists' => 'Selected agent does not exist',
        ];
    }
}
```

**File:** `app/Http/Resources/TaskResource.php`

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'type' => $this->type,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'priority' => $this->priority,
            'progress' => $this->progress,
            'assigned_agent' => new AgentResource($this->whenLoaded('agent')),
            'contact' => new ContactResource($this->whenLoaded('contact')),
            'conversation' => new ConversationResource($this->whenLoaded('conversation')),
            'workflow_id' => $this->workflow_id,
            'due_at' => $this->due_at?->toIso8601String(),
            'payload_data' => $this->payload_data,
            'result_data' => $this->result_data,
            'metadata' => $this->metadata,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
            'deleted_at' => $this->deleted_at?->toIso8601String(),
        ];
    }
}
```

**File:** `app/Http/Resources/TaskCollection.php`

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class TaskCollection extends ResourceCollection
{
    public $collects = TaskResource::class;

    public function toArray($request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total' => $this->collection->count(),
                'per_page' => request('per_page', 20),
                'current_page' => request('page', 1),
            ],
        ];
    }
}
```

**File:** `app/DTOs/TaskLogDTO.php`

```php
<?php

namespace App\DTOs;

class TaskLogDTO
{
    public function __construct(
        public string $taskId,
        public string $level,
        public string $message,
        public array $context = [],
        public string $timestamp = '',
    ) {
        if (!$this->timestamp) {
            $this->timestamp = now()->toIso8601String();
        }
    }

    public static function fromModel($taskLog): self
    {
        return new self(
            taskId: (string) $taskLog->agent_task_id,
            level: $taskLog->level,
            message: $taskLog->message,
            context: $taskLog->context ?? [],
            timestamp: $taskLog->created_at->toIso8601String(),
        );
    }

    public function toArray(): array
    {
        return [
            'task_id' => $this->taskId,
            'level' => $this->level,
            'message' => $this->message,
            'context' => $this->context,
            'timestamp' => $this->timestamp,
        ];
    }
}
```

---

## 3.2 Missing API Endpoints Implementation

### Step 1: Task Execution Endpoint

**File:** `app/Http/Controllers/TaskController.php` (Add Method)

```php
/**
 * POST /api/v1/tasks/{id}/execute
 * Manually force execution of an agent/system task
 */
public function execute(Request $request, string $id)
{
    try {
        $task = AgentTask::findOrFail($id);

        // Validate task can be executed
        if ($task->status === AgentTask::STATUS_IN_PROGRESS) {
            return response()->json([
                'error' => 'Task is already in progress'
            ], 409);
        }

        if (!in_array($task->status, [
            AgentTask::STATUS_TODO,
            AgentTask::STATUS_FAILED,
            AgentTask::STATUS_BLOCKED,
        ])) {
            return response()->json([
                'error' => "Cannot execute task in {$task->status} status"
            ], 409);
        }

        // Reset to TODO if failed
        if ($task->status === AgentTask::STATUS_FAILED) {
            $task->update(['status' => AgentTask::STATUS_TODO]);
        }

        // Execute the task
        $this->executionService->executeTask($task);

        return response()->json([
            'data' => new TaskResource($task->refresh()),
            'message' => 'Task execution started'
        ]);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}
```

### Step 2: Task Logs Endpoint

**File:** `app/Http/Controllers/TaskController.php` (Add Method)

```php
/**
 * GET /api/v1/tasks/{id}/logs
 * Retrieve execution logs for a specific task
 */
public function getLogs(Request $request, string $id)
{
    try {
        $task = AgentTask::findOrFail($id);
        
        $limit = $request->get('limit', 100);
        $level = $request->get('level'); // Optional filter

        $query = TaskLog::where('agent_task_id', $task->id);

        if ($level) {
            $query->where('level', $level);
        }

        $logs = $query
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get()
            ->map(fn($log) => new TaskLogDTO(
                taskId: (string) $log->agent_task_id,
                level: $log->level,
                message: $log->message,
                context: $log->context ?? [],
                timestamp: $log->created_at->toIso8601String(),
            ));

        return response()->json([
            'data' => $logs->toArray(),
            'total' => $logs->count(),
            'task_id' => $id,
        ]);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 404);
    }
}
```

### Step 3: Task Status Update Endpoint

**File:** `app/Http/Controllers/TaskController.php` (Add Method)

```php
/**
 * PATCH /api/v1/tasks/{id}/status
 * Update task status with state machine validation
 */
public function updateStatus(Request $request, string $id)
{
    $validated = $request->validate([
        'status' => 'required|in:todo,in_progress,blocked,completed,failed,cancelled',
    ]);

    try {
        $task = AgentTask::findOrFail($id);
        
        $newStatus = $validated['status'];

        // Use TaskManagementService to validate transition
        $updated = $this->taskManager->transitionStatus($task, $newStatus);

        return response()->json([
            'data' => new TaskResource($updated),
            'message' => "Task status updated to {$newStatus}"
        ]);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}
```

### Step 4: Update Routes

**File:** `routes/api.php`

```php
Route::prefix('v1')->middleware(['auth:sanctum'])->group(function () {
    // Task resource routes
    Route::resource('tasks', TaskController::class);
    
    // Task-specific action routes (MUST come before resource)
    Route::post('/tasks/{id}/execute', [TaskController::class, 'execute'])
        ->name('tasks.execute');
    
    Route::get('/tasks/{id}/logs', [TaskController::class, 'getLogs'])
        ->name('tasks.logs');
    
    Route::patch('/tasks/{id}/status', [TaskController::class, 'updateStatus'])
        ->name('tasks.status');
    
    Route::post('/tasks/{id}/cancel', [TaskController::class, 'cancel'])
        ->name('tasks.cancel');
    
    Route::post('/tasks/{id}/pause', [TaskController::class, 'pause'])
        ->name('tasks.pause');
    
    Route::post('/tasks/{id}/resume', [TaskController::class, 'resume'])
        ->name('tasks.resume');
});
```

---

## 3.3 Frontend Components

### Step 1: Enhanced NxTaskModal Component

**File:** `Nexus-Frontend/components/NxTaskModal.tsx`

```typescript
'use client';

import React, { useState, useEffect } from 'react';
import { NxDrawer } from './NxDrawer';
import { NxInput } from './NxInput';
import { NxSelect } from './NxSelect';
import { NxDateTimePicker } from './NxDateTimePicker';
import { NxActionButton } from './NxActionButton';
import { X, Save } from 'lucide-react';

interface NxTaskModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (taskData: any) => Promise<void>;
  initialData?: any;
  mode?: 'create' | 'edit';
}

export const NxTaskModal: React.FC<NxTaskModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  initialData,
  mode = 'create',
}) => {
  const [formData, setFormData] = useState({
    type: 'agent',
    title: '',
    description: '',
    priority: 3,
    due_at: null,
    agent_id: null,
    contact_id: null,
    conversation_id: null,
    payload_data: {},
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (initialData && mode === 'edit') {
      setFormData(initialData);
    }
  }, [initialData, mode]);

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
    // Clear error for this field
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: '',
      }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      await onSubmit(formData);
      onClose();
      // Reset form
      setFormData({
        type: 'agent',
        title: '',
        description: '',
        priority: 3,
        due_at: null,
        agent_id: null,
        contact_id: null,
        conversation_id: null,
        payload_data: {},
      });
    } catch (error: any) {
      setErrors(error.errors || { submit: error.message });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <NxDrawer isOpen={isOpen} onClose={onClose} title={mode === 'create' ? 'Create Task' : 'Edit Task'}>
      <form onSubmit={handleSubmit} className="space-y-4 p-4">
        {/* Task Type Selection */}
        <div>
          <label className="text-sm font-medium text-gray-300">Task Type</label>
          <NxSelect
            value={formData.type}
            onChange={(value) => handleInputChange('type', value)}
            options={[
              { label: 'Manual', value: 'manual' },
              { label: 'Agent', value: 'agent' },
              { label: 'System', value: 'system' },
            ]}
            error={errors.type}
          />
        </div>

        {/* Title */}
        <div>
          <label className="text-sm font-medium text-gray-300">Title</label>
          <NxInput
            value={formData.title}
            onChange={(value) => handleInputChange('title', value)}
            placeholder="Enter task title"
            error={errors.title}
          />
        </div>

        {/* Description */}
        <div>
          <label className="text-sm font-medium text-gray-300">Description</label>
          <textarea
            value={formData.description}
            onChange={(e) => handleInputChange('description', e.target.value)}
            placeholder="Enter task description"
            rows={3}
            className="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-gray-200 placeholder-gray-500"
          />
        </div>

        {/* Priority */}
        <div>
          <label className="text-sm font-medium text-gray-300">Priority</label>
          <NxSelect
            value={formData.priority}
            onChange={(value) => handleInputChange('priority', parseInt(value))}
            options={[
              { label: 'Low (1)', value: '1' },
              { label: 'Medium (2)', value: '2' },
              { label: 'High (3)', value: '3' },
              { label: 'Critical (4)', value: '4' },
              { label: 'Urgent (5)', value: '5' },
            ]}
          />
        </div>

        {/* Due Date */}
        <div>
          <label className="text-sm font-medium text-gray-300">Due Date</label>
          <NxDateTimePicker
            value={formData.due_at}
            onChange={(value) => handleInputChange('due_at', value)}
          />
        </div>

        {/* Agent Selection (for agentic tasks) */}
        {formData.type === 'agent' && (
          <div>
            <label className="text-sm font-medium text-gray-300">Assigned Agent</label>
            <NxSelect
              value={formData.agent_id}
              onChange={(value) => handleInputChange('agent_id', value)}
              options={[]} // Load from API
              error={errors.agent_id}
            />
          </div>
        )}

        {/* Contact Selection */}
        <div>
          <label className="text-sm font-medium text-gray-300">Related Contact</label>
          <NxSelect
            value={formData.contact_id}
            onChange={(value) => handleInputChange('contact_id', value)}
            options={[]} // Load from API
          />
        </div>

        {/* Conversation Selection */}
        <div>
          <label className="text-sm font-medium text-gray-300">Related Conversation</label>
          <NxSelect
            value={formData.conversation_id}
            onChange={(value) => handleInputChange('conversation_id', value)}
            options={[]} // Load from API
          />
        </div>

        {/* Submit Error */}
        {errors.submit && (
          <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
            {errors.submit}
          </div>
        )}

        {/* Form Actions */}
        <div className="flex gap-2 justify-end pt-4 border-t border-white/10">
          <NxActionButton
            variant="secondary"
            onClick={onClose}
          >
            Cancel
          </NxActionButton>
          <NxActionButton
            variant="primary"
            type="submit"
            disabled={isSubmitting}
            leftIcon={<Save className="w-4 h-4" />}
          >
            {isSubmitting ? 'Saving...' : 'Save Task'}
          </NxActionButton>
        </div>
      </form>
    </NxDrawer>
  );
};
```

### Step 2: NxTaskExecutionLog Component

**File:** `Nexus-Frontend/components/NxTaskExecutionLog.tsx`

```typescript
'use client';

import React, { useEffect, useState } from 'react';
import { AlertCircle, CheckCircle, Clock, AlertTriangle, Info } from 'lucide-react';
import { useReverbChannel } from '@/hooks/useReverbChannel';

interface TaskLog {
  task_id: string;
  level: 'info' | 'warning' | 'error' | 'debug';
  message: string;
  context?: Record<string, any>;
  timestamp: string;
}

interface NxTaskExecutionLogProps {
  taskId: string;
  onTaskComplete?: (result: any) => void;
  onTaskFailed?: (error: string) => void;
}

export const NxTaskExecutionLog: React.FC<NxTaskExecutionLogProps> = ({
  taskId,
  onTaskComplete,
  onTaskFailed,
}) => {
  const [logs, setLogs] = useState<TaskLog[]>([]);
  const [autoScroll, setAutoScroll] = useState(true);
  const scrollContainerRef = React.useRef<HTMLDivElement>(null);

  // Subscribe to real-time updates via Reverb WebSocket
  const { subscribe } = useReverbChannel();

  useEffect(() => {
    // Load initial logs
    loadInitialLogs();

    // Subscribe to real-time updates
    const unsubscribe = subscribe(`task.${taskId}`, {
      'task.completed': (data: any) => {
        handleTaskCompleted(data);
        onTaskComplete?.(data);
      },
      'task.failed': (data: any) => {
        handleTaskFailed(data);
        onTaskFailed?.(data.error);
      },
      'task.log': (data: any) => {
        addLog(data);
      },
    });

    return () => unsubscribe?.();
  }, [taskId]);

  useEffect(() => {
    // Auto-scroll to bottom when new logs arrive
    if (autoScroll && scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = scrollContainerRef.current.scrollHeight;
    }
  }, [logs, autoScroll]);

  const loadInitialLogs = async () => {
    try {
      const response = await fetch(`/api/v1/tasks/${taskId}/logs`);
      const data = await response.json();
      setLogs(data.data || []);
    } catch (error) {
      console.error('Failed to load task logs:', error);
    }
  };

  const addLog = (log: TaskLog) => {
    setLogs(prev => [...prev, log]);
  };

  const handleTaskCompleted = (data: any) => {
    addLog({
      task_id: taskId,
      level: 'info',
      message: '✓ Task completed successfully',
      context: data,
      timestamp: new Date().toISOString(),
    });
  };

  const handleTaskFailed = (data: any) => {
    addLog({
      task_id: taskId,
      level: 'error',
      message: `✗ Task failed: ${data.error}`,
      context: data,
      timestamp: new Date().toISOString(),
    });
  };

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-400" />;
      case 'warning':
        return <AlertTriangle className="w-4 h-4 text-yellow-400" />;
      case 'info':
        return <CheckCircle className="w-4 h-4 text-green-400" />;
      default:
        return <Info className="w-4 h-4 text-blue-400" />;
    }
  };

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'error':
        return 'text-red-400';
      case 'warning':
        return 'text-yellow-400';
      case 'info':
        return 'text-green-400';
      default:
        return 'text-gray-400';
    }
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Toolbar */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-white/10">
        <h3 className="text-sm font-semibold text-gray-200">Execution Logs</h3>
        <label className="flex items-center gap-2 cursor-pointer text-xs text-gray-400">
          <input
            type="checkbox"
            checked={autoScroll}
            onChange={(e) => setAutoScroll(e.target.checked)}
            className="w-3 h-3"
          />
          Auto-scroll
        </label>
      </div>

      {/* Log Container */}
      <div
        ref={scrollContainerRef}
        className="flex-1 bg-black/20 border border-white/5 rounded-lg p-3 overflow-y-auto max-h-96 font-mono text-xs space-y-1"
      >
        {logs.length === 0 ? (
          <div className="text-gray-500 text-center py-8">
            <Clock className="w-6 h-6 mx-auto mb-2 opacity-50" />
            <p>Waiting for task execution to begin...</p>
          </div>
        ) : (
          logs.map((log, idx) => (
            <div key={idx} className={`flex gap-2 ${getLevelColor(log.level)}`}>
              <span className="flex-shrink-0">{getLevelIcon(log.level)}</span>
              <span className="flex-shrink-0 text-gray-500">
                {new Date(log.timestamp).toLocaleTimeString()}
              </span>
              <span className="flex-1 break-words">{log.message}</span>
            </div>
          ))
        )}
      </div>

      {/* Summary Stats */}
      {logs.length > 0 && (
        <div className="text-xs text-gray-400 px-3">
          {logs.filter(l => l.level === 'error').length} errors • {logs.filter(l => l.level === 'warning').length} warnings • {logs.length} total logs
        </div>
      )}
    </div>
  );
};
```

### Step 3: Update Tasks Page Component

**File:** `Nexus-Frontend/app/tasks/page.tsx` (Partial Update)

```typescript
'use client';

import React, { useState } from 'react';
import { NxTaskModal } from '@/components/NxTaskModal';
import { NxTaskExecutionLog } from '@/components/NxTaskExecutionLog';
import { NxDataGrid } from '@/components/NxDataGrid';
import { NxDragDropZone } from '@/components/NxDragDropZone';

export default function TasksPage() {
  const [viewMode, setViewMode] = useState<'kanban' | 'table'>('kanban');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedTaskForLogs, setSelectedTaskForLogs] = useState<string | null>(null);
  const [tasks, setTasks] = useState([]);

  const handleCreateTask = async (taskData: any) => {
    const response = await fetch('/api/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(taskData),
    });

    if (!response.ok) throw new Error('Failed to create task');
    
    const result = await response.json();
    setTasks(prev => [...prev, result.data]);
  };

  const handleDragTaskToStatus = async (taskId: string, newStatus: string) => {
    const response = await fetch(`/api/v1/tasks/${taskId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: newStatus }),
    });

    if (!response.ok) throw new Error('Failed to update task status');
    
    // Update local state
    setTasks(prev =>
      prev.map(t => t.id === taskId ? { ...t, status: newStatus } : t)
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">Tasks</h1>
        <div className="flex gap-2">
          <button
            onClick={() => setViewMode('kanban')}
            className={`px-4 py-2 rounded ${viewMode === 'kanban' ? 'bg-blue-600' : 'bg-gray-700'}`}
          >
            Kanban
          </button>
          <button
            onClick={() => setViewMode('table')}
            className={`px-4 py-2 rounded ${viewMode === 'table' ? 'bg-blue-600' : 'bg-gray-700'}`}
          >
            Table
          </button>
          <button
            onClick={() => setIsModalOpen(true)}
            className="px-4 py-2 bg-blue-600 rounded hover:bg-blue-700"
          >
            + New Task
          </button>
        </div>
      </div>

      {/* Modal */}
      <NxTaskModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleCreateTask}
      />

      {/* View: Kanban or Table */}
      {viewMode === 'kanban' ? (
        <div className="grid grid-cols-3 gap-6">
          {['todo', 'in_progress', 'completed'].map(status => (
            <NxDragDropZone
              key={status}
              status={status}
              items={tasks.filter(t => t.status === status)}
              onDrop={(taskId) => handleDragTaskToStatus(taskId, status)}
              onTaskClick={(taskId) => setSelectedTaskForLogs(taskId)}
            />
          ))}
        </div>
      ) : (
        <NxDataGrid
          columns={['title', 'type', 'status', 'priority', 'due_at', 'actions']}
          data={tasks}
          onRowClick={(task) => setSelectedTaskForLogs(task.id)}
        />
      )}

      {/* Execution Log Sidebar */}
      {selectedTaskForLogs && (
        <div className="fixed right-0 top-0 w-96 h-full bg-gray-900 border-l border-white/10 p-4 overflow-y-auto">
          <button
            onClick={() => setSelectedTaskForLogs(null)}
            className="mb-4 text-gray-400 hover:text-gray-200"
          >
            ← Close
          </button>
          <NxTaskExecutionLog
            taskId={selectedTaskForLogs}
            onTaskComplete={() => {
              // Refresh tasks
            }}
          />
        </div>
      )}
    </div>
  );
}
```

---

## 3.4 Real-Time WebSocket Integration

### Step 1: Create Reverb Hook

**File:** `Nexus-Frontend/hooks/useReverbChannel.ts`

```typescript
import { useEffect, useCallback } from 'react';
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

let echoInstance: Echo | null = null;

export function useReverbChannel() {
  useEffect(() => {
    if (!echoInstance && typeof window !== 'undefined') {
      window.Pusher = Pusher;
      echoInstance = new Echo({
        broadcaster: 'reverb',
        key: process.env.NEXT_PUBLIC_REVERB_APP_KEY,
        wsHost: process.env.NEXT_PUBLIC_REVERB_HOST,
        wsPort: parseInt(process.env.NEXT_PUBLIC_REVERB_PORT || '8080'),
        wssPort: parseInt(process.env.NEXT_PUBLIC_REVERB_PORT || '443'),
        forceTLS: process.env.NODE_ENV === 'production',
        encrypted: process.env.NODE_ENV === 'production',
      });
    }
  }, []);

  const subscribe = useCallback((channel: string, listeners: Record<string, Function>) => {
    if (!echoInstance) return () => {};

    const channelInstance = echoInstance.channel(channel);

    Object.entries(listeners).forEach(([event, handler]) => {
      channelInstance.listen(event, handler);
    });

    return () => {
      if (channelInstance) {
        echoInstance?.leaveChannel(channel);
      }
    };
  }, []);

  return { subscribe };
}
```

### Step 2: Environment Variables

**File:** `.env.local`

```env
NEXT_PUBLIC_REVERB_APP_KEY=your_reverb_key
NEXT_PUBLIC_REVERB_HOST=localhost
NEXT_PUBLIC_REVERB_PORT=8080
```

---

## 3.5 Updated TaskController with All Endpoints

**File:** `app/Http/Controllers/TaskController.php` (Complete Controller)

```php
<?php

namespace App\Http\Controllers;

use App\DTOs\TaskLogDTO;
use App\Http\Requests\CreateTaskRequest;
use App\Http\Resources\TaskResource;
use App\Models\AgentTask;
use App\Models\TaskLog;
use App\Services\TaskExecutionService;
use App\Services\TaskManagementService;
use App\Services\TaskSchedulingService;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function __construct(
        protected TaskManagementService $taskManager,
        protected TaskExecutionService $executionService,
        protected TaskSchedulingService $schedulingService,
    ) {}

    /**
     * GET /api/v1/tasks
     * List all tasks with filters
     */
    public function index(Request $request)
    {
        $query = AgentTask::query();

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('agent_id')) {
            $query->where('agent_id', $request->agent_id);
        }

        if ($request->has('contact_id')) {
            $query->where('contact_id', $request->contact_id);
        }

        if ($request->has('priority')) {
            $query->where('priority', $request->priority);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $tasks = $query
            ->with(['agent', 'contact', 'conversation'])
            ->orderBy('priority', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 20);

        return response()->json([
            'data' => TaskResource::collection($tasks),
            'meta' => [
                'total' => $tasks->total(),
                'per_page' => $tasks->perPage(),
                'current_page' => $tasks->currentPage(),
            ],
        ]);
    }

    /**
     * POST /api/v1/tasks
     * Create a new task
     */
    public function store(CreateTaskRequest $request)
    {
        try {
            $task = $this->taskManager->createTask($request->validated());
            
            // Auto-execute if agentic or system
            if ($task->type !== AgentTask::TYPE_MANUAL) {
                $this->executionService->executeTask($task);
            }

            return response()->json([
                'data' => new TaskResource($task),
                'message' => 'Task created successfully',
            ], 201);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    /**
     * GET /api/v1/tasks/{id}
     * Get a specific task
     */
    public function show(string $id)
    {
        try {
            $task = $this->taskManager->getTask($id);
            return response()->json(['data' => new TaskResource($task)]);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 404);
        }
    }

    /**
     * PATCH /api/v1/tasks/{id}
     * Update a task
     */
    public function update(Request $request, string $id)
    {
        try {
            $data = $request->validate([
                'title' => 'nullable|string|max:255',
                'description' => 'nullable|string',
                'priority' => 'nullable|integer|min:1|max:5',
                'due_at' => 'nullable|date',
                'contact_id' => 'nullable|exists:contacts,id',
                'payload_data' => 'nullable|array',
            ]);

            $task = $this->taskManager->updateTask($id, $data);
            return response()->json(['data' => new TaskResource($task)]);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    /**
     * DELETE /api/v1/tasks/{id}
     * Delete a task (soft delete)
     */
    public function destroy(string $id)
    {
        try {
            $this->taskManager->deleteTask($id);
            return response()->json(['message' => 'Task deleted']);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 404);
        }
    }

    /**
     * POST /api/v1/tasks/{id}/execute
     * Execute a task
     */
    public function execute(string $id)
    {
        try {
            $task = AgentTask::findOrFail($id);
            $this->executionService->executeTask($task);
            return response()->json([
                'data' => new TaskResource($task->refresh()),
                'message' => 'Task execution started',
            ]);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    /**
     * GET /api/v1/tasks/{id}/logs
     * Get task logs
     */
    public function getLogs(Request $request, string $id)
    {
        try {
            $task = AgentTask::findOrFail($id);
            $limit = $request->get('limit', 100);
            $level = $request->get('level');

            $query = TaskLog::where('agent_task_id', $task->id);
            if ($level) {
                $query->where('level', $level);
            }

            $logs = $query
                ->orderBy('created_at', 'desc')
                ->limit($limit)
                ->get()
                ->map(fn($log) => TaskLogDTO::fromModel($log)->toArray());

            return response()->json([
                'data' => $logs,
                'total' => $logs->count(),
            ]);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 404);
        }
    }

    /**
     * PATCH /api/v1/tasks/{id}/status
     * Update task status
     */
    public function updateStatus(Request $request, string $id)
    {
        $validated = $request->validate([
            'status' => 'required|in:todo,in_progress,blocked,completed,failed,cancelled',
        ]);

        try {
            $task = AgentTask::findOrFail($id);
            $updated = $this->taskManager->transitionStatus($task, $validated['status']);
            return response()->json(['data' => new TaskResource($updated)]);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    // Additional methods for type-specific, scheduling, restore operations...
    // (See Phase 2 guide for complete implementations)
}
```

---

## PHASE 3 COMPLETION CHECKLIST

- [ ] CreateTaskRequest validation class created
- [ ] TaskResource and TaskCollection created
- [ ] TaskLogDTO created
- [ ] POST /api/v1/tasks/{id}/execute endpoint implemented
- [ ] GET /api/v1/tasks/{id}/logs endpoint implemented
- [ ] PATCH /api/v1/tasks/{id}/status endpoint implemented
- [ ] NxTaskModal component created
- [ ] NxTaskExecutionLog component created
- [ ] Reverb WebSocket hook created
- [ ] Real-time task updates working
- [ ] Tasks page updated with modal and logs
- [ ] Kanban and table view modes working
- [ ] All API endpoints tested
- [ ] DTOs used in all responses
- [ ] Error handling implemented
- [ ] Form validation working

---

**Status:** PHASE 3 IMPLEMENTATION GUIDE  
**Complexity:** HIGH  
**Dependencies:** Phase 1 & 2 (REQUIRED)  
**Ready for Implementation:** YES
