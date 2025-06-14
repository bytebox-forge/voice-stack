# Reverse Proxy Integration Guide

## Overview

The voice stack can be integrated with reverse proxy managers like Nginx Proxy Manager, Traefik, or Cloudflare Tunnel. This guide shows you how to expose your services through a reverse proxy.

## Default Port Mapping

The `docker-compose.portainer-standalone.yml` exposes these ports by default:

| Service | Port | Purpose |
|---------|------|---------|
| Synapse | 8008 | Matrix homeserver API |
| Element Web | 8080 | Web client interface |
| Coturn | 3478/5349 | TURN/STUN (voice/video) |

## Integration Options

### Option 1: Port-Based Access (Current Default)

**What it does**: Direct access via IP and ports
**Best for**: Simple setups, testing, local networks

Access your services at:
- Element Web: `http://your-server-ip:8080`
- Synapse API: `http://your-server-ip:8008`

### Option 2: Reverse Proxy with Custom Domains

**What it does**: Access via custom domains through your reverse proxy
**Best for**: Production setups, SSL termination, multiple services

Access your services at:
- Element Web: `https://chat.your-domain.com`
- Synapse API: `https://matrix.your-domain.com`

## Nginx Proxy Manager Integration

### Prerequisites

You need Nginx Proxy Manager already running. If you don't have it:

1. **Deploy NPM first**: Use a separate stack for Nginx Proxy Manager
2. **Create shared network**: Both stacks need to communicate

### Step 1: Create Shared Network

Create a network that both NPM and voice stack can use:

```bash
docker network create proxy-network
```

### Step 2: Update Voice Stack Network

Edit your voice stack environment variables in Portainer to use the shared network:

**Add this environment variable:**
```
PROXY_NETWORK=proxy-network
```

### Step 3: Configure NPM Proxy Hosts

In Nginx Proxy Manager, create these proxy hosts:

#### For Element Web (Chat Interface)
- **Domain**: `chat.your-domain.com`
- **Forward Hostname/IP**: `voice-stack-element`
- **Forward Port**: `80`
- **SSL**: Enable with Let's Encrypt

#### For Synapse (Matrix API)
- **Domain**: `matrix.your-domain.com`
- **Forward Hostname/IP**: `voice-stack-synapse`
- **Forward Port**: `8008`
- **SSL**: Enable with Let's Encrypt

### Step 4: Update Element Configuration

Update your environment variables to use the proxy domains:

```
SERVER_NAME=matrix.your-domain.com
PUBLIC_BASEURL=https://matrix.your-domain.com
ELEMENT_URL=https://chat.your-domain.com
```

## Alternative: Network-Level Integration

If you prefer to modify the Docker Compose file directly:

### Step 1: Add External Network Support

You can modify the `docker-compose.portainer-standalone.yml` to support external networks by adding this to each service:

```yaml
networks:
  - voice-stack-network
  - proxy-network  # Add your reverse proxy network
```

And update the networks section:

```yaml
networks:
  voice-stack-network:
    driver: bridge
  proxy-network:
    external: true
```

### Step 2: Remove Port Exposure (Optional)

If using a reverse proxy, you can remove the exposed ports since traffic goes through the proxy:

```yaml
# Comment out or remove these port mappings
# ports:
#   - "${SYNAPSE_PORT:-8008}:8008"
#   - "${ELEMENT_PORT:-8080}:80"
```

## Troubleshooting

### "Host not found" Errors

**Problem**: Nginx shows `host not found in upstream "matrix-synapse"`

**Solution**: Check your container names and network configuration:

1. **Verify container names**:
   ```bash
   docker ps | grep voice-stack
   ```
   
2. **Check networks**:
   ```bash
   docker network ls
   docker network inspect proxy-network
   ```

3. **Update NPM configuration** to use correct container names:
   - Use: `voice-stack-synapse` (not `matrix-synapse`)
   - Use: `voice-stack-element` (not `element-web`)

### Services Not Accessible

**Problem**: Can't reach services through reverse proxy

**Solutions**:

1. **Check container connectivity**:
   ```bash
   # From NPM container
   docker exec nginx-proxy-manager ping voice-stack-synapse
   ```

2. **Verify network membership**:
   ```bash
   docker inspect voice-stack-synapse | grep NetworkMode
   ```

3. **Check firewall rules** on your server

### SSL/Certificate Issues

**Problem**: SSL certificates not working

**Solutions**:

1. **DNS must resolve** to your server's public IP
2. **Ports 80/443** must be open and forwarded
3. **Domain validation** must complete for Let's Encrypt

## Security Considerations

### Recommended Setup

1. **Use SSL/TLS**: Always enable HTTPS for production
2. **Restrict access**: Use firewall rules or auth middleware
3. **Update regularly**: Keep NPM and voice stack updated
4. **Monitor logs**: Watch for unusual access patterns

### Firewall Configuration

If using a reverse proxy, you can block direct access to voice stack ports:

```bash
# Block direct access (NPM will proxy)
ufw deny 8008  # Synapse
ufw deny 8080  # Element

# Keep TURN ports open (required for voice/video)
ufw allow 3478  # TURN
ufw allow 5349  # TURNS
ufw allow 49152:49172/udp  # TURN relay range
```

## Example NPM + Voice Stack Setup

### Complete Environment Variables

For a reverse proxy setup, use these environment variables:

```
# Domain configuration
SERVER_NAME=matrix.your-domain.com
PUBLIC_BASEURL=https://matrix.your-domain.com

# Registration
REGISTRATION_TOKEN=family2024

# Security
POSTGRES_PASSWORD=secure_db_password
REGISTRATION_SECRET=admin_secret_key
TURN_SECRET=turn_secret_key

# Ports (optional if using proxy only)
SYNAPSE_PORT=8008
ELEMENT_PORT=8080
TURN_PORT=3478
TURNS_PORT=5349
```

### DNS Configuration

Point your domains to your server:

```
chat.your-domain.com     A    your-server-ip
matrix.your-domain.com   A    your-server-ip
```

This setup gives you professional URLs while keeping the voice stack deployment simple and self-contained.
