# TaskHub Remediation Guide - Phase 2
## Core Features Implementation (Weeks 3-4)

---

## PHASE 2 OBJECTIVES

1. **Event System** - Enable cross-hub communication
2. **Soft Deletes** - Implement data integrity & audit trails
3. **Task Scheduling** - Add cron-based recurring task support
4. **Task Type Discrimination** - Fully support manual/agent/system tasks

**Estimated Effort:** 30-40 hours  
**Timeline:** 2 weeks  
**Prerequisites:** Phase 1 completion (Foundation)

---

## 2.1 Event System Implementation

### Step 1: Create Task Events

**File:** `app/Events/TaskCompletedEvent.php`

```php
<?php

namespace App\Events;

use App\Models\AgentTask;
use Illuminate\Broadcasting\Channel;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;

class TaskCompletedEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets;

    public function __construct(public AgentTask $task)
    {
    }

    public function broadcastOn(): array
    {
        return [
            new Channel("task.{$this->task->id}"),
            new Channel('tasks'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'task.completed';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->task->id,
            'title' => $this->task->title,
            'status' => $this->task->status,
            'result_data' => $this->task->result_data,
            'completed_at' => $this->task->updated_at->toIso8601String(),
        ];
    }
}
```

**File:** `app/Events/TaskFailedEvent.php`

```php
<?php

namespace App\Events;

use App\Models\AgentTask;
use Illuminate\Broadcasting\Channel;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Throwable;

class TaskFailedEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets;

    public string $errorMessage;
    public string $errorCode;

    public function __construct(
        public AgentTask $task,
        Throwable $error
    ) {
        $this->errorMessage = $error->getMessage();
        $this->errorCode = (string) $error->getCode();
    }

    public function broadcastOn(): array
    {
        return [
            new Channel("task.{$this->task->id}"),
            new Channel('tasks'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'task.failed';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->task->id,
            'title' => $this->task->title,
            'status' => $this->task->status,
            'error' => $this->errorMessage,
            'error_code' => $this->errorCode,
            'failed_at' => $this->task->updated_at->toIso8601String(),
        ];
    }
}
```

**File:** `app/Events/TaskStatusChangedEvent.php`

```php
<?php

namespace App\Events;

use App\Models\AgentTask;
use Illuminate\Broadcasting\Channel;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;

class TaskStatusChangedEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets;

    public function __construct(
        public AgentTask $task,
        public string $oldStatus,
        public string $newStatus
    ) {
    }

    public function broadcastOn(): array
    {
        return [
            new Channel("task.{$this->task->id}"),
            new Channel('tasks'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'task.status-changed';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->task->id,
            'title' => $this->task->title,
            'old_status' => $this->oldStatus,
            'new_status' => $this->newStatus,
            'changed_at' => $this->task->updated_at->toIso8601String(),
        ];
    }
}
```

### Step 2: Create Listeners for Workflow Integration

**File:** `app/Listeners/HandleTaskCompleted.php`

```php
<?php

namespace App\Listeners;

use App\Events\TaskCompletedEvent;
use App\Models\Workflow;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class HandleTaskCompleted implements ShouldQueue
{
    public function handle(TaskCompletedEvent $event): void
    {
        $task = $event->task;

        // Find workflow associated with this task
        if ($task->workflow_id) {
            $workflow = Workflow::find($task->workflow_id);

            if ($workflow) {
                // Resume workflow if it was paused waiting for this task
                if ($workflow->status === 'paused') {
                    $this->resumeWorkflow($workflow, $task);
                }
            }
        }

        Log::info("Task completed event handled", [
            'task_id' => $task->id,
            'workflow_id' => $task->workflow_id,
        ]);
    }

    protected function resumeWorkflow(Workflow $workflow, $task): void
    {
        // Find the workflow step that was waiting for this task
        $currentStep = $workflow->metadata['current_step'] ?? 0;

        // Mark task as complete in workflow
        $steps = $workflow->steps ?? [];
        if (isset($steps[$currentStep])) {
            $steps[$currentStep]['status'] = 'completed';
            $steps[$currentStep]['result'] = $task->result_data;
        }

        // Move to next step
        $nextStep = $currentStep + 1;
        $workflow->update([
            'status' => count($steps) > $nextStep ? 'running' : 'completed',
            'metadata' => array_merge($workflow->metadata ?? [], [
                'current_step' => $nextStep,
                'steps' => $steps,
                'resumed_at' => now()->toIso8601String(),
            ]),
        ]);

        Log::info("Workflow resumed after task completion", [
            'workflow_id' => $workflow->id,
            'task_id' => $task->id,
        ]);
    }
}
```

