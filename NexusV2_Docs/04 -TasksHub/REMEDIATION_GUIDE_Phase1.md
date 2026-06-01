# TaskHub Remediation Guide
## Implementation Roadmap & Code Examples

---

## EXECUTIVE OVERVIEW

This guide provides step-by-step instructions for addressing the critical gaps identified in the TaskHub Audit Report (Score: 58/100).

**Estimated Total Effort:** 6-8 weeks  
**Breaking into Phases:** 4-week cycles with deployable increments

---

## PHASE 1: FOUNDATION (Weeks 1-2)

### Objective
Establish persistent job infrastructure, core service layer, and database schema compliance.

---

## 1.1 Database Schema Remediation

### Step 1: Create Migration for Schema Updates

**File:** `database/migrations/[timestamp]_fix_agent_tasks_schema_for_taskhub_spec.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('agent_tasks', function (Blueprint $table) {
            // Add missing columns
            $table->string('type')->default('agent')->after('status'); // manual, agent, system
            $table->foreignId('contact_id')->nullable()->after('agent_id')->constrained('contacts')->nullOnDelete();
            $table->foreignId('conversation_id')->nullable()->after('contact_id')->constrained('conversations')->nullOnDelete();
            
            // Rename workflow_id to workflow_execution_id for semantic correctness
            // $table->rename('workflow_id', 'workflow_execution_id'); // If supported
            
            // Add data fields
            $table->json('payload_data')->nullable()->after('metadata');
            $table->json('result_data')->nullable()->after('payload_data');
            
            // Add soft deletes
            $table->softDeletes()->after('updated_at');
            
            // Add indexes for performance
            $table->index('type');
            $table->index('status');
            $table->index(['agent_id', 'status']);
            $table->index('contact_id');
            $table->index('conversation_id');
            $table->index('created_at');
        });

        // Create task_logs table for task-specific logging
        Schema::create('task_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('agent_task_id')->constrained('agent_tasks')->cascadeOnDelete();
            $table->string('level'); // info, warning, error, debug
            $table->text('message');
            $table->json('context')->nullable();
            $table->timestamps();
            $table->index(['agent_task_id', 'level']);
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::table('agent_tasks', function (Blueprint $table) {
            $table->dropForeignIdFor('contact_id');
            $table->dropForeignIdFor('conversation_id');
            $table->dropColumn([
                'type',
                'contact_id',
                'conversation_id',
                'payload_data',
                'result_data',
                'deleted_at',
            ]);
            $table->dropIndex(['type']);
            $table->dropIndex(['status']);
            $table->dropIndex(['agent_id', 'status']);
            $table->dropIndex(['contact_id']);
            $table->dropIndex(['conversation_id']);
            $table->dropIndex(['created_at']);
        });

        Schema::dropIfExists('task_logs');
    }
};
```

### Step 2: Update AgentTask Model

