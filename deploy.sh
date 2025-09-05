#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    error ".env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1 && [ ! -f /tmp/docker-compose ]; then
    error "docker-compose not found. Please install docker-compose or ensure /tmp/docker-compose exists."
    exit 1
fi

# Use either system docker-compose or our downloaded version
DOCKER_COMPOSE_CMD="docker-compose"
if [ -f /tmp/docker-compose ]; then
    DOCKER_COMPOSE_CMD="/tmp/docker-compose"
fi

# Function to run docker-compose with environment
run_compose() {
    set -a
    source .env
    set +a
    
    echo 'code1337' | sudo -E -S "$DOCKER_COMPOSE_CMD" "$@"
}

case "${1:-start}" in
    start)
        log "Starting Voice Stack services..."
        run_compose up -d
        ;;
    stop)
        log "Stopping Voice Stack services..."
        run_compose down
        ;;
    restart)
        log "Restarting Voice Stack services..."
        run_compose down
        sleep 2
        run_compose up -d
        ;;
    logs)
        log "Showing logs for all services..."
        run_compose logs -f "${2:-}"
        ;;
    status)
        log "Checking service status..."
        run_compose ps
        ;;
    clean)
        warn "This will remove all containers and networks (but keep volumes)"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_compose down --remove-orphans
            log "Cleaned up containers and networks"
        fi
        ;;
    destroy)
        error "This will remove EVERYTHING including data volumes!"
        read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
        if [[ $REPLY = "yes" ]]; then
            run_compose down -v --remove-orphans
            log "Destroyed all containers, networks, and volumes"
        else
            log "Cancelled destruction"
        fi
        ;;
    health)
        log "Checking health status..."
        echo 'code1337' | sudo -S docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs [service]|status|health|clean|destroy}"
        echo ""
        echo "Commands:"
        echo "  start    - Start all services"
        echo "  stop     - Stop all services"
        echo "  restart  - Restart all services"
        echo "  logs     - Show logs (optionally for specific service)"
        echo "  status   - Show service status"
        echo "  health   - Show health status"
        echo "  clean    - Remove containers and networks (keep volumes)"
        echo "  destroy  - Remove everything including volumes"
        exit 1
        ;;
esac