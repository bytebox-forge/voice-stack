# Voice Stack Migration Guide

**Version:** 1.0  
**Compatible with:** Voice Stack Production v1.96.1  
**Last Updated:** September 4, 2025

## Overview

This guide provides step-by-step instructions for migrating your Voice Stack (Matrix family server) deployment to a new host while preserving all user data, configurations, and functionality.

## Migration Strategies

### Strategy 1: Full Data Migration (Recommended)
Complete transfer of all data and configuration to new host.
- **Downtime**: 30-60 minutes
- **Data Loss Risk**: Minimal
- **Complexity**: Medium

### Strategy 2: Configuration-Only Migration  
Fresh deployment with existing configuration, no data transfer.
- **Downtime**: 15-30 minutes
- **Data Loss Risk**: Complete (all chat history, media, users lost)
- **Complexity**: Low

This guide focuses on **Strategy 1** for production environments.

## Pre-Migration Requirements

### New Host Requirements
```bash
# Operating System
- Linux (Ubuntu 20.04+ or equivalent)
- Docker Engine 20.10+
- Docker Compose 2.0+ (or 1.29+)

# Resources
- CPU: 2+ cores
- RAM: 4GB+ (8GB recommended)
- Storage: 50GB+ available space
- Network: Public IP with open ports

# Required Ports
- 8008 (Synapse API)
- 8080 (Element Web)  
- 8082 (Synapse Admin)
- 3478 (CoTURN)
- 49152-49172 (CoTURN media relay)
```

### DNS Configuration (if changing domains)
```bash
# A Records
matrix.your-domain.com -> NEW_HOST_IP
chat.your-domain.com   -> NEW_HOST_IP

# SRV Records (optional but recommended)
_matrix._tcp.your-domain.com. 10 5 443 matrix.your-domain.com.
```

## Migration Process

### Phase 1: Preparation (On Old Host)

#### 1.1 Create Backup Directory
```bash
mkdir -p ~/voice-stack-backup
cd ~/voice-stack-backup
```

#### 1.2 Stop Services Gracefully
```bash
cd /path/to/voice-stack
./deploy.sh stop
```

#### 1.3 Backup Docker Volumes
```bash
# Create volume backups
docker run --rm -v voice-stack_postgres_data:/source -v ~/voice-stack-backup:/backup alpine tar czf /backup/postgres_data.tar.gz -C /source .

docker run --rm -v voice-stack_synapse_data:/source -v ~/voice-stack-backup:/backup alpine tar czf /backup/synapse_data.tar.gz -C /source .

docker run --rm -v voice-stack_media_store:/source -v ~/voice-stack-backup:/backup alpine tar czf /backup/media_store.tar.gz -C /source .

docker run --rm -v voice-stack_coturn_data:/source -v ~/voice-stack-backup:/backup alpine tar czf /backup/coturn_data.tar.gz -C /source .
```

#### 1.4 Backup Configuration Files
```bash
# Copy configuration
cp -r /path/to/voice-stack ~/voice-stack-backup/config
cd ~/voice-stack-backup/config
rm -rf .git  # Remove git history for security
```

#### 1.5 Verify Backup Integrity
```bash
cd ~/voice-stack-backup
ls -la *.tar.gz
du -sh *

# Verify archive integrity
for file in *.tar.gz; do
    echo "Testing $file..."
    tar -tzf "$file" > /dev/null && echo "✅ $file OK" || echo "❌ $file CORRUPTED"
done
```

### Phase 2: Transfer to New Host

#### 2.1 Transfer Backup Files
```bash
# Using rsync (recommended)
rsync -avz --progress ~/voice-stack-backup/ user@NEW_HOST_IP:~/voice-stack-backup/

# Alternative: Using scp
scp -r ~/voice-stack-backup/ user@NEW_HOST_IP:~/voice-stack-backup/
```

#### 2.2 Verify Transfer
```bash
# On new host
ssh user@NEW_HOST_IP
cd ~/voice-stack-backup
ls -la *.tar.gz
du -sh *
```

### Phase 3: New Host Setup

#### 3.1 Install Prerequisites
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

#### 3.2 Create Voice Stack Directory
```bash
mkdir -p ~/voice-stack
cd ~/voice-stack
cp -r ~/voice-stack-backup/config/* .
chmod +x *.sh
```

#### 3.3 Update Configuration for New Host
```bash
# Edit .env file
nano .env

# Update these values for new host:
SYNAPSE_SERVER_NAME=your-new-domain.com
ELEMENT_PUBLIC_URL=https://chat.your-new-domain.com
COTURN_EXTERNAL_IP=auto  # or set to new host IP
```

#### 3.4 Update Element Configuration (Critical)
```bash
# Update Element config for new domain
nano element-config/config.json

# Change these values:
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "http://your-new-domain.com:8008",
            "server_name": "your-new-domain.com"
        }
    },
    "default_server_name": "your-new-domain.com"
}
```

### Phase 4: Data Restoration

#### 4.1 Create Docker Volumes
```bash
# Create external volumes
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_coturn_data
```

