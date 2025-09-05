# Matrix Family Server - Deployment Checklist

## Pre-Deployment Requirements

### System Requirements ✅
- [ ] Docker Engine 24.0+ installed and running
- [ ] Docker Compose available (or /tmp/docker-compose binary)
- [ ] 4GB+ RAM available
- [ ] 20GB+ disk space for data volumes
- [ ] Ports 8008, 8080, 8082, 8090, 3478, 49152-49172 available
- [ ] sudo/root access for Docker operations

### Network Requirements ✅
- [ ] Internet connectivity for image pulls and CoTURN
- [ ] Firewall configured for required ports
- [ ] External IP address determined for CoTURN (auto-detection or manual)
- [ ] Domain name configured (optional for local deployment)

### Configuration Preparation ✅
- [ ] Environment file (.env) configured with:
  - [ ] SYNAPSE_SERVER_NAME set
  - [ ] Strong POSTGRES_PASSWORD set
  - [ ] REGISTRATION_SHARED_SECRET set
  - [ ] COTURN_STATIC_AUTH_SECRET set
  - [ ] COTURN_EXTERNAL_IP configured
- [ ] Review and validate all environment variables
- [ ] Backup any existing data if upgrading

## Deployment Steps

### 1. Initial Setup ✅
```bash
# Clone or setup project files
git clone <repository> voice-stack
cd voice-stack

# Configure environment
cp .env.clean .env
# Edit .env with your settings

# Verify configuration
./test-setup.sh
```

### 2. Service Deployment ✅
```bash
# Start all services
./deploy.sh start

# Verify containers are starting
./deploy.sh status

# Check container health
./deploy.sh health
```

### 3. Database Initialization ✅
```bash
# Wait for PostgreSQL to be ready (30-60 seconds)
./deploy.sh logs postgres

# Verify Synapse connects to PostgreSQL
./deploy.sh logs synapse
```

### 4. Admin User Creation ✅
```bash
# Create initial admin user
./create_admin_working.sh

# Verify admin user creation
curl -s http://localhost:8008/_synapse/admin/v1/server_version
```

## Post-Deployment Validation

### Service Health Checks ✅
- [ ] All containers running and healthy:
  ```bash
  docker ps --filter name=voice-stack --format "table {{.Names}}\t{{.Status}}"
  ```
- [ ] PostgreSQL has 156+ Synapse tables:
  ```bash
  docker exec voice-stack-postgres psql -U synapse -d synapse -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname='public';"
  ```
- [ ] Synapse health endpoint responds:
  ```bash
  curl http://localhost:8008/health
  ```

### Functionality Testing ✅
- [ ] Element Web loads: http://localhost:8080
- [ ] Synapse Admin loads: http://localhost:8082
- [ ] Well-known endpoints work: http://localhost:8090/.well-known/matrix/server
- [ ] Admin login works in Element Web
- [ ] Test message sending/receiving
- [ ] Voice/video call test between devices

### Run Test Suite ✅
```bash
# Run comprehensive test suite (expect 73%+ pass rate)
./voice_stack_tests.sh

# Expected failures for local setup:
# - DNS resolution (matrix.byte-box.org not real domain)
# - External connectivity (isolated setup)
# - Some well-known tests (different ports)
```

### Security Validation ✅
- [ ] Registration disabled for public users
- [ ] Admin-only user creation working
- [ ] Federation disabled (isolated server)
- [ ] Guest access disabled
- [ ] Directory listing blocked

## Troubleshooting Common Issues

### Container Startup Issues
```bash
# Check specific container logs
./deploy.sh logs synapse
./deploy.sh logs postgres

# Restart specific service
docker restart voice-stack-synapse
```

### Database Connection Issues
```bash
# Test PostgreSQL connection
docker exec voice-stack-postgres psql -U synapse -d synapse -c "SELECT 1;"

# Check Synapse database config
docker exec voice-stack-synapse grep -A5 database /data/homeserver.yaml
```

### Voice/Video Call Issues
```bash
# Check CoTURN server
docker logs voice-stack-coturn

# Verify external IP configuration
docker exec voice-stack-coturn env | grep EXTERNAL_IP
```

## Backup and Maintenance

### Data Backup ✅
```bash
# Backup all configuration and data
./backup-voice-stack.sh --full

# Backup only data volumes
./backup-voice-stack.sh --volumes-only
```

### Updates and Maintenance
```bash
# Stop services for maintenance
./deploy.sh stop

# Update images
docker-compose pull

# Restart services
./deploy.sh start
```

## Migration to New Host

### Export Current Setup
```bash
# Create complete backup
./backup-voice-stack.sh --verify

# Generate portable configuration
./generate-element-config.sh
```

### Import to New Host
1. Copy backup files to new host
2. Run `./restore-voice-stack.sh <backup-file>`
3. Update environment variables for new host
4. Run deployment validation

## Success Criteria ✅

Your deployment is successful when:
- [ ] All 6 containers are running and healthy
- [ ] PostgreSQL contains 156+ Synapse tables
- [ ] Admin user can log in to Element Web
- [ ] Voice/video calls work between clients
- [ ] Test suite shows 70%+ pass rate
- [ ] Family members can be added via admin interface

**🎉 Congratulations! Your Matrix family server is ready for secure family communication with enterprise-grade voice/video capabilities.**