# Portainer Deployment Guide

## Quick Deploy in Portainer

### Step 1: Create Stack
1. Open Portainer web interface
2. Go to "Stacks" → "Add stack"
3. Name your stack: `voice-stack`

### Step 2: Environment Variables
Add these environment variables in Portainer:

**Required:**
```
SERVER_NAME=your-domain.com
TURN_SECRET=your-random-secret-key-here
REGISTRATION_SECRET=another-random-secret-here
```

**Optional:**
```
POSTGRES_PASSWORD=secure_db_password
TURN_USERNAME=turn_user
TURN_PASSWORD=secure_turn_password
SYNAPSE_PORT=8008
FEDERATION_PORT=8448
ELEMENT_PORT=8080
TURN_PORT=3478
TURNS_PORT=5349
```

### Step 3: Deploy
1. Copy the contents of `docker-compose.portainer.yml`
2. Paste into the web editor in Portainer
3. Click "Deploy the stack"

### Step 4: Access Services
- **Element Web**: http://your-server:8080
- **Matrix API**: http://your-server:8008
- **Federation**: http://your-server:8448

### Step 5: Create Admin User (Optional)
1. Go to "Containers" in Portainer
2. Open console for `voice-stack_synapse_1`
3. Run:
   ```bash
   register_new_matrix_user -c /data/homeserver.yaml -u admin -p admin_password -a http://localhost:8008
   ```

## Security Notes for Production

1. **Change all default passwords**
2. **Use strong random secrets** (at least 32 characters)
3. **Set up SSL/TLS** with reverse proxy
4. **Configure firewall** properly
5. **Regular backups** of volumes

## Firewall Ports
```
8008/tcp  - Matrix HTTP
8448/tcp  - Matrix Federation
8080/tcp  - Element Web
3478/udp  - TURN/STUN
3478/tcp  - TURN/STUN
5349/udp  - TURN/STUN over TLS
5349/tcp  - TURN/STUN over TLS
49152-49172/udp - TURN relay ports
```

## Volumes Created
- `voice-stack_postgres_data` - Database storage
- `voice-stack_synapse_data` - Synapse configuration
- `voice-stack_media_store` - Uploaded media files
- `voice-stack_redis_data` - Redis cache

## Troubleshooting

### Check Container Logs
In Portainer, go to Containers → Select container → Logs

### Common Issues
1. **Can't connect**: Check firewall and port mapping
2. **Voice calls fail**: Verify TURN server ports are open
3. **Registration fails**: Check REGISTRATION_SECRET is set
4. **Database errors**: Check POSTGRES_PASSWORD matches

### Generate Strong Secrets
```bash
# Use this command to generate random secrets
openssl rand -base64 32
```

## Git Repository Integration

Portainer supports deploying stacks directly from Git repositories, which provides automatic updates and version control for your deployments.

### Method 1: Git Repository Deployment (Recommended)

#### Step 1: Setup Git Repository Connection
1. Open Portainer web interface
2. Go to **"Stacks"** → **"Add stack"**
3. Choose **"Repository"** tab
4. Configure repository settings:

**Repository Configuration:**
```
Repository URL: https://github.com/anykolaiszyn/voice-stack.git
Repository reference: main
Compose path: docker-compose.portainer.yml
```

**Important:** Use `main` (not `refs/heads/main`) for the repository reference.

**Authentication (if needed):**
- For public repos: Leave authentication empty
- For private repos: Add your GitHub credentials or use Personal Access Token

#### Step 2: Configure Auto-Updates
```
Auto-update settings:
✓ Enable auto-update
Polling interval: 5m
Webhook: (optional) https://your-portainer-url/api/webhooks/your-webhook-id
```

#### Step 3: Environment Variables
Set the same environment variables as listed in the Quick Deploy section:

**Required:**
```
SERVER_NAME=matrix.byte-box.org
TURN_SECRET=your-random-secret-key-here
REGISTRATION_SECRET=another-random-secret-here
```

**Optional:**
```
POSTGRES_PASSWORD=secure_db_password
TURN_USERNAME=turn_user
TURN_PASSWORD=secure_turn_password
TURN_PORT=3478
TURNS_PORT=5349
EXTERNAL_IP=your-server-ip
```

#### Step 4: Deploy from Repository
1. Click **"Deploy the stack"**
2. Portainer will clone the repository and deploy using `docker-compose.portainer.yml`
3. Monitor deployment in the **"Stacks"** section