#### 4.2 Restore Volume Data
```bash
cd ~/voice-stack-backup

# Restore PostgreSQL data
docker run --rm -v voice-stack_postgres_data:/target -v $(pwd):/backup alpine sh -c "cd /target && tar xzf /backup/postgres_data.tar.gz"

# Restore Synapse data
docker run --rm -v voice-stack_synapse_data:/target -v $(pwd):/backup alpine sh -c "cd /target && tar xzf /backup/synapse_data.tar.gz"

# Restore media store
docker run --rm -v voice-stack_media_store:/target -v $(pwd):/backup alpine sh -c "cd /target && tar xzf /backup/media_store.tar.gz"

# Restore CoTURN data
docker run --rm -v voice-stack_coturn_data:/target -v $(pwd):/backup alpine sh -c "cd /target && tar xzf /backup/coturn_data.tar.gz"
```

#### 4.3 Verify Volume Restoration
```bash
# Check volume contents
docker run --rm -v voice-stack_postgres_data:/data alpine ls -la /data
docker run --rm -v voice-stack_synapse_data:/data alpine ls -la /data
```

### Phase 5: Service Startup and Validation

#### 5.1 Start Services
```bash
cd ~/voice-stack
./deploy.sh start
```

#### 5.2 Monitor Startup
```bash
# Watch logs for all services
./deploy.sh logs

# Check individual service logs
./deploy.sh logs synapse
./deploy.sh logs postgres
./deploy.sh logs element
```

#### 5.3 Validate Services
```bash
# Check service health
./deploy.sh health

# Run built-in tests
./test-setup.sh
```

#### 5.4 Test Functionality
```bash
# Test database connectivity
docker exec voice-stack-postgres psql -U synapse -d synapse -c "SELECT version();"

# Test Synapse API
curl -s http://localhost:8008/health

# Test Element Web
curl -s http://localhost:8080/ | grep -q "Element" && echo "Element OK"
```

### Phase 6: Post-Migration Tasks

#### 6.1 Update DNS Records
```bash
# Update A records to point to new host IP
# Update any CDN or load balancer configurations
# Verify DNS propagation: nslookup your-domain.com
```

#### 6.2 SSL Certificate Setup
```bash
# If using Let's Encrypt with nginx/Apache
sudo certbot --nginx -d your-domain.com -d chat.your-domain.com

# Or configure your SSL termination proxy
```

#### 6.3 Test User Access
1. Access Element Web interface
2. Test user login
3. Verify chat history is preserved
4. Test voice/video calls
5. Check admin interface functionality

#### 6.4 Update Federation (if applicable)
```bash
# Test federation with other Matrix servers
curl https://federationtester.matrix.org/api/report?server_name=your-domain.com
```

## Rollback Procedure

If migration fails, you can rollback to the original host:

#### Quick Rollback
```bash
# On original host
cd /path/to/voice-stack
./deploy.sh start

# Update DNS to point back to original host
```

#### Full Rollback with Recent Data
```bash
# Stop services on new host
./deploy.sh stop

# Create incremental backup from new host
# Transfer back to original host
# Restore incremental changes
```

## Troubleshooting Common Issues

### Database Connection Errors
```bash
# Check PostgreSQL logs
./deploy.sh logs postgres

# Verify database permissions
docker exec voice-stack-postgres psql -U synapse -d synapse -c "\du"
```

### Element Web Not Loading
```bash
# Check Element container
docker logs voice-stack-element

# Verify Element configuration
docker exec voice-stack-element cat /app/config.json
```

### CoTURN External IP Issues
```bash
# Check detected external IP
docker logs voice-stack-coturn

# Manually set external IP in .env
COTURN_EXTERNAL_IP=YOUR.PUBLIC.IP.HERE
./deploy.sh restart
```

### Port Conflicts
```bash
# Check port usage
sudo netstat -tlnp | grep -E ":8008|:8080|:8082|:3478"

# Update port mappings in .env if needed
```

## Validation Checklist

After migration, verify these items:

- [ ] All containers running and healthy
- [ ] Database accessible and contains user data  
- [ ] Element Web interface loads correctly
- [ ] Users can log in with existing credentials
- [ ] Chat history is preserved
- [ ] Media files (images, videos) are accessible
- [ ] Voice/video calls work correctly
- [ ] Federation with other servers works
- [ ] Admin interface is functional
- [ ] SSL certificates are valid
- [ ] DNS records resolve correctly
- [ ] All configured ports are accessible
- [ ] Backup verification completed

## Security Considerations

### Post-Migration Security Tasks
1. **Change Passwords**: Update any shared admin passwords
2. **Review Access**: Audit user access and permissions
3. **SSL Verification**: Ensure SSL certificates are properly configured
4. **Firewall Rules**: Configure appropriate firewall rules on new host
5. **Monitoring Setup**: Configure monitoring and alerting
6. **Backup Schedule**: Set up automated backup schedule

### Data Security During Migration
- Use encrypted transfer methods (SSH/SCP/rsync over SSH)
- Verify backup file integrity
- Securely delete backup files after successful migration
- Monitor access logs during migration window

## Performance Optimization

After successful migration, consider:

### Resource Monitoring
```bash
# Monitor container resources
docker stats

# Check disk usage
df -h
docker system df
```

### Database Optimization
```bash
# PostgreSQL maintenance
docker exec voice-stack-postgres vacuumdb -U synapse -d synapse -v
```

### Log Management
```bash
# Configure log rotation
# Set appropriate log levels in .env
LOG_LEVEL=INFO
```

## Support and Additional Resources

- **Matrix Community**: `#matrix:matrix.org`
- **Element Community**: `#element-web:matrix.org`  
- **Documentation**: https://matrix.org/docs/guides/
- **Troubleshooting**: Check `VOICE_STACK_TEST_REPORT.md` for common issues

---

**Important**: Always test migration procedures in a staging environment before applying to production systems.