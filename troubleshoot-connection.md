# Connection Troubleshooting Guide

## Quick Tests for Ubuntu/Linux Docker Host

### 1. Check Container Status
```bash
# Check if voice stack containers are running
docker ps --filter "name=voice-stack"

# Check container logs for errors
docker logs voice-stack-synapse
docker logs voice-stack-element
docker logs voice-stack-coturn
```

### 2. Check Port Bindings
```bash
# Check if ports are actually bound on the host
sudo ss -tlnp | grep -E "(8008|8080|3478|5349)"

# Or use netstat
sudo netstat -tlnp | grep -E "(8008|8080|3478|5349)"
```

### 3. Test Local Connectivity
```bash
# Test from the Docker host itself
curl -I http://localhost:8008  # Synapse
curl -I http://localhost:8080  # Element Web

# Test with wget if curl not available
wget --spider http://localhost:8008
wget --spider http://localhost:8080
```

### 4. Test External Connectivity
```bash
# Get your host IP
hostname -I

# Test from another machine or use the host IP
curl -I http://YOUR_HOST_IP:8008
curl -I http://YOUR_HOST_IP:8080
```

### 5. Ubuntu Firewall Check
```bash
# Check UFW status
sudo ufw status

# If UFW is blocking, allow the ports
sudo ufw allow 8008  # Synapse
sudo ufw allow 8080  # Element Web  
sudo ufw allow 3478  # TURN
sudo ufw allow 5349  # TURNS

# Check iptables (if not using UFW)
sudo iptables -L INPUT -n
```

### 6. Run Automated Test Script
```bash
# Download and run the test script
chmod +x test-connection.sh
./test-connection.sh
```

## 1. Check Container Status in Portainer

In Portainer, go to your stack and verify:
- [ ] All containers show as "running" (green)
- [ ] No containers are "restarting" or "exited"
- [ ] Check the "Published Ports" column for each container

Expected ports:
- **synapse**: `8008:8008/tcp`
- **element-web**: `8080:80/tcp` (or your custom ELEMENT_PORT)
- **coturn**: `3478:3478/tcp`, `3478:3478/udp`, `5349:5349/tcp`, `5349:5349/udp`

## 2. Test from Docker Host (Local Machine)

Open PowerShell/Command Prompt on the Docker host and test:

```powershell
# Test if ports are listening locally
netstat -an | findstr ":8008"
netstat -an | findstr ":8080"

# Test HTTP connectivity locally
curl http://localhost:8008
curl http://localhost:8080

# Or use PowerShell equivalent
Invoke-WebRequest -Uri "http://localhost:8008" -UseBasicParsing
Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing
```

## 3. Check Docker Port Bindings

```powershell
# If you have Docker CLI access
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

# Check specific containers
docker port voice-stack-synapse
docker port voice-stack-element
```

## 4. Test Network Connectivity

From another machine on your network:

```powershell
# Test if ports are reachable
Test-NetConnection -ComputerName 192.168.1.92 -Port 8008
Test-NetConnection -ComputerName 192.168.1.92 -Port 8080

# Test HTTP response
curl http://192.168.1.92:8008
curl http://192.168.1.92:8080
```

## 5. Check Windows Firewall

```powershell
# Check if ports are allowed through Windows Firewall
netsh advfirewall firewall show rule name="Docker Desktop" dir=in
netsh advfirewall firewall show rule name=all | findstr "8008\|8080"

# Add firewall rules if needed
netsh advfirewall firewall add rule name="Voice Stack Synapse" dir=in action=allow protocol=TCP localport=8008
netsh advfirewall firewall add rule name="Voice Stack Element" dir=in action=allow protocol=TCP localport=8080
```

## 6. Check Container Logs

In Portainer, click on each container and check the logs:

### Expected Synapse Logs:
```
Starting Synapse configuration...
Config file created successfully
Synapse starting...
Listening on port 8008
```

### Expected Element Logs:
```
Starting Element Web configuration...
Config file created successfully
Element Web starting...
Server will be available on port 80
```

## 7. Diagnose Common Issues

### Issue: Containers not starting
**Check**: Container logs for error messages
**Solution**: Look for configuration errors, missing environment variables

### Issue: Ports not published
**Check**: Portainer container details -> Published Ports section
**Solution**: Redeploy stack, check YAML syntax

### Issue: Connection refused from external IP
**Check**: Windows Firewall settings
**Solution**: Add firewall rules for ports 8008, 8080

### Issue: Services can't reach each other
**Check**: All containers are on the same network (voice-stack-network)
**Solution**: Verify network configuration in stack

## 8. Quick Diagnostic Commands

Run these in PowerShell on the Docker host:

```powershell
# Check if Docker is binding ports
netstat -an | findstr "0.0.0.0:8008\|0.0.0.0:8080"

# Check if services respond locally
try { 
    $response = Invoke-WebRequest -Uri "http://localhost:8008" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Synapse: WORKING - Status $($response.StatusCode)"
} catch { 
    Write-Host "Synapse: FAILED - $($_.Exception.Message)"
}

try { 
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -UseBasicParsing
    Write-Host "Element: WORKING - Status $($response.StatusCode)"
} catch { 
    Write-Host "Element: FAILED - $($_.Exception.Message)"
}
```

## 9. Environment Variable Check

Verify your environment variables in Portainer stack:
- `SERVER_NAME=matrix.byte-box.org` (or your domain)
- `ELEMENT_PORT=8080` (if you changed it)
- `SYNAPSE_PORT=8008` (if you changed it)

## Next Steps

1. Start with checking container status in Portainer
2. Run the local connectivity tests
3. Check the container logs for errors
4. Test firewall rules if local access works but remote doesn't

Let me know what you find from these tests!
