# DNS Configuration for byte-box.org Voice Stack with Cloudflare

## Cloudflare Setup (Recommended)

### Cloudflare Tunnel Configuration

#### 1. Install Cloudflared
```bash
# On your Docker host
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

#### 2. Create Tunnel
```bash
# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create voice-stack

# Configure tunnel
nano ~/.cloudflared/config.yml
```

#### 3. Tunnel Configuration File
```yaml
tunnel: voice-stack
credentials-file: /root/.cloudflared/YOUR-TUNNEL-ID.json

ingress:
  # Element Web Client
  - hostname: chat.byte-box.org
    service: http://localhost:8080
    originRequest:
      httpHostHeader: chat.byte-box.org
  
  # Matrix Synapse API
  - hostname: matrix.byte-box.org
    service: http://localhost:8008
    originRequest:
      httpHostHeader: matrix.byte-box.org
  
  # Catch-all rule
  - service: http_status:404
```

#### 4. DNS Records in Cloudflare
Set these DNS records in your Cloudflare dashboard:

```dns
chat.byte-box.org      CNAME   YOUR-TUNNEL-ID.cfargotunnel.com   (Proxied ✅)
matrix.byte-box.org    CNAME   YOUR-TUNNEL-ID.cfargotunnel.com   (Proxied ✅)

# SRV record for Matrix federation
_matrix._tcp.byte-box.org    SRV    10 0 443 matrix.byte-box.org
```

## Nginx Proxy Manager Configuration

Since you mentioned using NPM, here are the proxy configurations:

### 1. Element Web Client (chat.byte-box.org)
- **Domain**: `chat.byte-box.org`
- **Scheme**: `http`
- **Forward Hostname/IP**: `your-docker-host-ip`
- **Forward Port**: `8080`
- **Block Common Exploits**: ✅
- **Websockets Support**: ✅
- **SSL**: Enable with Let's Encrypt

### 2. Matrix Synapse (matrix.byte-box.org)
- **Domain**: `matrix.byte-box.org`
- **Scheme**: `http`
- **Forward Hostname/IP**: `your-docker-host-ip`
- **Forward Port**: `8008`
- **Block Common Exploits**: ✅
- **Websockets Support**: ✅
- **SSL**: Enable with Let's Encrypt

**Advanced Tab - Custom Nginx Configuration:**
```nginx
# Matrix federation
location /.well-known/matrix/server {
    return 200 '{"m.server": "matrix.byte-box.org:443"}';
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}

location /.well-known/matrix/client {
    return 200 '{"m.homeserver": {"base_url": "https://matrix.byte-box.org"}, "m.identity_server": {"base_url": "https://vector.im"}}';
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}

# Handle federation port
location /_matrix/federation/ {
    proxy_pass http://your-docker-host-ip:8448;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Portainer Environment Variables for Cloudflare

Update your Portainer stack with these environment variables:

```env
SERVER_NAME=matrix.byte-box.org
EXTERNAL_IP=YOUR_PUBLIC_IP
TURN_SECRET=your-strong-random-secret-here
REGISTRATION_SECRET=another-strong-secret-here
POSTGRES_PASSWORD=secure-database-password
TURN_USERNAME=turn_user
TURN_PASSWORD=secure-turn-password
```

## Important: TURN Server Configuration

**⚠️ Critical for Voice/Video Calls:**
- TURN server **CANNOT** be proxied through Cloudflare
- You **MUST** expose TURN ports directly to the internet
- Configure your firewall to allow these ports:

```text
3478/udp     # STUN/TURN
3478/tcp     # STUN/TURN
5349/udp     # STUN/TURN over TLS
5349/tcp     # STUN/TURN over TLS
49152-49172/udp  # TURN relay range
```

### TURN Server DNS Record
Add an A record for the TURN server (bypasses Cloudflare):

```dns
turn.byte-box.org    A    YOUR_PUBLIC_IP   (DNS Only - NOT Proxied ❌)
```

### Update Synapse Configuration
Make sure your `synapse/homeserver.yaml` has:

```yaml
turn_uris:
  - "turn:YOUR_PUBLIC_IP:3478?transport=udp"
  - "turn:YOUR_PUBLIC_IP:3478?transport=tcp"
  - "turns:YOUR_PUBLIC_IP:5349?transport=udp"
  - "turns:YOUR_PUBLIC_IP:5349?transport=tcp"
```

## Firewall Configuration

Open these ports on your server:

```bash
# For Nginx Proxy Manager
80/tcp    # HTTP (Let's Encrypt challenges)
443/tcp   # HTTPS

# For Docker containers (internal)
8008/tcp  # Matrix Synapse
8080/tcp  # Element Web
8448/tcp  # Matrix Federation

# For TURN server (voice/video)
3478/udp
3478/tcp
5349/udp
5349/tcp
49152-49172/udp
```

## Testing Your Setup

### 1. Test DNS Resolution
```bash
dig chat.byte-box.org A
dig matrix.byte-box.org A
dig _matrix._tcp.byte-box.org SRV
```

### 2. Test SSL Certificates
```bash
curl -I https://chat.byte-box.org
curl -I https://matrix.byte-box.org
```

### 3. Test Matrix Federation
Visit: https://federationtester.matrix.org/
Enter: `byte-box.org`

### 4. Test TURN Server
```bash
# From inside the coturn container
docker exec -it voice-stack-coturn-1 turnutils_uclient -t -T -u turn_user -w turn_password your-server-ip
```

## Deployment Steps

1. **Set up DNS records** (A and SRV records above)
2. **Configure Nginx Proxy Manager** with the proxy hosts
3. **Deploy Portainer stack** with correct environment variables
4. **Wait for SSL certificates** to be issued
5. **Test federation** using the Matrix Federation Tester
6. **Create admin user** and test voice calls

## Troubleshooting

### Federation Not Working
- Check SRV record: `dig _matrix._tcp.byte-box.org SRV`
- Verify port 8448 is accessible
- Test with: https://federationtester.matrix.org/

### Voice Calls Failing
- Check TURN server logs: `docker logs voice-stack-coturn-1`
- Verify UDP ports 49152-49172 are open
- Test STUN connectivity

### SSL Certificate Issues
- Check Nginx Proxy Manager logs
- Verify DNS propagation
- Ensure ports 80/443 are accessible

## Security Notes

- Use strong, unique secrets for TURN_SECRET and REGISTRATION_SECRET
- Consider disabling open registration after initial setup
- Regularly update Docker images
- Monitor logs for suspicious activity
- Backup your configuration and data regularly
