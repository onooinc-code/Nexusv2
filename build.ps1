# Nexus Build Script for Windows PowerShell
# Builds both Backend (Laravel/Vite) and Frontend (Next.js) projects

$ErrorActionPreference = "Stop"

# Define project paths
$backendPath = Join-Path $PSScriptRoot "Nexus-backend"
$frontendPath = Join-Path $PSScriptRoot "Nexus-Frontend"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Nexus Project Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to handle errors
function Handle-Error {
    param (
        [string]$ErrorMessage,
        [string]$ProjectName
    )
    Write-Host "❌ Error building $ProjectName : $ErrorMessage" -ForegroundColor Red
    exit 1
}

# Build Backend
Write-Host "📦 Building Backend..." -ForegroundColor Yellow
Write-Host "Location: $backendPath" -ForegroundColor Gray

try {
    if (-not (Test-Path $backendPath)) {
        Handle-Error "Backend directory not found" "Backend"
    }
    
    Push-Location $backendPath
    
    # Install PHP dependencies with Composer
    Write-Host "📥 Installing PHP dependencies (Composer)..." -ForegroundColor Cyan
    composer install
    if ($LASTEXITCODE -ne 0) {
        throw "composer install failed"
    }
    
    # Install Node dependencies
    Write-Host "📥 Installing Node dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed"
    }
    
    # Generate application key
    Write-Host "🔑 Generating application key..." -ForegroundColor Cyan
    php artisan key:generate
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Application key generation skipped or already set" -ForegroundColor Yellow
    }
    
    # Setup environment file
    Write-Host "⚙️  Setting up environment configuration..." -ForegroundColor Cyan
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Host "✅ Created .env from .env.example" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  No .env or .env.example found" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "ℹ️  .env file already exists" -ForegroundColor Gray
    }
    
    # Run database migrations
    Write-Host "🗄️  Running database migrations..." -ForegroundColor Cyan
    php artisan migrate --force
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Database migrations skipped or already run" -ForegroundColor Yellow
    }
    
    # Run database seeders
    Write-Host "🌱 Running database seeders..." -ForegroundColor Cyan
    php artisan db:seed
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Database seeding skipped or already run" -ForegroundColor Yellow
    }
    
    # Cache configuration
    Write-Host "💾 Caching configuration..." -ForegroundColor Cyan
    php artisan config:cache
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Config cache skipped" -ForegroundColor Yellow
    }
    
    Write-Host "✅ Backend setup completed successfully!" -ForegroundColor Green
    Pop-Location
}
catch {
    Handle-Error $_.Exception.Message "Backend"
}

Write-Host ""

# Build Frontend
Write-Host "📦 Building Frontend..." -ForegroundColor Yellow
Write-Host "Location: $frontendPath" -ForegroundColor Gray

try {
    if (-not (Test-Path $frontendPath)) {
        Handle-Error "Frontend directory not found" "Frontend"
    }
    
    Push-Location $frontendPath
    
    # Install dependencies
    Write-Host "📥 Installing frontend dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed"
    }
    
    # Build frontend
    Write-Host "🔨 Running frontend build..." -ForegroundColor Cyan
    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Frontend build failed"
    }
    
    Write-Host "✅ Frontend build completed successfully!" -ForegroundColor Green
    Pop-Location
}
catch {
    Handle-Error $_.Exception.Message "Frontend"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ All projects built successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host ""
Write-Host "🚀 Starting development servers..." -ForegroundColor Yellow
Write-Host ""

try {
    Push-Location $backendPath
    
    Write-Host "📊 Checking server prerequisites..." -ForegroundColor Cyan
    Write-Host ""
    
    # Check if database is accessible
    Write-Host "🗄️  Testing database connection..." -ForegroundColor Cyan
    php artisan db:monitor 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database connection OK" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Database connection check skipped" -ForegroundColor Yellow
    }
    
    # Check Reverb configuration
    Write-Host "📡 Checking Reverb WebSocket configuration..." -ForegroundColor Cyan
    php artisan monitor:reverb-health 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Reverb configured" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Reverb configuration check skipped" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "🔧 Starting backend services..." -ForegroundColor Cyan
    Write-Host ""
    
    # Start Reverb in a new window
    Write-Host "📡 Starting Reverb WebSocket server (port 8080)..." -ForegroundColor Cyan
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-Command","cd '$backendPath'; php artisan reverb:start --host=0.0.0.0 --port=8080"
    Start-Sleep -Seconds 2
    Write-Host "✅ Reverb server started" -ForegroundColor Green
    
    # Start Laravel app server
    Write-Host "🔧 Starting Laravel application server (port 8000)..." -ForegroundColor Cyan
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-Command","cd '$backendPath'; php artisan serve --host=127.0.0.1 --port=8000"
    Start-Sleep -Seconds 1
    Write-Host "✅ Laravel app server started" -ForegroundColor Green
    
    # Start queue worker
    Write-Host "🔧 Starting queue worker..." -ForegroundColor Cyan
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-Command","cd '$backendPath'; php artisan queue:work --tries=1 --sleep=3"
    Start-Sleep -Seconds 1
    Write-Host "✅ Queue worker started" -ForegroundColor Green
    
    # Start Vite dev server
    Write-Host "🔧 Starting Vite dev server (port 5173)..." -ForegroundColor Cyan
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-Command","cd '$backendPath'; npm run dev"
    Start-Sleep -Seconds 2
    Write-Host "✅ Vite dev server started" -ForegroundColor Green
    
    Pop-Location
    
    # Start frontend
    Push-Location $frontendPath
    Write-Host "🔧 Starting Next.js frontend server (port 3000)..." -ForegroundColor Cyan
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-Command","cd '$frontendPath'; npm run dev"
    Start-Sleep -Seconds 2
    Write-Host "✅ Next.js frontend started" -ForegroundColor Green
    
    Pop-Location
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "🚀 Development Environment Ready!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Backend Services:" -ForegroundColor Green
    Write-Host "  📡 Reverb WebSocket:    ws://127.0.0.1:8080" -ForegroundColor Green
    Write-Host "  🎯 Laravel API:         http://127.0.0.1:8000" -ForegroundColor Green
    Write-Host "  ⚡ Vite Dev Server:     http://127.0.0.1:5173" -ForegroundColor Green
    Write-Host "  🔄 Queue Worker:        Running (background)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Frontend Services:" -ForegroundColor Green
    Write-Host "  🖥️  Next.js App:         http://127.0.0.1:3000" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Useful commands:" -ForegroundColor Cyan
    Write-Host "  Database console:       php artisan tinker" -ForegroundColor Gray
    Write-Host "  Queue monitoring:       php artisan queue:monitor" -ForegroundColor Gray
    Write-Host "  Health check:           php artisan monitor:reverb-health" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "All servers are running. To stop them, close the command windows." -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host "ERROR: Error starting servers: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
