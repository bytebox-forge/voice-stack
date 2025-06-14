# Voice Stack - Matrix Synapse with Voice/Video Support

A complete Docker setup for a Matrix homeserver with voice and video calling capabilities, designed for deployment with Portainer.

## Components

- **Matrix Synapse**: The homeserver that handles Matrix protocol
- **PostgreSQL**: Database backend for Synapse
- **Redis**: Caching and session storage
- **Coturn**: TURN/STUN server for voice/video calling
- **Element Web**: Web client for accessing the Matrix server

## Features

- ✅ Voice and video calling support
- ✅ Open registration enabled
- ✅ Modern web interface (Element)
- ✅ Optimized for Docker deployment
- ✅ Portainer compatible
- ✅ PostgreSQL database backend
- ✅ Redis caching for better performance

## Quick Start

### Using Portainer

1. Create a new stack in Portainer
2. Copy the contents of `docker-compose.yml` into the stack editor
3. In the environment variables section, add:
   ```
   SERVER_NAME=your-domain.com
   TURN_SECRET=your-random-secret-key
   TURN_USERNAME=turn_user
   TURN_PASSWORD=your-turn-password
   ```
4. Deploy the stack

### Using Docker Compose

1. **Clone the repository:**
   ```bash
   git clone https://github.com/anykolaiszyn/voice-stack.git
   cd voice-stack
   ```

2. **Run the setup script (REQUIRED - first time only):**
   ```bash
   # Linux/Mac
   chmod +x setup.sh
   ./setup.sh
   
   # Windows
   setup.bat
   ```
   
   **What the setup script does:**
   - Creates `.env` file from template
   - Creates necessary directories
   - Generates cryptographic keys
   - Updates configuration files
   
3. **Edit the `.env` file** with your actual configuration:
   ```bash
   # Edit .env with your preferred editor
   nano .env
   ```

4. **Start the services:**
   ```bash
   docker-compose up -d
   ```

**Important:** Run the setup script only once from the project root directory (`voice-stack/`). It's not needed for Portainer Git deployment.

## Configuration

### Required Environment Variables

- `SERVER_NAME`: Your Matrix server domain (e.g., `matrix.example.com`)
- `TURN_SECRET`: Shared secret for TURN server authentication
- `TURN_USERNAME`: Username for TURN server
- `TURN_PASSWORD`: Password for TURN server

### Optional Environment Variables

- `PUBLIC_BASEURL`: Public URL of your server (defaults to https://SERVER_NAME)
- `POSTGRES_PASSWORD`: Database password (default: `synapse_password`)
- `ENABLE_REGISTRATION`: Enable open registration (default: `true`)

## Services and Ports

| Service | Internal Port | External Port | Description |
|---------|---------------|---------------|-------------|
| Synapse | 8008 | 8008* | Matrix homeserver HTTP |
| Synapse | 8448 | 8448 | Matrix federation |
| Element | 80 | 8081* | Web client |
| Coturn | 3478 | 3478* | TURN/STUN (UDP/TCP) |
| Coturn | 5349 | 5349* | TURN/STUN over TLS |
| Coturn | 49152-49172 | 49152-49172 | TURN relay ports (UDP) |

*Configurable via environment variables: `SYNAPSE_PORT`, `ELEMENT_PORT`, `TURN_PORT`, `TURNS_PORT`

**Default Access URLs:**
- Element Web: `http://your-server:8080`
- Synapse API: `http://your-server:8008`

**Port Conflict Resolution:**
If you encounter port conflicts, customize them in your `.env` file:
```bash
ELEMENT_PORT=8080    # Change if port 8080 is in use
SYNAPSE_PORT=8008    # Change if port 8008 is in use  
TURN_PORT=3478       # Change if port 3478 is in use
TURNS_PORT=5349      # Change if port 5349 is in use
```

**Common Port Alternatives:**
If the default ports are still in use, try these alternatives:
- Element Web: 8081, 8082, 8083, 9080, 9081
- Synapse: 8008, 8009, 8010, 9008, 9009
- TURN: 3478, 3479, 3480, 4478, 4479

## DNS Configuration

For proper operation, configure your DNS:

```
# A record for the main domain
matrix.example.com -> YOUR_SERVER_IP

# SRV records for federation (optional but recommended)
_matrix._tcp.example.com -> matrix.example.com:8448
```

## SSL/TLS Setup

For production use, you'll need SSL certificates. You can:

1. Use a reverse proxy like Nginx or Traefik
2. Use Let's Encrypt with certbot
3. Use your existing SSL certificate setup

Example Nginx configuration:
```nginx
server {
    listen 443 ssl http2;
    server_name matrix.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/private.key;
    
    location / {
        proxy_pass http://localhost:8008;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Firewall Configuration

Open the following ports in your firewall:

```bash
# HTTP/HTTPS (if using reverse proxy)
80/tcp
443/tcp

# Matrix Federation (if not using reverse proxy)
8448/tcp

# TURN/STUN
3478/udp
3478/tcp
5349/udp  
5349/tcp
49152-49172/udp
```

## Creating Admin User

After the first startup, create an admin user:

```bash
# Enter the Synapse container
docker exec -it voice-stack-synapse bash

# Create admin user
register_new_matrix_user -c /data/homeserver.yaml -u admin -p your_password -a http://localhost:8008
```

## Troubleshooting

### Voice/Video Calls Not Working

1. Check TURN server configuration:
   ```bash
   docker logs voice-stack-coturn
   ```

2. Verify TURN server is reachable:
   ```bash
   # Test STUN
   stunclient coturn 3478
   ```

3. Check firewall rules for UDP ports 49152-49172

### Federation Issues

1. Check if port 8448 is accessible from the internet
2. Verify DNS SRV records
3. Test federation with Matrix Federation Tester

### Database Connection Issues

1. Check PostgreSQL logs:
   ```bash
   docker logs voice-stack-postgres
   ```

2. Verify database credentials in environment variables

## Security Notes

- Change default passwords in production
- Use strong secrets for TURN and registration
- Consider disabling open registration after initial setup
- Implement rate limiting if exposed to the internet
- Regular security updates for all components

## Backup

Important directories to backup:
- `./synapse/` - Synapse configuration and signing keys
- `./media_store/` - Uploaded media files
- PostgreSQL database (use pg_dump)

## Support

For issues related to:
- Matrix Synapse: https://github.com/matrix-org/synapse
- Element Web: https://github.com/vector-im/element-web
- Coturn: https://github.com/coturn/coturn

## License

This configuration setup is provided as-is for educational and deployment purposes.

### Portainer Git Integration

For easy deployment and automatic updates using Portainer:

1. **Create Stack from Repository:**
   - Go to Portainer → Stacks → Add stack
   - Choose "Repository" tab
   - Repository URL: `https://github.com/anykolaiszyn/voice-stack.git`
   - Repository reference: `main`
   - Compose path: `docker-compose.portainer.yml`

2. **Configure Environment Variables** (same as above)

3. **Enable Auto-Updates:**
   - Check "Enable auto-update"
   - Set polling interval: `5m`

4. **Optional Webhook Integration:**
   - Enable GitOps updates in Portainer
   - Configure GitHub webhook for instant deployments

See [PORTAINER.md](PORTAINER.md) for detailed Git integration setup.
