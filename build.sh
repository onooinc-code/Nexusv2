#!/bin/bash

# Nexus Build Script for Unix/Linux/macOS
# Builds both Backend (Laravel/Vite) and Frontend (Next.js) projects

set -e

# Define project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_PATH="$SCRIPT_DIR/Nexus-backend"
FRONTEND_PATH="$SCRIPT_DIR/Nexus-Frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo "Nexus Project Build Script"
echo "========================================${NC}"
echo ""

# Function to handle errors
handle_error() {
    local error_message="$1"
    local project_name="$2"
    echo -e "${RED}❌ Error building $project_name: $error_message${NC}"
    exit 1
}

# Build Backend
echo -e "${YELLOW}📦 Building Backend...${NC}"
echo -e "${GRAY}Location: $BACKEND_PATH${NC}"

if [ ! -d "$BACKEND_PATH" ]; then
    handle_error "Backend directory not found" "Backend"
fi

(
    cd "$BACKEND_PATH"
    
    # Install PHP dependencies with Composer
    echo -e "${CYAN}📥 Installing PHP dependencies (Composer)...${NC}"
    COMPOSER_INSTALL_CMD="composer install"
    if uname | grep -Eiq "(mingw|msys|cygwin)"; then
        echo -e "${YELLOW}⚠️  Windows detected; ignoring ext-pcntl and ext-posix platform requirements for composer install.${NC}"
        COMPOSER_INSTALL_CMD="composer install --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-posix"
    fi
    $COMPOSER_INSTALL_CMD || handle_error "composer install failed" "Backend"
    
    # Install Node dependencies
    echo -e "${CYAN}📥 Installing Node dependencies...${NC}"
    npm install || handle_error "npm install failed" "Backend"
    
    # Generate application key
    echo -e "${CYAN}🔑 Generating application key...${NC}"
    php artisan key:generate || echo -e "${YELLOW}⚠️  Application key generation skipped or already set${NC}"
    
    # Setup environment file
    echo -e "${CYAN}⚙️  Setting up environment configuration...${NC}"
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            echo -e "${GREEN}✅ Created .env from .env.example${NC}"
        else
            echo -e "${YELLOW}⚠️  No .env or .env.example found${NC}"
        fi
    else
        echo -e "${GRAY}ℹ️  .env file already exists${NC}"
    fi
    
    # Run database migrations
    echo -e "${CYAN}🗄️  Running database migrations...${NC}"
    php artisan migrate --force || echo -e "${YELLOW}⚠️  Database migrations skipped or already run${NC}"
    
    # Run database seeders
    echo -e "${CYAN}🌱 Running database seeders...${NC}"
    php artisan db:seed || echo -e "${YELLOW}⚠️  Database seeding skipped or already run${NC}"
    
    # Cache configuration
    echo -e "${CYAN}💾 Caching configuration...${NC}"
    php artisan config:cache || echo -e "${YELLOW}⚠️  Config cache skipped${NC}"
    
    echo -e "${GREEN}✅ Backend setup completed successfully!${NC}"
) || handle_error "Backend setup process failed" "Backend"

echo ""

# Build Frontend
echo -e "${YELLOW}📦 Building Frontend...${NC}"
echo -e "${GRAY}Location: $FRONTEND_PATH${NC}"

if [ ! -d "$FRONTEND_PATH" ]; then
    handle_error "Frontend directory not found" "Frontend"
fi

(
    cd "$FRONTEND_PATH"
    
    # Install dependencies
    echo -e "${CYAN}📥 Installing frontend dependencies...${NC}"
    npm install || handle_error "npm install failed" "Frontend"
    
    # Build frontend
    echo -e "${CYAN}🔨 Running frontend build...${NC}"
    npm run build || handle_error "Frontend build failed" "Frontend"
    
    echo -e "${GREEN}✅ Frontend build completed successfully!${NC}"
) || handle_error "Frontend build process failed" "Frontend"

echo ""
echo -e "${YELLOW}🚀 Starting development servers...${NC}"

