# Portainer Git Repository Configuration

This directory contains configuration files for deploying the Voice Stack using Portainer's Git integration feature.

## Repository Setup in Portainer

Use these settings when creating a stack from Git repository in Portainer:

### Repository Configuration
```
Repository URL: https://github.com/anykolaiszyn/voice-stack.git
Repository reference: main
Compose path: docker-compose.portainer.yml
```

**Important:** Use `main` (not `refs/heads/main`) for the repository reference.

### Environment Variables Template
Copy the required environment variables from `.env.example` into Portainer's environment variables section.

### Auto-Update Configuration
```
Enable auto-update: Yes
Polling interval: 5m (or your preferred interval)
```

## Webhook Configuration

If you want automatic deployments when pushing to GitHub:

1. **Generate Webhook in Portainer:**
   - Go to your stack → Editor tab
   - Enable "GitOps updates"
   - Copy the webhook URL

2. **Configure GitHub Webhook:**
   - Repository Settings → Webhooks → Add webhook
   - Paste the Portainer webhook URL
   - Content type: application/json
   - Trigger: Just the push event

## Benefits

- ✅ Automatic updates when code changes
- ✅ Version control for your deployment
- ✅ Easy rollback to previous versions
- ✅ Team collaboration through Git
- ✅ Centralized configuration management
