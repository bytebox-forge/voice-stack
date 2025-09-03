# Voice Stack Deployment - Minimal Portainer Setup

## Prerequisites
- Docker and Portainer running
- Your domain (matrix.byte-box.org) DNS configured

## Deployment Steps

### 1. Create Docker Volumes (Host Command)
```bash
# Run on Docker host:
./create-volumes.cmd
```
Or manually:
```bash
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_element_data  
docker volume create voice-stack_coturn_data
```

### 2. Portainer Stack Deployment

1. **Open Portainer** → Stacks → Add Stack
2. **Name**: `voice-stack`
3. **Copy** the entire `docker-compose.yml` content
4. **Set Environment Variables**:
   ```
   SYNAPSE_SERVER_NAME=matrix.byte-box.org
   POSTGRES_PASSWORD=your_strong_password_here
   REGISTRATION_SHARED_SECRET=ByteBox_Matrix_2025_SuperSecretKey_Family
   COTURN_STATIC_AUTH_SECRET=ByteBox_TURN_2025_MediaRelaySecret_Secure
   ```
5. **Deploy Stack**

### 3. Create Admin User
After deployment is complete, run the command from `create-admin-user.txt`

### 4. Configure Reverse Proxy
Point your reverse proxy to:
- Matrix Server: `http://server:8008` → `https://matrix.byte-box.org`
- Element Web: `http://server:8080` → `https://chat.byte-box.org`
- Well-known: `http://server:8090/.well-known/matrix/*` → `https://matrix.byte-box.org/.well-known/matrix/*`

## Access Points
- **Element Web**: https://chat.byte-box.org
- **Synapse Admin**: `localhost:8082` (internal only)
- **Matrix API**: https://matrix.byte-box.org

## Health Check
```bash
docker ps | grep voice-stack
curl http://localhost:8090/.well-known/matrix/server
curl http://localhost:8090/.well-known/matrix/client
```

That's it! No complex scripts, just pure Portainer deployment.
