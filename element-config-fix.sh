#!/bin/sh
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
  # Check if the file is valid JSON (using grep since jq might not be available)
  if grep -q "default_server_config" /app/config/config.json; then
    echo "✅ config.json appears to be valid"
    
    # Extract and display important settings
    echo ""
    echo "Important settings (extract):"
    grep -A 3 "server_name" /app/config/config.json
    grep -A 2 "base_url" /app/config/config.json
  else
    echo "❌ config.json may not be valid!"
    echo "File content (first 20 lines):"
    head -n 20 /app/config/config.json
  fi
else
  echo "❌ config.json is missing!"
  echo "Creating a basic config.json file..."
  
  # Get SERVER_NAME and SYNAPSE_URL from environment
  SERVER_NAME=${SERVER_NAME:-matrix.byte-box.org}
  SYNAPSE_URL=${SYNAPSE_URL:-http://synapse:8008}
  
  # Create a basic config.json
  cat > /app/config/config.json << EOF
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "${SYNAPSE_URL}",
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
echo "SYNAPSE_URL=${SYNAPSE_URL:-not set}"
echo ""

echo "=== Nginx Process Check ==="
if ps | grep -v grep | grep -q nginx; then
  echo "✅ Nginx process is running"
  ps | grep nginx
else
  echo "❌ Nginx process not found!"
  echo "Attempting to start nginx..."
  nginx -g "daemon off;" &
  sleep 2
  if ps | grep -v grep | grep -q nginx; then
    echo "✅ Nginx started successfully"
  else
    echo "❌ Failed to start nginx"
  fi
fi

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
echo "=== Manual Fix Instructions ==="
echo "To manually fix Element Web configuration:"
echo ""
echo "1. Create a correct config.json file:"
echo "   cat > /app/config/config.json << EOF"
echo "   {"
echo "     \"default_server_config\": {"
echo "       \"m.homeserver\": {"
echo "         \"base_url\": \"http://synapse:8008\","
echo "         \"server_name\": \"${SERVER_NAME:-matrix.byte-box.org}\""
echo "       },"
echo "       \"m.identity_server\": {"
echo "         \"base_url\": \"https://vector.im\""
echo "       }"
echo "     },"
echo "     \"disable_custom_urls\": false,"
echo "     \"disable_guests\": true,"
echo "     \"brand\": \"Element\""
echo "   }"
echo "   EOF"
echo ""
echo "2. Set proper permissions:"
echo "   chmod 644 /app/config/config.json"
echo ""
echo "3. Start nginx directly:"
echo "   nginx -g \"daemon off;\""
echo ""
echo "=== Diagnostics Complete ==="
