#!/bin/bash

# Portainer Git Integration Setup Script
# This script helps configure webhook integration between GitHub and Portainer

echo "=== Portainer Git Integration Setup ==="
echo ""

# Get Portainer details
echo "Please provide your Portainer details:"
read -p "Portainer URL (e.g., https://portainer.example.com): " PORTAINER_URL
read -p "Portainer Username: " PORTAINER_USER
read -s -p "Portainer Password: " PORTAINER_PASS
echo ""

# Get stack details
read -p "Stack name (default: voice-stack): " STACK_NAME
STACK_NAME=${STACK_NAME:-voice-stack}

# Get GitHub details
read -p "GitHub repository (default: anykolaiszyn/voice-stack): " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-anykolaiszyn/voice-stack}

echo ""
echo "=== Configuration Summary ==="
echo "Portainer URL: $PORTAINER_URL"
echo "Stack Name: $STACK_NAME"
echo "GitHub Repository: $GITHUB_REPO"
echo ""

# Instructions for manual setup
echo "=== Manual Setup Instructions ==="
echo ""
echo "1. Create Stack in Portainer:"
echo "   - Go to Stacks → Add stack"
echo "   - Choose 'Repository' tab"
echo "   - Repository URL: https://github.com/$GITHUB_REPO.git"
echo "   - Reference: refs/heads/main"
echo "   - Compose path: docker-compose.portainer.yml"
echo ""
echo "2. Set Environment Variables:"
echo "   - SERVER_NAME=matrix.byte-box.org"
echo "   - TURN_SECRET=$(openssl rand -base64 32)"
echo "   - REGISTRATION_SECRET=$(openssl rand -base64 32)"
echo "   - POSTGRES_PASSWORD=secure_db_password"
echo ""
echo "3. Enable Auto-Updates:"
echo "   - Check 'Enable auto-update'"
echo "   - Set polling interval: 5m"
echo ""
echo "4. Deploy the stack"
echo ""
echo "5. Configure GitHub Webhook (optional):"
echo "   - In Portainer, go to your stack → Editor tab"
echo "   - Enable 'GitOps updates'"
echo "   - Copy the webhook URL"
echo "   - In GitHub: Settings → Webhooks → Add webhook"
echo "   - Paste the webhook URL"
echo "   - Content type: application/json"
echo "   - Trigger: Just the push event"
echo ""
echo "=== Next Steps ==="
echo "1. Follow the manual setup instructions above"
echo "2. Verify all services are running in Portainer"
echo "3. Test connectivity to your Matrix server"
echo "4. Set up DNS records as described in DNS-SETUP.md"
echo ""
echo "For detailed documentation, see PORTAINER.md"
