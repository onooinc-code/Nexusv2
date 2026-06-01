# TaskHub Remediation Guide - Phase 4
## Polish, Testing & Optimization (Week 7+)

---

## PHASE 4 OBJECTIVES

1. **Rate Limiting & Concurrency Control** - Prevent system overload
2. **Dead Letter Queue Management** - Failed task monitoring & recovery
3. **Comprehensive Testing** - Unit, integration, performance tests
4. **Performance Optimization** - Indexing, caching, query optimization

**Estimated Effort:** 25-30 hours  
**Timeline:** 1 week (ongoing)  
**Prerequisites:** Phase 1, 2, 3 completion

---

## 4.1 Rate Limiting & Concurrency Control

### Step 1: Create Rate Limiting Middleware

**File:** `app/Http/Middleware/TaskRateLimiting.php`

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Symfony\Component\HttpFoundation\Response;

class TaskRateLimiting
{
    public function handle(Request $request, Closure $next): Response
    {
        // Rate limit task creation by user
        if ($request->isMethod('post') && $request->path() === 'api/v1/tasks') {
            $userId = $request->user()?->id;
            if ($userId) {
                $key = "task-create:{$userId}";
                if (RateLimiter::tooManyAttempts($key, 10)) { // 10 per minute
                    return response()->json([
                        'error' => 'Too many task creation requests. Please wait before creating more tasks.',
                    ], 429);
                }
                RateLimiter::hit($key, 60);
            }
        }

        return $next($request);
    }
}
```

### Step 2: Configure Horizon Queue Concurrency

**File:** `config/horizon.php` (Create/Update)

```php
<?php

return [
    'defaults' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['agent-tasks'],
            'balance' => 'simple',
            'minProcesses' => 1,
            'maxProcesses' => 10,
            'balanceMaxShift' => '1:0',
            'balanceWaitSeconds' => 1,
            'timeout' => 3600,
            'maxTries' => 3,
        ],
        'supervisor-2' => [
            'connection' => 'redis',
            'queue' => ['system-tasks'],
            'balance' => 'simple',
            'minProcesses' => 1,
            'maxProcesses' => 5,
            'timeout' => 1800,
            'maxTries' => 3,
        ],
        'supervisor-3' => [
            'connection' => 'redis',
            'queue' => ['default'],
            'balance' => 'simple',
            'minProcesses' => 1,
            'maxProcesses' => 3,
            'timeout' => 900,
            'maxTries' => 1,
        ],
    ],

    'environments' => [
        'production' => [
            'supervisor-1' => [
                'maxProcesses' => 20,
                'maxTries' => 5,
            ],
            'supervisor-2' => [
                'maxProcesses' => 10,
                'maxTries' => 5,
            ],
        ],
    ],

    'trim' => [
        'monitored' => 10080,
        'recent' => 60,
    ],

    'path' => 'horizon',
    'use' => 'default',
    'prefix' => env('HORIZON_PREFIX', 'horizon:'),
    'snapshot_wait' => 0,
];
```

### Step 3: Implement Task Queue Concurrency Limiter

**File:** `app/Services/TaskQueueService.php` (Add Methods)

```php
/**
 * Check if agent task queue is at capacity
 */
public function isAgentQueueAtCapacity(): bool
{
    $maxConcurrent = config('task.max_concurrent_agent_tasks', 10);
    $activeCount = AgentTask::where('status', AgentTask::STATUS_IN_PROGRESS)
        ->where('type', AgentTask::TYPE_AGENT)
        ->count();

    return $activeCount >= $maxConcurrent;
}

/**
 * Get current queue load percentage
 */
public function getQueueLoadPercentage(): int
{
    $maxConcurrent = config('task.max_concurrent_agent_tasks', 10);
    $activeCount = AgentTask::where('status', AgentTask::STATUS_IN_PROGRESS)
        ->count();

    return (int) (($activeCount / $maxConcurrent) * 100);
}

/**
 * Implement backpressure - delay task execution if queue is overloaded
 */
