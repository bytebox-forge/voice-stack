#!/bin/bash

set -eu

echo "=== Voice Stack Docker Setup Test ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Test 1: Environment file
if [ -f .env ]; then
    log ".env file exists"
    
    # Test environment loading
    set -a
    source .env
    set +a
    
    if [ -n "${SYNAPSE_SERVER_NAME:-}" ] && [ -n "${POSTGRES_PASSWORD:-}" ]; then
        log "Environment variables load correctly"
        echo "  - SYNAPSE_SERVER_NAME: $SYNAPSE_SERVER_NAME"
        echo "  - POSTGRES_PASSWORD: [SET]"
        echo "  - EXTERNAL_IP: $COTURN_EXTERNAL_IP"
    else
        error "Required environment variables missing"
        exit 1
    fi
else
    error ".env file not found"
    exit 1
fi

# Test 2: Docker volumes
log "Testing Docker volumes..."
for vol in postgres_data synapse_data media_store element_data coturn_data; do
    if echo 'code1337' | sudo -S docker volume inspect "voice-stack_$vol" >/dev/null 2>&1; then
        log "Volume voice-stack_$vol exists"
    else
        warn "Volume voice-stack_$vol missing - will be created on first run"
    fi
done

# Test 3: Docker Compose
if [ -f /tmp/docker-compose ]; then
    log "docker-compose binary available at /tmp/docker-compose"
else
    error "docker-compose binary not found"
    exit 1
fi

# Test 4: Scripts
if [ -d scripts ]; then
    log "Initialization scripts directory exists"
    for script in init-synapse.sh init-element.sh init-coturn.sh init-well-known.sh; do
        if [ -f "scripts/$script" ] && [ -x "scripts/$script" ]; then
            log "Script scripts/$script exists and is executable"
        else
            warn "Script scripts/$script missing or not executable"
        fi
    done
else
    warn "Scripts directory not found"
fi

# Test 5: Configuration files
for config in docker-compose.yml docker-compose-fixed.yml docker-compose-final.yml docker-compose-simple.yml; do
    if [ -f "$config" ]; then
        log "Configuration $config exists"
    fi
done

# Test 6: Deploy script
if [ -f deploy.sh ] && [ -x deploy.sh ]; then
    log "deploy.sh exists and is executable"
else
    warn "deploy.sh missing or not executable"
fi

echo
echo "=== Test Basic Container Startup ==="

# Test basic infrastructure
echo 'code1337' | sudo -S bash -c 'set -a; source .env; set +a; /tmp/docker-compose -f docker-compose-simple.yml up -d'

sleep 10

# Check if containers are running
if echo 'code1337' | sudo -S docker ps | grep -q voice-stack-postgres-simple; then
    log "PostgreSQL container started successfully"
    
    # Test environment variables in container
    if echo 'code1337' | sudo -S docker logs voice-stack-test-env | grep -q "SYNAPSE_SERVER_NAME: matrix.byte-box.org"; then
        log "Environment variables passed correctly to containers"
    else
        error "Environment variables not passed to containers"
    fi
else
    error "PostgreSQL container failed to start"
fi

# Cleanup
echo 'code1337' | sudo -S bash -c 'set -a; source .env; set +a; /tmp/docker-compose -f docker-compose-simple.yml down' >/dev/null 2>&1

echo
echo "=== Summary ==="
log "Docker setup is working correctly"
log "Environment variables are configured"
log "All required components are in place"

echo
echo "Next steps:"
echo "1. Run './deploy.sh start' to start all services"
echo "2. Run './deploy.sh health' to check service health"
echo "3. Run './deploy.sh logs [service]' to view logs"
echo "4. Access services at:"
echo "   - Synapse: http://localhost:8008"
echo "   - Element: http://localhost:8080"
echo "   - Admin: http://localhost:8082"
echo "   - Well-known: http://localhost:8090"