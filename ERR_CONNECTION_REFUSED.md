# ERR_CONNECTION_REFUSED Fix Guide

Since Synapse is starting successfully but you're getting ERR_CONNECTION_REFUSED, this is likely a port accessibility issue.

## Quick Diagnosis Commands

Run these commands to identify the issue:

### 1. Check Container Port Mappings
```bash
docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected Output Should Show:**
```
voice-stack-element    Up    0.0.0.0:8080->80/tcp
voice-stack-synapse    Up    0.0.0.0:8008->8008/tcp
```

### 2. Check If Ports Are Actually Listening
```powershell
# Check if ports are listening (Windows)
netstat -an | findstr :8080
netstat -an | findstr :8008

# Should show:
# TCP    0.0.0.0:8080    0.0.0.0:0    LISTENING
# TCP    0.0.0.0:8008    0.0.0.0:0    LISTENING
```

### 3. Test Local Access
```powershell
# Test Element Web locally
curl http://localhost:8080

# Test Synapse locally  
curl http://localhost:8008
```

## Common Causes & Solutions

### Issue 1: Ports Not Mapped Correctly

**Check Docker Port Mapping:**
```bash
# Check specific container ports
docker port voice-stack-element
docker port voice-stack-synapse
```

**Solution - Restart Stack:**
In Portainer:
1. Go to Stacks → voice-stack
2. Click "Stop"
3. Wait for all containers to stop
4. Click "Start"

### Issue 2: Port Conflicts

**Check for Port Conflicts:**
```powershell
# See what's using port 8080
netstat -ano | findstr :8080

# See what's using port 8008
netstat -ano | findstr :8008
```

**Solution - Change Ports:**
If ports are in use, update environment variables in Portainer:
```
SYNAPSE_PORT=8009
ELEMENT_PORT=8081
```

### Issue 3: Firewall Blocking Connections

**Windows Firewall:**
```powershell
# Add firewall rules for the ports
netsh advfirewall firewall add rule name="Voice Stack Element" dir=in action=allow protocol=TCP localport=8080
netsh advfirewall firewall add rule name="Voice Stack Synapse" dir=in action=allow protocol=TCP localport=8008
```

**Docker Desktop Issues:**
- Restart Docker Desktop
- Check Docker Desktop settings → Resources → Network

### Issue 4: Container Network Problems

**Check Docker Networks:**
```bash
# List networks
docker network ls | findstr voice-stack

# Check network details
docker network inspect voice-stack_voice-stack-network
```

**Solution - Recreate Network:**
```bash
# Stop stack first
docker-compose -f docker-compose.portainer-standalone.yml down

# Remove networks
docker network prune -f

# Start stack
docker-compose -f docker-compose.portainer-standalone.yml up -d
```

## Step-by-Step Troubleshooting

### Step 1: Verify Container Status
In Portainer → Containers, check that ALL containers show "running":
- voice-stack-postgres: Running, Healthy
- voice-stack-redis: Running, Healthy
- voice-stack-synapse: Running
- voice-stack-element: Running, Healthy
- voice-stack-coturn: Running

### Step 2: Check Container Logs
Click on each container and check the Logs tab for errors:

**Synapse Logs - Look for:**
- ✅ "Synapse now listening on TCP port 8008"
- ❌ "Port already in use"
- ❌ "Permission denied"

**Element Logs - Look for:**
- ✅ "start worker processes"
- ❌ "nginx: [emerg]"

### Step 3: Test Internal Connectivity
In Portainer → Containers → voice-stack-element → Console:
```bash
# Test if Element can reach Synapse
wget -q --spider http://synapse:8008
echo $?
# Should return 0 if successful
```

### Step 4: Test External Access Methods

**Method 1: Direct IP Access**
```
http://127.0.0.1:8080  (Element Web)
http://127.0.0.1:8008  (Synapse)
```

**Method 2: Docker Host IP**
```bash
# Get Docker host IP
docker network inspect bridge | findstr "Gateway"
# Use that IP: http://GATEWAY_IP:8080
```

**Method 3: Container IP Direct**
```bash
# Get container IP
docker inspect voice-stack-element | findstr "IPAddress"
# Test: http://CONTAINER_IP:80
```

## Emergency Fixes

### Fix 1: Complete Stack Reset
```bash
# Stop everything
docker-compose -f docker-compose.portainer-standalone.yml down

# Remove volumes (WARNING: Deletes data)
docker volume prune -f

# Remove networks
docker network prune -f

# Start fresh
docker-compose -f docker-compose.portainer-standalone.yml up -d
```

### Fix 2: Use Different Ports
Update your stack environment variables:
```
SYNAPSE_PORT=8009
ELEMENT_PORT=8081
TURN_PORT=3479
```

### Fix 3: Check Docker Desktop
- Open Docker Desktop
- Go to Settings → Resources → Advanced
- Ensure adequate CPU/Memory allocated
- Restart Docker Desktop

## Success Test

Once fixed, you should be able to:
```bash
# Test Element Web
curl -I http://localhost:8080
# Returns: HTTP/1.1 200 OK

# Test Synapse
curl http://localhost:8008/_matrix/client/versions
# Returns: JSON with version info
```

## What to Check Next

1. **Run the port mapping check** - This will tell us if Docker is properly exposing ports
2. **Check for port conflicts** - See if another service is using 8080/8008
3. **Test local access** - Try curl commands to see if services respond locally
4. **Check container logs** - Look for any binding or startup errors

**Please run the port mapping check first and share the results:**
```bash
docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
