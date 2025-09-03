# Connection Troubleshooting Guide

This guide helps resolve connection issues when accessing your Voice Stack services.

## Quick Diagnosis Commands

If you're experiencing connection issues, run these commands to quickly diagnose the problem:

```bash
# 1. Check all voice-stack containers and their status
docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. Test if Synapse is responding
curl -I http://localhost:8008
# Or test the API endpoint
curl http://localhost:8008/_matrix/client/versions

# 3. Check Synapse logs if there are issues
docker logs voice-stack-synapse | tail -50

# 4. Test Element Web access
curl -I http://localhost:8080

# 5. Test internal container communication
docker exec voice-stack-element wget -q --spider http://synapse:8008/_matrix/client/versions
echo $?  # Should return 0 if successful

# Quick fix: Restart just the Synapse container
docker restart voice-stack-synapse

# Or restart the entire stack
docker-compose restart
```

## Detailed Troubleshooting

### Step 1: Check Container Status

First, verify all containers are running:

**In Portainer:**
1. Go to **Containers** 
2. Look for these containers and their status:
   - `voice-stack-postgres` - Should be "running" and healthy
   - `voice-stack-redis` - Should be "running" and healthy  
   - `voice-stack-synapse` - Should be "running"
   - `voice-stack-coturn` - Should be "running"
   - `voice-stack-element` - Should be "running" and healthy

**Via Command Line:**
```bash
docker ps --filter "name=voice-stack"
```

### Step 2: Check Service Health

Look for containers that are:
- ❌ **Exited/Stopped** - Service crashed or failed to start
- ⚠️ **Restarting** - Service is crash-looping
- 🔄 **Starting** - Service is still initializing

## Common Causes & Solutions

### 🔧 Issue 1: Element Web Stuck in Configuration Loop

**Symptoms:**
- Element Web interface shows "Configuring Element Web..." message repeatedly
- Element container is running but the interface doesn't load

**Check Element Logs:**
```bash
# In Portainer: Containers → voice-stack-element → Logs
# Or via command line:
docker logs voice-stack-element
```

**Common Solutions:**

**A) Ensure You're Using the Latest Version:**
- The latest version (June 15, 2025) completely replaces the Element Web container with an nginx-based alternative

### 🔧 Issue 2: Invalid Configuration Error in Element Web

**Symptoms:**
- Error message: "Your Element is misconfigured: Invalid configuration: no default server specified"
- Element loads but shows an error preventing login

**Cause:**
This happens when the config.json file doesn't have the proper `default_server_config` section or environment variables weren't properly expanded.

**Solution:**

**A) Update to the Latest Version:**
The latest version (June 15, 2025) has improved environment variable handling that fixes this issue automatically. Make sure you're using the latest docker-compose.yml file.

**B) If Still Experiencing Issues, Check Configuration Manually:**
```bash
# Access the container
docker exec -it voice-stack-element /bin/sh

# Verify the config.json content
cat /usr/share/nginx/html/config/config.json

# If needed, restart the container
exit
docker restart voice-stack-element
```

**B) Check Element Web Configuration:**

In the latest version (June 15, 2025+), you shouldn't need to manually fix the configuration, but if you're experiencing issues:

- Make sure both `SERVER_NAME` and `SYNAPSE_URL` environment variables are correctly set
- Verify the environment variables are properly passed to the container

**C) Manual Verification:**

You can check if Element Web is installed correctly:
```bash
docker exec -it voice-stack-element ls -la /usr/share/nginx/html
```

And verify the configuration has the proper default_server_config section:
```bash
docker exec -it voice-stack-element cat /usr/share/nginx/html/config/config.json
```

### 🔧 Issue 2: Synapse Container Not Starting

**Symptoms:**
- Connection refused on port 8008
- Synapse container shows "Exited" status

**Check Synapse Logs:**
```bash
# In Portainer: Containers → voice-stack-synapse → Logs
# Or via command line:
docker logs voice-stack-synapse
```

**Common Solutions:**

**A) Database Connection Issues:**
```bash
# Check if PostgreSQL is ready
docker logs voice-stack-postgres

# Look for: "database system is ready to accept connections"
```

**B) Configuration Generation Failed:**
```bash
# Check for homeserver.yaml creation errors
docker logs voice-stack-synapse | grep -i error
docker logs voice-stack-synapse | grep -i "homeserver.yaml"
```

**C) Permission or Volume Issues:**
```bash
# Reset Synapse data volume (WARNING: This removes all data)
docker volume rm voice-stack_synapse_data
# Then restart the stack
```

### 🔧 Issue 3: Element Web Not Accessible

**Symptoms:**
- Connection refused on port 8080
- Element Web container shows "Exited" status