public function enqueueWithBackpressure(AgentTask $task, array $options = []): AgentTask
{
    $loadPercent = $this->getQueueLoadPercentage();

    // If queue is 80%+ loaded, add delay
    if ($loadPercent >= 80) {
        $delay = match (true) {
            $loadPercent >= 95 => 300, // 5 minutes
            $loadPercent >= 90 => 180, // 3 minutes
            $loadPercent >= 85 => 60,  // 1 minute
            default => 0,
        };

        if ($delay > 0) {
            $options['delay'] = $delay;
            \Log::warning("Queue overloaded ({$loadPercent}%). Delaying task execution.", [
                'task_id' => $task->id,
                'delay_seconds' => $delay,
            ]);
        }
    }

    return $this->enqueue($task, $options);
}
```

### Step 4: Add Concurrency Monitoring Endpoint

**File:** `app/Http/Controllers/TaskController.php` (Add Method)

```php
/**
 * GET /api/v1/tasks/metrics/concurrency
 * Monitor queue concurrency and load
 */
public function getConcurrencyMetrics()
{
    $agentTasksActive = AgentTask::where('type', AgentTask::TYPE_AGENT)
        ->where('status', AgentTask::STATUS_IN_PROGRESS)
        ->count();

    $agentTasksPending = AgentTask::where('type', AgentTask::TYPE_AGENT)
        ->where('status', AgentTask::STATUS_TODO)
        ->count();

    $systemTasksActive = AgentTask::where('type', AgentTask::TYPE_SYSTEM)
        ->where('status', AgentTask::STATUS_IN_PROGRESS)
        ->count();

    $maxConcurrentAgent = config('task.max_concurrent_agent_tasks', 10);

    return response()->json([
        'agent_tasks' => [
            'active' => $agentTasksActive,
            'pending' => $agentTasksPending,
            'max_concurrent' => $maxConcurrentAgent,
            'load_percentage' => (int) (($agentTasksActive / $maxConcurrentAgent) * 100),
        ],
        'system_tasks' => [
            'active' => $systemTasksActive,
        ],
        'timestamp' => now()->toIso8601String(),
    ]);
}
```

---

## 4.2 Dead Letter Queue Management

### Step 1: Create DLQ Model

**File:** `app/Models/DeadLetterTask.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeadLetterTask extends BaseModel
{
    protected $table = 'dead_letter_tasks';

    protected $fillable = [
        'agent_task_id',
        'error_message',
        'error_code',
        'job_exception',
        'retry_count',
        'max_retries',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'json',
    ];

    public function task(): BelongsTo
    {
        return $this->belongsTo(AgentTask::class, 'agent_task_id');
    }

    /**
     * Scope: Get tasks in DLQ
     */
    public function scopeInDLQ($query)
    {
        return $query->whereNotNull('agent_task_id');
    }

    /**
     * Scope: Get tasks by error
     */
    public function scopeByError($query, string $errorCode)
    {
        return $query->where('error_code', $errorCode);
    }
}
```

### Step 2: Create DLQ Migration

**File:** `database/migrations/[timestamp]_create_dead_letter_tasks_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('dead_letter_tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('agent_task_id')->constrained('agent_tasks')->cascadeOnDelete();
            $table->string('error_message');
            $table->string('error_code')->nullable();
            $table->text('job_exception')->nullable();
            $table->integer('retry_count')->default(0);
            $table->integer('max_retries')->default(3);
            $table->json('metadata')->nullable();
            $table->timestamps();
            
            $table->index('agent_task_id');
            $table->index('error_code');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dead_letter_tasks');
    }
};
```

### Step 3: Create DLQ Service

**File:** `app/Services/DeadLetterQueueService.php`

```php
<?php

namespace App\Services;

use App\Models\AgentTask;
use App\Models\DeadLetterTask;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Log;
use Throwable;

class DeadLetterQueueService
{
    protected LogService $logService;

    public function __construct(LogService $logService)
    {
        $this->logService = $logService;
    }

