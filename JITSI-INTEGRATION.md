# Jitsi Meet Integration with Voice Stack

## Integration Steps to Connect Host B's Jitsi into Voice-Stack on Host A

### 1. Commit `docker-compose.jitsi.yml` to your GitHub repo

The `docker-compose.jitsi.yml` file has been created alongside your existing voice-stack compose file. This will be committed to your repository for deployment on Host B.

### 2. Deploy Jitsi Stack on Host B via Portainer

1. **In Portainer on Host B**: Go to **Stacks** → **Add stack** → **Git repository**
2. **Repository URL**: Point to your voice-stack GitHub repository
3. **Compose path**: Enter `docker-compose.jitsi.yml`
4. **Auto-update**: Enable if desired for automatic updates

### 3. Configure Environment Variables in Portainer

The repository includes `.env.jitsi.example` as a template. In the stack's **Environment variables** section, define these required variables:

**Copy from `.env.jitsi.example` and customize:**

```bash
# === REQUIRED DOMAIN CONFIGURATION ===
# Your public Jitsi Meet domain (must have DNS A record pointing to Host B)
DOMAIN=meet.example.org

# XMPP internal domain (can be internal)
XMPP_DOMAIN=xmpp.meet.example.org

# === REQUIRED SECURITY SECRETS ===
# Generate strong random secrets for these:
JICOFO_COMPONENT_SECRET=your_strong_jicofo_secret_here
JICOFO_AUTH_PASSWORD=your_jicofo_auth_password
JVB_AUTH_PASSWORD=your_jvb_auth_password
JIGASI_XMPP_PASSWORD=your_jigasi_password
JIBRI_RECORDER_PASSWORD=your_recorder_password
JIBRI_XMPP_PASSWORD=your_jibri_password

# === REQUIRED SSL CONFIGURATION ===
# Your email for Let's Encrypt certificate registration
LETSENCRYPT_EMAIL=admin@example.org

# === OPTIONAL CONFIGURATION ===
# Timezone
TZ=America/New_York

# TURN server integration (connect to your voice-stack TURN server on Host A)
TURN_URL=turn:turn.byte-box.org:3478?transport=udp
TURN_USERNAME=your_turn_username
TURN_PASSWORD=your_turn_password

# Docker host address for JVB (usually auto-detect works)
DOCKER_HOST_ADDRESS=auto-detect

# Feature toggles
ENABLE_AUTH=1
ENABLE_GUESTS=1
ENABLE_RECORDING=0
ENABLE_P2P=1
ENABLE_SIMULCAST=1
```

**Secret Generation Example:**
```bash
# Generate secure secrets
openssl rand -hex 32  # For JICOFO_COMPONENT_SECRET
openssl rand -hex 16  # For auth passwords
```

### 4. Configure Network in Portainer

The Jitsi stack uses its own internal `jitsi-network` (no external network configuration needed):

