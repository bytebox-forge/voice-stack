# Connection Refused Troubleshooting Guide

This guide helps resolve "connection refused" errors when accessing your Voice Stack services.

## Quick Diagnosis

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

### 🔧 Issue 1: Synapse Container Not Starting

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

### 🔧 Issue 2: Element Web Not Accessible

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

### 🔧 Issue 3: Network Connectivity Issues

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
docker-compose -f docker-compose.portainer-standalone.yml down

# Remove networks
docker network prune

# Start the stack
docker-compose -f docker-compose.portainer-standalone.yml up -d
```

### 🔧 Issue 4: Port Binding Issues

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
docker-compose -f docker-compose.portainer-standalone.yml down
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
docker-compose -f docker-compose.portainer-standalone.yml up -d
```

### Step 4: Wait and Monitor
```bash
# Watch containers start up
docker-compose -f docker-compose.portainer-standalone.yml logs -f
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
docker-compose -f docker-compose.portainer-standalone.yml logs | grep -i error
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
