#!/bin/bash

echo "=== Voice Stack Connection Test ==="
echo "Date: $(date)"
echo ""

# Get the host IP
HOST_IP=$(hostname -I | awk '{print $1}')
echo "Host IP: $HOST_IP"
echo ""

echo "=== 1. Checking if ports are bound ==="
echo "Port 8008 (Synapse):"
ss -tlnp | grep ":8008" || echo "Port 8008 not bound"
echo ""

echo "Port 8080 (Element):"
ss -tlnp | grep ":8080" || echo "Port 8080 not bound"
echo ""

echo "Port 3478 (TURN):"
ss -tlnp | grep ":3478" || echo "Port 3478 not bound"
echo ""

echo "=== 2. Checking Docker containers ==="
if command -v docker &> /dev/null; then
    echo "Voice stack containers:"
    docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo "Container health status:"
    docker ps --filter "name=voice-stack" --format "{{.Names}}: {{.Status}}"
    echo ""
else
    echo "Docker command not available - check with 'sudo docker ps'"
    echo ""
fi

echo "=== 3. Testing local connectivity ==="
echo "Testing Synapse (localhost:8008):"
if command -v curl &> /dev/null; then
    curl -s -m 5 http://localhost:8008 > /dev/null && echo "✓ Synapse responding" || echo "✗ Synapse not responding"
else
    echo "curl not available - install with: sudo apt install curl"
fi

echo ""
echo "Testing Element (localhost:8080):"
if command -v curl &> /dev/null; then
    curl -s -m 5 http://localhost:8080 > /dev/null && echo "✓ Element responding" || echo "✗ Element not responding"
else
    echo "wget test:"
    wget -q --timeout=5 --tries=1 --spider http://localhost:8080 && echo "✓ Element responding" || echo "✗ Element not responding"
fi

echo ""
echo "=== 4. Testing external connectivity ==="
echo "Testing Synapse ($HOST_IP:8008):"
if command -v curl &> /dev/null; then
    curl -s -m 5 http://$HOST_IP:8008 > /dev/null && echo "✓ Synapse accessible externally" || echo "✗ Synapse not accessible externally"
fi

echo ""
echo "Testing Element ($HOST_IP:8080):"
if command -v curl &> /dev/null; then
    curl -s -m 5 http://$HOST_IP:8080 > /dev/null && echo "✓ Element accessible externally" || echo "✗ Element not accessible externally"
fi

echo ""
echo "=== 5. Firewall check ==="
if command -v ufw &> /dev/null; then
    echo "UFW Status:"
    sudo ufw status
    echo ""
    echo "If UFW is active and blocking, run:"
    echo "  sudo ufw allow 8008"
    echo "  sudo ufw allow 8080"
    echo "  sudo ufw allow 3478"
    echo "  sudo ufw allow 5349"
elif command -v iptables &> /dev/null; then
    echo "Checking iptables rules for blocked ports..."
    iptables -L INPUT -n | grep -E "(8008|8080|3478|5349)" || echo "No specific rules found for voice stack ports"
else
    echo "No firewall management tool detected"
fi

echo ""
echo "=== 6. Network interfaces ==="
echo "Available network interfaces:"
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1"

echo ""
echo "=== Test URLs ==="
echo "If services are running, try accessing:"
echo "  Synapse API: http://$HOST_IP:8008"
echo "  Element Web: http://$HOST_IP:8080"
echo ""
echo "=== Quick fixes ==="
echo "1. Check container logs: docker logs voice-stack-synapse"
echo "2. Restart containers: docker restart voice-stack-synapse voice-stack-element"
echo "3. Check Portainer stack status"
echo "4. Verify firewall allows ports 8008, 8080, 3478, 5349"