1. **Network**: Leave as default (internal bridge network will be created automatically)
2. **Firewall Requirements**: Open these ports on Host B:
   - **80/tcp**: HTTP (Let's Encrypt challenges)
   - **443/tcp**: HTTPS (Jitsi Meet web interface)
   - **10000/udp**: JVB media port (client connections)

### 5. Deploy and Verify Jitsi Stack

1. **Deploy the stack** in Portainer
2. **Verify all containers start healthy**:
   ```bash
   docker ps | grep jitsi
   ```

3. **Check container logs** for any errors:
   ```bash
   docker logs jitsi-prosody
   docker logs jitsi-jicofo
   docker logs jitsi-jvb
   docker logs jitsi-web
   docker logs jitsi-nginx
   ```

4. **Verify SSL certificate provisioning**:
   - Let's Encrypt should automatically provision certificates for `${DOMAIN}`
   - Check nginx logs: `docker logs jitsi-letsencrypt`

5. **Test Jitsi Meet access**:
   - Navigate to `https://${DOMAIN}` (e.g., `https://meet.example.org`)
   - Should see Jitsi Meet welcome page
   - Test creating a room and joining

6. **Verify UDP 10000 connectivity**:
   - Join a test room from multiple devices
   - Ensure video/audio works properly
   - Check JVB logs for media flow

### 6. Update Element Web on Host A

Modify your Element Web configuration to use the new Jitsi instance:

**Option A: Environment Variable Method (Recommended)**

In your voice-stack `.env` file on Host A, update:
```bash
# Change from your current Jitsi domain to your new one
ELEMENT_JITSI_DOMAIN=meet.example.org
```

**Option B: Direct config.json Modification**

If you need more advanced Jitsi configuration, modify Element's config directly:

```bash
# On Host A, access Element container
docker exec -it voice-stack-element sh

# Edit the config.json
cat > /usr/share/nginx/html/config.json << 'EOF'
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "http://matrix.byte-box.org:8008",
      "server_name": "matrix.byte-box.org"
    }
  },
  "brand": "Element",
  "jitsi": {
    "preferredDomain": "meet.example.org",
    "baseUrl": "https://meet.example.org/",
    "wsUrl": "wss://meet.example.org/xmpp-websocket",
    "mucDomain": "conference.xmpp.meet.example.org"
  },
  "integrations_ui_url": "https://scalar.vector.im/",
  "integrations_rest_url": "https://scalar.vector.im/api",
  "integrations_widgets_urls": [
    "https://scalar.vector.im/api/widgets"
  ],
  "default_theme": "light",
  "features": {
    "feature_groups": "labs",
    "feature_pinning": "labs"
  }
}
EOF
```

### 7. Restart Element Web and Test Integration

1. **Restart Element Web container on Host A**:
   ```bash
   docker restart voice-stack-element
   ```

2. **Test the integration**:
   - Open Element Web: `http://host-a-ip:8080`
   - Log into your Matrix account
   - Create or join a room
   - Click the **"Start a call"** button or **video call icon**
   - Element should now open meetings on your Jitsi Meet instance at `https://meet.example.org`

3. **Verify video calling**:
   - Calls should launch in new tab/window showing your Jitsi Meet domain
   - Multiple participants should be able to join
   - Audio/video should work properly
   - Screen sharing should function

## DNS Configuration Requirements

For this integration to work, you need:

1. **DNS A Record**: `meet.example.org` → Host B's public IP
2. **Firewall Rules**: 
   - Host B: Ports 80, 443, 10000/udp open to internet
3. **SSL Certificate**: Automatically handled by Let's Encrypt

**Note**: The Jitsi stack runs independently on Host B with its own network. Element on Host A connects to it via the public domain.

## Troubleshooting

### Jitsi Meet Not Accessible
- Check DNS resolution: `nslookup meet.example.org`
- Verify nginx container: `docker logs jitsi-nginx`
- Check Let's Encrypt: `docker logs jitsi-letsencrypt`

### Video/Audio Issues
- Verify UDP 10000 is open: `netstat -an | grep 10000`
- Check JVB logs: `docker logs jitsi-jvb`
- Test TURN server integration

### Element Integration Not Working
- Verify ELEMENT_JITSI_DOMAIN is set correctly
- Check Element config.json contains correct Jitsi domain
- Clear browser cache and test again

### Container Startup Issues
- Check all environment variables are set
- Verify secrets are properly generated
- Review container logs for specific errors

## Security Considerations

1. **Strong Secrets**: Use cryptographically strong secrets for all auth passwords
2. **Firewall**: Only expose necessary ports (80, 443, 10000/udp)
3. **Updates**: Keep Jitsi containers updated regularly
4. **Monitoring**: Monitor logs for unauthorized access attempts
5. **Network Isolation**: Use Docker networks to isolate services

## Performance Tuning

For production use, consider:

1. **JVB Scaling**: Add multiple JVB instances for high load
2. **Resource Limits**: Set CPU/memory limits in docker-compose
3. **Monitoring**: Add monitoring stack (Prometheus/Grafana)
4. **Load Balancing**: Use multiple Jitsi instances behind load balancer
5. **Database**: Consider external database for prosody in high-scale deployments

This integration provides a complete self-hosted video conferencing solution integrated with your Matrix/Element setup!
