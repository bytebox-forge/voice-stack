# Portainer Deployment Guide

## Quick Deploy in Portainer

### Step 1: Create Stack
1. Open Portainer web interface
2. Go to "Stacks" → "Add stack"
3. Name your stack: `voice-stack`

### Step 2: Environment Variables
Add these environment variables in Portainer:

**Required:**
```
SERVER_NAME=your-domain.com
TURN_SECRET=your-random-secret-key-here
REGISTRATION_SECRET=another-random-secret-here
```

**Optional:**
```
POSTGRES_PASSWORD=secure_db_password
TURN_USERNAME=turn_user
TURN_PASSWORD=secure_turn_password
SYNAPSE_PORT=8008
FEDERATION_PORT=8448
ELEMENT_PORT=8080
TURN_PORT=3478
TURNS_PORT=5349
```

### Step 3: Deploy
1. Copy the contents of `docker-compose.portainer.yml`
2. Paste into the web editor in Portainer
3. Click "Deploy the stack"

### Step 4: Access Services
- **Element Web**: http://your-server:8080
- **Matrix API**: http://your-server:8008
- **Federation**: http://your-server:8448

### Step 5: Create Admin User (Optional)
1. Go to "Containers" in Portainer
2. Open console for `voice-stack_synapse_1`
3. Run:
   ```bash
   register_new_matrix_user -c /data/homeserver.yaml -u admin -p admin_password -a http://localhost:8008
   ```

## Security Notes for Production

1. **Change all default passwords**
2. **Use strong random secrets** (at least 32 characters)
3. **Set up SSL/TLS** with reverse proxy
4. **Configure firewall** properly
5. **Regular backups** of volumes

## Firewall Ports
```
8008/tcp  - Matrix HTTP
8448/tcp  - Matrix Federation
8080/tcp  - Element Web
3478/udp  - TURN/STUN
3478/tcp  - TURN/STUN
5349/udp  - TURN/STUN over TLS
5349/tcp  - TURN/STUN over TLS
49152-49172/udp - TURN relay ports
```

## Volumes Created
- `voice-stack_postgres_data` - Database storage
- `voice-stack_synapse_data` - Synapse configuration
- `voice-stack_media_store` - Uploaded media files
- `voice-stack_redis_data` - Redis cache

## Troubleshooting

### Check Container Logs
In Portainer, go to Containers → Select container → Logs

### Common Issues
1. **Can't connect**: Check firewall and port mapping
2. **Voice calls fail**: Verify TURN server ports are open
3. **Registration fails**: Check REGISTRATION_SECRET is set
4. **Database errors**: Check POSTGRES_PASSWORD matches

### Generate Strong Secrets
```bash
# Use this command to generate random secrets
openssl rand -base64 32
```
