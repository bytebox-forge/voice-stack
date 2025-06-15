#!/bin/bash
# Element Web Configuration Diagnostics Script
# Use this script to troubleshoot Element Web configuration issues
# Run this from inside the container: docker exec -it voice-stack-element /bin/sh

echo "=== Element Web Configuration Diagnostics ==="
echo ""

# Check if config directory exists
echo "Checking config directory..."
if [ -d "/app/config" ]; then
  echo "✅ Config directory exists: /app/config"
  ls -la /app/config
else
  echo "❌ Config directory missing: /app/config"
  echo "Creating directory..."
  mkdir -p /app/config
  chmod 755 /app/config
fi

echo ""

# Check if config.json exists
echo "Checking config.json..."
if [ -f "/app/config/config.json" ]; then
  echo "✅ config.json exists"
  echo "File permissions:"
  ls -la /app/config/config.json
  
  echo ""
  echo "Content validation:"
  # Check if the file is valid JSON
  if jq . /app/config/config.json > /dev/null 2>&1; then
    echo "✅ config.json is valid JSON"
    
    # Extract and display important settings
    echo ""
    echo "Important settings:"
    echo "- Server name: $(jq -r '.default_server_config.\"m.homeserver\".server_name' /app/config/config.json)"
    echo "- Homeserver URL: $(jq -r '.default_server_config.\"m.homeserver\".base_url' /app/config/config.json)"
    echo "- Identity server: $(jq -r '.default_server_config.\"m.identity_server\".base_url' /app/config/config.json)"
    echo "- Guest access: $(if [ "$(jq -r '.disable_guests' /app/config/config.json)" = "true" ]; then echo "Disabled"; else echo "Enabled"; fi)"
  else
    echo "❌ config.json is not valid JSON!"
    echo "File content (first 20 lines):"
    head -n 20 /app/config/config.json
  fi
else
  echo "❌ config.json is missing!"
  echo "Creating a basic config.json file..."
  
  # Get SERVER_NAME from environment, default to matrix.byte-box.org
  SERVER_NAME=${SERVER_NAME:-matrix.byte-box.org}
  
  # Create a basic config.json
  cat > /app/config/config.json << EOF
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "http://synapse:8008",
      "server_name": "${SERVER_NAME}"
    },
    "m.identity_server": {
      "base_url": "https://vector.im"
    }
  },
  "disable_custom_urls": false,
  "disable_guests": true,
  "brand": "Element"
}
EOF
  chmod 644 /app/config/config.json
  echo "✅ Created basic config.json with server_name: ${SERVER_NAME}"
fi

echo ""
echo "=== Environment Variables ==="
echo "SERVER_NAME=${SERVER_NAME:-not set}"
echo ""

echo "=== Connectivity Test ==="
echo "Testing connection to Synapse..."
if wget --spider -q -T 5 http://synapse:8008/_matrix/static/ 2>/dev/null; then
  echo "✅ Can connect to Synapse server"
else
  echo "❌ Cannot connect to Synapse server!"
  echo "Checking network resolution..."
  getent hosts synapse || echo "Cannot resolve 'synapse' hostname"
fi

echo ""
echo "=== Diagnostics Complete ==="
echo "If you're still having issues, try manually restarting the Element Web container:"
echo "docker restart voice-stack-element"
echo ""
echo "Or recreate the configuration with:"
echo "rm -rf /app/config/config.json && restart the container"
