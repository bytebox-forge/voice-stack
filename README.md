# Voice Stack - Production Matrix Server

A production-ready, security-hardened Matrix server stack optimized for Portainer deployment. Features persistent PostgreSQL storage, working Element Call integration, and comprehensive operational tools.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose v2
- External reverse proxy (Nginx Proxy Manager, Cloudflare Tunnels, etc.)
- Domain name with SSL certificates
- At least 2GB RAM and 10GB storage

### Portainer Deployment

1. **Create volumes first** (required for external volumes):
   ```bash
   docker volume create voice-stack_postgres_data
   docker volume create voice-stack_synapse_data
   docker volume create voice-stack_media_store
   docker volume create voice-stack_element_data
   docker volume create voice-stack_coturn_data
   ```

2. **In Portainer**:
   - Go to **Stacks** → **Add Stack**
   - Name: `voice-stack`
   - Copy contents of `docker-compose.yml`
   - Set environment variables (see below)
   - Deploy

### Environment Variables (Required)

Set these in Portainer's environment variables section:

```bash
SYNAPSE_SERVER_NAME=matrix.yourdomain.com
POSTGRES_PASSWORD=your_secure_database_password_here
REGISTRATION_SHARED_SECRET=your_registration_secret_here
COTURN_STATIC_AUTH_SECRET=your_turn_secret_here
```

**Generate secure secrets:**
```bash
# For passwords and secrets
openssl rand -base64 32
openssl rand -hex 32
```

### Reverse Proxy Configuration

Configure your external reverse proxy to route:

| Service | Internal URL | External URL | Notes |
|---------|-------------|--------------|--------|
| Matrix API | `http://server:8008` | `https://matrix.yourdomain.com` | Main Matrix server |
| Element Web | `http://server:8080` | `https://chat.yourdomain.com` | Web client |
| Synapse Admin | `http://server:8082` | `https://admin.yourdomain.com` | Admin interface |
| Well-Known | `http://server:8090/.well-known/matrix/*` | `https://matrix.yourdomain.com/.well-known/matrix/*` | Discovery |

### Post-Deployment

1. **Create admin user**:
   ```bash
   # SSH into your server
   ./scripts/register-admin.sh
   ```

2. **Health check**:
   ```bash
   ./scripts/healthcheck.sh
   ```

3. **Access services**:
   - Element Web: https://chat.yourdomain.com
   - Synapse Admin: https://admin.yourdomain.com

## 📋 Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SYNAPSE_SERVER_NAME` | Matrix server domain | - | ✅ |
| `POSTGRES_PASSWORD` | Database password | - | ✅ |
| `REGISTRATION_SHARED_SECRET` | Admin registration secret | - | ✅ |
| `COTURN_STATIC_AUTH_SECRET` | TURN server secret | - | ✅ |
| `COTURN_EXTERNAL_IP` | Server public IP | `auto` | - |
| `ENABLE_REGISTRATION` | Public registration | `false` | - |
| `ELEMENT_VERSION` | Element Web version | `v1.11.86` | - |
| `LOG_LEVEL` | Logging level | `INFO` | - |

## 🏗️ Architecture

### Services Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Reverse       │    │   Voice Stack   │    │   External      │
│   Proxy         │────│   Services      │────│   Users         │
│   (Cloudflare)  │    │   (Docker)      │    │   (Matrix)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Service Details

- **PostgreSQL**: Persistent database with optimized settings
- **Synapse**: Matrix homeserver with Element Call support
- **Element Web**: Modern Matrix web client
- **CoTURN**: TURN server for NAT traversal
- **Well-Known**: Discovery service for Element Call
- **Synapse Admin**: Web-based administration

## 🔒 Security Features

- ✅ **No Federation**: Private family server mode
- ✅ **PostgreSQL Only**: No SQLite vulnerabilities
- ✅ **Admin Registration**: Controlled user creation
- ✅ **Rate Limiting**: Protection against abuse
- ✅ **Container Hardening**: No new privileges, logging limits
- ✅ **Strong Passwords**: Enforced complexity requirements
- ✅ **Guest Access**: Disabled by default

## 🛠️ Operations

### Backup & Restore

**Create Backup**:
```bash
./scripts/backup.sh
```

**Restore from Backup**:
```bash
./scripts/restore.sh backup_manifest_YYYYMMDD_HHMMSS.txt
```

**Automated Backups** (add to cron):
```bash
0 2 * * * cd /path/to/voice-stack && ./scripts/backup.sh
```

### Monitoring

