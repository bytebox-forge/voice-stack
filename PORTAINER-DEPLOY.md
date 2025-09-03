# Portainer Deployment Guide

Quick deployment guide for Voice Stack via Portainer.

## Pre-Deployment Setup

**On your Docker host**, run the setup script:

```bash
git clone <repository>
cd voice-stack
./setup.sh
```

This will:
- Create external Docker volumes
- Generate secure secrets
- Validate configuration
- Check port availability

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

### 4. Deploy Stack

Click **Deploy the stack**

## Post-Deployment

### 1. Health Check

```bash
./scripts/health-check.sh
```

### 2. Create Admin User

```bash
./scripts/create-admin.sh
```

### 3. Configure Reverse Proxy

Route these endpoints through your reverse proxy:

- `https://matrix.byte-box.org` → `http://server:8008`
- `https://chat.byte-box.org` → `http://server:8080`  
- `https://admin.byte-box.org` → `http://server:8082`
- `https://matrix.byte-box.org/.well-known/matrix/*` → `http://server:8090/.well-known/matrix/*`

## Troubleshooting

### Stack Won't Start

1. Check external volumes exist:
   ```bash
   docker volume ls | grep voice-stack
   ```

2. Re-run setup if volumes missing:
   ```bash
   ./setup.sh
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
./scripts/backup-data.sh
```

**Restore data:**
```bash
./scripts/restore-data.sh YYYYMMDD_HHMMSS
```

**Update stack:**
1. Edit image tags in docker-compose.yml via Portainer
2. Redeploy stack

---

**For detailed documentation, see [README.md](README.md)**