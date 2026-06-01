<?php
/**
 * Quick verification script for TaskHub implementation
 * Run with: php verify_taskhub.php
 */

use App\Models\AgentTask;
use App\Models\TaskLog;
use App\Services\TaskManagementService;
use App\Services\TaskExecutionService;
use App\Services\LogService;
use Illuminate\Database\Capsule\Manager as DB;

// Bootstrap Laravel (simplified for verification)
require __DIR__ . '/Nexus-backend/vendor/autoload.php';
$app = require __DIR__ . '/Nexus-backend/bootstrap/app.php';

$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== TaskHub Implementation Verification ===\n\n";

// Test 1: Check AgentTask model
echo "1. Checking AgentTask model...\n";
$model = new App\Models\AgentTask();
$propertyNames = $model->getFillable();
$traits = class_uses(App\Models\AgentTask::class);
if (in_array(Illuminate\Database\Eloquent\SoftDeletes::class, $traits)) {
    $propertyNames[] = 'deleted_at';
}

$requiredFields = ['type', 'contact_id', 'conversation_id', 'payload_data', 'result_data', 'deleted_at'];
$missingFields = array_filter($requiredFields, function($field) use ($propertyNames) {
    return !in_array($field, $propertyNames);
});

if (empty($missingFields)) {
    echo "   ✓ All required fields present\n";
} else {
    echo "   ✗ Missing fields: " . implode(', ', $missingFields) . "\n";
}

// Check status constants
if (defined('App\Models\AgentTask::STATUS_TODO')) {
    echo "   ✓ Status constants defined\n";
} else {
    echo "   ✗ Status constants missing\n";
}

// Test 2: Check TaskLog model
echo "\n2. Checking TaskLog model...\n";
if (class_exists(App\Models\TaskLog::class)) {
    echo "   ✓ TaskLog model exists\n";
    
    // Check if it has the expected properties
    $taskLogModel = new App\Models\TaskLog();
    $taskLogPropertyNames = $taskLogModel->getFillable();
    
    $expectedProperties = ['task_id', 'level', 'message', 'context'];
    $missingProperties = array_filter($expectedProperties, function($prop) use ($taskLogPropertyNames) {
        return !in_array($prop, $taskLogPropertyNames);
    });
    
    if (empty($missingProperties)) {
        echo "   ✓ TaskLog has expected properties\n";
    } else {
        echo "   ✗ TaskLog missing properties: " . implode(', ', $missingProperties) . "\n";
    }
} else {
    echo "   ✗ TaskLog model not found\n";
}

// Test 3: Check Services
echo "\n3. Checking Services...\n";
$services = [
    'TaskManagementService' => App\Services\TaskManagementService::class,
    'TaskExecutionService' => App\Services\TaskExecutionService::class,
];

foreach ($services as $name => $class) {
    if (class_exists($class)) {
        echo "   ✓ $name exists\n";
    } else {
        echo "   ✗ $name not found\n";
    }
}

// Test 4: Check Jobs
echo "\n4. Checking Jobs...\n";
if (class_exists(App\Jobs\ExecuteAgentTaskJob::class)) {
    echo "   ✓ ExecuteAgentTaskJob exists\n";
    
    // Check if it implements ShouldQueue
    $reflection = new ReflectionClass(App\Jobs\ExecuteAgentTaskJob::class);
    $implements = $reflection->getInterfaceNames();
    
    if (in_array(Illuminate\Contracts\Queue\ShouldQueue::class, $implements)) {
        echo "   ✓ ExecuteAgentTaskJob implements ShouldQueue\n";
    } else {
        echo "   ✗ ExecuteAgentTaskJob does not implement ShouldQueue\n";
    }
} else {
    echo "   ✗ ExecuteAgentTaskJob not found\n";
}

// Test 5: Check Controller Methods
echo "\n5. Checking TaskController methods...\n";
if (class_exists(App\Http\Controllers\TaskController::class)) {
    $reflection = new ReflectionClass(App\Http\Controllers\TaskController::class);
    $methods = $reflection->getMethods(ReflectionMethod::IS_PUBLIC);
    $methodNames = array_map(function($method) { return $method->getName(); }, $methods);
    
    $requiredMethods = ['execute', 'logs', 'updateStatus', 'createManual', 'createAgent', 'createSystem', 'getByType', 'getStatsByType'];
    $missingMethods = array_filter($requiredMethods, function($method) use ($methodNames) {
        return !in_array($method, $methodNames);
    });
    
    if (empty($missingMethods)) {
        echo "   ✓ All required controller methods present\n";
    } else {
        echo "   ✗ Missing controller methods: " . implode(', ', $missingMethods) . "\n";
    }
} else {
    echo "   ✗ TaskController not found\n";
}

// Test 6: Check Routes
echo "\n6. Checking API routes...\n";
$routesFile = __DIR__ . '/Nexus-backend/routes/api.php';
if (file_exists($routesFile)) {
    $routesContent = file_get_contents($routesFile);
    
    $requiredRoutes = [
        'tasks/{id}/execute',
        'tasks/{id}/logs',
        'tasks/{id}/status',
        'tasks/manual',
        'tasks/agent',
        'tasks/system',
        'tasks/type/{type}',
        'tasks/stats/by-type'
    ];
    
    $missingRoutes = array_filter($requiredRoutes, function($route) use ($routesContent) {
        return strpos($routesContent, $route) === false;
    });
    
    if (empty($missingRoutes)) {
        echo "   ✓ All required API routes present\n";
    } else {
        echo "   ✗ Missing API routes: " . implode(', ', $missingRoutes) . "\n";
    }
} else {
    echo "   ✗ Routes file not found\n";
}

// Test 7: Check Events and Listeners
echo "\n7. Checking Events and Listeners...\n";
$events = [
    'TaskCompletedEvent' => App\Events\TaskCompletedEvent::class,
    'TaskFailedEvent' => App\Events\TaskFailedEvent::class,
    'TaskStatusChangedEvent' => App\Events\TaskStatusChangedEvent::class,
];

foreach ($events as $name => $class) {
    if (class_exists($class)) {
        echo "   ✓ $name exists\n";
    } else {
        echo "   ✗ $name not found\n";
    }
}

$listeners = [
    'HandleTaskCompleted' => App\Listeners\HandleTaskCompleted::class,
    'HandleTaskFailed' => App\Listeners\HandleTaskFailed::class,
];

foreach ($listeners as $name => $class) {
    if (class_exists($class)) {
        echo "   ✓ $name exists\n";
    } else {
        echo "   ✗ $name not found\n";
    }
}

// Test 8: Check ServiceProvider
echo "\n8. Checking EventServiceProvider...\n";
if (class_exists(App\Providers\EventServiceProvider::class)) {
    echo "   ✓ EventServiceProvider exists\n";
    
    // Check if it's registered in app.php
    $configApp = __DIR__ . '/Nexus-backend/config/app.php';
    if (file_exists($configApp)) {
        $appContent = file_get_contents($configApp);
        if (strpos($appContent, 'App\\Providers\\EventServiceProvider::class') !== false) {
            echo "   ✓ EventServiceProvider registered in app.php\n";
        } else {
            echo "   ✗ EventServiceProvider not found in app.php providers\n";
        }
    }
} else {
    echo "   ✗ EventServiceProvider not found\n";
}

echo "\n=== Verification Complete ===\n";
echo "Next steps:\n";
echo "1. Run migrations: php artisan migrate\n";
echo "2. Test the API endpoints\n";
echo "3. Begin frontend implementation\n";
?>