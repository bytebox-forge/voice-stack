# Portainer Deployment Guide

Quick deployment guide for Voice Stack via Portainer - **No setup scripts required!**

## Pre-Deployment Setup

**On your Docker host**, create Docker volumes:

```bash
# Windows
create-volumes.cmd

# Or manually:
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_element_data
docker volume create voice-stack_coturn_data
```

This creates the persistent storage volumes needed by the stack.

## Portainer Deployment

### 1. Create Stack

In Portainer:
- Go to **Stacks** → **Add Stack**
- Name: `voice-stack`
- Build method: **Web editor**

### 2. Copy Docker Compose

Copy the entire contents of `docker-compose.yml` into the web editor.

### 3. Set Environment Variables

In the **Environment variables** section, add:

| Variable | Value |
|----------|--------|
| `SYNAPSE_SERVER_NAME` | `matrix.byte-box.org` |
| `POSTGRES_PASSWORD` | `your_strong_database_password_here` |
| `REGISTRATION_SHARED_SECRET` | `ByteBox_Matrix_2025_SuperSecretKey_Family` |
| `COTURN_STATIC_AUTH_SECRET` | `ByteBox_TURN_2025_MediaRelaySecret_Secure` |
| `ELEMENT_PUBLIC_URL` | `https://chat.byte-box.org` |

### 4. Deploy Stack

Click **Deploy the stack**

## Post-Deployment

### 1. Health Check

```bash
# Check all containers are running
docker ps | grep voice-stack

# Test well-known endpoints
curl http://localhost:8081/.well-known/matrix/server
curl http://localhost:8081/.well-known/matrix/client
```

### 2. Create Admin User

Use the single command from `create-admin-user.txt`:

```bash
# Set your values
USERNAME="admin"
PASSWORD="YourSecurePassword123" 
REG_SECRET="ByteBox_Matrix_2025_SuperSecretKey_Family"

# Create admin user (single command)
nonce=$(openssl rand -hex 32) && mac=$(echo -n "${nonce}${USERNAME}${PASSWORD}admin${REG_SECRET}" | openssl dgst -sha1 -hmac "${REG_SECRET}" | cut -d' ' -f2) && curl -X POST -H "Content-Type: application/json" -d "{\"nonce\":\"$nonce\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"admin\":true,\"mac\":\"$mac\"}" http://localhost:8008/_synapse/admin/v1/register
```

### 3. Configure Reverse Proxy

Route these endpoints through your reverse proxy:

- `https://matrix.byte-box.org` → `http://server:8008`
- `https://chat.byte-box.org` → `http://server:8080`  
- `https://admin.byte-box.org` → `http://server:8082`
- `https://matrix.byte-box.org/.well-known/matrix/*` → `http://server:8090/.well-known/matrix/*`

## Troubleshooting

### Stack Won't Start

1. Check volumes exist:
   ```bash
   docker volume ls | grep voice-stack
   ```

2. Create volumes if missing:
   ```bash
   # Run create-volumes.cmd or create manually
   docker volume create voice-stack_postgres_data
   docker volume create voice-stack_synapse_data
   docker volume create voice-stack_media_store
   docker volume create voice-stack_element_data
   docker volume create voice-stack_coturn_data
   ```

### Services Unhealthy  

1. Check Portainer logs for each service
2. Verify environment variables are set correctly
3. Run health check for detailed status

### Element Call Issues

1. Verify well-known endpoint accessible externally
2. Check reverse proxy routes `/.well-known/matrix/*` correctly
3. Test TURN server connectivity

## Backup & Maintenance

**Backup data:**
```bash
# Stop stack first, then backup volumes
docker run --rm -v voice-stack_postgres_data:/backup-volume -v $(pwd):/backup busybox tar czf /backup/postgres_data.tar.gz -C /backup-volume .
docker run --rm -v voice-stack_synapse_data:/backup-volume -v $(pwd):/backup busybox tar czf /backup/synapse_data.tar.gz -C /backup-volume .
docker run --rm -v voice-stack_media_store:/backup-volume -v $(pwd):/backup busybox tar czf /backup/media_store.tar.gz -C /backup-volume .
```

**Update stack:**
1. Edit image tags in docker-compose.yml via Portainer
2. Redeploy stack

---

**For detailed documentation, see [README.md](README.md)**
