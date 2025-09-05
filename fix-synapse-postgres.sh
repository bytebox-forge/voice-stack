#!/bin/bash

# Fix Synapse PostgreSQL Connection Script
# This script updates the homeserver.yaml configuration in the Synapse Docker volume
# to use the correct PostgreSQL connection parameters

set -euo pipefail

echo "=== Synapse PostgreSQL Configuration Fix ==="
echo "This script will:"
echo "1. Stop the current Synapse container"
echo "2. Update homeserver.yaml with correct PostgreSQL configuration"
echo "3. Test the PostgreSQL connection"
echo "4. Restart Synapse with the new configuration"
echo

# Load environment variables
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    source .env
else
    echo "ERROR: .env file not found!"
    exit 1
fi

# Verify required environment variables
required_vars=(
    "POSTGRES_USER"
    "POSTGRES_PASSWORD" 
    "POSTGRES_DB"
    "SYNAPSE_SERVER_NAME"
    "REGISTRATION_SHARED_SECRET"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "ERROR: Required environment variable $var is not set!"
        exit 1
    fi
done

echo "Environment variables verified ✓"

# Function to stop Synapse container
stop_synapse() {
    echo "Stopping Synapse container..."
    if docker ps -q --filter "name=voice-stack-synapse" | grep -q .; then
        docker stop voice-stack-synapse || true
        echo "Synapse container stopped ✓"
    else
        echo "Synapse container is not running"
    fi
}

# Function to test PostgreSQL connection
test_postgres_connection() {
    echo "Testing PostgreSQL connection..."
    
    # Test connection using docker exec
    if docker exec voice-stack-postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
        echo "PostgreSQL is ready ✓"
    else
        echo "ERROR: PostgreSQL is not ready!"
        return 1
    fi
    
    # Test authentication
    if docker exec voice-stack-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT version();" > /dev/null; then
        echo "PostgreSQL authentication successful ✓"
    else
        echo "ERROR: PostgreSQL authentication failed!"
        return 1
    fi
}

# Function to create proper homeserver.yaml
create_homeserver_config() {
    local config_path="/tmp/homeserver.yaml"
    
    echo "Creating homeserver.yaml with PostgreSQL configuration..."
    
    cat > "$config_path" << EOF
# vim:ft=yaml

## Server ##
server_name: "${SYNAPSE_SERVER_NAME}"
pid_file: /homeserver.pid
web_client: false
soft_file_limit: 0

## Database ##
database:
  name: psycopg2
  args:
    user: "${POSTGRES_USER}"
    password: "${POSTGRES_PASSWORD}"
    database: "${POSTGRES_DB}"
    host: postgres
    port: 5432
    cp_min: 5
    cp_max: 10

## Listeners ##
listeners:
  - port: 8008
    tls: false
    bind_addresses: ['::']
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation]
        compress: false

## Logging ##
log_config: "/data/log.config"

## Media ##
media_store_path: "/data/media_store"
max_upload_size: "50M"
max_image_pixels: "32M"
dynamic_thumbnails: false

## Registration ##
enable_registration: false
registration_shared_secret: "${REGISTRATION_SHARED_SECRET}"
bcrypt_rounds: 12
allow_guest_access: false
enable_group_creation: true

## Security ##
macaroon_secret_key: "$(openssl rand -hex 32)"
form_secret: "$(openssl rand -hex 32)"

## Signing Keys ##
signing_key_path: "/data/${SYNAPSE_SERVER_NAME}.signing.key"

## Trusted Key Servers ##
trusted_key_servers:
  - server_name: matrix.org
    verify_keys:
      "ed25519:auto": "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw"

## Performance ##
event_cache_size: "10K"

## Rate Limiting ##
rc_messages_per_second: 0.2
rc_message_burst_count: 10.0

## Stats ##
report_stats: false
enable_metrics: false

## URL Preview ##
url_preview_enabled: false

## TURN Server Configuration ##
turn_uris: []
turn_shared_secret: ""
turn_user_lifetime: "1h"
turn_allow_guests: true

## Additional Settings ##
expire_access_token: false
password_config:
  enabled: true
EOF

    echo "homeserver.yaml configuration created ✓"
    return 0
}

# Function to copy config to Synapse volume
update_synapse_config() {
    local config_path="/tmp/homeserver.yaml"
    
    echo "Updating Synapse configuration in Docker volume..."
    
    # Copy the configuration file to the Synapse data volume
    docker cp "$config_path" voice-stack-synapse:/data/homeserver.yaml
    
    # Also ensure log config exists
    docker exec voice-stack-synapse sh -c 'if [ ! -f /data/log.config ]; then echo "
version: 1
formatters:
  precise:
    format: '\''%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s'\''
handlers:
  console:
    class: logging.StreamHandler
    formatter: precise
    stream: ext://sys.stdout
loggers:
    synapse:
        level: INFO
    synapse.storage:
        level: INFO
root:
    level: INFO
    handlers: [console]
" > /data/log.config; fi'
    
    echo "Synapse configuration updated ✓"
    
    # Clean up temp file
    rm -f "$config_path"
}

# Function to start Synapse
start_synapse() {
    echo "Starting Synapse container..."
    
    # Start using docker-compose to ensure proper dependency handling
    docker-compose up -d synapse
    
    echo "Synapse container started ✓"
}

# Function to wait for Synapse to be ready
wait_for_synapse() {
    echo "Waiting for Synapse to be ready..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec voice-stack-synapse python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8008/health', timeout=5).getcode()==200 else 1)" 2>/dev/null; then
            echo "Synapse is ready ✓"
            return 0
        fi
        
        echo "Attempt $((attempt + 1))/$max_attempts: Synapse not ready yet, waiting..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Synapse failed to become ready after $max_attempts attempts"
    return 1
}

# Function to show Synapse logs
show_synapse_logs() {
    echo "=== Recent Synapse Logs ==="
    docker logs voice-stack-synapse --tail=50
}

# Main execution
main() {
    echo "Starting Synapse PostgreSQL fix process..."
    
    # Step 1: Test PostgreSQL first
    if ! test_postgres_connection; then
        echo "ERROR: PostgreSQL connection test failed. Please ensure PostgreSQL is running and accessible."
        exit 1
    fi
    
    # Step 2: Stop Synapse
    stop_synapse
    
    # Step 3: Create new configuration
    create_homeserver_config
    
    # Step 4: Update Synapse configuration  
    update_synapse_config
    
    # Step 5: Start Synapse
    start_synapse
    
    # Step 6: Wait for Synapse to be ready
    if wait_for_synapse; then
        echo
        echo "=== SUCCESS ==="
        echo "Synapse has been successfully configured to use PostgreSQL!"
        echo "Database connection parameters:"
        echo "  Host: postgres"
        echo "  Database: $POSTGRES_DB"
        echo "  User: $POSTGRES_USER"
        echo "  Port: 5432"
        echo
        echo "You can now access Synapse at: http://localhost:8008"
    else
        echo
        echo "=== FAILURE ==="
        echo "Synapse failed to start properly. Showing logs for debugging:"
        show_synapse_logs
        exit 1
    fi
}

# Run main function
main "$@"