    /**
     * Move failed task to Dead Letter Queue
     */
    public function moveToQueue(
        AgentTask $task,
        Throwable $exception,
        int $retryCount = 0,
        int $maxRetries = 3
    ): DeadLetterTask {
        $dlqEntry = DeadLetterTask::create([
            'agent_task_id' => $task->id,
            'error_message' => $exception->getMessage(),
            'error_code' => (string) $exception->getCode(),
            'job_exception' => $exception->getTraceAsString(),
            'retry_count' => $retryCount,
            'max_retries' => $maxRetries,
            'metadata' => [
                'moved_at' => now()->toIso8601String(),
                'task_type' => $task->type,
                'task_status' => $task->status,
            ],
        ]);

        // Update task metadata
        $task->update([
            'metadata' => array_merge($task->metadata ?? [], [
                'in_dlq' => true,
                'dlq_moved_at' => now()->toIso8601String(),
                'dlq_entry_id' => $dlqEntry->id,
            ]),
        ]);

        $this->logService->error('Task moved to Dead Letter Queue', [
            'channel' => 'dlq',
            'type' => 'move_to_dlq',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => [
                'error' => $exception->getMessage(),
                'retry_count' => $retryCount,
            ],
        ]);

        return $dlqEntry;
    }

    /**
     * Retry a task from DLQ
     */
    public function retryTask(string $dlqEntryId): AgentTask
    {
        $dlqEntry = DeadLetterTask::findOrFail($dlqEntryId);
        $task = $dlqEntry->task;

        if (!$task) {
            throw new \Exception('Associated task not found');
        }

        if ($dlqEntry->retry_count >= $dlqEntry->max_retries) {
            throw new \Exception('Maximum retry attempts exceeded');
        }

        // Reset task to TODO for retry
        $task->update([
            'status' => AgentTask::STATUS_TODO,
            'metadata' => array_merge($task->metadata ?? [], [
                'dlq_retry_attempt' => ($dlqEntry->retry_count + 1),
                'dlq_retry_at' => now()->toIso8601String(),
            ]),
        ]);

        // Update DLQ entry
        $dlqEntry->increment('retry_count');

        $this->logService->info('DLQ task retried', [
            'channel' => 'dlq',
            'type' => 'retry',
            'related_id' => $task->id,
            'related_type' => AgentTask::class,
            'context' => ['retry_count' => $dlqEntry->retry_count],
        ]);

        return $task;
    }

    /**
     * Get tasks in DLQ
     */
    public function getQueuedTasks(array $filters = []): Collection
    {
        $query = DeadLetterTask::query();

        if (isset($filters['error_code'])) {
            $query->where('error_code', $filters['error_code']);
        }

        if (isset($filters['task_type'])) {
            $query->whereJsonContains('metadata->task_type', $filters['task_type']);
        }

        return $query
            ->with('task')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Get DLQ statistics
     */
    public function getStatistics(): array
    {
        $totalInQueue = DeadLetterTask::count();
        $byErrorCode = DeadLetterTask::selectRaw('error_code, COUNT(*) as count')
            ->groupBy('error_code')
            ->pluck('count', 'error_code');

        $averageRetries = DeadLetterTask::avg('retry_count');

        return [
            'total_in_queue' => $totalInQueue,
            'errors' => $byErrorCode->toArray(),
            'average_retries' => round($averageRetries, 2),
            'timestamp' => now()->toIso8601String(),
        ];
    }

    /**
     * Clean up old DLQ entries (older than 30 days)
     */
    public function cleanupOldEntries(int $daysOld = 30): int
    {
        $cutoffDate = now()->subDays($daysOld);

        $deleted = DeadLetterTask::where('created_at', '<', $cutoffDate)
            ->delete();

        Log::info("Cleaned up {$deleted} old DLQ entries");

        return $deleted;
    }
}
```

### Step 4: Add DLQ API Endpoints

**File:** `routes/api.php`

```php
// Dead Letter Queue routes
Route::prefix('dlq')->group(function () {
    Route::get('/tasks', [\App\Http\Controllers\DLQController::class, 'index'])
        ->name('dlq.tasks');
    
    Route::post('/tasks/{id}/retry', [\App\Http\Controllers\DLQController::class, 'retry'])
        ->name('dlq.retry');
    
    Route::delete('/tasks/{id}', [\App\Http\Controllers\DLQController::class, 'dismiss'])
        ->name('dlq.dismiss');
    
    Route::get('/stats', [\App\Http\Controllers\DLQController::class, 'stats'])
        ->name('dlq.stats');
});
```

**File:** `app/Http/Controllers/DLQController.php`

```php
<?php

namespace App\Http\Controllers;

use App\Services\DeadLetterQueueService;
use Illuminate\Http\Request;

class DLQController extends Controller
{
    public function __construct(
        protected DeadLetterQueueService $dlqService
    ) {}

