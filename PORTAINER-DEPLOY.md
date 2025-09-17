# Portainer Deployment Guide

Complete step-by-step guide for deploying Voice Stack via Portainer.

## 📋 Prerequisites

- Portainer running on your Docker host
- Domain name with SSL certificates configured
- Reverse proxy setup (Nginx Proxy Manager, Cloudflare Tunnels, etc.)

## 🚀 Deployment Steps

### Step 1: Create Docker Volumes

**SSH into your Docker host** and run:

```bash
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_coturn_data
```

### Step 2: Create Stack in Portainer

1. **Login to Portainer**
2. **Stacks** → **Add Stack**
3. **Name**: `voice-stack`
4. **Build method**: **Web editor**

### Step 3: Copy Docker Compose Configuration

Copy the **entire contents** of `docker-compose.yml` into the web editor.

### Step 4: Configure Environment Variables

In the **Environment variables** section, add these **required** variables:

| Variable | Example Value | Description |
|----------|---------------|-------------|
| `SYNAPSE_SERVER_NAME` | `matrix.yourdomain.com` | Your Matrix server domain |
| `POSTGRES_PASSWORD` | `secure_db_password_123` | Database password |
| `REGISTRATION_SHARED_SECRET` | `registration_secret_xyz` | Admin user creation secret |
| `COTURN_STATIC_AUTH_SECRET` | `turn_server_secret_abc` | TURN server secret |
| `ELEMENT_PUBLIC_URL` | `https://chat.yourdomain.com` | Element client URL |

**Optional variables** (uses defaults if not set):

| Variable | Default | Description |
|----------|---------|-------------|
| `SYNAPSE_PORT` | `8008` | Matrix server port |
| `ELEMENT_PORT` | `8080` | Element client port |
| `SYNAPSE_ADMIN_PORT` | `8082` | Admin panel port |
| `WELL_KNOWN_PORT` | `8090` | Well-known service port |
| `COTURN_PORT` | `3478` | TURN server port |

**Generate secure secrets:**
```bash
openssl rand -base64 32
```

### Step 5: Deploy Stack

1. **Click "Deploy the stack"**
2. **Wait for deployment** to complete
3. **Check container status** in Portainer

## ✅ Post-Deployment Setup

### 1. Verify Services are Running

In Portainer, check all containers show **running** status:
- `voice-stack-postgres`
- `voice-stack-synapse`
- `voice-stack-element`
- `voice-stack-coturn`
- `voice-stack-synapse-admin`
- `voice-stack-well-known`

### 2. Create Admin User

**SSH into your Docker host** and run:

```bash
# Set your admin credentials
USERNAME="admin"
PASSWORD="YourSecurePassword123"
REG_SECRET="your_registration_secret_here"

# Create admin user (single command)
nonce=$(openssl rand -hex 32) && mac=$(echo -n "${nonce}${USERNAME}${PASSWORD}admin${REG_SECRET}" | openssl dgst -sha1 -hmac "${REG_SECRET}" | cut -d' ' -f2) && curl -X POST -H "Content-Type: application/json" -d "{\"nonce\":\"$nonce\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"admin\":true,\"mac\":\"$mac\"}" http://localhost:8008/_synapse/admin/v1/register
```

### 3. Configure Reverse Proxy Routes

Configure your reverse proxy to route these endpoints:

| Domain | Target | Description |
|--------|--------|-------------|
| `https://matrix.yourdomain.com` | `http://server:8008` | Matrix server |
| `https://chat.yourdomain.com` | `http://server:8080` | Element client |
| `https://admin.yourdomain.com` | `http://server:8082` | Admin panel |
| `https://matrix.yourdomain.com/.well-known/matrix/*` | `http://server:8090/.well-known/matrix/*` | Federation |

### 4. Test Deployment

1. **Visit** `https://chat.yourdomain.com`
2. **Login** with your admin credentials
3. **Test federation**: `curl https://matrix.yourdomain.com/.well-known/matrix/server`

## 🔧 Troubleshooting

### Stack Won't Start

**Check volumes exist:**
```bash
docker volume ls | grep voice-stack
```

**Create missing volumes:**
```bash
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_coturn_data
```

### Containers Failing Health Checks

1. **Check Portainer logs** for each failing service
2. **Verify environment variables** are set correctly
3. **Ensure external volumes** exist

### Element Call Not Working

1. **Check well-known endpoints:**
   ```bash
   curl http://localhost:8090/.well-known/matrix/server
   curl http://localhost:8090/.well-known/matrix/client
   ```

2. **Verify reverse proxy** routes `/.well-known/matrix/*` correctly

3. **Test TURN server:**
   ```bash
   docker logs voice-stack-coturn
   ```

### Can't Create Admin User

1. **Check Synapse is responding:**
   ```bash
   curl http://localhost:8008/health
   ```

2. **Verify registration secret** matches environment variable

3. **Check Synapse logs:**
   ```bash
   docker logs voice-stack-synapse
   ```

## 🔄 Updates and Maintenance

### Update Stack

1. **Edit docker-compose.yml** in Portainer
2. **Update image tags** to newer versions
3. **Redeploy stack**

### Backup Data

```bash
# Backup PostgreSQL data
docker run --rm -v voice-stack_postgres_data:/backup-volume -v $(pwd):/backup busybox tar czf /backup/postgres_data.tar.gz -C /backup-volume .

# Backup Synapse data
docker run --rm -v voice-stack_synapse_data:/backup-volume -v $(pwd):/backup busybox tar czf /backup/synapse_data.tar.gz -C /backup-volume .

# Backup media store
docker run --rm -v voice-stack_media_store:/backup-volume -v $(pwd):/backup busybox tar czf /backup/media_store.tar.gz -C /backup-volume .
```

## 📝 Notes

- **External volumes** are used to ensure data persistence across deployments
- **Health checks** monitor service availability
- **Security hardening** prevents privilege escalation
- **Resource limits** prevent resource exhaustion

---

**For full documentation, see [README.md](README.md)**