**File:** `app/Models/AgentTask.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class AgentTask extends BaseModel
{
    use SoftDeletes;

    protected $fillable = [
        'agent_id',
        'type',
        'title',
        'description',
        'status',
        'priority',
        'progress',
        'due_at',
        'contact_id',
        'conversation_id',
        'workflow_id',
        'payload_data',
        'result_data',
        'metadata',
    ];

    protected $casts = [
        'type' => 'string', // manual, agent, system
        'priority' => 'integer',
        'progress' => 'integer',
        'due_at' => 'datetime',
        'payload_data' => 'json',
        'result_data' => 'json',
        'metadata' => 'json',
    ];

    // Task Type Constants
    public const TYPE_MANUAL = 'manual';
    public const TYPE_AGENT = 'agent';
    public const TYPE_SYSTEM = 'system';

    // Status Constants
    public const STATUS_TODO = 'todo';
    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_BLOCKED = 'blocked';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_FAILED = 'failed';
    public const STATUS_CANCELLED = 'cancelled';

    public function agent(): BelongsTo
    {
        return $this->belongsTo(Agent::class);
    }

    public function contact(): BelongsTo
    {
        return $this->belongsTo(Contact::class);
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function steps(): HasMany
    {
        return $this->hasMany(TaskStep::class);
    }

    public function logs(): HasMany
    {
        return $this->hasMany(TaskLog::class);
    }

    public function workflow(): BelongsTo
    {
        return $this->belongsTo(Workflow::class);
    }

    /**
     * Scope: Get tasks by type
     */
    public function scopeByType($query, string $type)
    {
        return $query->where('type', $type);
    }

    /**
     * Scope: Get active tasks
     */
    public function scopeActive($query)
    {
        return $query->whereIn('status', [
            self::STATUS_TODO,
            self::STATUS_IN_PROGRESS,
            self::STATUS_BLOCKED,
        ]);
    }

    /**
     * Check if task can transition to a new status
     */
    public function canTransitionTo(string $newStatus): bool
    {
        $validTransitions = [
            self::STATUS_TODO => [self::STATUS_IN_PROGRESS, self::STATUS_CANCELLED],
            self::STATUS_IN_PROGRESS => [self::STATUS_BLOCKED, self::STATUS_COMPLETED, self::STATUS_FAILED, self::STATUS_CANCELLED],
            self::STATUS_BLOCKED => [self::STATUS_IN_PROGRESS, self::STATUS_CANCELLED],
            self::STATUS_COMPLETED => [], // Terminal state
            self::STATUS_FAILED => [self::STATUS_IN_PROGRESS], // Retry
            self::STATUS_CANCELLED => [], // Terminal state
        ];

        return in_array($newStatus, $validTransitions[$this->status] ?? []);
    }
}
```

### Step 3: Create TaskLog Model

**File:** `app/Models/TaskLog.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TaskLog extends BaseModel
{
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
}
```

---

## 1.2 Redis & Queue Infrastructure Setup

### Step 1: Update .env Configuration

```env
# CACHE DRIVER
CACHE_DRIVER=redis
CACHE_STORE=redis

# QUEUE DRIVER
QUEUE_CONNECTION=redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_DB=0
REDIS_CACHE_DB=1
REDIS_QUEUE_DB=2

# HORIZON (Optional but recommended for monitoring)
HORIZON_PREFIX=nexus:horizon
```

### Step 2: Configure Queue in config/queue.php

```php
'default' => env('QUEUE_CONNECTION', 'redis'),

'connections' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'default',
        'queue' => env('REDIS_QUEUE', 'default'),
        'retry_after' => 90,
        'block_for' => null,
    ],
],
```

### Step 3: Update Supervisor Configuration

**File:** `/etc/supervisor/conf.d/nexus-horizon.conf`

```ini
[program:nexus-horizon]
process_name=%(program_name)s
command=php /path/to/nexus-backend/artisan horizon
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/horizon.log
```

---

## 1.3 Core Service Layer - TaskManagementService

**File:** `app/Services/TaskManagementService.php`