    /**
     * Get tasks in Dead Letter Queue
     */
    public function index(Request $request)
    {
        $filters = $request->only(['error_code', 'task_type']);
        $tasks = $this->dlqService->getQueuedTasks($filters);

        return response()->json([
            'data' => $tasks,
            'total' => $tasks->count(),
        ]);
    }

    /**
     * Retry a failed task
     */
    public function retry(string $id)
    {
        try {
            $task = $this->dlqService->retryTask($id);
            return response()->json([
                'data' => $task,
                'message' => 'Task queued for retry',
            ]);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    /**
     * Dismiss a task from DLQ (mark as acknowledged)
     */
    public function dismiss(string $id)
    {
        try {
            $dlqEntry = DeadLetterTask::findOrFail($id);
            $dlqEntry->delete();

            return response()->json(['message' => 'Task dismissed from DLQ']);
        } catch (\Throwable $e) {
            return response()->json(['error' => $e->getMessage()], 404);
        }
    }

    /**
     * Get DLQ statistics
     */
    public function stats()
    {
        $stats = $this->dlqService->getStatistics();
        return response()->json(['data' => $stats]);
    }
}
```

---

## 4.3 Comprehensive Testing Suite

### Step 1: Unit Tests for TaskManagementService

**File:** `tests/Unit/Services/TaskManagementServiceTest.php`

```php
<?php

namespace Tests\Unit\Services;

use App\Models\AgentTask;
use App\Models\Agent;
use App\Services\TaskManagementService;
use App\Services\LogService;
use Tests\TestCase;

class TaskManagementServiceTest extends TestCase
{
    protected TaskManagementService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = $this->app->make(TaskManagementService::class);
    }

    public function test_can_create_task()
    {
        $data = [
            'type' => 'agent',
            'title' => 'Test Task',
            'description' => 'Test Description',
            'priority' => 3,
            'agent_id' => Agent::factory()->create()->id,
        ];

        $task = $this->service->createTask($data);

        $this->assertInstanceOf(AgentTask::class, $task);
        $this->assertEquals('agent', $task->type);
        $this->assertEquals('Test Task', $task->title);
        $this->assertDatabaseHas('agent_tasks', ['id' => $task->id]);
    }

    public function test_can_transition_status()
    {
        $task = AgentTask::factory()->create(['status' => 'todo']);

        $updated = $this->service->transitionStatus($task, 'in_progress');

        $this->assertEquals('in_progress', $updated->status);
        $this->assertDatabaseHas('agent_tasks', [
            'id' => $task->id,
            'status' => 'in_progress',
        ]);
    }

    public function test_cannot_transition_invalid_status()
    {
        $this->expectException(\Exception::class);
        
        $task = AgentTask::factory()->create(['status' => 'completed']);
        $this->service->transitionStatus($task, 'todo'); // Invalid transition
    }

    public function test_can_soft_delete_task()
    {
        $task = AgentTask::factory()->create();
        $id = $task->id;

        $this->service->deleteTask($id);

        $this->assertSoftDeleted('agent_tasks', ['id' => $id]);
    }

    public function test_can_restore_deleted_task()
    {
        $task = AgentTask::factory()->create();
        $task->delete();

        $restored = $this->service->restoreTask($task->id);

        $this->assertFalse($restored->trashed());
    }
}
```

### Step 2: Integration Tests for Task Execution

**File:** `tests/Feature/TaskExecutionTest.php`

```php
<?php

namespace Tests\Feature;

use App\Models\AgentTask;
use App\Models\Agent;
use App\Services\TaskExecutionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TaskExecutionTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_execute_agent_task()
    {
        $agent = Agent::factory()->create();
        $task = AgentTask::factory()->create([
            'type' => 'agent',
            'agent_id' => $agent->id,
            'status' => 'todo',
        ]);

        $service = $this->app->make(TaskExecutionService::class);
        $service->executeTask($task);

        $task->refresh();
        $this->assertEquals('in_progress', $task->status);
    }

