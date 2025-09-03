# Registration Tokens Setup Guide

## Overview

This guide explains how to set up registration tokens for your Matrix server. Registration tokens allow you to control who can create accounts on your server by requiring a special token during registration.

**Important**: Registration tokens must be created manually after your server is deployed and running. The Matrix admin API requires authentication, so tokens cannot be created automatically during initial setup.

## Deployment Configuration

### Step 1: Configure Environment Variables

In your Portainer stack or `.env` file, set these variables to enable token-based registration:

```bash
# Server configuration
SERVER_NAME=matrix.your-domain.com
REGISTRATION_SECRET=your_secure_registration_secret_here

# Optional: Set a registration token for reference
# This enables token-based registration but doesn't create the token
REGISTRATION_TOKEN=family2024
```

### Step 2: Deploy Your Stack

Deploy the stack first with token-based registration enabled. This configures Synapse to require tokens but doesn't create them yet.

## Creating Registration Tokens (Manual Process)

### Method 1: Using the Admin API (Recommended)

After your server is running, create tokens via the admin API:

1. **Get your admin access token** (see admin setup guide)
2. **Create a registration token**:

```bash
# Create a token with unlimited uses
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "family2024"}' \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/new

# Create a token with limited uses (5 uses)
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "friends2024", "uses_allowed": 5}' \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/new
```

### Method 2: Using Docker Exec

If you prefer to work directly with the container:

```bash
# Enter the Synapse container
docker exec -it voice-stack-synapse bash

# Create a registration token
python -m synapse.app.admin_cmd registration_token \
  --config-path /data/homeserver.yaml \
  --token family2024 \
  --uses-allowed unlimited

# Or with limited uses
python -m synapse.app.admin_cmd registration_token \
  --config-path /data/homeserver.yaml \
  --token friends2024 \
  --uses-allowed 5
```

## Admin Account Setup

Before creating tokens, you need an admin account. Create one using the registration secret:

```bash
# Enter the Synapse container
docker exec -it voice-stack-synapse bash

# Create admin user
python -m synapse.app.admin_cmd \
  --config-path /data/homeserver.yaml \
  register_new_matrix_user \
  --user admin \
  --password secure_admin_password \
  --admin
```

## Using Registration Tokens

### For Users Registering

1. **Go to your Element Web interface**: `http://your-server:8080`
2. **Click "Create Account"**
3. **Enter registration details**:
   - Username: `newuser`
   - Password: `secure_password`  
   - **Registration Token**: `family2024` (the token you created)
4. **Complete registration**

### Checking Token Status

List all tokens and their usage:

```bash
# Via admin API
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  http://your-server:8008/_synapse/admin/v1/registration_tokens

# Via container
docker exec -it voice-stack-synapse \
  python -m synapse.app.admin_cmd registration_token \
  --config-path /data/homeserver.yaml \
  --list
```

## Managing Tokens

### Creating Different Token Types

```bash
# Unlimited family token
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "family2024"}' \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/new

# Limited friend token (10 uses)
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "friends2024", "uses_allowed": 10}' \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/new

# One-time guest token
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "guest2024", "uses_allowed": 1}' \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/new
```

### Deleting Tokens

```bash
# Delete a token
curl -X DELETE \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/old_token
```

## Security Best Practices

### 1. Token Management

- **Use descriptive names**: `family2024`, `friends2024`, `work2024`
- **Set usage limits**: Prevent token sharing
- **Regular rotation**: Create new tokens periodically

### 2. Token Distribution

- **Secure channels**: Share tokens via secure messaging
- **One-time use**: For temporary access  
- **Family tokens**: Unlimited for trusted family members

### 3. Monitoring

- **Check logs**: Monitor token usage in container logs
- **Regular audits**: Review who has registered recently
- **Revoke unused**: Remove tokens that aren't needed

## Integration with Family Setup

Registration tokens work perfectly with family-friendly configurations:

1. **Admin account**: Create via registration secret (no token needed)
2. **Family tokens**: Unlimited tokens for family members
3. **Friend tokens**: Limited tokens for family friends  
4. **Temporary tokens**: One-time tokens for specific people

## Quick Setup Summary

1. **Deploy your stack** with `REGISTRATION_TOKEN` environment variable set
2. **Create admin account** using registration secret
3. **Get admin access token** for API calls
4. **Create registration tokens** via admin API or container commands
5. **Share tokens** with family/friends securely
6. **Monitor usage** through logs and admin API

## Troubleshooting

### Token Not Working

- Ensure Synapse has been restarted after config changes
- Check that `registration_requires_token: true` is in homeserver.yaml
- Verify the token wasn't already used up

### Can't Create Tokens

- Check that Synapse container is running
- Verify admin API is accessible
- Ensure you have a valid admin access token

### Users Still Can't Register

- Confirm `enable_registration: true` is set in homeserver.yaml
- Check Element Web is pointing to correct server
- Verify no firewall is blocking registration API

This manual token system gives you complete control over who can join your family Matrix server while maintaining security.
