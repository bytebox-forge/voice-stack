#!/bin/bash

# Voice Stack Validation Script
# Tests docker-compose.yml syntax and validates configuration

set -e

echo "🧪 Voice Stack Validation"
echo "========================"

# Check if docker-compose file exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found"
    exit 1
fi

echo "✅ docker-compose.yml found"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found, using .env.example"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "📝 Created .env from .env.example - please customize it"
    else
        echo "❌ No .env.example found"
        exit 1
    fi
fi

echo "✅ Environment file ready"

# Test docker-compose syntax
echo "🔍 Validating Docker Compose syntax..."
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif [ -f "/tmp/docker-compose" ]; then
    COMPOSE_CMD="/tmp/docker-compose"
else
    echo "❌ Docker Compose not found"
    echo "💡 Install Docker Compose or run: curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /tmp/docker-compose && chmod +x /tmp/docker-compose"
    exit 1
fi

# Validate compose file
echo "🔧 Testing with: $COMPOSE_CMD"
if $COMPOSE_CMD config >/dev/null 2>&1; then
    echo "✅ Docker Compose syntax is valid"
else
    echo "❌ Docker Compose validation failed:"
    $COMPOSE_CMD config
    exit 1
fi

# Check required environment variables
echo "🔍 Checking required environment variables..."
source .env

REQUIRED_VARS=(
    "SYNAPSE_SERVER_NAME"
    "POSTGRES_PASSWORD"
    "REGISTRATION_SHARED_SECRET"
    "COTURN_STATIC_AUTH_SECRET"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ] || [[ "${!var}" == *"your_"* ]] || [[ "${!var}" == *"yourdomain"* ]]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "⚠️  Please customize these variables in .env:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo "💡 Generate secure secrets with: openssl rand -base64 32"
else
    echo "✅ All required variables are set"
fi

# Check Docker volumes (if Docker is available)
if command -v docker >/dev/null 2>&1; then
    echo "🔍 Checking Docker volumes..."
    REQUIRED_VOLUMES=(
        "voice-stack_postgres_data"
        "voice-stack_synapse_data"
        "voice-stack_media_store"
        "voice-stack_coturn_data"
    )

    MISSING_VOLUMES=()
    for volume in "${REQUIRED_VOLUMES[@]}"; do
        if ! docker volume ls | grep -q "$volume"; then
            MISSING_VOLUMES+=("$volume")
        fi
    done

    if [ ${#MISSING_VOLUMES[@]} -gt 0 ]; then
        echo "⚠️  Missing Docker volumes. Create with:"
        for volume in "${MISSING_VOLUMES[@]}"; do
            echo "   docker volume create $volume"
        done
    else
        echo "✅ All required volumes exist"
    fi
else
    echo "⚠️  Docker not accessible - skipping volume check"
fi

# Check port availability (basic check)
echo "🔍 Checking default port availability..."
DEFAULT_PORTS=(8008 8080 8082 8090 3478)
BUSY_PORTS=()

for port in "${DEFAULT_PORTS[@]}"; do
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            BUSY_PORTS+=("$port")
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            BUSY_PORTS+=("$port")
        fi
    fi
done

if [ ${#BUSY_PORTS[@]} -gt 0 ]; then
    echo "⚠️  These ports appear to be in use:"
    for port in "${BUSY_PORTS[@]}"; do
        echo "   - $port"
    done
    echo "💡 Consider changing port variables in .env"
else
    echo "✅ Default ports appear available"
fi

echo ""
echo "🎯 Validation Summary"
echo "===================="

if [ ${#MISSING_VARS[@]} -eq 0 ] && [ ${#MISSING_VOLUMES[@]} -eq 0 ]; then
    echo "✅ Ready for deployment!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Deploy via Portainer (see PORTAINER-DEPLOY.md)"
    echo "2. Or run locally: $COMPOSE_CMD up -d"
    echo "3. Create admin user (see README.md)"
else
    echo "⚠️  Please address the issues above before deployment"
fi

echo ""
echo "📚 Documentation:"
echo "- README.md - Complete setup guide"
echo "- PORTAINER-DEPLOY.md - Portainer deployment"
echo "- docs/ - Troubleshooting guides"