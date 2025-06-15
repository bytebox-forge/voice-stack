# Port Configuration Guide

This guide explains how to configure custom ports for your Voice Stack to avoid conflicts.

## Environment Variables for Port Configuration

Set these environment variables in Portainer to customize ports:

### Element Web (Default: 8080)
```bash
ELEMENT_PORT=8082
```
Access Element Web at: `http://your-server:8082`

### Synapse API (Default: 8008)
```bash
SYNAPSE_PORT=8009
```
Access Synapse API at: `http://your-server:8009`

### TURN Server (Default: 3478/5349)
```bash
TURN_PORT=3479
TURNS_PORT=5350
```

## Setting Environment Variables in Portainer

1. **Go to Stacks** → **voice-stack**
2. **Click "Editor"** tab
3. **Add environment variables** in the Environment Variables section:
   ```
   ELEMENT_PORT=8082
   SYNAPSE_PORT=8009
   TURN_PORT=3479
   TURNS_PORT=5350
   ```
4. **Click "Update Stack"**

## Common Port Conflicts

### Port 8080 (Element Web)
Often used by:
- Development servers
- Jenkins
- Tomcat
- Other web applications

**Solution**: Use `ELEMENT_PORT=8082` or `ELEMENT_PORT=8081`

### Port 8008 (Synapse)
Sometimes used by:
- Alternative HTTP servers
- Development applications

**Solution**: Use `SYNAPSE_PORT=8009` or `SYNAPSE_PORT=8018`

### Ports 3478/5349 (TURN Server)
Less common conflicts, but may conflict with:
- Other TURN/STUN servers
- VoIP applications

**Solution**: Use `TURN_PORT=3479` and `TURNS_PORT=5350`

## Checking for Port Conflicts

Before deployment, check which ports are in use:

```powershell
# Check specific ports (Windows)
netstat -an | findstr :8080
netstat -an | findstr :8008
netstat -an | findstr :3478

# Should return empty if ports are available
```

```bash
# Check specific ports (Linux/Mac)
netstat -an | grep :8080
netstat -an | grep :8008
netstat -an | grep :3478
```

## Complete Example Configuration

If you have port conflicts, use this complete environment variable set:

```bash
# Server Configuration
SERVER_NAME=matrix.your-domain.com
POSTGRES_PASSWORD=your_secure_password
REGISTRATION_SECRET=your_registration_secret
TURN_SECRET=your_turn_secret

# Custom Ports (to avoid conflicts)
ELEMENT_PORT=8082
SYNAPSE_PORT=8009
TURN_PORT=3479
TURNS_PORT=5350

# Optional Settings
REGISTRATION_TOKEN=family2024
```

## Accessing Services with Custom Ports

After setting custom ports:

- **Element Web**: `http://your-server:8082`
- **Synapse API**: `http://your-server:8009`
- **Health Check**: `http://your-server:8009/_matrix/client/versions`

## Firewall Configuration

If using custom ports on a remote server, update firewall rules:

```bash
# Example for Ubuntu/Debian
sudo ufw allow 8082/tcp  # Element Web
sudo ufw allow 8009/tcp  # Synapse
sudo ufw allow 3479/udp  # TURN
sudo ufw allow 5350/udp  # TURNS
```

## Troubleshooting Port Issues

### Error: "Port already allocated"
- Another service is using the port
- Change the port using environment variables
- Or stop the conflicting service

### Error: "Connection refused"
- Port might not be properly mapped
- Check container logs for binding errors
- Verify environment variables are set correctly

### Error: "Network unreachable"
- Firewall blocking the custom ports
- Add firewall rules for the new ports
- Check cloud security groups if using cloud hosting

## Default Port Summary

| Service | Default Port | Environment Variable | Purpose |
|---------|--------------|---------------------|---------|
| Element Web | 8080 | `ELEMENT_PORT` | Web interface |
| Synapse | 8008 | `SYNAPSE_PORT` | Matrix API |
| TURN | 3478 | `TURN_PORT` | Voice/Video UDP/TCP |
| TURNS | 5349 | `TURNS_PORT` | Voice/Video TLS |
| PostgreSQL | 5432 | N/A | Database (internal) |
| Redis | 6379 | N/A | Cache (internal) |

The PostgreSQL and Redis ports are not exposed externally and don't typically need customization.
