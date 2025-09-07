# Portainer Deployment Guide

This guide covers deploying the Voice Stack using Portainer's web interface, making it accessible for users who prefer GUI-based deployment over command-line tools.

## Prerequisites

- Portainer CE/BE running and accessible
- Docker host with sufficient resources (4GB+ RAM, 20GB+ storage)
- Domain name with SSL certificates configured in your reverse proxy
- Basic understanding of Docker environment variables

## Step 1: Create Required Volumes

Before deploying the stack, create the necessary external volumes. You can do this either through Portainer's web interface or via command line.

### Via Portainer Web Interface

1. Navigate to **Volumes** in the left sidebar
2. Click **Add Volume** 
3. Create these volumes one by one:
   - `voice-stack_postgres_data`
   - `voice-stack_synapse_data` 
   - `voice-stack_media_store`
   - `voice-stack_coturn_data`

### Via Command Line (Alternative)

On Windows:
```powershell
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_coturn_data
```

On Linux/macOS:
```bash
docker volume create voice-stack_postgres_data
docker volume create voice-stack_synapse_data
docker volume create voice-stack_media_store
docker volume create voice-stack_coturn_data
```

## Step 2: Deploy the Stack

1. **Navigate to Stacks**: In Portainer, go to **Stacks** in the left sidebar

2. **Add New Stack**: Click **Add Stack** button

3. **Configure Stack**:
   - **Name**: `voice-stack`
   - **Build method**: Select **Web editor**

4. **Copy Docker Compose**: Copy the entire contents of `docker-compose.yml` into the web editor

5. **Configure Environment Variables**: Scroll down to **Environment variables** section and add:

   ```
   SYNAPSE_SERVER_NAME=matrix.yourdomain.com
   POSTGRES_PASSWORD=your_strong_password_here
   REGISTRATION_SHARED_SECRET=your_registration_secret_here
   COTURN_STATIC_AUTH_SECRET=your_turn_secret_here
   ```

   **Generate Strong Secrets**: Use a password generator or command line:
   ```bash
   # Generate 32-character base64 secrets
   openssl rand -base64 32
   ```

6. **Optional Environment Variables** (use defaults if unsure):
   ```
   POSTGRES_DB=synapse
   POSTGRES_USER=synapse
   SYNAPSE_REPORT_STATS=no
   ENABLE_REGISTRATION=false
   ALLOW_GUEST_ACCESS=false
   URL_PREVIEW_ENABLED=true
   SYNAPSE_PORT=8008
   ELEMENT_PORT=8080
   SYNAPSE_ADMIN_PORT=8082
   WELL_KNOWN_PORT=8090
   COTURN_PORT=3478
   COTURN_MIN_PORT=49152
   COTURN_MAX_PORT=49172
   COTURN_EXTERNAL_IP=auto
   ELEMENT_VERSION=v1.11.86
   ELEMENT_JITSI_DOMAIN=meet.jit.si
   LOG_LEVEL=INFO
   ```

7. **Deploy**: Click **Deploy the stack**

## Step 3: Monitor Deployment

1. **Check Container Status**: After deployment, go to **Containers** to see all `voice-stack-*` containers
2. **Expected Containers**:
   - `voice-stack-postgres` (should be healthy)
   - `voice-stack-synapse` (may take 1-2 minutes to start)
   - `voice-stack-element` 
   - `voice-stack-coturn`
   - `voice-stack-synapse-admin`
   - `voice-stack-well-known`

3. **Check Logs**: Click on any container to view logs if there are issues

## Step 4: Create Admin User

Once all containers are running, create your first admin user:

1. **Access Container Console**: In Portainer, go to the `voice-stack-synapse` container
2. **Open Console**: Click **Console** and select **Connect** with `/bin/bash`
3. **Register Admin User**: Run:
   ```bash
   register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008
   ```
4. **Follow Prompts**: Enter username, password, and confirm admin privileges

### Alternative: Using Host Command Line

If you have access to the Docker host:

On Windows:
```powershell
docker exec -it voice-stack-synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008
```

On Linux/macOS:
```bash
docker exec -it voice-stack-synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008
```

## Step 5: Configure Reverse Proxy

Configure your reverse proxy (Nginx Proxy Manager, Cloudflare Tunnel, etc.) to route:

| External URL | Internal Target | Purpose |
|-------------|----------------|---------|
| `https://matrix.yourdomain.com` | `http://docker-host:8008` | Matrix API |
| `https://chat.yourdomain.com` | `http://docker-host:8080` | Element Web |
| `https://matrix.yourdomain.com/.well-known/matrix/*` | `http://docker-host:8090/.well-known/matrix/*` | Discovery |

**Important**: 
- Replace `docker-host` with your actual Docker host IP
- Ensure SSL certificates are valid for your domains
- The well-known endpoint is critical for Element Call functionality

## Step 6: Test Access

1. **Element Web**: Visit `https://chat.yourdomain.com`
2. **Login**: Use the admin credentials created in Step 4
3. **Synapse Admin**: Access `http://docker-host:8082` (internal network only)

## Troubleshooting

### Container Won't Start

1. **Check Logs**: In Portainer, click the container and view logs
2. **Common Issues**:
   - Missing environment variables
   - Volume permission issues  
   - Port conflicts

### Element Web Shows "Failed to connect"

1. **Check well-known endpoint**: `curl https://matrix.yourdomain.com/.well-known/matrix/client`
2. **Verify reverse proxy**: Ensure Matrix API is accessible
3. **Check container logs**: Look at `voice-stack-element` logs

### Element Call Not Working

1. **Verify well-known**: Should return correct homeserver URL
2. **Check TURN server**: `voice-stack-coturn` container should be running
3. **Firewall**: Ensure UDP ports 49152-49172 are open
4. **External IP**: Set `COTURN_EXTERNAL_IP` if auto-detection fails

### Database Connection Issues

1. **Check PostgreSQL**: Ensure `voice-stack-postgres` is healthy
2. **Verify passwords**: Ensure `POSTGRES_PASSWORD` matches in environment
3. **Volume persistence**: Verify external volumes are created and mounted

## Stack Management

### Updating the Stack

1. **Edit Stack**: In Portainer, go to **Stacks** → **voice-stack** → **Editor**
2. **Update Configuration**: Modify environment variables or compose file
3. **Redeploy**: Click **Update the stack**

### Backup Considerations

- **Database**: Regularly backup the `voice-stack_postgres_data` volume
- **Media**: Backup the `voice-stack_media_store` volume  
- **Configuration**: Export stack configuration from Portainer

### Scaling/Performance

- **Memory**: Increase Docker host RAM for better performance
- **Storage**: Monitor volume usage and expand as needed
- **Network**: Ensure adequate bandwidth for media streams

## Security Notes

- **Internal Ports**: Services bind to `127.0.0.1` (localhost only)
- **Secrets**: Generate unique, strong secrets for each deployment
- **Updates**: Regularly update container images for security patches
- **Firewall**: Only expose necessary ports through reverse proxy

## Support

For issues specific to this Portainer deployment:

1. **Check Portainer logs**: Container and stack logs
2. **Verify environment**: Ensure all required variables are set
3. **Test connectivity**: Use Portainer's container console for debugging
4. **Consult documentation**: Refer to main README.md for detailed troubleshooting

This deployment method provides a user-friendly alternative to command-line deployment while maintaining the same functionality and security features.
