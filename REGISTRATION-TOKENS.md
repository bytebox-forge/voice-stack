# Registration Tokens Setup Guide

## Overview

This guide explains how to set up registration tokens (keys) for your Matrix server. Registration tokens allow you to control who can create accounts on your server by requiring a special token during registration.

## Environment Variable Configuration

### Step 1: Configure Your .env File

Copy `.env.example` to `.env` and configure the registration token settings:

```bash
# Copy the example file
cp .env.example .env
```

Edit your `.env` file and set these variables:

```bash
# Enable registration with tokens
REGISTRATION_REQUIRES_TOKEN=true

# Pre-create registration tokens (comma-separated list)
# Format: "token1:uses,token2:uses" or "token1,token2" (unlimited uses)
# Examples:
REGISTRATION_TOKENS="family2024:5,friends2024:10,relatives2024"

# Other settings
REGISTRATION_SECRET=your_secure_registration_secret_here
SERVER_NAME=matrix.your-domain.com
```

### Token Format Examples

```bash
# Single unlimited token
REGISTRATION_TOKENS="family2024"

# Multiple tokens with usage limits
REGISTRATION_TOKENS="family2024:5,friends2024:10,school2024:3"

# Mix of limited and unlimited tokens
REGISTRATION_TOKENS="family2024,friends2024:10,temp2024:1"
```

## How It Works

1. **Token Creation**: Tokens are automatically created when the container starts
## Deployment Steps

### Step 1: Update Configuration

1. Edit your `.env` file with the token settings above
2. Commit and push to your git repository:

```bash
git add .env
git commit -m "Configure registration tokens"
git push origin main
```

### Step 2: Deploy via Portainer

1. **Go to Portainer** → **Stacks** → **voice-stack**
2. **Click "Update Stack"** (this pulls the latest changes)
3. **Review environment variables** in the stack configuration
4. **Click "Update"** to restart with new settings

### Step 3: Verify Token Creation

1. **Check container logs**:
   - Portainer → Containers → `voice-stack-synapse`
   - Click **Logs** tab
   - Look for messages like: `Creating token 'family2024' with 5 uses...`

## Using Registration Tokens

### For Users Registering

1. **Go to your Element Web interface**: `http://your-server:8080`
2. **Click "Create Account"**
3. **Enter registration details**:
   - Username: `newuser`
   - Password: `secure_password`
   - **Registration Token**: `family2024` (the token you provided)
4. **Complete registration**

### Token Status

Tokens are automatically managed:
- ✅ **Valid tokens**: Allow registration
- ❌ **Expired tokens**: Registration fails
- ⚠️ **Used up tokens**: No more registrations allowed

## Managing Tokens

### Via Environment Variables (Recommended)

Update your `.env` file and redeploy:

```bash
# Add new tokens
REGISTRATION_TOKENS="family2024:5,friends2024:10,newtoken2024:3"

# Commit and redeploy
git add .env && git commit -m "Add new registration tokens" && git push
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

Registration tokens work perfectly with the family setup:

1. **Admin account**: Create via command line (no token needed)
2. **Family tokens**: Unlimited tokens for family members
3. **Friend tokens**: Limited tokens for family friends
4. **Temporary tokens**: One-time tokens for specific people

```bash
# Example family configuration
REGISTRATION_REQUIRES_TOKEN=true
REGISTRATION_TOKENS="family2024,friends2024:10,playdates2024:5"
```

This setup provides:
- ✅ **Family control**: Only authorized people can register
- ✅ **Flexible access**: Different token types for different groups
- ✅ **Easy management**: Environment variable configuration
- ✅ **Security**: No public registration, controlled access
   ```powershell
   .\manage-tokens.ps1 list
   ```

## Troubleshooting

### Token Not Working
- Ensure Synapse has been restarted after config changes
- Check that `registration_requires_token: true` is in homeserver.yaml
- Verify the token wasn't already used up

### Can't Create Tokens
- Check that Synapse container is running
- Verify admin API is accessible
- Check Docker/Portainer connectivity

### Users Still Can't Register
- Confirm `enable_registration: true` is set
- Check Element Web is pointing to correct server
- Verify no firewall blocking registration API

This system gives you complete control over who can join your family Matrix server while keeping it secure from random registrations.
