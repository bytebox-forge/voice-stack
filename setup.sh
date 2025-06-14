#!/bin/bash

# Voice Stack Setup Script
# This script helps initialize the Matrix Synapse voice server stack

set -e

echo "=== Voice Stack Setup ==="

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "Please edit .env file with your configuration before proceeding!"
    echo "At minimum, update SERVER_NAME and TURN_SECRET"
    exit 1
fi

# Source environment variables
source .env

echo "Setting up directories..."
mkdir -p synapse/data
mkdir -p media_store
mkdir -p logs

# Generate secrets if they don't exist
if [ ! -f synapse/signing.key ]; then
    echo "Generating Synapse signing key..."
    docker run --rm -v $(pwd)/synapse:/data matrixdotorg/synapse:latest generate_signing_key.py -o /data/signing.key
fi

# Update configuration with environment variables
echo "Updating configuration files..."

# Update Synapse homeserver.yaml with environment variables
sed -i "s/voice\.local/${SERVER_NAME}/g" synapse/homeserver.yaml
sed -i "s/your_turn_secret_key_here/${TURN_SECRET}/g" synapse/homeserver.yaml

# Update Coturn configuration
sed -i "s/your_turn_secret_key_here/${TURN_SECRET}/g" coturn/turnserver.conf
sed -i "s/turn_user:turn_password/${TURN_USERNAME}:${TURN_PASSWORD}/g" coturn/turnserver.conf

# Update Element configuration
sed -i "s/voice\.local/${SERVER_NAME}/g" element/config.json

# Set proper permissions
chmod 644 synapse/homeserver.yaml
chmod 644 coturn/turnserver.conf
chmod 644 element/config.json

echo "=== Setup Complete ==="
echo "You can now run: docker-compose up -d"
echo ""
echo "Services will be available at:"
echo "- Matrix Synapse: http://localhost:8008"
echo "- Element Web: http://localhost:8080"
echo "- TURN server: localhost:3478 (UDP/TCP)"
echo ""
echo "Remember to:"
echo "1. Update your DNS to point ${SERVER_NAME} to this server"
echo "2. Set up SSL certificates for production use"
echo "3. Configure your firewall to allow the required ports"
