# Port 8080 Already in Use - Troubleshooting Guide

## Problem
You're getting an error like:
```
Error response from daemon: driver failed programming external connectivity on endpoint voice-stack-element: Error starting userland proxy: listen tcp4 0.0.0.0:8080: bind: address already in use
```

This happens when:
1. Another service is already using port 8080
2. The environment variable for custom ports isn't being applied correctly
3. Portainer isn't reading the environment variables properly

## Solutions

### Option 1: Use Different Ports
Set custom ports in Portainer's environment variables:

**In Portainer Stack Environment Variables:**
```
ELEMENT_PORT=8082
SYNAPSE_PORT=8009
TURN_PORT=3479
TURNS_PORT=5350
```

### Option 2: Find What's Using Port 8080
Check what's already using the port:

**Windows PowerShell:**
```powershell
netstat -ano | findstr :8080
```

**Linux/Mac:**
```bash
sudo lsof -i :8080
# or
sudo netstat -tlnp | grep :8080
```

Stop the conflicting service or choose different ports.

### Option 3: Force Environment Variable Application
If Portainer isn't applying environment variables correctly:

1. **Delete the existing stack completely**
2. **Wait 30 seconds** for cleanup
3. **Redeploy with fresh environment variables**

### Option 4: Common Port Conflicts
These ports are often used by other services:
- **8080**: Many web servers, Jenkins, Tomcat
- **8008**: Alternative web servers
- **3478**: Some TURN/STUN servers
- **5349**: WebRTC applications

**Recommended Alternative Ports:**
```
ELEMENT_PORT=8082
SYNAPSE_PORT=8009
TURN_PORT=3479
TURNS_PORT=5350
```

### Option 5: Verify Environment Variables in Portainer
1. Go to **Stacks** → **voice-stack**
2. Click **Editor**
3. Scroll down to **Environment Variables**
4. Verify your variables are listed:
   ```
   ELEMENT_PORT=8082
   SYNAPSE_PORT=8009
   SERVER_NAME=your-domain.com
   ```
5. Click **Update the stack**

### Option 6: Check Docker Networks
Sometimes old containers hold ports. Clean up:
```powershell
docker container prune
docker network prune
```

## Testing the Fix
After redeploying with custom ports:

1. **Check if containers are running:**
   ```powershell
   docker ps | findstr voice-stack
   ```

2. **Access Element Web:**
   ```
   http://localhost:8082
   ```
   (Replace 8082 with your ELEMENT_PORT)

3. **Check Synapse:**
   ```
   http://localhost:8009
   ```
   (Replace 8009 with your SYNAPSE_PORT)

## Prevention
- Always check what ports are in use before deployment
- Use non-standard ports (above 8000) to avoid common conflicts
- Document your port assignments for future reference

## Still Having Issues?
If the problem persists:
1. Check the Portainer logs for the stack
2. Verify no typos in environment variable names
3. Ensure the compose file formatting is correct
4. Try deploying on a completely clean Docker environment
