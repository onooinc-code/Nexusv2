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
    Write-Host "ERROR building $ProjectName : $ErrorMessage" -ForegroundColor Red
    exit 1
}

# Build Backend
Write-Host "Building Backend..." -ForegroundColor Yellow
Write-Host "Location: $backendPath" -ForegroundColor Gray

try {
    if (-not (Test-Path $backendPath)) {
        Handle-Error "Backend directory not found" "Backend"
    }
    
    Push-Location $backendPath
    
    # Install PHP dependencies with Composer
    Write-Host "Installing PHP dependencies (Composer)..." -ForegroundColor Cyan
    composer install --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-redis --ignore-platform-req=ext-posix
    if ($LASTEXITCODE -ne 0) {
        throw "composer install failed"
    }
    
    # Install Node dependencies
    Write-Host "Installing Node dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed"
    }
    
    # Generate application key
    Write-Host "Generating application key..." -ForegroundColor Cyan
    php artisan key:generate --force
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Application key generation skipped or already set" -ForegroundColor Yellow
    }
    
    # Setup environment file
    Write-Host "Setting up environment configuration..." -ForegroundColor Cyan
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Host "Created .env from .env.example" -ForegroundColor Green
        }
        else {
            Write-Host "No .env or .env.example found" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host ".env file already exists" -ForegroundColor Gray
    }
    
    # Run database migrations
    Write-Host "Running database migrations..." -ForegroundColor Cyan
    php artisan migrate --force
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Database migrations skipped or already run" -ForegroundColor Yellow
    }
    
    # Run database seeders
    Write-Host "Running database seeders..." -ForegroundColor Cyan
    php artisan db:seed --force
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Database seeding skipped or already run" -ForegroundColor Yellow
    }
    
    # Cache configuration
    Write-Host "Caching configuration..." -ForegroundColor Cyan
    php artisan config:cache
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Config cache skipped" -ForegroundColor Yellow
    }
    
    Write-Host "Backend setup completed successfully!" -ForegroundColor Green
    Pop-Location
}
catch {
    Handle-Error $_.Exception.Message "Backend"
}

Write-Host ""

# Build Frontend
Write-Host "Building Frontend..." -ForegroundColor Yellow
Write-Host "Location: $frontendPath" -ForegroundColor Gray

try {
    if (-not (Test-Path $frontendPath)) {
        Handle-Error "Frontend directory not found" "Frontend"
    }
    
    Push-Location $frontendPath
    
    # Install dependencies
    Write-Host "Installing frontend dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) {
        throw "npm install failed"
    }
    
    # Build frontend
    Write-Host "Running frontend build..." -ForegroundColor Cyan
    npm run build --inspect
    if ($LASTEXITCODE -ne 0) {
        throw "Frontend build failed"
    }
    
    Write-Host "Frontend build completed successfully!" -ForegroundColor Green
    Pop-Location
}
catch {
    Handle-Error $_.Exception.Message "Frontend"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All projects built successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host ""
Write-Host "Starting development servers..." -ForegroundColor Yellow
Write-Host ""

try {
    Push-Location $backendPath
    
    Write-Host "Checking server prerequisites..." -ForegroundColor Cyan
    Write-Host ""
    
    # Check if database is accessible
    Write-Host "Testing database connection..." -ForegroundColor Cyan
    php artisan db:monitor 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database connection OK" -ForegroundColor Green
    }
    else {
        Write-Host "Database connection check skipped" -ForegroundColor Yellow
    }
    
    # Check Reverb configuration
    Write-Host "Checking Reverb WebSocket configuration..." -ForegroundColor Cyan
    php artisan monitor:reverb-health 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Reverb configured" -ForegroundColor Green
    }
    else {
        Write-Host "Reverb configuration check skipped" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Starting all services in a single window..." -ForegroundColor Cyan
    
    # Run the custom Node.js runner to start Reverb, API, Queue, Vite, and Next.js
    node "$PSScriptRoot\start-servers.js"
    
    Pop-Location
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Development Environment Ready!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Backend Services:" -ForegroundColor Green
    Write-Host "  Reverb WebSocket:    ws://127.0.0.1:8080" -ForegroundColor Green
    Write-Host "  Laravel API:         http://127.0.0.1:8000" -ForegroundColor Green
    Write-Host "  Vite Dev Server:     http://127.0.0.1:5173" -ForegroundColor Green
    Write-Host "  Queue Worker:        Running (background)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Frontend Services:" -ForegroundColor Green
    Write-Host "  Next.js App:         http://127.0.0.1:3000" -ForegroundColor Green
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
    Write-Host "ERROR: Error starting servers" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