**File:** `app/Listeners/HandleTaskFailed.php`

```php
<?php

namespace App\Listeners;

use App\Events\TaskFailedEvent;
use App\Models\Workflow;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class HandleTaskFailed implements ShouldQueue
{
    public function handle(TaskFailedEvent $event): void
    {
        $task = $event->task;

        // Find workflow associated with this task
        if ($task->workflow_id) {
            $workflow = Workflow::find($task->workflow_id);

            if ($workflow) {
                // Transition workflow to blocked/failed state
                $this->handleWorkflowFailure($workflow, $task, $event->errorMessage);
            }
        }

        Log::warning("Task failed event handled", [
            'task_id' => $task->id,
            'error' => $event->errorMessage,
        ]);
    }

    protected function handleWorkflowFailure(Workflow $workflow, $task, string $error): void
    {
        $workflow->update([
            'status' => 'blocked',
            'metadata' => array_merge($workflow->metadata ?? [], [
                'blocking_task_id' => $task->id,
                'blocking_error' => $error,
                'blocked_at' => now()->toIso8601String(),
            ]),
        ]);

        Log::error("Workflow blocked due to task failure", [
            'workflow_id' => $workflow->id,
            'task_id' => $task->id,
            'error' => $error,
        ]);
    }
}
```

### Step 3: Register Events and Listeners

**File:** `app/Providers/EventServiceProvider.php`

```php
<?php

namespace App\Providers;

use App\Events\TaskCompletedEvent;
use App\Events\TaskFailedEvent;
use App\Events\TaskStatusChangedEvent;
use App\Listeners\HandleTaskCompleted;
use App\Listeners\HandleTaskFailed;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        TaskCompletedEvent::class => [
            HandleTaskCompleted::class,
        ],
        TaskFailedEvent::class => [
            HandleTaskFailed::class,
        ],
        TaskStatusChangedEvent::class => [
            // Add more listeners as needed
        ],
    ];
}
```

---

## 2.2 Soft Deletes & Data Integrity

### Step 1: Update Models with Soft Delete Trait

The migration was created in Phase 1. Now update the model relationships:

**File:** `app/Models/TaskLog.php` (Update)

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class TaskLog extends BaseModel
{
    use SoftDeletes;

    protected $fillable = [
        'agent_task_id',
        'level',
        'message',
        'context',
    ];

    protected $casts = [
        'context' => 'json',
    ];

    public function task(): BelongsTo
    {
        return $this->belongsTo(AgentTask::class, 'agent_task_id');
    }

    /**
     * Get all logs including soft-deleted ones
     */
    public function scopeWithTrashed($query)
    {
        return $query->withTrashed();
    }

    /**
     * Get only soft-deleted logs
     */
    public function scopeOnlyTrashed($query)
    {
        return $query->onlyTrashed();
    }
}
```

### Step 2: Create Task Restore Functionality

**File:** `app/Services/TaskManagementService.php` (Add Methods)

```php
/**
 * Restore a soft-deleted task
 */
public function restoreTask(string $taskId): AgentTask
{
    $task = AgentTask::withTrashed()->findOrFail($taskId);
    $task->restore();

    $this->logService->info('Task restored', [
        'channel' => 'task',
        'type' => 'restore',
        'related_id' => $task->id,
        'related_type' => AgentTask::class,
    ]);

    return $task;
}

/**
 * Permanently delete a task
 */
public function permanentlyDeleteTask(string $taskId): bool
{
    $task = AgentTask::withTrashed()->findOrFail($taskId);
    
    // Delete all related logs first
    TaskLog::where('agent_task_id', $task->id)->forceDelete();
    
    // Permanently delete task
    $task->forceDelete();

    $this->logService->warning('Task permanently deleted', [
        'channel' => 'task',
        'type' => 'permanent_delete',
        'related_id' => $taskId,
        'related_type' => AgentTask::class,
    ]);

    return true;
}

/**
 * Get soft-deleted tasks
 */
