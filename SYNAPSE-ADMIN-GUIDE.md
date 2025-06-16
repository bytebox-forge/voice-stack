# Synapse Admin Panel Guide

This guide covers how to use the Synapse Admin web interface included in your voice-stack deployment.

## 📋 Table of Contents
- [Accessing the Admin Panel](#accessing-the-admin-panel)
- [First-Time Setup](#first-time-setup)
- [Creating Your First Admin User](#creating-your-first-admin-user)
- [Admin Panel Features](#admin-panel-features)
- [Common Admin Tasks](#common-admin-tasks)
- [User Management](#user-management)
- [Room Management](#room-management)
- [Server Statistics](#server-statistics)
- [Troubleshooting](#troubleshooting)

## 🌐 Accessing the Admin Panel

After deploying your voice-stack:

1. **URL**: `http://your-server:8082` (default port)
2. **Custom Port**: Check your `.env` file for `SYNAPSE_ADMIN_PORT` if you changed it
3. **Local Testing**: `http://localhost:8082`

## 🚀 First-Time Setup

### Step 1: Create Your First Admin User

You need an admin user to access the admin panel. Choose one of these methods:

#### Method A: Using the Built-in Registration Script (Recommended)
```bash
# Connect to your Synapse container
docker exec -it voice-stack-synapse-1 bash

# Create admin user with the registration script
register_new_matrix_user -u admin -p YourStrongPassword -a -c /data/homeserver.yaml http://localhost:8008
```

#### Method B: Promote an Existing User
If you already have a regular user account:

```bash
# Get your access token first (login via Element, then check developer tools)
# Replace YOUR_ACCESS_TOKEN and @youruser:yourdomain.com

curl -X PUT "http://your-server:8008/_synapse/admin/v1/users/@youruser:yourdomain.com/admin" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"admin": true}'
```

#### Method C: Database Direct Edit (Advanced)
```bash
# Connect to PostgreSQL container
docker exec -it voice-stack-postgres-1 psql -U synapse -d synapse

# Make user admin (replace 'youruser' with actual username)
UPDATE users SET admin = 1 WHERE name = '@youruser:yourdomain.com';
\q
```

### Step 2: Login to Admin Panel

1. Go to `http://your-server:8082`
2. **Homeserver URL**: `http://your-server:8008` (or your actual Synapse URL)
3. **Username**: Your admin username (e.g., `admin` or `@admin:yourdomain.com`)
4. **Password**: Your admin password

## 🛠️ Admin Panel Features

### Main Dashboard
- **Server Information**: Version, uptime, database info
- **User Count**: Total registered users
- **Room Count**: Total rooms on your server
- **Federation Status**: Connected servers

### Navigation Menu
- **Users**: Manage all user accounts
- **Rooms**: View and moderate rooms
- **Reports**: Handle user reports and abuse
- **Federation**: Manage server connections
- **Device Management**: View user devices and sessions

## 👥 User Management

### View All Users
1. Click **"Users"** in the sidebar
2. See list of all registered users
3. Filter by admin status, deactivated users, etc.

### Create New User
1. **Users** → **"Add User"** button
2. Fill in:
   - **User ID**: `@username:yourdomain.com`
   - **Display Name**: Optional friendly name
   - **Password**: Strong password
   - **Admin**: Check if making admin
   - **Send notification**: Uncheck to skip welcome email

### Edit Existing User
1. **Users** → Click on username
2. Available actions:
   - **Deactivate/Reactivate**: Disable/enable account
   - **Make Admin**: Grant admin privileges
   - **Reset Password**: Force password change
   - **View Devices**: See logged-in sessions
   - **View User Info**: Registration date, last seen, etc.

### Bulk Actions
- **Export Users**: Download CSV of all users
- **Deactivate Multiple**: Select and bulk deactivate

## 🏠 Room Management

### View All Rooms
1. Click **"Rooms"** in sidebar
2. See all rooms on your server (public and private)
3. View member counts, creation dates

### Room Details
Click any room to see:
- **Members**: All users in the room
- **Settings**: Room name, topic, encryption status
- **Events**: Recent message history
- **State Events**: Technical room state information

### Room Moderation
- **Delete Room**: Permanently remove room and all messages
- **Block Room**: Prevent new users from joining
- **Purge History**: Delete message history before specific date
- **Remove User**: Kick users from rooms

### Room Creation
1. **Rooms** → **"Add Room"**
2. Configure:
   - **Room Name**: Display name
   - **Room Alias**: `#roomname:yourdomain.com`
   - **Topic**: Room description
   - **Visibility**: Public or private
   - **Encryption**: Enable E2E encryption

## 📊 Server Statistics

### Resource Usage
- **Memory Usage**: Current RAM consumption
- **CPU Usage**: Server load
- **Database Size**: Storage used by Synapse database
- **Media Storage**: Files and images uploaded

### User Activity
- **Daily Active Users**: Users active in last 24h
- **Monthly Active Users**: Users active in last 30 days
- **New Registrations**: Recent account creations

### Federation Stats
- **Known Servers**: Other Matrix servers you're connected to
- **Incoming/Outgoing Events**: Federation message counts

## 🔧 Common Admin Tasks

### 1. Handling User Reports
1. **Reports** section shows abuse reports
2. Review reported content
3. Take action: warn user, deactivate account, delete content

### 2. Managing Federation
1. **Federation** → **"Destination Rooms"**
2. See which remote servers you're connected to
3. Block problematic servers if needed

### 3. Media Management
1. **Users** → Select user → **"Media"**
2. View all files uploaded by user
3. Delete inappropriate content
4. Set media retention policies

### 4. Device/Session Management
1. **Users** → Select user → **"Devices"**
2. See all logged-in sessions
3. Force logout from specific devices
4. Useful for security incidents

### 5. Backup and Maintenance
- **Export user data** before major changes
- **Monitor server stats** for performance issues
- **Review federation connections** regularly

## 🐛 Troubleshooting

### Can't Access Admin Panel
1. **Check port**: Verify `SYNAPSE_ADMIN_PORT` in `.env`
2. **Check container**: `docker ps | grep synapse-admin`
3. **Check logs**: `docker logs synapse-admin`

### Can't Login
1. **Verify admin status**: User must be admin
2. **Check homeserver URL**: Should be `http://your-server:8008`
3. **Try different user**: Create new admin user

### Admin Panel Shows Errors
1. **Check Synapse connection**: Admin panel needs to reach Synapse
2. **Verify network**: Containers must be on same network
3. **Check Synapse logs**: `docker logs voice-stack-synapse-1`

### Federation Issues
1. **DNS**: Ensure proper DNS setup for your domain
2. **Firewall**: Ports 8008 and 8448 must be open
3. **SSL**: HTTPS required for federation (use reverse proxy)

## 🔐 Security Best Practices

### Admin Account Security
- **Strong Passwords**: Use long, complex passwords
- **Limited Admin Users**: Only create admins when necessary
- **Regular Review**: Audit admin users periodically

### User Management
- **Monitor New Users**: Review registrations if open
- **Handle Reports Quickly**: Address abuse reports promptly
- **Regular Cleanup**: Deactivate unused accounts

### Server Security
- **Keep Updated**: Update Synapse regularly
- **Monitor Logs**: Watch for suspicious activity
- **Backup Regularly**: Export important data

## 📚 Additional Resources

- **Synapse Admin API Docs**: https://matrix-org.github.io/synapse/latest/admin_api/
- **Matrix Specification**: https://spec.matrix.org/
- **Synapse Documentation**: https://matrix-org.github.io/synapse/latest/

## 🆘 Getting Help

If you encounter issues:
1. Check container logs: `docker logs synapse-admin`
2. Verify network connectivity between containers
3. Review your `.env` configuration
4. Check Matrix community support channels

---

**Note**: The admin panel is a powerful tool. Be careful when making changes, especially deleting users or rooms, as these actions are often irreversible.
