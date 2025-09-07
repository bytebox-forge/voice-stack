# Voice Stack Deployment - Minimal Portainer Setup

## Prerequisites
- Docker and Portainer running
- Your domain DNS configured
- SSL certificates ready for your domain

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
docker volume create voice-stack_coturn_data
```

### 2. Portainer Stack Deployment

1. **Open Portainer** → Stacks → Add Stack
2. **Name**: `voice-stack`
3. **Copy** the entire `docker-compose.yml` content
4. **Set Environment Variables**:
   ```
   SYNAPSE_SERVER_NAME=matrix.yourdomain.com
   POSTGRES_PASSWORD=your_strong_password_here
   REGISTRATION_SHARED_SECRET=your_registration_secret_here
   COTURN_STATIC_AUTH_SECRET=your_turn_secret_here
   ```
5. **Deploy Stack**

### 3. Create Admin User
After deployment is complete, run the command from `create-admin-user.txt`

### 4. Configure Reverse Proxy
Point your reverse proxy to:
- Matrix Server: `http://server:8008` → `https://matrix.yourdomain.com`
- Element Web: `http://server:8080` → `https://chat.yourdomain.com`
- Well-known: `http://server:8090/.well-known/matrix/*` → `https://matrix.yourdomain.com/.well-known/matrix/*`

## Access Points
- **Element Web**: https://chat.yourdomain.com
- **Synapse Admin**: `localhost:8082` (internal only)
- **Matrix API**: https://matrix.yourdomain.com

## Health Check
```bash
docker ps | grep voice-stack
curl http://localhost:8090/.well-known/matrix/server
curl http://localhost:8090/.well-known/matrix/client
```

That's it! No complex scripts, just pure Portainer deployment.