PIDS=()
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping development servers...${NC}"
    if [ ${#PIDS[@]} -gt 0 ]; then
        kill "${PIDS[@]}" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

pushd "$BACKEND_PATH" >/dev/null

echo ""
echo -e "${CYAN}📊 Checking server prerequisites...${NC}"

# Check if database is accessible
echo -e "${CYAN}🗄️  Testing database connection...${NC}"
php artisan db:monitor > /dev/null 2>&1 && echo -e "${GREEN}✅ Database connection OK${NC}" || echo -e "${YELLOW}⚠️  Database connection check skipped${NC}"

# Check Reverb configuration
echo -e "${CYAN}📡 Checking Reverb WebSocket configuration...${NC}"
php artisan monitor:reverb-health > /dev/null 2>&1 && echo -e "${GREEN}✅ Reverb configured${NC}" || echo -e "${YELLOW}⚠️  Reverb configuration check skipped${NC}"

echo ""
echo -e "${CYAN}🔧 Starting backend services...${NC}"

# Start Reverb WebSocket server
echo -e "${CYAN}📡 Starting Reverb WebSocket server (port 8080)...${NC}"
php artisan reverb:start --host=0.0.0.0 --port=8080 > /tmp/reverb.log 2>&1 &
REVERB_PID=$!
PIDS+=("$REVERB_PID")
sleep 2
if kill -0 $REVERB_PID 2>/dev/null; then
    echo -e "${GREEN}✅ Reverb server started (PID: $REVERB_PID)${NC}"
else
    echo -e "${YELLOW}⚠️  Reverb server may not have started properly${NC}"
fi

echo -e "${CYAN}🔧 Starting Laravel application server (port 8000)...${NC}"
php artisan serve --host=127.0.0.1 --port=8000 &
PIDS+=("$!")
sleep 1
echo -e "${GREEN}✅ Laravel app server started${NC}"

echo -e "${CYAN}🔧 Starting queue worker...${NC}"
php artisan queue:work --tries=1 --sleep=3 &
PIDS+=("$!")
sleep 1
echo -e "${GREEN}✅ Queue worker started${NC}"

echo -e "${CYAN}🔧 Starting Vite dev server (port 5173)...${NC}"
npm run dev &
PIDS+=("$!")
sleep 2
echo -e "${GREEN}✅ Vite dev server started${NC}"

popd >/dev/null

pushd "$FRONTEND_PATH" >/dev/null

echo -e "${CYAN}🔧 Starting Next.js frontend server (port 3000)...${NC}"
npm run dev &
PIDS+=("$!")
sleep 2
echo -e "${GREEN}✅ Next.js frontend started${NC}"
popd >/dev/null

echo -e "${GREEN}✅ All development servers started.${NC}"
echo ""
echo -e "${CYAN}========================================"
echo "🚀 Development Environment Ready!"
echo "========================================${NC}"
echo -e "${GREEN}Backend Services:${NC}"
echo -e "  📡 Reverb WebSocket:    ws://127.0.0.1:8080${NC}"
echo -e "  🎯 Laravel API:         http://127.0.0.1:8000${NC}"
echo -e "  ⚡ Vite Dev Server:     http://127.0.0.1:5173${NC}"
echo -e "  🔄 Queue Worker:        Running (background)${NC}"
echo ""
echo -e "${GREEN}Frontend Services:${NC}"
echo -e "  🖥️  Next.js App:         http://127.0.0.1:3000${NC}"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo -e "  ${GRAY}View logs:              tail -f /tmp/reverb.log${NC}"
echo -e "  ${GRAY}Database console:       php artisan tinker${NC}"
echo -e "  ${GRAY}Queue monitoring:       php artisan queue:monitor${NC}"
echo -e "  ${GRAY}Health check:           php artisan monitor:reverb-health${NC}"
echo -e "${GRAY}Press Ctrl+C to stop all servers.${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

wait "${PIDS[@]}"

echo ""
echo -e "${GREEN}========================================"
echo "✅ All projects built successfully and servers started!"
echo "========================================${NC}"