**Check Element Logs:**
```bash
docker logs voice-stack-element
```

**Common Solutions:**

**A) Port Conflicts:**
```bash
# Check if port 8080 is already in use
netstat -an | findstr :8080
# Or on Linux/Mac:
# netstat -an | grep :8080
```

**B) Nginx Configuration Issues:**
```bash
# Check Element Web container logs for nginx errors
docker logs voice-stack-element | grep nginx
```

### 🔧 Issue 4: Network Connectivity Issues

**Symptoms:**
- Services are running but can't communicate
- Internal connection errors between containers

**Check Docker Networks:**
```bash
# List Docker networks
docker network ls | findstr voice-stack

# Inspect the network
docker network inspect voice-stack_voice-stack-network
```

**Solutions:**

**A) Restart Docker Networks:**
```bash
# Stop the stack
docker-compose down

# Remove networks
docker network prune

# Start the stack
docker-compose up -d
```

### 🔧 Issue 5: Port Binding Issues

**Symptoms:**
- Error: "Port already in use" 
- Connection refused on specific ports

**Check Port Usage:**
```powershell
# Check what's using your ports
netstat -ano | findstr :8008
netstat -ano | findstr :8080
netstat -ano | findstr :3478
```

**Solutions:**

**A) Change Ports (if conflicts exist):**

Update your environment variables in Portainer:
```bash
SYNAPSE_PORT=8009     # Instead of 8008
ELEMENT_PORT=8081     # Instead of 8080
TURN_PORT=3479        # Instead of 3478
```

**B) Stop Conflicting Services:**
```bash
# Find the process using the port
tasklist /FI "PID eq XXXX"  # Use PID from netstat output
# Stop the conflicting service if safe to do so
```

## Service-Specific Troubleshooting

### PostgreSQL Issues

**Check Database Status:**
```bash
docker logs voice-stack-postgres | tail -20
```

**Look for:**
- ✅ "database system is ready to accept connections"
- ❌ "FATAL: password authentication failed"
- ❌ "FATAL: database does not exist"

**Fix Database Issues:**
```bash
# Reset database (WARNING: Removes all data)
docker volume rm voice-stack_postgres_data
# Restart stack to recreate database
```

### Redis Issues

**Check Redis Status:**
```bash
docker logs voice-stack-redis
```

**Test Redis Connection:**
```bash
docker exec -it voice-stack-redis redis-cli ping
# Should return: PONG
```

### Coturn Issues

**Check Coturn Logs:**
```bash
docker logs voice-stack-coturn
```

**Look for:**
- ✅ "TURN Server listening on"
- ❌ "Cannot bind to port"
- ❌ "Permission denied"

## Complete Reset Procedure

If all else fails, perform a complete reset:

### Step 1: Stop Everything
```bash
# In Portainer: Stack → voice-stack → Stop
# Or via command line:
docker-compose down
```

### Step 2: Clean Up (Optional - Removes Data)
```bash
# Remove all volumes (WARNING: This deletes all data)
docker volume prune -f

# Remove networks
docker network prune -f
```

### Step 3: Restart
```bash
# In Portainer: Stack → voice-stack → Start
# Or via command line:
docker-compose up -d
```

### Step 4: Wait and Monitor
```bash
# Watch containers start up
docker-compose logs -f
```

## Verification Steps

After fixing issues:

### 1. Check All Containers
```bash
docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2. Test Connectivity
```bash
# Test Synapse API
curl http://localhost:8008/_matrix/client/versions

# Test Element Web
curl http://localhost:8080

# Should get HTML responses, not connection refused
```

### 3. Check Logs
```bash
# Look for any remaining errors
docker-compose logs | grep -i error
```

## Environment Variables Check

Ensure these are set correctly in Portainer:

```bash
# Required
SERVER_NAME=your.domain.com
POSTGRES_PASSWORD=secure_password
REGISTRATION_SECRET=secure_secret
TURN_SECRET=secure_turn_secret

# Optional (if ports conflict)
SYNAPSE_PORT=8008
ELEMENT_PORT=8080
TURN_PORT=3478
```

## Getting Help

If the issue persists:

1. **Collect Information:**
   - Container status (`docker ps`)
   - Recent logs for failing services
   - Your environment variables
   - Error messages from Portainer

2. **Check Common Issues:**
   - Firewall blocking ports
   - Antivirus interfering with Docker
   - Insufficient system resources
   - Port conflicts with other applications

3. **Try Minimal Test:**
   - Stop the stack
   - Start only PostgreSQL and Redis first
   - Then add Synapse
   - Finally add Element Web and Coturn

This systematic approach helps identify exactly which component is causing the connection refused error.