    public function test_can_mark_task_completed()
    {
        $task = AgentTask::factory()->create(['status' => 'in_progress']);

        $service = $this->app->make(TaskExecutionService::class);
        $service->markCompleted($task, ['result' => 'success']);

        $task->refresh();
        $this->assertEquals('completed', $task->status);
        $this->assertEquals(100, $task->progress);
        $this->assertEquals(['result' => 'success'], $task->result_data);
    }

    public function test_can_mark_task_failed()
    {
        $task = AgentTask::factory()->create(['status' => 'in_progress']);
        $error = new \Exception('Test error');

        $service = $this->app->make(TaskExecutionService::class);
        $service->markFailed($task, $error);

        $task->refresh();
        $this->assertEquals('failed', $task->status);
    }
}
```

### Step 3: API Endpoint Tests

**File:** `tests/Feature/TaskApiTest.php`

```php
<?php

namespace Tests\Feature;

use App\Models\AgentTask;
use App\Models\Agent;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TaskApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
    }

    public function test_can_list_tasks()
    {
        AgentTask::factory(5)->create();

        $response = $this->actingAs($this->user)
            ->getJson('/api/v1/tasks');

        $response->assertStatus(200)
            ->assertJsonStructure(['data', 'meta'])
            ->assertJsonCount(5, 'data');
    }

    public function test_can_create_task()
    {
        $agent = Agent::factory()->create();

        $response = $this->actingAs($this->user)
            ->postJson('/api/v1/tasks', [
                'type' => 'agent',
                'title' => 'New Task',
                'description' => 'Test',
                'priority' => 3,
                'agent_id' => $agent->id,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.title', 'New Task');
    }

    public function test_can_update_task_status()
    {
        $task = AgentTask::factory()->create(['status' => 'todo']);

        $response = $this->actingAs($this->user)
            ->patchJson("/api/v1/tasks/{$task->id}/status", [
                'status' => 'in_progress',
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('agent_tasks', [
            'id' => $task->id,
            'status' => 'in_progress',
        ]);
    }

    public function test_can_get_task_logs()
    {
        $task = AgentTask::factory()->create();
        // Create some logs
        TaskLog::factory(5)->create(['agent_task_id' => $task->id]);

        $response = $this->actingAs($this->user)
            ->getJson("/api/v1/tasks/{$task->id}/logs");

        $response->assertStatus(200)
            ->assertJsonPath('total', 5);
    }
}
```

### Step 4: Performance Tests

**File:** `tests/Performance/TaskBenchmark.php`

```php
<?php

namespace Tests\Performance;

use App\Models\AgentTask;
use App\Services\TaskManagementService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TaskBenchmark extends TestCase
{
    use RefreshDatabase;

    public function test_create_1000_tasks_performance()
    {
        $service = $this->app->make(TaskManagementService::class);
        
        $start = microtime(true);

        for ($i = 0; $i < 1000; $i++) {
            $service->createTask([
                'type' => 'manual',
                'title' => "Task {$i}",
                'priority' => rand(1, 5),
            ]);
        }

        $duration = microtime(true) - $start;

        // Should complete in under 10 seconds
        $this->assertLessThan(10, $duration);
        $this->assertDatabaseCount('agent_tasks', 1000);
    }

    public function test_filter_tasks_performance()
    {
        AgentTask::factory(10000)->create();

        $service = $this->app->make(TaskManagementService::class);
        
        $start = microtime(true);

        for ($i = 0; $i < 100; $i++) {
            $service->searchTasks([
                'status' => 'todo',
                'priority' => rand(1, 5),
            ]);
        }

        $duration = microtime(true) - $start;

        // 100 queries on 10k records should complete under 5 seconds
        $this->assertLessThan(5, $duration);
    }
}
```

---

## 4.4 Database Optimization

### Step 1: Create Optimization Migration

**File:** `database/migrations/[timestamp]_optimize_agent_tasks_indexes.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('agent_tasks', function (Blueprint $table) {
            // Composite indexes for common queries
            $table->index(['status', 'created_at']);
            $table->index(['type', 'status']);
            $table->index(['agent_id', 'status', 'created_at']);
            $table->index(['contact_id', 'created_at']);
            $table->index(['priority', 'status']);
            
            // Full-text search index
            $table->fullText(['title', 'description']);
        });

        // Create indexes on task_logs
        Schema::table('task_logs', function (Blueprint $table) {
            $table->index(['agent_task_id', 'created_at']);
            $table->index(['level', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::table('agent_tasks', function (Blueprint $table) {
            $table->dropIndex(['status', 'created_at']);
            $table->dropIndex(['type', 'status']);
            $table->dropIndex(['agent_id', 'status', 'created_at']);
            $table->dropIndex(['contact_id', 'created_at']);
            $table->dropIndex(['priority', 'status']);
            $table->dropFullText(['title', 'description']);
        });

        Schema::table('task_logs', function (Blueprint $table) {
            $table->dropIndex(['agent_task_id', 'created_at']);
            $table->dropIndex(['level', 'created_at']);
        });
    }
};
```

### Step 2: Query Optimization in Services

**File:** `app/Services/TaskManagementService.php` (Update searchTasks)

```php
/**
 * Optimized search with eager loading
 */
public function searchTasks(array $filters = []): Collection
{
    $query = AgentTask::query();

    // Apply filters efficiently
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
        // Use full-text search
        $search = $filters['search'];
        $query->whereRaw("MATCH(title, description) AGAINST(? IN BOOLEAN MODE)", [$search]);
    }

    // Eager load relations to prevent N+1 queries
    return $query
        ->with(['agent:id,name', 'contact:id,name', 'conversation:id,title'])
        ->orderBy('priority', 'desc')
        ->orderBy('created_at', 'desc')
        ->get();
}
```

### Step 3: Redis Caching

**File:** `app/Services/TaskManagementService.php` (Add Caching)

```php
/**
 * Get task statistics with caching
 */
public function getTaskStatistics(): array
{
    return \Cache::remember('task:statistics', 60, function () {
        return [
            'total' => AgentTask::count(),
            'by_status' => [
                'todo' => AgentTask::where('status', 'todo')->count(),
                'in_progress' => AgentTask::where('status', 'in_progress')->count(),
                'completed' => AgentTask::where('status', 'completed')->count(),
                'failed' => AgentTask::where('status', 'failed')->count(),
            ],
            'by_type' => [
                'manual' => AgentTask::where('type', 'manual')->count(),
                'agent' => AgentTask::where('type', 'agent')->count(),
                'system' => AgentTask::where('type', 'system')->count(),
            ],
        ];
    });
}

/**
 * Clear statistics cache when tasks change
 */
protected function clearStatsCache(): void
{
    \Cache::forget('task:statistics');
}
```

---

## 4.5 Monitoring & Observability

### Step 1: Create Monitoring Artisan Command

**File:** `app/Console/Commands/MonitorTaskHealth.php`

```php
<?php

namespace App\Console\Commands;

use App\Models\AgentTask;
use App\Models\DeadLetterTask;
use App\Services\DeadLetterQueueService;
use Illuminate\Console\Command;

class MonitorTaskHealth extends Command
{
    protected $signature = 'tasks:health-check';
    protected $description = 'Monitor task system health and emit alerts';

    public function handle(DeadLetterQueueService $dlqService)
    {
        $this->line('═══════════════════════════════════');
        $this->line('Task System Health Report');
        $this->line('═══════════════════════════════════');

        // Task statistics
        $stats = [
            'Total Tasks' => AgentTask::count(),
            'Active' => AgentTask::where('status', 'in_progress')->count(),
            'Pending' => AgentTask::where('status', 'todo')->count(),
            'Completed' => AgentTask::where('status', 'completed')->count(),
            'Failed' => AgentTask::where('status', 'failed')->count(),
        ];

        $this->table(['Metric', 'Count'], array_map(fn($k, $v) => [$k, $v], array_keys($stats), $stats));

        // DLQ statistics
        $dlqStats = $dlqService->getStatistics();
        $this->newLine();
        $this->info("Dead Letter Queue: {$dlqStats['total_in_queue']} tasks");

        // Performance metrics
        $avgExecutionTime = AgentTask::where('status', 'completed')
            ->whereNotNull('updated_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(SECOND, created_at, updated_at)) as avg_time')
            ->first()
            ->avg_time;

        $this->newLine();
        $this->info("Average Execution Time: " . round($avgExecutionTime / 60, 2) . " minutes");

        // Alerts
        $this->newLine();
        $this->line('─── Alerts ───');

        if ($stats['Active'] > 20) {
            $this->warn("⚠ High number of active tasks: {$stats['Active']}");
        }

        if ($stats['Failed'] > 10) {
            $this->warn("⚠ High number of failed tasks: {$stats['Failed']}");
        }

        if ($dlqStats['total_in_queue'] > 5) {
            $this->warn("⚠ Tasks in Dead Letter Queue: {$dlqStats['total_in_queue']}");
        }

        return self::SUCCESS;
    }
}
```

---

## 4.6 Documentation & Deployment Guide

### Step 1: Create Deployment Checklist

**File:** `docs/DEPLOYMENT_CHECKLIST.md`

```markdown
# TaskHub Deployment Checklist

## Pre-Deployment

- [ ] All tests passing (unit, integration, feature)
- [ ] Code review completed
- [ ] Performance testing completed
- [ ] Database backups created
- [ ] Redis cluster health verified
- [ ] Reverb WebSocket service ready

## Deployment Steps

1. **Backup Database**
   ```bash
   php artisan backup:run
   ```

2. **Run Migrations**
   ```bash
   php artisan migrate --force
   ```

3. **Clear Caches**
   ```bash
   php artisan cache:clear
   php artisan config:clear
   ```

4. **Start Horizon (if not using Supervisor)**
   ```bash
   php artisan horizon
   ```

5. **Verify Services**
   ```bash
   php artisan health-check
   php artisan tasks:health-check
   ```

## Post-Deployment

- [ ] Monitor error logs for 24 hours
- [ ] Check task execution rates
- [ ] Verify real-time WebSocket updates
- [ ] Test all API endpoints
- [ ] Validate task creation and execution
- [ ] Monitor Redis memory usage
- [ ] Check queue processing times
```

---

## PHASE 4 COMPLETION CHECKLIST

- [ ] Rate limiting middleware created
- [ ] Horizon queue configuration optimized
- [ ] Task queue concurrency limiter implemented
- [ ] Backpressure mechanism working
- [ ] DeadLetterTask model created
- [ ] DLQ migration created
- [ ] DeadLetterQueueService implemented
- [ ] DLQ API endpoints created
- [ ] DLQ UI component built (optional)
- [ ] Unit tests for services created
- [ ] Integration tests for execution created
- [ ] API endpoint tests created
- [ ] Performance benchmark tests created
- [ ] Database indexes optimized
- [ ] Query optimization implemented
- [ ] Redis caching added
- [ ] Monitoring command created
- [ ] Health check dashboard built
- [ ] Deployment guide created
- [ ] All documentation updated

---

## PRODUCTION READINESS CHECKLIST

Before deploying to production:

- [ ] All Phase 1-4 items completed
- [ ] 80%+ test coverage achieved
- [ ] Performance targets met (p95 < 2s)
- [ ] No console errors or warnings
- [ ] Rate limiting tested
- [ ] DLQ tested with manual failures
- [ ] Horizontal scaling tested
- [ ] Disaster recovery plan documented
- [ ] Monitoring alerts configured
- [ ] On-call runbook prepared
- [ ] Team trained on operations
- [ ] Load testing completed (1000+ tasks/min)

---

## ONGOING MAINTENANCE

After deployment:

```bash
# Daily health checks
php artisan tasks:health-check

# Weekly cleanup
php artisan queue:flush
php artisan db:seed --class=TaskCleanupSeeder

# Monthly optimization
php artisan db:optimize
php artisan cache:prune-stale-tags

# Monitor metrics
php artisan metrics:export
```

---

**Status:** PHASE 4 IMPLEMENTATION GUIDE  
**Complexity:** MEDIUM  
**Dependencies:** Phase 1, 2, 3 (REQUIRED)  
**Ready for Implementation:** YES

**Total Project Timeline:** 7-8 weeks  
**Team Recommendation:** 1-2 senior engineers  
**Post-Implementation Support:** 2 weeks (bug fixes, tuning)
