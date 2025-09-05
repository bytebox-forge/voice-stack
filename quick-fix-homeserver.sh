#!/bin/bash

# Quick Fix for Synapse homeserver.yaml PostgreSQL Configuration
# This script directly replaces the homeserver.yaml with correct PostgreSQL settings

set -euo pipefail

echo "=== Quick Synapse PostgreSQL Configuration Fix ==="

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "ERROR: .env file not found!"
    exit 1
fi

# Create a temporary homeserver.yaml with the correct PostgreSQL configuration
cat > /tmp/homeserver_postgres.yaml << EOF
# Synapse homeserver configuration
server_name: "${SYNAPSE_SERVER_NAME}"
pid_file: /homeserver.pid
web_client: false

# Database configuration - PostgreSQL
database:
  name: psycopg2
  args:
    user: ${POSTGRES_USER}
    password: "${POSTGRES_PASSWORD}"
    database: ${POSTGRES_DB}
    host: postgres
    port: 5432
    cp_min: 5
    cp_max: 10

# HTTP listeners
listeners:
  - port: 8008
    tls: false
    bind_addresses: ['::']
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation]
        compress: false

# Logging
log_config: "/data/log.config"

# Media store
media_store_path: "/data/media_store"
max_upload_size: "50M"

# Registration
enable_registration: false
registration_shared_secret: "${REGISTRATION_SHARED_SECRET}"
allow_guest_access: false

# Security
macaroon_secret_key: "$(openssl rand -hex 32)"
form_secret: "$(openssl rand -hex 32)"

# Signing key
signing_key_path: "/data/${SYNAPSE_SERVER_NAME}.signing.key"

# Trusted key servers
trusted_key_servers:
  - server_name: matrix.org

# Stats
report_stats: false

# Performance
event_cache_size: "10K"
EOF

echo "1. Stopping Synapse container..."
docker-compose stop synapse

echo "2. Updating homeserver.yaml in Synapse container..."
docker cp /tmp/homeserver_postgres.yaml voice-stack-synapse:/data/homeserver.yaml

echo "3. Creating log configuration if it doesn't exist..."
docker exec voice-stack-synapse sh -c '
if [ ! -f /data/log.config ]; then
    cat > /data/log.config << "LOG_EOF"
version: 1
formatters:
  precise:
    format: "%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(message)s"
handlers:
  console:
    class: logging.StreamHandler
    formatter: precise
    stream: ext://sys.stdout
loggers:
    synapse:
        level: INFO
root:
    level: INFO
    handlers: [console]
LOG_EOF
fi'

echo "4. Starting Synapse with new configuration..."
docker-compose up -d synapse

echo "5. Waiting for Synapse to start..."
sleep 10

echo "6. Checking Synapse status..."
if docker exec voice-stack-synapse python -c "
import urllib.request
import sys
try:
    response = urllib.request.urlopen('http://localhost:8008/health', timeout=10)
    if response.getcode() == 200:
        print('Synapse is healthy!')
        sys.exit(0)
    else:
        print(f'Synapse returned status: {response.getcode()}')
        sys.exit(1)
except Exception as e:
    print(f'Health check failed: {e}')
    sys.exit(1)
" 2>/dev/null; then
    echo "SUCCESS: Synapse is running with PostgreSQL!"
else
    echo "WARNING: Health check failed. Showing recent logs..."
    docker logs voice-stack-synapse --tail=20
fi

# Clean up
rm -f /tmp/homeserver_postgres.yaml

echo
echo "=== Configuration Summary ==="
echo "Database: PostgreSQL"
echo "Host: postgres"
echo "Database: ${POSTGRES_DB}"
echo "User: ${POSTGRES_USER}"
echo "Port: 5432"
echo
echo "If Synapse is still having issues, check the logs with:"
echo "  docker logs voice-stack-synapse"