public function getTrashedTasks(array $filters = []): Collection
{
    $query = AgentTask::onlyTrashed();

    if (isset($filters['agent_id'])) {
        $query->where('agent_id', $filters['agent_id']);
    }

    return $query->orderBy('deleted_at', 'desc')->get();
}
```

### Step 3: Add API Endpoints for Restore/Permanent Delete

**File:** `routes/api.php` (Add to task routes)

```php
// Soft delete recovery routes
Route::post('/tasks/{id}/restore', [\App\Http\Controllers\TaskController::class, 'restore'])
    ->name('tasks.restore');

Route::delete('/tasks/{id}/permanent', [\App\Http\Controllers\TaskController::class, 'permanentDelete'])
    ->name('tasks.permanent-delete');

Route::get('/tasks/trash', [\App\Http\Controllers\TaskController::class, 'getTrashed'])
    ->name('tasks.trash');
```

**File:** `app/Http/Controllers/TaskController.php` (Add Methods)

```php
/**
 * Restore a soft-deleted task
 */
public function restore(string $id)
{
    try {
        $task = $this->taskManager->restoreTask($id);
        return response()->json(['data' => $task, 'message' => 'Task restored'], 200);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Permanently delete a task
 */
public function permanentDelete(string $id)
{
    try {
        $this->taskManager->permanentlyDeleteTask($id);
        return response()->json(['message' => 'Task permanently deleted'], 200);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Get trashed tasks
 */
public function getTrashed(Request $request)
{
    $filters = $request->only(['agent_id', 'search']);
    $tasks = $this->taskManager->getTrashedTasks($filters);
    
    return response()->json(['data' => $tasks, 'total' => $tasks->count()]);
}
```

---

## 2.3 Task Scheduling Service

### Step 1: Create TaskSchedulingService

**File:** `app/Services/TaskSchedulingService.php`

```php
<?php

namespace App\Services;

use App\Models\AgentTask;
use Cron\CronExpression;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Log;
use Exception;

class TaskSchedulingService
{
    protected LogService $logService;
    protected TaskExecutionService $executionService;

    public function __construct(
        LogService $logService,
        TaskExecutionService $executionService
    ) {
        $this->logService = $logService;
        $this->executionService = $executionService;
    }

    /**
     * Schedule a recurring task with cron expression
     */
    public function scheduleRecurringTask(
        string $taskId,
        string $cronExpression,
        ?string $timezone = null
    ): AgentTask {
        $task = AgentTask::findOrFail($taskId);

        // Validate cron expression
        if (!$this->isValidCronExpression($cronExpression)) {
            throw new Exception("Invalid cron expression: {$cronExpression}");
        }

        // Update task metadata with scheduling info
        $task->update([
            'metadata' => array_merge($task->metadata ?? [], [
                'is_recurring' => true,
                'cron_expression' => $cronExpression,
                'timezone' => $timezone ?? config('app.timezone'),
                'scheduled_at' => now()->toIso8601String(),
                'next_execution' => $this->getNextExecutionTime($cronExpression, $timezone),
                'execution_count' => 0,
            ]),
        ]);

        $this->logService->info('Task scheduled as recurring', [
            'channel' => 'task',
            'type' => 'schedule_recurring',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => ['cron' => $cronExpression],
        ]);

        return $task;
    }

    /**
     * Schedule a one-time task for a specific date/time
     */
    public function scheduleOneTimeTask(
        string $taskId,
        string $executionTime
    ): AgentTask {
        $task = AgentTask::findOrFail($taskId);

        $executionDateTime = \Carbon\Carbon::parse($executionTime);

        if ($executionDateTime->isPast()) {
            throw new Exception("Scheduled time must be in the future");
        }

        $task->update([
            'due_at' => $executionDateTime,
            'metadata' => array_merge($task->metadata ?? [], [
                'is_scheduled' => true,
                'scheduled_for' => $executionDateTime->toIso8601String(),
                'scheduled_at' => now()->toIso8601String(),
            ]),
        ]);

        $this->logService->info('Task scheduled for one-time execution', [
            'channel' => 'task',
            'type' => 'schedule_once',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => ['execution_time' => $executionDateTime->toIso8601String()],
        ]);

        return $task;
    }

    /**
     * Evaluate and execute due tasks
     * This should be called by a scheduled command
     */
    public function evaluateAndExecuteDueTasks(): int
    {
        $dueTasks = $this->getDueTasksForExecution();
        $executedCount = 0;

        foreach ($dueTasks as $task) {
            try {
                $this->executionService->executeTask($task);
                $executedCount++;

                // Update execution count for recurring tasks
                if ($task->metadata['is_recurring'] ?? false) {
                    $this->updateRecurringTaskMetadata($task);
                }
            } catch (\Throwable $e) {
                $this->logService->error('Failed to execute scheduled task', [
                    'channel' => 'task',
                    'type' => 'schedule_execution_failed',
                    'related_id' => $task->id,
                    'related_type' => AgentTask::class,
                    'context' => ['error' => $e->getMessage()],
                ]);
            }
        }

        Log::info("Executed {$executedCount} scheduled tasks");

        return $executedCount;
    }

    /**
     * Get all tasks due for execution
     */
    public function getDueTasksForExecution(): Collection
    {
        $now = now();

        // One-time scheduled tasks
        $oneTimeTasks = AgentTask::query()
            ->where('due_at', '<=', $now)
            ->where('status', AgentTask::STATUS_TODO)
            ->get();

        // Recurring tasks
        $recurringTasks = AgentTask::query()
            ->where('status', AgentTask::STATUS_TODO)
            ->get()
            ->filter(function ($task) {
                $metadata = $task->metadata ?? [];
                if (!($metadata['is_recurring'] ?? false)) {
                    return false;
                }

                $cron = $metadata['cron_expression'] ?? null;
                if (!$cron) {
                    return false;
                }

                $nextExecution = $this->getNextExecutionTime(
                    $cron,
                    $metadata['timezone'] ?? config('app.timezone')
                );

                return $nextExecution <= now();
            });

        return $oneTimeTasks->concat($recurringTasks);
    }

    /**
     * Calculate next execution time for cron expression
     */
    public function getNextExecutionTime(
        string $cronExpression,
        ?string $timezone = null
    ): \DateTime {
        try {
            $cron = CronExpression::factory($cronExpression);
            $nextRun = $cron->getNextRunDate(timezone: $timezone ?? config('app.timezone'));
            return $nextRun;
        } catch (\Throwable $e) {
            throw new Exception("Invalid cron expression: {$e->getMessage()}");
        }
    }

    /**
     * Validate cron expression
     */
    public function isValidCronExpression(string $expression): bool
    {
        try {
            CronExpression::factory($expression);
            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    /**
     * Update metadata for recurring tasks after execution
     */
    protected function updateRecurringTaskMetadata(AgentTask $task): void
    {
        $metadata = $task->metadata ?? [];
        $cronExpression = $metadata['cron_expression'];

        $nextExecution = $this->getNextExecutionTime(
            $cronExpression,
            $metadata['timezone'] ?? config('app.timezone')
        );

        $task->update([
            'metadata' => array_merge($metadata, [
                'execution_count' => ($metadata['execution_count'] ?? 0) + 1,
                'last_execution' => now()->toIso8601String(),
                'next_execution' => $nextExecution->toDateTimeString(),
            ]),
        ]);
    }

    /**
     * Unschedule a task
     */
    public function unscheduleTask(string $taskId): AgentTask
    {
        $task = AgentTask::findOrFail($taskId);

        $metadata = $task->metadata ?? [];
        unset($metadata['is_recurring'], $metadata['is_scheduled'], $metadata['cron_expression']);

        $task->update(['metadata' => $metadata]);

        $this->logService->info('Task unscheduled', [
            'channel' => 'task',
            'type' => 'unschedule',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
        ]);

        return $task;
    }
}
```

### Step 2: Create Artisan Command for Scheduled Task Evaluation

**File:** `app/Console/Commands/EvaluateScheduledTasks.php`

```php
<?php

namespace App\Console\Commands;

use App\Services\TaskSchedulingService;
use Illuminate\Console\Command;

class EvaluateScheduledTasks extends Command
{
    protected $signature = 'tasks:evaluate-scheduled';
    protected $description = 'Evaluate and execute tasks that are due for execution';

    public function __construct(
        protected TaskSchedulingService $schedulingService
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $this->info('Evaluating scheduled tasks...');

        $executedCount = $this->schedulingService->evaluateAndExecuteDueTasks();

        $this->info("Executed {$executedCount} scheduled tasks");

        return self::SUCCESS;
    }
}
```

### Step 3: Register Scheduled Command

**File:** `app/Console/Kernel.php`

```php
protected function schedule(Schedule $schedule)
{
    // Run task evaluation every minute
    $schedule->command('tasks:evaluate-scheduled')
        ->everyMinute()
        ->withoutOverlapping();

    // Or run every 5 minutes for lower frequency
    // $schedule->command('tasks:evaluate-scheduled')
    //     ->everyFiveMinutes()
    //     ->withoutOverlapping();
}
```

### Step 4: Add Scheduling API Endpoints

**File:** `routes/api.php`

```php
// Task scheduling routes
Route::post('/tasks/{id}/schedule-recurring', [\App\Http\Controllers\TaskController::class, 'scheduleRecurring'])
    ->name('tasks.schedule-recurring');

Route::post('/tasks/{id}/schedule-once', [\App\Http\Controllers\TaskController::class, 'scheduleOnce'])
    ->name('tasks.schedule-once');

Route::post('/tasks/{id}/unschedule', [\App\Http\Controllers\TaskController::class, 'unschedule'])
    ->name('tasks.unschedule');

Route::get('/tasks/scheduled', [\App\Http\Controllers\TaskController::class, 'getScheduledTasks'])
    ->name('tasks.scheduled');
```

**File:** `app/Http/Controllers/TaskController.php` (Add Methods)

```php
/**
 * Schedule a recurring task
 */
public function scheduleRecurring(Request $request, string $id)
{
    $validated = $request->validate([
        'cron_expression' => 'required|string',
        'timezone' => 'nullable|timezone',
    ]);

    try {
        $task = $this->schedulingService->scheduleRecurringTask(
            $id,
            $validated['cron_expression'],
            $validated['timezone'] ?? null
        );

        return response()->json([
            'data' => $task,
            'message' => 'Task scheduled as recurring',
        ]);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Schedule a one-time task
 */
public function scheduleOnce(Request $request, string $id)
{
    $validated = $request->validate([
        'execution_time' => 'required|date',
    ]);

    try {
        $task = $this->schedulingService->scheduleOneTimeTask(
            $id,
            $validated['execution_time']
        );

        return response()->json([
            'data' => $task,
            'message' => 'Task scheduled for one-time execution',
        ]);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Unschedule a task
 */
public function unschedule(string $id)
{
    try {
        $task = $this->schedulingService->unscheduleTask($id);
        return response()->json(['data' => $task, 'message' => 'Task unscheduled']);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Get all scheduled tasks
 */
public function getScheduledTasks()
{
    $tasks = AgentTask::where(function ($query) {
        $query->where('due_at', '!=', null)
              ->orWhereJsonContains('metadata->is_recurring', true)
              ->orWhereJsonContains('metadata->is_scheduled', true);
    })
    ->with(['agent', 'contact'])
    ->get();

    return response()->json(['data' => $tasks, 'total' => $tasks->count()]);
}
```

---

## 2.4 Task Type Discrimination

### Step 1: Enhance TaskManagementService for Task Types

**File:** `app/Services/TaskManagementService.php` (Add Methods)

```php
/**
 * Create a manual task (requires human intervention)
 */
public function createManualTask(array $data): AgentTask
{
    $data['type'] = AgentTask::TYPE_MANUAL;
    return $this->createTask($data);
}

/**
 * Create an agentic task (delegated to AI agent)
 */
public function createAgenticTask(array $data): AgentTask
{
    $data['type'] = AgentTask::TYPE_AGENT;
    
    // Require agent_id for agentic tasks
    if (empty($data['agent_id'])) {
        throw new \InvalidArgumentException('agent_id is required for agentic tasks');
    }

    return $this->createTask($data);
}

/**
 * Create a system task (automated backend execution)
 */
public function createSystemTask(array $data): AgentTask
{
    $data['type'] = AgentTask::TYPE_SYSTEM;
    
    // Require payload_data for system tasks
    if (empty($data['payload_data'])) {
        throw new \InvalidArgumentException('payload_data is required for system tasks');
    }

    return $this->createTask($data);
}

/**
 * Get tasks by type
 */
public function getTasksByType(string $type, array $filters = []): Collection
{
    $query = AgentTask::where('type', $type);

    if (isset($filters['status'])) {
        $query->where('status', $filters['status']);
    }

    if (isset($filters['agent_id'])) {
        $query->where('agent_id', $filters['agent_id']);
    }

    return $query->orderBy('created_at', 'desc')->get();
}

/**
 * Get manual tasks requiring human attention
 */
public function getManualTasks(array $filters = []): Collection
{
    return $this->getTasksByType(AgentTask::TYPE_MANUAL, $filters);
}

/**
 * Get agentic tasks
 */
public function getAgenticTasks(array $filters = []): Collection
{
    return $this->getTasksByType(AgentTask::TYPE_AGENT, $filters);
}

/**
 * Get system tasks
 */
public function getSystemTasks(array $filters = []): Collection
{
    return $this->getTasksByType(AgentTask::TYPE_SYSTEM, $filters);
}
```

### Step 2: Update TaskExecutionService for Type-Specific Handling

**File:** `app/Services/TaskExecutionService.php` (Review & Enhance)

The implementation in Phase 1 already supports task type routing. Enhance it:

```php
/**
 * Update progress for manual tasks (human feedback)
 */
public function updateManualTaskProgress(AgentTask $task, int $progress, ?string $feedback = null): void
{
    if ($task->type !== AgentTask::TYPE_MANUAL) {
        throw new \InvalidArgumentException('Task is not a manual task');
    }

    $task->update([
        'progress' => min($progress, 100),
        'metadata' => array_merge($task->metadata ?? [], [
            'human_feedback' => $feedback,
            'human_feedback_at' => now()->toIso8601String(),
        ]),
    ]);

    $this->logService->info('Manual task progress updated', [
        'channel' => 'task',
        'type' => 'manual_progress',
        'related_id' => $task->id,
        'related_type' => AgentTask::class,
        'context' => ['progress' => $progress],
    ]);
}

/**
 * Get task execution statistics by type
 */
public function getTaskStatsByType(): array
{
    return [
        'manual' => [
            'total' => AgentTask::where('type', AgentTask::TYPE_MANUAL)->count(),
            'in_progress' => AgentTask::where('type', AgentTask::TYPE_MANUAL)
                ->where('status', AgentTask::STATUS_IN_PROGRESS)->count(),
            'completed' => AgentTask::where('type', AgentTask::TYPE_MANUAL)
                ->where('status', AgentTask::STATUS_COMPLETED)->count(),
        ],
        'agent' => [
            'total' => AgentTask::where('type', AgentTask::TYPE_AGENT)->count(),
            'in_progress' => AgentTask::where('type', AgentTask::TYPE_AGENT)
                ->where('status', AgentTask::STATUS_IN_PROGRESS)->count(),
            'completed' => AgentTask::where('type', AgentTask::TYPE_AGENT)
                ->where('status', AgentTask::STATUS_COMPLETED)->count(),
        ],
        'system' => [
            'total' => AgentTask::where('type', AgentTask::TYPE_SYSTEM)->count(),
            'in_progress' => AgentTask::where('type', AgentTask::TYPE_SYSTEM)
                ->where('status', AgentTask::STATUS_IN_PROGRESS)->count(),
            'completed' => AgentTask::where('type', AgentTask::TYPE_SYSTEM)
                ->where('status', AgentTask::STATUS_COMPLETED)->count(),
        ],
    ];
}
```

### Step 3: Add Type-Specific API Endpoints

**File:** `routes/api.php`

```php
// Task type-specific routes
Route::post('/tasks/manual', [\App\Http\Controllers\TaskController::class, 'createManual'])
    ->name('tasks.manual.create');

Route::post('/tasks/agent', [\App\Http\Controllers\TaskController::class, 'createAgent'])
    ->name('tasks.agent.create');

Route::post('/tasks/system', [\App\Http\Controllers\TaskController::class, 'createSystem'])
    ->name('tasks.system.create');

Route::get('/tasks/type/{type}', [\App\Http\Controllers\TaskController::class, 'getByType'])
    ->name('tasks.by-type');

Route::post('/tasks/{id}/manual-progress', [\App\Http\Controllers\TaskController::class, 'updateManualProgress'])
    ->name('tasks.manual-progress');

Route::get('/tasks/stats/by-type', [\App\Http\Controllers\TaskController::class, 'getStatsByType'])
    ->name('tasks.stats-by-type');
```

**File:** `app/Http/Controllers/TaskController.php` (Add Methods)

```php
/**
 * Create a manual task
 */
public function createManual(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'priority' => 'nullable|integer|min:1|max:5',
        'due_at' => 'nullable|date',
        'contact_id' => 'nullable|exists:contacts,id',
        'conversation_id' => 'nullable|exists:conversations,id',
    ]);

    try {
        $task = $this->taskManager->createManualTask($validated);
        return response()->json(['data' => $task, 'message' => 'Manual task created'], 201);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Create an agentic task
 */
public function createAgent(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'agent_id' => 'required|exists:agents,id',
        'priority' => 'nullable|integer|min:1|max:5',
        'due_at' => 'nullable|date',
        'contact_id' => 'nullable|exists:contacts,id',
        'conversation_id' => 'nullable|exists:conversations,id',
        'payload_data' => 'nullable|array',
        'workflow_id' => 'nullable|exists:workflows,id',
    ]);

    try {
        $task = $this->taskManager->createAgenticTask($validated);
        $this->executionService->executeTask($task);
        return response()->json(['data' => $task, 'message' => 'Agent task created and queued'], 201);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Create a system task
 */
public function createSystem(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'priority' => 'nullable|integer|min:1|max:5',
        'payload_data' => 'required|array',
    ]);

    try {
        $task = $this->taskManager->createSystemTask($validated);
        $this->executionService->executeTask($task);
        return response()->json(['data' => $task, 'message' => 'System task created and queued'], 201);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Get tasks by type
 */
public function getByType(Request $request, string $type)
{
    if (!in_array($type, ['manual', 'agent', 'system'])) {
        return response()->json(['error' => 'Invalid task type'], 400);
    }

    $filters = $request->only(['status', 'agent_id']);
    $tasks = $this->taskManager->getTasksByType($type, $filters);

    return response()->json(['data' => $tasks, 'total' => $tasks->count()]);
}

/**
 * Update manual task progress
 */
public function updateManualProgress(Request $request, string $id)
{
    $validated = $request->validate([
        'progress' => 'required|integer|min:0|max:100',
        'feedback' => 'nullable|string',
    ]);

    try {
        $task = AgentTask::findOrFail($id);
        $this->executionService->updateManualTaskProgress(
            $task,
            $validated['progress'],
            $validated['feedback'] ?? null
        );

        return response()->json(['message' => 'Manual task progress updated']);
    } catch (\Throwable $e) {
        return response()->json(['error' => $e->getMessage()], 400);
    }
}

/**
 * Get task statistics by type
 */
public function getStatsByType()
{
    $stats = $this->executionService->getTaskStatsByType();
    return response()->json(['data' => $stats]);
}
```

---

## PHASE 2 COMPLETION CHECKLIST

- [ ] Event classes created (TaskCompletedEvent, TaskFailedEvent, TaskStatusChangedEvent)
- [ ] Event listeners created (HandleTaskCompleted, HandleTaskFailed)
- [ ] EventServiceProvider updated
- [ ] Soft delete migration applied
- [ ] Model updated with SoftDeletes trait
- [ ] Restore/permanent delete functionality added
- [ ] API endpoints for restore/trash implemented
- [ ] TaskSchedulingService created
- [ ] Artisan command for scheduled task evaluation
- [ ] Scheduler registered in Kernel
- [ ] Scheduling API endpoints created
- [ ] Task type methods added to TaskManagementService
- [ ] Type-specific API endpoints created
- [ ] Type validation in requests
- [ ] Manual task progress tracking
- [ ] Statistics by type endpoint
- [ ] All services injected in controllers
- [ ] Comprehensive testing of new features

---

## INSTALLATION & TESTING

```bash
# Run migrations (from Phase 1)
php artisan migrate

# Register command
php artisan list | grep evaluate-scheduled

# Test event system
php artisan tinker
# >>> event(new \App\Events\TaskCompletedEvent($task));

# Test scheduling
php artisan tasks:evaluate-scheduled

# Run tests
php artisan test --filter=Task
```

---

**Status:** PHASE 2 IMPLEMENTATION GUIDE  
**Complexity:** MEDIUM  
**Dependencies:** Phase 1 (REQUIRED)  
**Ready for Implementation:** YES