```php
<?php

namespace App\Services;

use App\Models\AgentTask;
use App\Models\Contact;
use App\Models\Conversation;
use Illuminate\Validation\ValidationException;
use Illuminate\Database\Eloquent\Collection;

class TaskManagementService
{
    protected LogService $logService;

    public function __construct(LogService $logService)
    {
        $this->logService = $logService;
    }

    /**
     * Create a new task
     */
    public function createTask(array $data): AgentTask
    {
        // Validate input
        $validated = $this->validateTaskData($data);

        // Create the task
        $task = AgentTask::create($validated);

        // Log creation
        $this->logService->info('Task created', [
            'channel' => 'task',
            'type' => 'create',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => [
                'title' => $task->title,
                'task_type' => $task->type,
                'status' => $task->status,
            ],
        ]);

        return $task;
    }

    /**
     * Update a task
     */
    public function updateTask(string $taskId, array $data): AgentTask
    {
        $task = AgentTask::findOrFail($taskId);
        
        $validated = $this->validateTaskData($data, $task);
        $task->update($validated);

        $this->logService->info('Task updated', [
            'channel' => 'task',
            'type' => 'update',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
        ]);

        return $task->refresh();
    }

    /**
     * Transition task status with validation
     */
    public function transitionStatus(AgentTask $task, string $newStatus): AgentTask
    {
        // Validate transition
        if (!$task->canTransitionTo($newStatus)) {
            throw ValidationException::withMessages([
                'status' => "Cannot transition from {$task->status} to {$newStatus}",
            ]);
        }

        // Update status
        $oldStatus = $task->status;
        $task->update(['status' => $newStatus]);

        // Update progress if moving to completed
        if ($newStatus === AgentTask::STATUS_COMPLETED) {
            $task->update(['progress' => 100]);
        }

        // Log transition
        $this->logService->info('Task status transitioned', [
            'channel' => 'task',
            'type' => 'status_transition',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => [
                'from_status' => $oldStatus,
                'to_status' => $newStatus,
            ],
        ]);

        return $task->refresh();
    }

    /**
     * Get valid next statuses for a task
     */
    public function getValidNextStatuses(AgentTask $task): array
    {
        $transitions = [
            AgentTask::STATUS_TODO => [
                AgentTask::STATUS_IN_PROGRESS,
                AgentTask::STATUS_CANCELLED,
            ],
            AgentTask::STATUS_IN_PROGRESS => [
                AgentTask::STATUS_BLOCKED,
                AgentTask::STATUS_COMPLETED,
                AgentTask::STATUS_FAILED,
                AgentTask::STATUS_CANCELLED,
            ],
            AgentTask::STATUS_BLOCKED => [
                AgentTask::STATUS_IN_PROGRESS,
                AgentTask::STATUS_CANCELLED,
            ],
            AgentTask::STATUS_COMPLETED => [],
            AgentTask::STATUS_FAILED => [
                AgentTask::STATUS_IN_PROGRESS, // Retry
            ],
            AgentTask::STATUS_CANCELLED => [],
        ];

        return $transitions[$task->status] ?? [];
    }

    /**
     * Delete a task (soft delete)
     */
    public function deleteTask(string $taskId): bool
    {
        $task = AgentTask::findOrFail($taskId);
        $task->delete();

        $this->logService->info('Task deleted', [
            'channel' => 'task',
            'type' => 'delete',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
        ]);

        return true;
    }

    /**
     * Validate task data
     */
    public function validateTaskData(array $data, ?AgentTask $existing = null): array
    {
        $rules = [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'type' => 'required|in:manual,agent,system',
            'status' => 'nullable|in:todo,in_progress,blocked,completed,failed,cancelled',
            'priority' => 'nullable|integer|min:1|max:5',
            'progress' => 'nullable|integer|min:0|max:100',
            'due_at' => 'nullable|date',
            'agent_id' => 'nullable|exists:agents,id',
            'contact_id' => 'nullable|exists:contacts,id',
            'conversation_id' => 'nullable|exists:conversations,id',
            'workflow_id' => 'nullable|exists:workflows,id',
            'payload_data' => 'nullable|array',
            'result_data' => 'nullable|array',
            'metadata' => 'nullable|array',
        ];

        return validator($data, $rules)->validate();
    }

    /**
     * Get task with all relations
     */
    public function getTask(string $taskId): AgentTask
    {
        return AgentTask::with([
            'agent',
            'contact',
            'conversation',
            'workflow',
            'steps',
            'logs',
        ])->findOrFail($taskId);
    }

    /**
     * Search tasks with filters
     */
    public function searchTasks(array $filters = []): Collection
    {
        $query = AgentTask::query();

        if (isset($filters['type'])) {
            $query->where('type', $filters['type']);
        }

        if (isset($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (isset($filters['agent_id'])) {
            $query->where('agent_id', $filters['agent_id']);
        }

        if (isset($filters['contact_id'])) {
            $query->where('contact_id', $filters['contact_id']);
        }

        if (isset($filters['priority'])) {
            $query->where('priority', $filters['priority']);
        }

        if (isset($filters['search'])) {
            $search = $filters['search'];
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        return $query->with(['agent', 'contact'])
            ->orderBy('priority', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();
    }
}
```

---

## 1.4 TaskExecutionService (Core Job Dispatcher)

**File:** `app/Services/TaskExecutionService.php`

