# Manual Portainer Deployment - Copy & Paste Method

If Git integration is not working, you can deploy manually by copying and pasting the Docker Compose content.

## Steps:

1. **Go to Portainer** → Stacks → Add stack
2. **Choose "Web editor" tab** (not Repository)
3. **Copy the content below** and paste it into the editor
4. **Set environment variables** (same as Git method)
5. **Deploy the stack**

## Docker Compose Content for Portainer:

```yaml
version: '3.8'

# Voice Stack for Portainer Deployment with Cloudflare
# Optimized for external core-network and Cloudflare tunneling

services:
  postgres:
    image: postgres:15-alpine
    container_name: voice-stack-postgres
    environment:
      POSTGRES_DB: synapse
      POSTGRES_USER: synapse
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-synapse_password}
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - core-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U synapse"]
      interval: 30s
      timeout: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: voice-stack-redis
    volumes:
      - redis_data:/data
    networks:
      - core-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  synapse:
    image: matrixdotorg/synapse:latest
    container_name: voice-stack-synapse
    volumes:
      - ./synapse:/data
      - ./media_store:/media_store
    environment:
      SYNAPSE_SERVER_NAME: ${SERVER_NAME:-matrix.byte-box.org}
      SYNAPSE_REPORT_STATS: "no"
      SYNAPSE_CONFIG_PATH: /data/homeserver.yaml
    depends_on:
      - postgres
      - redis
    networks:
      - core-network
    restart: unless-stopped

  coturn:
    image: coturn/coturn:latest
    container_name: voice-stack-coturn
    # TURN server MUST expose ports - cannot be proxied through Cloudflare
    ports:
      - "${TURN_PORT:-3478}:3478/udp"
      - "${TURN_PORT:-3478}:3478/tcp"
      - "${TURNS_PORT:-5349}:5349/udp"
      - "${TURNS_PORT:-5349}:5349/tcp"
      - "49152-49172:49152-49172/udp"
    volumes:
      - ./coturn/turnserver.conf:/etc/coturn/turnserver.conf:ro
    environment:
      TURN_USERNAME: ${TURN_USERNAME:-turn_user}
      TURN_PASSWORD: ${TURN_PASSWORD:-turn_password}
    networks:
      - core-network
    restart: unless-stopped

  element-web:
    image: vectorim/element-web:latest
    container_name: voice-stack-element
    volumes:
      - ./element/config.json:/app/config.json:ro
    depends_on:
      - synapse
    networks:
      - core-network
    restart: unless-stopped

networks:
  core-network:
    external: true

volumes:
  postgres_data:
  redis_data:
```

## Environment Variables to Set:

**Required:**
```
SERVER_NAME=matrix.byte-box.org
TURN_SECRET=your-random-secret-here
REGISTRATION_SECRET=another-random-secret-here
```

**Optional:**
```
POSTGRES_PASSWORD=secure_db_password
TURN_USERNAME=turn_user
TURN_PASSWORD=secure_turn_password
TURN_PORT=3478
TURNS_PORT=5349
EXTERNAL_IP=auto-detect
```

## Note:
This method bypasses Git integration issues but you'll need to manually update the stack when changes are made to the repository.
