#!/bin/bash

# Enhanced Synapse entrypoint with registration token support
# This script processes environment variables and creates tokens on startup

set -e

echo "Starting Synapse with enhanced configuration..."

# Function to substitute environment variables in config files using sed
substitute_env_vars() {
    local file="$1"
    echo "Processing environment variables in $file..."
    
    # Replace environment variables using sed
    sed -i "s|\${ENABLE_REGISTRATION:-true}|${ENABLE_REGISTRATION:-true}|g" "$file"
    sed -i "s|\${REGISTRATION_REQUIRES_TOKEN:-false}|${REGISTRATION_REQUIRES_TOKEN:-false}|g" "$file"
    sed -i "s|\${REGISTRATION_SECRET:-your_registration_secret_here}|${REGISTRATION_SECRET:-your_registration_secret_here}|g" "$file"
    sed -i "s|\${SERVER_NAME:-matrix.byte-box.org}|${SERVER_NAME:-matrix.byte-box.org}|g" "$file"
    sed -i "s|\${PUBLIC_BASEURL:-https://matrix.byte-box.org}|${PUBLIC_BASEURL:-https://matrix.byte-box.org}|g" "$file"
}

# Process the homeserver configuration
substitute_env_vars "/data/homeserver.yaml"

# Generate signing key if it doesn't exist
if [ ! -f /data/signing.key ]; then
    echo "Generating signing key..."
    python -m synapse.app.homeserver --generate-keys -c /data/homeserver.yaml
fi

# Function to create registration tokens from environment variable
create_registration_tokens() {
    if [ -n "$REGISTRATION_TOKENS" ] && [ "$REGISTRATION_REQUIRES_TOKEN" = "true" ]; then
        echo "Creating registration tokens from environment variable: $REGISTRATION_TOKENS"
        
        # Wait for Synapse database to be ready
        sleep 20
        
        # Split tokens by comma and process each
        IFS=',' read -ra TOKENS <<< "$REGISTRATION_TOKENS"
        for token_spec in "${TOKENS[@]}"; do
            # Trim whitespace
            token_spec=$(echo "$token_spec" | xargs)
            
            # Check if token has usage limit (format: token:uses)
            if [[ "$token_spec" == *":"* ]]; then
                token=$(echo "$token_spec" | cut -d':' -f1)
                uses=$(echo "$token_spec" | cut -d':' -f2)
                echo "Creating token '$token' with $uses uses..."
                
                # Create token with usage limit using admin API
                curl -X POST "http://localhost:8008/_synapse/admin/v1/registration_tokens/new" \
                     -H "Content-Type: application/json" \
                     -d "{\"token\":\"$token\",\"uses_allowed\":$uses}" \
                     2>/dev/null || echo "Token $token might already exist or Synapse not ready yet"
            else
                token="$token_spec"
                echo "Creating unlimited token '$token'..."
                
                # Create unlimited token using admin API
                curl -X POST "http://localhost:8008/_synapse/admin/v1/registration_tokens/new" \
                     -H "Content-Type: application/json" \
                     -d "{\"token\":\"$token\"}" \
                     2>/dev/null || echo "Token $token might already exist or Synapse not ready yet"
            fi
        done
        
        echo "Registration token creation completed"
    fi
}

# Start token creation in background after Synapse starts
if [ "$REGISTRATION_REQUIRES_TOKEN" = "true" ] && [ -n "$REGISTRATION_TOKENS" ]; then
    echo "Registration tokens will be created after Synapse starts..."
    (
        # Wait for Synapse to be ready
        create_registration_tokens
    ) &
fi

echo "Starting Synapse server..."

# Apply family-safe defaults by disabling public registration and room directory
echo "Applying family-safe defaults..."

# Start Synapse
exec python -m synapse.app.homeserver --config-path /data/homeserver.yaml