```php
<?php

namespace App\Services;

use App\Jobs\ExecuteAgentTaskJob;
use App\Models\AgentTask;
use Illuminate\Support\Facades\Queue;

class TaskExecutionService
{
    protected TaskManagementService $taskManager;
    protected LogService $logService;

    public function __construct(
        TaskManagementService $taskManager,
        LogService $logService
    ) {
        $this->taskManager = $taskManager;
        $this->logService = $logService;
    }

    /**
     * Execute a task (routes based on type)
     */
    public function executeTask(AgentTask $task): void
    {
        // Validate task can be executed
        if (!$this->canExecute($task)) {
            $this->logService->warning('Task cannot be executed', [
                'channel' => 'task',
                'type' => 'execute_blocked',
                'related_id' => $task->id,
                'related_type' => AgentTask::class,
                'context' => ['status' => $task->status],
            ]);
            return;
        }

        // Route based on task type
        match ($task->type) {
            AgentTask::TYPE_AGENT => $this->executeAgentTask($task),
            AgentTask::TYPE_MANUAL => $this->executeManualTask($task),
            AgentTask::TYPE_SYSTEM => $this->executeSystemTask($task),
            default => throw new \InvalidArgumentException("Unknown task type: {$task->type}"),
        };
    }

    /**
     * Execute an agentic task (async via job queue)
     */
    protected function executeAgentTask(AgentTask $task): void
    {
        // Transition to in_progress
        $this->taskManager->transitionStatus($task, AgentTask::STATUS_IN_PROGRESS);

        // Dispatch to queue
        $job = new ExecuteAgentTaskJob($task->id);
        Queue::connection('redis')
            ->onQueue('agent-tasks')
            ->dispatch($job);

        $this->logService->info('Agentic task dispatched to queue', [
            'channel' => 'task',
            'type' => 'execute_agent',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
        ]);
    }

    /**
     * Execute a manual task (no-op, awaiting human)
     */
    protected function executeManualTask(AgentTask $task): void
    {
        // Transition to in_progress (awaiting human)
        $this->taskManager->transitionStatus($task, AgentTask::STATUS_IN_PROGRESS);

        $this->logService->info('Manual task marked for human execution', [
            'channel' => 'task',
            'type' => 'execute_manual',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
        ]);
    }

    /**
     * Execute a system task (immediate execution)
     */
    protected function executeSystemTask(AgentTask $task): void
    {
        $this->taskManager->transitionStatus($task, AgentTask::STATUS_IN_PROGRESS);

        try {
            // Execute system command (example)
            $result = $this->executeSystemCommand($task->payload_data);

            // Mark completed with result
            $this->markCompleted($task, $result);
        } catch (\Throwable $e) {
            $this->markFailed($task, $e);
        }
    }

    /**
     * Mark task as completed
     */
    public function markCompleted(AgentTask $task, array $result = []): void
    {
        $task->update([
            'status' => AgentTask::STATUS_COMPLETED,
            'progress' => 100,
            'result_data' => $result,
            'metadata' => array_merge($task->metadata ?? [], [
                'completed_at' => now()->toIso8601String(),
            ]),
        ]);

        $this->logService->info('Task completed', [
            'channel' => 'task',
            'type' => 'complete',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => ['result_length' => count($result)],
        ]);

        // Emit TaskCompletedEvent for workflow integration
        event(new \App\Events\TaskCompletedEvent($task));
    }

    /**
     * Mark task as failed
     */
    public function markFailed(AgentTask $task, \Throwable $error): void
    {
        $task->update([
            'status' => AgentTask::STATUS_FAILED,
            'metadata' => array_merge($task->metadata ?? [], [
                'failed_at' => now()->toIso8601String(),
                'error' => $error->getMessage(),
                'error_code' => $error->getCode(),
            ]),
        ]);

        $this->logService->error('Task failed', [
            'channel' => 'task',
            'type' => 'fail',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => [
                'error' => $error->getMessage(),
                'file' => $error->getFile(),
                'line' => $error->getLine(),
            ],
        ]);

        // Emit TaskFailedEvent
        event(new \App\Events\TaskFailedEvent($task, $error));
    }

    /**
     * Check if task can be executed
     */
    protected function canExecute(AgentTask $task): bool
    {
        return in_array($task->status, [
            AgentTask::STATUS_TODO,
            AgentTask::STATUS_BLOCKED,
            AgentTask::STATUS_FAILED, // Retry
        ]);
    }

    /**
     * Execute system command (stub)
     */
    protected function executeSystemCommand(array $payload): array
    {
        // Implementation depends on payload structure
        return ['success' => true];
    }
}
```

