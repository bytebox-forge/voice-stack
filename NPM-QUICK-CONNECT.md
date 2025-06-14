# Quick NPM Integration

## Simple Method: Connect NPM to Voice Stack Network

If you already have Nginx Proxy Manager running and want to connect it to your voice stack:

### Step 1: Connect NPM to Voice Stack Network

```bash
docker network connect voice-stack-network nginx-proxy-manager
```

### Step 2: Configure Proxy Hosts in NPM

In Nginx Proxy Manager web interface:

#### For Matrix/Synapse API:
- **Domain**: `matrix.your-domain.com`
- **Forward Hostname/IP**: `voice-stack-synapse`
- **Forward Port**: `8008`
- **Enable SSL** with Let's Encrypt

#### For Element Web Client:
- **Domain**: `chat.your-domain.com` 
- **Forward Hostname/IP**: `voice-stack-element`
- **Forward Port**: `80`
- **Enable SSL** with Let's Encrypt

### Step 3: Update Voice Stack Environment

In your Portainer stack, update these environment variables:

```
SERVER_NAME=matrix.your-domain.com
PUBLIC_BASEURL=https://matrix.your-domain.com
```

### Step 4: Optional - Remove Port Exposure

Since traffic goes through NPM, you can remove direct port access by commenting out ports in your stack:

```yaml
# ports:
#   - "${SYNAPSE_PORT:-8008}:8008"  # Remove direct access
#   - "${ELEMENT_PORT:-8080}:80"    # Remove direct access
```

## Advanced Method: Dual Network Setup

If you want more organized networking, the voice stack now supports dual networks:

### Step 1: Create Shared Network

```bash
docker network create proxy-bridge
```

### Step 2: Connect NPM to Shared Network

```bash
docker network connect proxy-bridge nginx-proxy-manager
```

### Step 3: Update Voice Stack

Add this environment variable to your Portainer stack:

```
ADDITIONAL_NETWORK=proxy-bridge
```

Then redeploy the stack. The voice stack will now be on both networks:
- `voice-stack-network` (internal communication)
- `proxy-bridge` (NPM communication)

## Verification

### Test Network Connectivity

From NPM container, test connectivity:

```bash
docker exec nginx-proxy-manager ping voice-stack-synapse
docker exec nginx-proxy-manager ping voice-stack-element
```

### Check Networks

```bash
# List networks
docker network ls

# Inspect voice stack network
docker network inspect voice-stack-network

# Check what networks NPM is on
docker inspect nginx-proxy-manager | grep NetworkMode
```

## Troubleshooting

### "Host not found" Error

**Problem**: `nginx: [emerg] host not found in upstream "matrix-synapse"`

**Solution**: 
1. Use correct container name: `voice-stack-synapse` (not `matrix-synapse`)
2. Ensure NPM is connected to `voice-stack-network`
3. Restart NPM after network connection

### Can't Reach Services

**Problem**: Proxy hosts show as offline

**Solutions**:
1. Verify container names are correct
2. Check both containers are on same network
3. Test ping connectivity (command above)
4. Check firewall/security groups if on cloud

This approach keeps your voice stack self-contained while allowing NPM integration when needed!
