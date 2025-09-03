# Admin Account Setup Guide

This guide explains how to create the initial admin account on your Matrix server after deployment.

## Prerequisites

- Your Voice Stack is deployed and running
- All containers are healthy (check in Portainer)
- You have your `REGISTRATION_SECRET` from your environment variables

## Step 1: Create Admin Account

### Method 1: Using Docker Exec (Recommended)

```bash
# Enter the Synapse container
docker exec -it voice-stack-synapse bash

# Create the admin account
python -m synapse.app.admin_cmd \
  --config-path /data/homeserver.yaml \
  register_new_matrix_user \
  --user admin \
  --password your_secure_admin_password \
  --admin

# Exit the container
exit
```

### Method 2: Using Registration Secret API

```bash
# Create admin account via API
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "your_secure_admin_password",
    "admin": true,
    "mac": "CALCULATED_MAC"
  }' \
  http://your-server:8008/_synapse/admin/v1/register
```

**Note**: Method 1 is easier as it handles the MAC calculation automatically.

## Step 2: Test Admin Account

1. **Log into Element Web**: `http://your-server:8080`
2. **Enter credentials**:
   - Username: `admin`
   - Password: `your_secure_admin_password`
   - Server: `matrix.your-domain.com` (or your SERVER_NAME)
3. **Verify login successful**

## Step 3: Get Admin Access Token

Once logged in, you need an access token for admin API calls:

### Via Element Web

1. **Open Element Web** in your browser
2. **Log in as admin**
3. **Open Developer Tools** (F12)
4. **Go to Application/Storage tab**
5. **Find "Local Storage"** → your domain
6. **Look for access token** (starts with `syt_`)

### Via API Login

```bash
# Get access token via API
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "type": "m.login.password",
    "user": "admin",
    "password": "your_secure_admin_password"
  }' \
  http://your-server:8008/_matrix/client/r0/login
```

The response will contain your `access_token`.

## Step 4: Create Registration Tokens

Now you can create registration tokens for your family/friends:

```bash
# Create unlimited family token
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "family2024"}' \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/new

# Create limited friend token (10 uses)
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "friends2024", "uses_allowed": 10}' \
  http://your-server:8008/_synapse/admin/v1/registration_tokens/new
```

## Admin Management Tasks

### List All Users

```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  http://your-server:8008/_synapse/admin/v2/users
```

### Deactivate User

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"deactivated": true}' \
  http://your-server:8008/_synapse/admin/v2/users/@username:your-domain.com
```

### List Registration Tokens

```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  http://your-server:8008/_synapse/admin/v1/registration_tokens
```

## Security Best Practices

1. **Strong admin password**: Use a secure, unique password
2. **Secure token storage**: Keep your admin access token secure
3. **Regular token rotation**: Create new tokens and delete old ones
4. **Monitor usage**: Check logs for unusual activity
5. **Backup access**: Keep registration secret safe as backup

## Troubleshooting

### Can't Create Admin Account

- Check that Synapse container is running: `docker ps`
- Verify you're using the correct container name: `voice-stack-synapse`
- Check container logs: `docker logs voice-stack-synapse`

### Admin Login Fails

- Verify username/password are correct
- Check that Element Web is pointing to correct server
- Ensure no typos in SERVER_NAME configuration

### API Calls Fail

- Verify access token is correct and current
- Check that admin account has proper permissions
- Ensure API endpoints are accessible (no firewall blocking)

## Next Steps

After creating your admin account:

1. **Create registration tokens** for family/friends
2. **Configure rooms and spaces** for organization  
3. **Set up family-friendly policies** and room settings
4. **Share registration tokens** securely with family
5. **Monitor and manage** your server regularly

For detailed registration token management, see [`REGISTRATION-TOKENS.md`](REGISTRATION-TOKENS.md).
