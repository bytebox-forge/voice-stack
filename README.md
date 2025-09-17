# Voice Stack - Production Matrix Server

A production-ready, security-hardened Matrix server stack with Element web client, optimized for Portainer deployment.

## 🚀 Features

- **Matrix Synapse** server with PostgreSQL database
- **Element** web client with working Element Call
- **CoTURN** TURN server for voice/video calls
- **Synapse Admin** panel for user management
- **Well-known** service for federation
- **Production security** hardening and health checks
- **Portainer ready** with external volumes

## 📋 Prerequisites

- Docker server with Docker Compose
- Domain name with SSL certificates
- Reverse proxy (Nginx Proxy Manager, Cloudflare Tunnels, etc.)
- At least 2GB RAM and 10GB storage

## 🔧 Quick Deployment

### 1. Create Docker Volumes

```bash
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_coturn_data
```

### 2. Deploy via Portainer

1. **Portainer** → **Stacks** → **Add Stack**
2. **Name**: `voice-stack`
3. **Copy** `docker-compose.yml` content
4. **Set environment variables** (see below)
5. **Deploy**

### 3. Environment Variables

Set these in Portainer:

```env
SYNAPSE_SERVER_NAME=matrix.yourdomain.com
POSTGRES_PASSWORD=your_secure_password_here
REGISTRATION_SHARED_SECRET=your_registration_secret_here
COTURN_STATIC_AUTH_SECRET=your_turn_secret_here
ELEMENT_PUBLIC_URL=https://chat.yourdomain.com
```

**Generate secure secrets:**
```bash
openssl rand -base64 32
```

### 4. Create Admin User

```bash
USERNAME="admin"
PASSWORD="YourSecurePassword123"
REG_SECRET="your_registration_secret_here"

nonce=$(openssl rand -hex 32) && mac=$(echo -n "${nonce}${USERNAME}${PASSWORD}admin${REG_SECRET}" | openssl dgst -sha1 -hmac "${REG_SECRET}" | cut -d' ' -f2) && curl -X POST -H "Content-Type: application/json" -d "{\"nonce\":\"$nonce\",\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"admin\":true,\"mac\":\"$mac\"}" http://localhost:8008/_synapse/admin/v1/register
```

### 5. Configure Reverse Proxy

Route these endpoints:

- `https://matrix.yourdomain.com` → `http://server:8008` (Matrix server)
- `https://chat.yourdomain.com` → `http://server:8080` (Element client)
- `https://admin.yourdomain.com` → `http://server:8082` (Admin panel)
- `https://matrix.yourdomain.com/.well-known/matrix/*` → `http://server:8090/.well-known/matrix/*`

## 🔍 Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Synapse | 8008 | Matrix server |
| Element | 8080 | Web client |
| Admin | 8082 | Admin panel |
| Well-known | 8090 | Federation |
| CoTURN | 3478 | TURN server |

## 📁 Project Structure

```
voice-stack/
├── docker-compose.yml      # Main deployment file
├── Dockerfile.element      # Element web client build
├── .env.example           # Environment template
├── backup-voice-stack.sh  # Backup script
├── element-config/        # Element configuration
└── docs/                  # Documentation
    ├── ADMIN-SETUP.md
    ├── CONNECTION-TROUBLESHOOTING.md
    ├── ELEMENT-CALL-TROUBLESHOOTING.md
    ├── FAMILY-SAFE-TROUBLESHOOTING.md
    ├── REVERSE-PROXY.md
    ├── SYNAPSE-ADMIN-GUIDE.md
    └── VIDEO-CALLING-GUIDE.md
```

## 🛠️ Maintenance

### Backup Data
```bash
./backup-voice-stack.sh
```

### Update Stack
1. Edit image tags in `docker-compose.yml`
2. Redeploy via Portainer

### Health Check
```bash
docker ps | grep voice-stack
curl http://localhost:8090/.well-known/matrix/server
```

## 📖 Documentation

- **[Admin Setup](docs/ADMIN-SETUP.md)** - Admin user management
- **[Connection Troubleshooting](docs/CONNECTION-TROUBLESHOOTING.md)** - Network issues
- **[Element Call](docs/ELEMENT-CALL-TROUBLESHOOTING.md)** - Voice/video calling
- **[Family Safety](docs/FAMILY-SAFE-TROUBLESHOOTING.md)** - Content filtering
- **[Reverse Proxy](docs/REVERSE-PROXY.md)** - Proxy configuration
- **[Synapse Admin](docs/SYNAPSE-ADMIN-GUIDE.md)** - Server administration
- **[Video Calling](docs/VIDEO-CALLING-GUIDE.md)** - Voice/video setup

## 🔒 Security

- No new privileges for containers
- Non-root container execution
- Secure secret management
- Health check monitoring
- Resource limits and logging

---

**Production-ready Matrix stack for secure family communication**