### Method 2: Webhook-Based Auto-Updates

For automatic updates when you push changes to GitHub:

#### Setup GitHub Webhook
1. In your GitHub repository, go to **Settings** → **Webhooks**
2. Click **"Add webhook"**
3. Configure:
   ```
   Payload URL: https://your-portainer-url/api/webhooks/your-webhook-id
   Content type: application/json
   Secret: your-webhook-secret
   Events: Just the push event
   ```

#### Get Portainer Webhook URL
1. In Portainer, go to your stack
2. Click **"Editor"** tab
3. Enable **"GitOps updates"**
4. Copy the generated webhook URL

### Benefits of Git Integration

✅ **Version Control**: Track all changes to your configuration
✅ **Automatic Updates**: Deploy changes by pushing to Git
✅ **Rollback**: Easy rollback to previous versions
✅ **Team Collaboration**: Multiple team members can contribute
✅ **Audit Trail**: See who made what changes and when
✅ **Backup**: Your configuration is safely stored in Git

### Git Workflow Example

```bash
# 1. Make changes to your local repository
git clone https://github.com/anykolaiszyn/voice-stack.git
cd voice-stack

# 2. Edit configuration files
nano docker-compose.portainer.yml
nano .env.example

# 3. Commit and push changes
git add .
git commit -m "Update Matrix server configuration"
git push origin main

# 4. Portainer automatically detects changes and redeploys
# (if auto-update is enabled or webhook is configured)
```

### Repository Structure for Portainer

Your repository should be organized like this:
```
voice-stack/
├── docker-compose.yml              # Standard deployment
├── docker-compose.portainer.yml    # Portainer deployment
├── docker-compose.cloudflare.yml   # Cloudflare tunnel deployment
├── .env.example                    # Environment variables template
├── synapse/
│   ├── homeserver.yaml            # Matrix Synapse configuration
│   └── log.config                 # Logging configuration
├── coturn/
│   └── turnserver.conf            # TURN server configuration
├── element/
│   └── config.json                # Element web client configuration
├── README.md                      # Main documentation
├── PORTAINER.md                   # This file
└── DNS-SETUP.md                   # DNS and Cloudflare setup
```

### Troubleshooting Git Integration

**Common Issues:**

1. **Repository not found**: Check URL and authentication
2. **File not found**: Verify `docker-compose.portainer.yml` exists in repo
3. **Auto-update not working**: Check polling interval and webhook configuration
4. **Permission denied**: Verify Git credentials or use Personal Access Token

**Debug Steps:**
1. Check Portainer logs: **Home** → **Events**
2. Verify repository access: Try cloning manually
3. Test webhook: Use GitHub's webhook testing feature
4. Check environment variables: Ensure all required variables are set

### Common Git Repository Errors

#### "Reference not found" Error
**Problem:** Unable to clone git repository: reference not found

**Solutions:**
1. **Use correct branch name:** Use `main` instead of `refs/heads/main`
2. **Check repository accessibility:** Ensure the repository is public or credentials are correct
3. **Verify branch exists:** Confirm the branch name matches exactly

**Correct Configuration:**
```
Repository URL: https://github.com/anykolaiszyn/voice-stack.git
Repository reference: main
Compose path: docker-compose.portainer.yml
```

#### "File not found" Error
**Problem:** docker-compose.portainer.yml not found

**Solutions:**
1. **Check compose path:** Ensure it's exactly `docker-compose.portainer.yml`
2. **Verify file exists:** Check that the file is in the repository root
3. **Case sensitivity:** Ensure exact filename match

#### Authentication Issues
**Problem:** Repository access denied

**Solutions:**
1. **Public repository:** Leave authentication fields empty
2. **Private repository:** Use GitHub Personal Access Token
3. **Token permissions:** Ensure token has repository read access

#### Network/Connectivity Issues
**Problem:** Connection timeout or network errors

**Solutions:**
1. **Check Portainer network:** Ensure Portainer can reach GitHub
2. **Firewall settings:** Allow outbound HTTPS connections
3. **DNS resolution:** Verify GitHub.com resolves correctly

**Test connectivity from Portainer host:**
```bash
# Test from Portainer server
curl -I https://github.com/anykolaiszyn/voice-stack.git
nslookup github.com
```
