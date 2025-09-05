# Voice Stack Pre-Deployment Checklist

**Version:** 1.0  
**Target Environment:** Production  
**Last Updated:** September 4, 2025

## Overview

This checklist ensures all prerequisites are met before deploying the Voice Stack Matrix family server to a new host. Complete all items before proceeding with deployment.

---

## 🖥️ Host System Requirements

### Operating System
- [ ] Linux distribution (Ubuntu 20.04+ / CentOS 8+ / Debian 11+)
- [ ] System fully updated (`sudo apt update && sudo apt upgrade`)
- [ ] At least 4GB RAM available (8GB recommended)
- [ ] At least 2 CPU cores available
- [ ] 50GB+ free disk space (100GB+ recommended for production)

### Docker Installation
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose 2.0+ installed (or 1.29+)
- [ ] Current user added to docker group
- [ ] Docker service running and enabled
- [ ] Docker daemon accessible without sudo

**Verification Commands:**
```bash
docker --version          # Should show 20.10+
docker-compose --version  # Should show 1.29+ or 2.0+
docker run hello-world    # Should run without sudo
systemctl status docker   # Should show active/running
```

---

## 🌐 Network and DNS Configuration

### Domain Setup
- [ ] Primary domain configured (e.g., `matrix.example.com`)
- [ ] Element subdomain configured (e.g., `chat.example.com`)
- [ ] DNS A records pointing to correct IP address
- [ ] DNS propagation verified (`nslookup your-domain.com`)
- [ ] Optional: SRV records configured for federation

### Port Requirements
- [ ] Port 8008 available (Synapse API)
- [ ] Port 8080 available (Element Web)
- [ ] Port 8082 available (Synapse Admin)
- [ ] Port 3478 available (CoTURN)
- [ ] Ports 49152-49172 available (CoTURN media relay)
- [ ] No conflicting services on these ports

**Port Verification:**
```bash
sudo netstat -tlnp | grep -E ":8008|:8080|:8082|:3478"
# Should return empty if ports are available
```

### Firewall Configuration
- [ ] UFW/iptables configured to allow required ports
- [ ] Cloud provider security groups configured (if applicable)
- [ ] External access verified for public-facing ports

---

## 🔐 SSL/TLS Configuration

### Certificate Requirements
- [ ] SSL certificate available for matrix domain
- [ ] SSL certificate available for Element domain
- [ ] Certificate includes both domains or wildcard
- [ ] Certificate not expired (check expiration date)
- [ ] Certificate chain complete and valid

### SSL Termination Strategy
- [ ] **Option A:** External load balancer/proxy (recommended)
  - [ ] Nginx/Apache/HAProxy configured
  - [ ] SSL termination at proxy level
  - [ ] Backend connections to localhost ports
- [ ] **Option B:** Direct SSL in containers
  - [ ] Certificate files accessible to containers
  - [ ] Docker Compose modified for SSL

---

## 🔧 Configuration Files

### Environment Configuration
- [ ] `.env.example` copied to `.env`
- [ ] `SYNAPSE_SERVER_NAME` updated with your domain
- [ ] `POSTGRES_PASSWORD` set to strong password
- [ ] `REGISTRATION_SHARED_SECRET` set to random string
- [ ] `COTURN_STATIC_AUTH_SECRET` set to random string
- [ ] `ELEMENT_PUBLIC_URL` updated with Element domain
- [ ] `COTURN_EXTERNAL_IP` set correctly (or `auto`)
- [ ] All port mappings reviewed and adjusted if needed

### Element Web Configuration
- [ ] `element-config/config.json` updated with correct domain
- [ ] Base URL matches your Synapse server
- [ ] Server name matches your domain
- [ ] HTTPS/HTTP protocol correctly configured

### Secrets Generation
**Generate strong secrets (minimum 32 characters):**
```bash
# PostgreSQL password
openssl rand -base64 32

# Registration shared secret
openssl rand -base64 32

# CoTURN static auth secret  
openssl rand -base64 32
```
- [ ] All generated secrets recorded securely
- [ ] Secrets different from examples/defaults

---

## 💾 Storage and Backup Preparation

### Docker Volumes
- [ ] External volume naming understood
- [ ] Sufficient space for volume growth
- [ ] Volume backup strategy planned
- [ ] Volume locations documented

### Backup Infrastructure
- [ ] Backup storage location identified
- [ ] Backup automation planned (cron jobs/scripts)
- [ ] Restore procedure tested in dev environment
- [ ] Database backup strategy defined

---

## 👤 User Management Planning

