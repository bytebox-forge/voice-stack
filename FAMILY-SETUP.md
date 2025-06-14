# Family Setup Guide - Child-Safe Matrix Accounts

## Overview
This guide helps you create secure Matrix accounts for your children with restricted access to prevent them from joining public rooms or communicating with strangers.

## Step 1: Create Admin Account

First, create an admin account to manage other users:

```bash
# SSH into your Ubuntu server
ssh your-username@192.168.1.92

# Create admin user in the Synapse container
docker exec -it voice-stack-synapse register_new_matrix_user -c /data/homeserver.yaml -u admin -p your_secure_admin_password -a http://localhost:8008
```

## Step 2: Login as Admin

1. Go to `http://192.168.1.92:8080`
2. Click "Sign in"
3. Enter:
   - **Username**: `admin`
   - **Password**: `your_secure_admin_password`
   - **Server**: `matrix.byte-box.org` (or your SERVER_NAME)

## Step 3: Create Child Accounts

### Method 1: Via Admin Interface (Recommended)

1. Login as admin to Element Web
2. Go to Settings (gear icon) → General → Deactivate Account
3. Instead, use the command line method below for better control

### Method 2: Via Command Line (More Control)

```bash
# Create accounts for each child
docker exec -it voice-stack-synapse register_new_matrix_user -c /data/homeserver.yaml -u child1 -p secure_password_1 http://localhost:8008

docker exec -it voice-stack-synapse register_new_matrix_user -c /data/homeserver.yaml -u child2 -p secure_password_2 http://localhost:8008
```

## Step 4: Create Family Rooms

1. **Login as admin** in Element Web
2. **Create a family room**:
   - Click the "+" next to "Rooms"
   - Select "Create Room"
   - Name: "Family Chat"
   - Privacy: "Private room (invite only)"
   - Enable encryption
3. **Invite your children**:
   - Click room settings → People → Invite
   - Enter: `@child1:matrix.byte-box.org`
   - Repeat for other children

## Step 5: Security Settings for Children

### Disable Room Directory Access

Add this to your Element Web config (for child accounts):

```json
{
  "room_directory": {
    "servers": []
  },
  "disable_guests": true,
  "disable_custom_urls": true,
  "disable_3pid_login": true
}
```

### Create Restricted Element Instance

For maximum safety, create a separate Element instance for children:

1. **Create child-safe config file**:

```bash
# Create a restricted config for children
docker exec -it voice-stack-element sh -c 'cat > /app/config-safe.json << EOF
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "https://matrix.byte-box.org",
      "server_name": "matrix.byte-box.org"
    }
  },
  "default_server_name": "matrix.byte-box.org",
  "brand": "Family Chat",
  "disable_custom_urls": true,
  "disable_guests": true,
  "disable_3pid_login": true,
  "room_directory": {
    "servers": []
  },
  "enable_presence_by_hs_url": {
    "https://matrix.byte-box.org": false
  }
}
EOF'
```

2. **Access child-safe version**: `http://192.168.1.92:8080/config-safe.json`

## Step 6: Child Account Guidelines

### For Each Child Account:

1. **Login**: `http://192.168.1.92:8080`
   - Username: `child1` (or their assigned username)
   - Password: Their secure password
   - Server: `matrix.byte-box.org`

2. **Settings to Configure**:
   - **Security & Privacy** → **Disable** "Allow unknown devices"
   - **Security & Privacy** → **Enable** "Never send encrypted messages to unverified devices"
   - **Preferences** → **Disable** "Show advanced settings"

3. **Teach them**:
   - Only join rooms they're invited to
   - Never share personal information
   - Always tell parents about new contacts
   - Don't click suspicious links

## Step 7: Monitoring (Optional)

### Admin Tools

As admin, you can:

1. **Monitor room membership**:
   - View all rooms in server
   - See who's in each room
   - Remove users if needed

2. **Deactivate accounts** if needed:
```bash
# Deactivate a user account
docker exec -it voice-stack-synapse bash
# Inside container:
curl -X POST http://localhost:8008/_synapse/admin/v1/deactivate/@username:matrix.byte-box.org \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"erase": false}'
```

## Step 8: Backup Admin Credentials

**Important**: Save your admin credentials securely!

- **Username**: `admin`
- **Password**: `your_secure_admin_password`
- **Server**: `matrix.byte-box.org`
- **Admin Access**: Can create/delete users, manage rooms

## Family Room Ideas

Create different rooms for different purposes:

- **Family Announcements** (admin-only posting)
- **Family Chat** (general conversation)
- **Homework Help** (school-related discussions)
- **Family Gaming** (if they play games together)
- **Photo Sharing** (family photos and memories)

## Security Best Practices

1. **Regular password changes** (every 3-6 months)
2. **Monitor room memberships** regularly
3. **Educate children** about online safety
4. **Use encrypted rooms** for sensitive conversations
5. **Regular server updates** (update the Docker stack periodically)
6. **Backup important conversations** if needed

## Troubleshooting

### Child can't login:
- Check username format: `@child1:matrix.byte-box.org`
- Verify password
- Ensure account was created successfully

### Child sees public rooms:
- Check Element Web configuration
- Use restricted config file
- Contact admin to verify server settings

### Need to reset child password:
```bash
# Reset password for a user
docker exec -it voice-stack-synapse register_new_matrix_user -c /data/homeserver.yaml -u child1 -p new_password http://localhost:8008
```

## Summary

This setup provides:
- ✅ Private family Matrix server
- ✅ Admin-controlled user creation
- ✅ No public room access
- ✅ Encrypted family communications
- ✅ Monitoring capabilities
- ✅ Complete control over who can join

Your children will only be able to access rooms they're invited to, and you maintain full administrative control over the server.
