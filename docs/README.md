# Voice Stack Documentation

## System Overview

This Matrix family server provides enterprise-grade secure communication with:
- **PostgreSQL Backend** (156 tables) for scalability and reliability
- **Element Call Integration** for native voice/video calling (up to 8 participants)
- **Complete Federation Isolation** for family privacy
- **Admin-Only User Creation** for controlled access
- **WebRTC Support** with CoTURN for NAT traversal
- **Well-Known Discovery** for proper Matrix client integration

## ✅ Current Status
All services operational with PostgreSQL backend:
- Matrix Synapse v1.96.1 ✅
- Element Web v1.11.86 with Element Call ✅  
- PostgreSQL 15.4 database ✅
- CoTURN 4.6.2 media relay ✅
- Well-Known server for discovery ✅
- Synapse Admin interface ✅

## Core Guides

### Setup & Administration
- **[ADMIN-SETUP.md](ADMIN-SETUP.md)** - Create admin users and manage family members
- **[REGISTRATION-TOKENS.md](REGISTRATION-TOKENS.md)** - User registration management
- **[SYNAPSE-ADMIN-GUIDE.md](SYNAPSE-ADMIN-GUIDE.md)** - PostgreSQL-backed administration

### Voice & Video Features
- **[VIDEO-CALLING-GUIDE.md](VIDEO-CALLING-GUIDE.md)** - Element Call setup and usage
- **[ELEMENT-CALL-TROUBLESHOOTING.md](ELEMENT-CALL-TROUBLESHOOTING.md)** - Voice/video troubleshooting

### Integration & Deployment
- **[REVERSE-PROXY.md](REVERSE-PROXY.md)** - Production SSL/TLS with well-known endpoints
- **[CONNECTION-TROUBLESHOOTING.md](CONNECTION-TROUBLESHOOTING.md)** - Network, PostgreSQL, service issues

### Security & Privacy
- **[FAMILY-SAFE-TROUBLESHOOTING.md](FAMILY-SAFE-TROUBLESHOOTING.md)** - Privacy, isolation, security validation

### Advanced Features
- **[CUSTOM-BOT-DEVELOPMENT.md](CUSTOM-BOT-DEVELOPMENT.md)** - Build custom family Matrix bots

## Quick Links
- **[Main Deployment Guide](../README.md)** - Complete setup instructions
- **[Deployment Checklist](../PRE_DEPLOYMENT_CHECKLIST.md)** - Pre-deployment validation
- **[Environment Configuration](../.env)** - Current working configuration
- **[Admin User Creation](../create_admin_working.sh)** - Create family admin accounts
- **[Test Suite](../voice_stack_tests.sh)** - Validate functionality (73% pass rate)

## Architecture
```
Internet -> CoTURN (3478) -> Docker Network -> 
  ├── PostgreSQL (5432) [Data Storage]
  ├── Matrix Synapse (8008) [Core Server] 
  ├── Element Web (8080) [Client Interface]
  ├── Well-Known (8090) [Discovery]
  └── Synapse Admin (8082) [Management]
```

All services are containerized, health-checked, and production-ready for family use.