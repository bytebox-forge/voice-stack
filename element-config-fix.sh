#!/bin/sh
# Element Web Configuration Diagnostics Script
# Use this script to troubleshoot Element Web configuration issues
# Run this from inside the container: docker exec -it voice-stack-element /bin/sh

echo "=== Element Web Configuration Diagnostics ==="
echo ""

# Check if Element Web files exist
echo "Checking Element Web installation..."
if [ -f "/usr/share/nginx/html/index.html" ]; then
  echo "✅ Element Web files exist"
  ls -la /usr/share/nginx/html | head -n 10
else
  echo "❌ Element Web files missing!"
  echo "Attempting to download Element Web..."
  
  if ! command -v wget >/dev/null 2>&1; then
    echo "Installing wget..."
    apk add --no-cache wget tar
  fi
  
  cd /tmp
  wget -qO element.tar.gz https://github.com/vector-im/element-web/releases/download/v1.11.50/element-v1.11.50.tar.gz
  mkdir -p /usr/share/nginx/html
  tar -xzf element.tar.gz -C /usr/share/nginx/html --strip-components=1
  echo "✅ Element Web downloaded and installed"
fi

echo ""

# Check if config directory exists
echo "Checking config directory..."
if [ -d "/usr/share/nginx/html/config" ]; then
  echo "✅ Config directory exists"
  ls -la /usr/share/nginx/html/config
else
  echo "❌ Config directory missing!"
  echo "Creating directory..."
  mkdir -p /usr/share/nginx/html/config
fi

echo ""

# Check if config.json exists
echo "Checking config.json..."
if [ -f "/usr/share/nginx/html/config/config.json" ]; then
  echo "✅ config.json exists"
  echo "File content:"
  cat /usr/share/nginx/html/config/config.json
else
  echo "❌ config.json is missing!"
  echo "Creating a basic config.json file..."
  
  # Get SERVER_NAME and SYNAPSE_URL from environment
  SERVER_NAME=${SERVER_NAME:-matrix.byte-box.org}
  SYNAPSE_URL=${SYNAPSE_URL:-http://synapse:8008}
  
  # Create a basic config.json
  cat > /usr/share/nginx/html/config/config.json << EOF
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
echo "1. Make sure Element Web is installed:"
echo "   apk add --no-cache wget tar"
echo "   cd /tmp"
echo "   wget -qO element.tar.gz https://github.com/vector-im/element-web/releases/download/v1.11.50/element-v1.11.50.tar.gz"
echo "   mkdir -p /usr/share/nginx/html"
echo "   tar -xzf element.tar.gz -C /usr/share/nginx/html --strip-components=1"
echo ""
echo "2. Create config directory:"
echo "   mkdir -p /usr/share/nginx/html/config"
echo ""
echo "3. Create a correct config.json file:"
echo "   cat > /usr/share/nginx/html/config/config.json << EOF"
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
echo "4. Start nginx:"
echo "   nginx -g \"daemon off;\""
echo ""
echo "=== Diagnostics Complete ==="