---

## 1.5 Create ExecuteAgentTaskJob

**File:** `app/Jobs/ExecuteAgentTaskJob.php`

```php
<?php

namespace App\Jobs;

use App\Models\AgentTask;
use App\Services\TaskExecutionService;
use App\Services\TaskLogService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ExecuteAgentTaskJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $maxAttempts = 3;
    public int $backoff = 60; // Start with 60 second backoff

    protected string $taskId;

    public function __construct(string $taskId)
    {
        $this->taskId = $taskId;
        $this->onQueue('agent-tasks');
    }

    public function handle(
        TaskExecutionService $executionService,
        TaskLogService $taskLogService
    ): void {
        $task = AgentTask::find($this->taskId);

        if (!$task) {
            Log::warning("Task not found: {$this->taskId}");
            return;
        }

        try {
            $taskLogService->info($task, 'Starting agent execution', [
                'attempt' => $this->attempts(),
            ]);

            // Call agent to execute task
            $result = $this->callAgent($task);

            // Mark completed
            $executionService->markCompleted($task, $result);

            $taskLogService->info($task, 'Agent execution completed');
        } catch (\Throwable $e) {
            $taskLogService->error($task, 'Agent execution failed: ' . $e->getMessage());

            // Determine if should retry
            if ($this->shouldRetry($e)) {
                $this->release($this->calculateBackoff());
            } else {
                $executionService->markFailed($task, $e);
                $this->fail($e);
            }
        }
    }

    protected function callAgent(AgentTask $task): array
    {
        // Call AgentsHub API
        // Implementation depends on AgentsHub contract
        return [
            'agent_response' => 'Task executed successfully',
            'execution_time' => now()->diffInSeconds(now()),
        ];
    }

    protected function shouldRetry(\Throwable $e): bool
    {
        $retryableErrors = [
            'timeout',
            'connection',
            'rate_limit',
            'service_unavailable',
        ];

        $message = strtolower($e->getMessage());

        foreach ($retryableErrors as $error) {
            if (str_contains($message, $error)) {
                return true;
            }
        }

        return false;
    }

    protected function calculateBackoff(): int
    {
        $attempt = $this->attempts();
        return (int) (60 * (2 ** ($attempt - 1)));
    }

    public function failed(\Throwable $exception): void
    {
        $task = AgentTask::find($this->taskId);
        if ($task) {
            $task->update([
                'status' => 'failed',
                'metadata' => array_merge($task->metadata ?? [], [
                    'job_failed_at' => now()->toIso8601String(),
                    'job_exception' => $exception->getMessage(),
                ]),
            ]);

            // Push to Dead Letter Queue
            event(new \App\Events\TaskMovedToDLQEvent($task, $exception));
        }
    }
}
```

---

## NEXT STEPS

**Continue with Phase 1:**
1. Run migrations
2. Install Redis (if not already present)
3. Configure Supervisor
4. Test queue with sample job

**Proceed to Phase 2:** Event system, Soft Deletes, API endpoints

---

## Installation Verification Checklist

- [ ] Migration successful
- [ ] TaskLog model created
- [ ] AgentTask model updated with soft deletes
- [ ] Redis running and accessible
- [ ] Queue driver configured
- [ ] TaskManagementService created and tested
- [ ] TaskExecutionService created and tested
- [ ] ExecuteAgentTaskJob created
- [ ] Sample job dispatched and processed
- [ ] Logs appearing in SystemLog table

---

**Status:** PHASE 1 IMPLEMENTATION GUIDE  
**Last Updated:** May 27, 2026  
**Ready for Implementation:** YES