### Administrative Access
- [ ] Matrix admin user credentials planned
- [ ] Admin user creation procedure understood
- [ ] Admin access to Synapse Admin interface planned

### User Registration Policy
- [ ] Registration settings configured in `.env`
- [ ] User invite workflow planned (if registration disabled)
- [ ] Guest access policy decided

---

## 🔍 Monitoring and Logging

### Log Management
- [ ] Log retention policy defined
- [ ] Log rotation configured or planned
- [ ] Log level set appropriately (`LOG_LEVEL` in `.env`)
- [ ] Centralized logging solution planned (optional)

### Health Monitoring
- [ ] Container health check strategy
- [ ] Service monitoring solution planned
- [ ] Alerting for service failures configured
- [ ] Performance monitoring considered

---

## 🧪 Testing Preparation

### Pre-Deployment Testing
- [ ] `test-setup.sh` script reviewed
- [ ] Test execution planned post-deployment
- [ ] Functionality testing checklist prepared
- [ ] WebRTC testing strategy planned

### Staging Environment
- [ ] Staging environment available for testing (recommended)
- [ ] Migration procedure tested in staging
- [ ] Rollback procedure tested
- [ ] Performance benchmarking completed

---

## 📋 Deployment Day Preparation

### Team Coordination
- [ ] Deployment window scheduled
- [ ] Team members notified of deployment
- [ ] Rollback authority identified
- [ ] Communication channels established

### Documentation
- [ ] Deployment runbook prepared
- [ ] Troubleshooting guide accessible
- [ ] Emergency contact information available
- [ ] Post-deployment validation checklist ready

### Backup Safety Net
- [ ] Current system backup completed (if migrating)
- [ ] Backup restoration tested
- [ ] Original system kept running during migration
- [ ] Quick rollback plan documented

---

## ⚡ Performance Optimization

### Resource Planning
- [ ] Expected user load estimated
- [ ] Resource requirements calculated
- [ ] Auto-scaling strategy considered (if applicable)
- [ ] Database performance tuning planned

### Content Delivery
- [ ] CDN considered for Element Web static assets
- [ ] Media storage optimization planned
- [ ] Large file upload policies defined

---

## 🛡️ Security Hardening

### Container Security
- [ ] Docker daemon security configured
- [ ] Container runtime security reviewed
- [ ] Non-root containers where possible
- [ ] Security scanning tools considered

### Application Security
- [ ] Matrix server security best practices reviewed
- [ ] Rate limiting configuration reviewed
- [ ] Federation security policies defined
- [ ] Admin interface access restrictions planned

---

## 📞 Federation and Integration

### Matrix Federation
- [ ] Federation requirements understood
- [ ] Well-known files configuration planned
- [ ] Federation testing strategy prepared
- [ ] Trusted key servers configured

### External Integrations
- [ ] Jitsi Meet integration configured (if using)
- [ ] Element Call configuration reviewed
- [ ] Third-party integrations planned
- [ ] Webhook configurations prepared

---

## ✅ Final Verification

### Pre-Flight Check
- [ ] All checklist items completed
- [ ] Configuration files validated
- [ ] Secrets securely stored
- [ ] Team ready for deployment
- [ ] Monitoring systems prepared
- [ ] Backup systems verified

### Go/No-Go Decision Criteria
- [ ] All critical items completed
- [ ] No known blocking issues
- [ ] Team confident in deployment
- [ ] Rollback plan confirmed
- [ ] Success criteria defined

---

## 🚀 Deployment Commands

Once all checklist items are complete, proceed with deployment:

```bash
# 1. Navigate to Voice Stack directory
cd ~/voice-stack

# 2. Validate configuration
./test-setup.sh

# 3. Start services
./deploy.sh start

# 4. Monitor startup
./deploy.sh logs

# 5. Verify health
./deploy.sh health

# 6. Run full test suite
./voice_stack_tests.sh
```

---

## 📞 Emergency Contacts

**During deployment, ensure these contacts are available:**

- [ ] System administrator contact information
- [ ] DNS management access
- [ ] SSL certificate management access
- [ ] Cloud provider support (if applicable)
- [ ] Backup system administrator
- [ ] Network administrator contact

---

## 📝 Notes Section

Use this space to record deployment-specific notes, custom configurations, or lessons learned:

```
Date: _______________
Deployed by: _______________
Environment: _______________
Special configurations:

Issues encountered:

Resolution notes:

Performance observations:

```

---

**⚠️ Important Reminder**: Do not proceed with production deployment until ALL applicable checklist items are completed and verified. A failed deployment can result in service downtime and potential data loss.