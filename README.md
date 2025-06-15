# Family Voice Stack - Self-Hosted Matrix Server

A complete, family-friendly voice and chat server stack using Matrix Synapse, Element Web, and Coturn for secure communications.

## 🎯 Perfect For

- **Families** wanting private voice/video chat
- **Small groups** needing secure communication  
- **Self-hosted** enthusiasts who want control
- **Privacy-focused** users avoiding big tech platforms

## ✨ Features

- 🎙️ **Voice and video calling** support
- 🔐 **Registration tokens** for controlled access
- 👶 **Family-safe defaults** (no public rooms)
- 🌐 **Modern web interface** (Element)
- 🐳 **Single-file deployment** via Portainer
- 🗄️ **PostgreSQL database** backend
- ⚡ **Redis caching** for performance
- 🔗 **Reverse proxy ready** (NPM, Traefik, etc.)

## 🚀 Quick Deploy

### Method 1: Portainer (Recommended)

1. **Create new stack** in Portainer
2. **Repository URL**: `https://github.com/anykolaiszyn/voice-stack.git`
3. **Compose Path**: `docker-compose.portainer-standalone.yml`
4. **Set environment variables** (see Configuration below)
5. **Deploy**

> **Note:** If you see Element Web stuck in a "Configuring Element Web..." loop, the most recent version (June 15, 2025) completely redesigns the Element Web container with a custom entrypoint that bypasses the default configuration loop issue. Make sure your Portainer stack is using the latest version from the repository.
>
> You can also use the included diagnostic script to troubleshoot Element Web configuration issues:
> ```bash
> docker exec -it voice-stack-element /bin/sh -c "wget -O - https://raw.githubusercontent.com/anykolaiszyn/voice-stack/main/element-config-fix.sh | sh"
> ```

### Method 2: Docker Compose

```bash
git clone https://github.com/anykolaiszyn/voice-stack.git
cd voice-stack
cp .env.example .env
# Edit .env with your settings
docker-compose up -d
```

## ⚙️ Configuration

### Required Environment Variables

```bash
# Server identity
SERVER_NAME=matrix.your-domain.com
POSTGRES_PASSWORD=secure_database_password
REGISTRATION_SECRET=admin_registration_secret
TURN_SECRET=turn_server_secret

# Optional: Registration token for controlled access
REGISTRATION_TOKEN=family2024
```

### Optional Environment Variables

```bash
# Port customization (if conflicts exist)
SYNAPSE_PORT=8008
ELEMENT_PORT=8080
TURN_PORT=3478
TURNS_PORT=5349

# TURN server credentials
TURN_USERNAME=turn_user
TURN_PASSWORD=turn_password

# Public URLs (for reverse proxy setups)
PUBLIC_BASEURL=https://matrix.your-domain.com
```

### Registration Token Options

- **Set `REGISTRATION_TOKEN`**: Enables token-based registration (tokens created manually after deployment)
- **Leave empty**: Registration disabled (admin-only account creation via registration secret)

**Important**: Registration tokens must be created manually after deployment using the Matrix admin API. See [`REGISTRATION-TOKENS.md`](REGISTRATION-TOKENS.md) for complete instructions.

## 🌐 Access Your Server

After deployment, access your services at:

- **Element Web**: `http://your-server-ip:8080`
- **Synapse API**: `http://your-server-ip:8008`

## 📚 Documentation

- **[`PORTAINER-SIMPLE.md`](PORTAINER-SIMPLE.md)** - Complete Portainer deployment guide
- **[`ADMIN-SETUP.md`](ADMIN-SETUP.md)** - Creating your first admin account  
- **[`REGISTRATION-TOKENS.md`](REGISTRATION-TOKENS.md)** - User registration control
- **[`CONNECTION-TROUBLESHOOTING.md`](CONNECTION-TROUBLESHOOTING.md)** - Fix connection refused errors
- **[`FAMILY-SAFE-TROUBLESHOOTING.md`](FAMILY-SAFE-TROUBLESHOOTING.md)** - Fix privacy and security issues
- **[`REVERSE-PROXY.md`](REVERSE-PROXY.md)** - Custom domains with NPM/Traefik
- **[`NPM-QUICK-CONNECT.md`](NPM-QUICK-CONNECT.md)** - Nginx Proxy Manager integration
- **[`FAMILY-SETUP.md`](FAMILY-SETUP.md)** - Creating child-safe accounts

## 🔧 Port Usage

| Service | Port | Purpose |
|---------|------|---------|
| Element Web | 8080 | Web interface |
| Synapse | 8008 | Matrix API |
| Coturn | 3478/5349 | Voice/Video (TURN/STUN) |
| Coturn | 49152-49172 | Voice/Video relay range |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Element Web   │    │  Nginx Proxy    │
│     :8080       │    │   Manager       │
└─────────────────┘    │   (Optional)    │
         │              └─────────────────┘
         │                       │
    ┌─────────────────────────────────┐
    │        Matrix Synapse           │
    │          :8008                  │
    └─────────────────────────────────┘
         │              │
┌─────────────────┐ ┌─────────────────┐
│   PostgreSQL    │ │     Redis       │
│   Database      │ │    Cache        │
└─────────────────┘ └─────────────────┘
         │
┌─────────────────┐
│     Coturn      │
│  TURN Server    │
│ :3478 & :5349   │
└─────────────────┘
```

## 🛠️ Troubleshooting

### Common Issues

**Can't access services**:
- Check if ports are already in use
- Verify firewall settings
- Check container logs in Portainer

**Registration not working**:

- Create admin account first (see [`ADMIN-SETUP.md`](ADMIN-SETUP.md))
- Manually create registration tokens (see [`REGISTRATION-TOKENS.md`](REGISTRATION-TOKENS.md))
- Wait 30 seconds after deployment for initial setup to complete

**Voice/Video not working**:
- Ensure TURN ports (3478, 5349, 49152-49172) are open
- Check if behind NAT/firewall
- Verify `TURN_SECRET` matches across services

### Get Help

- Check container logs in Portainer
- Review the troubleshooting guides in the documentation
- Verify environment variables are set correctly

## 🔒 Security Features

- **No public registration** by default (token or admin-only)
- **No public room discovery** (family-safe)
- **Encrypted communications** support
- **Isolated Docker networks** for security
- **Configurable access controls**

## 📋 What's Included

| Component | Purpose |
|-----------|---------|
| **Matrix Synapse** | Core Matrix homeserver |
| **Element Web** | Modern web chat interface |
| **PostgreSQL** | Reliable database backend |
| **Redis** | Performance caching |
| **Coturn** | Voice/video calling support |

## 🎯 Use Cases

- **Family chat server** with voice/video calling
- **Small team communication** with privacy
- **Gaming group coordination** without Discord
- **Community server** with controlled access
- **Learning platform** for Matrix/self-hosting

## 🔄 Updates

The stack is automatically updated when you pull the latest changes from the repository in Portainer. Always backup your data before updating.

## 📄 License

This project is open source. The individual components (Synapse, Element, etc.) have their own licenses.

---

**Need help?** Check the documentation links above or review the container logs in Portainer for troubleshooting information.