**Health Check**:
```bash
./scripts/healthcheck.sh
```

**View Logs**:
```bash
# Via Docker
docker compose logs -f synapse

# Via Portainer
# Go to Containers → voice-stack-synapse → Logs
```

### User Management

**Register Admin**:
```bash
./scripts/register-admin.sh
```

**Manage Users**:
- Use Synapse Admin interface at: https://admin.yourdomain.com
- Login with admin credentials

## 🔧 Troubleshooting

### Element Call Issues

**"MISSING_MATRIX_RTC_FOCUS" Error**:
1. Check well-known endpoint: `curl https://matrix.yourdomain.com/.well-known/matrix/client`
2. Verify service is running: `docker compose ps well-known`
3. Check reverse proxy routes /.well-known/matrix/* correctly

**No Media in Calls**:
1. Verify TURN server: `docker compose logs coturn`
2. Check public IP: Set `COTURN_EXTERNAL_IP` if auto-detection fails
3. Ensure firewall allows ports 3478, 5349, 49152-49172

### Database Issues

**Connection Failed**:
1. Check PostgreSQL health: `docker compose ps postgres`
2. Verify passwords match in environment variables
3. Check volumes exist: `docker volume ls | grep voice-stack`

**Data Loss After Restart**:
1. Ensure external volumes are created before deployment
2. Check Portainer stack configuration
3. Restore from backup if needed

### Performance Issues

**High Memory Usage**:
- Reduce PostgreSQL `shared_buffers` in compose file
- Adjust Synapse worker processes

**Slow Response**:
- Check reverse proxy timeout settings
- Monitor database performance
- Review container resource limits

## 📁 File Structure

```
voice-stack/
├── docker-compose.yml          # Main Portainer-optimized stack
├── .env.example               # Environment configuration template
├── scripts/                   # Operational scripts
│   ├── bootstrap.sh          # Initial setup and validation
│   ├── healthcheck.sh        # Service health verification  
│   ├── register-admin.sh     # Admin user creation
│   ├── backup.sh            # Database and media backup
│   └── restore.sh           # Backup restoration
├── config/                   # Configuration templates
│   ├── nginx/               # Reverse proxy examples
│   ├── synapse/            # Synapse configuration  
│   └── well-known/         # Matrix discovery files
└── docs/                   # Comprehensive documentation
    ├── README.md          # This file
    └── [various guides]   # Specialized guides
```

## 🔄 Migration

### From SQLite Matrix Server

1. Export data: `synapse_port_db --sqlite-database homeserver.db --postgres-config homeserver.yaml`
2. Deploy this stack with empty database
3. Import exported data
4. Update configuration

### From Matrix.org Synapse

1. Backup existing signing keys and database
2. Deploy this stack
3. Copy signing keys to synapse_data volume
4. Import database dump
5. Update homeserver.yaml with security settings

## 📊 Monitoring

### Health Endpoints

- Synapse: `http://localhost:8008/health`
- Element: `http://localhost:8080/`
- Well-Known: `http://localhost:8090/.well-known/matrix/client`

### Key Metrics

- **Database Size**: Monitor PostgreSQL data growth
- **Media Storage**: Track media_store volume usage  
- **Memory Usage**: Watch container memory consumption
- **Network**: Monitor TURN server connectivity

## 🆘 Support

### Log Collection

```bash
# Collect all logs for support
./scripts/healthcheck.sh > healthcheck.log 2>&1
docker compose logs > docker.log 2>&1
```

### Common Issues

1. **Element Call not working**: Check well-known configuration
2. **Can't register users**: Verify REGISTRATION_SHARED_SECRET
3. **Database errors**: Check PostgreSQL container logs
4. **External connectivity**: Verify reverse proxy configuration

### Resources

- [Matrix Specification](https://spec.matrix.org/)
- [Synapse Documentation](https://matrix-org.github.io/synapse/)
- [Element Call Guide](https://github.com/vector-im/element-call)
- [CoTURN Configuration](https://github.com/coturn/coturn)

---

## 📋 Final Validation

Before going live, verify:

- [ ] External volumes created
- [ ] Environment variables set with strong secrets
- [ ] Reverse proxy configured correctly
- [ ] TURN server ports open in firewall
- [ ] SSL certificates valid for all domains
- [ ] Health check passes
- [ ] Admin user can login
- [ ] Element Call works between two users
- [ ] Backup system functional

**For issues and contributions**: [GitHub Repository](https://github.com/voice-stack)

---

*Production-hardened Matrix server stack - Deployed with ❤️ via Portainer*