# Family-Safe Troubleshooting Guide

This guide helps resolve common issues with the family-safe configuration of your Matrix server.

## Problem: Can Still Register with External Email

### Symptoms
- Users can register with Gmail or other external email addresses
- Registration works even when tokens aren't provided
- Public registration appears to be enabled

### Root Cause
This usually happens when:
1. The homeserver configuration wasn't applied properly during setup
2. Registration settings are being overridden by default values
3. The container was started before the configuration was complete

### Solution

**Step 1: Verify Current Configuration**

Check your homeserver.yaml file:
```bash
# Enter the Synapse container
docker exec -it voice-stack-synapse bash

# Check the current registration settings
grep -A5 -B5 "enable_registration" /data/homeserver.yaml
grep -A5 -B5 "registration_requires_token" /data/homeserver.yaml
```

**Step 2: Restart the Stack**

If settings are incorrect, restart the entire stack:
```bash
# In Portainer: Stack → voice-stack → Stop → Start
# Or via command line:
docker-compose -f docker-compose.portainer-standalone.yml down
docker-compose -f docker-compose.portainer-standalone.yml up -d
```

**Step 3: Manually Fix Configuration**

If restart doesn't work, manually edit the homeserver.yaml:
```bash
# Enter the container
docker exec -it voice-stack-synapse bash

# Edit the homeserver configuration
echo "enable_registration: false" >> /data/homeserver.yaml
echo "registration_requires_token: true" >> /data/homeserver.yaml

# Restart Synapse
supervisorctl restart synapse
```

## Problem: Still See Public Spaces/Rooms

### Symptoms
- Element Web shows public spaces from matrix.org
- Can browse/join public rooms from other servers
- Room directory shows external rooms

### Root Cause
1. Element Web is using default configuration that connects to matrix.org
2. Federation isn't properly disabled in Synapse
3. Room directory is showing federated results

### Solution

**Method 1: Manual Element Web Configuration (Recommended)**

1. **Access Element Web**: Go to `http://your-server:8080`
2. **Before logging in**, click the "Edit" button next to the server field
3. **Change server settings**:
   - Homeserver URL: `http://your-server-ip:8008`
   - Identity Server: Leave empty or use `https://vector.im`
4. **Save settings** and proceed with login

**Method 2: Container-based Configuration**

If you need to enforce the configuration, you can manually configure Element Web:

```bash
# Enter Element Web container
docker exec -it voice-stack-element sh

# Create configuration directory
mkdir -p /app/config

# Create family-safe configuration
cat > /app/config/config.json << 'EOF'
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "http://your-server-name:8008",
      "server_name": "your-server-name"
    }
  },
  "disable_custom_urls": true,
  "disable_guests": true,
  "room_directory": {
    "servers": ["your-server-name"]
  },
  "default_federate": false
}
EOF

# Restart the container
exit
docker restart voice-stack-element
```

**Method 3: Verify Synapse Federation Settings**

Ensure Synapse is properly configured to block federation:

```bash
# Enter Synapse container
docker exec -it voice-stack-synapse bash

# Check federation settings
grep -i federation /data/homeserver.yaml
grep -i "public_rooms" /data/homeserver.yaml

# If settings are missing, add them:
echo "federation_domain_whitelist: []" >> /data/homeserver.yaml
echo "allow_public_rooms_over_federation: false" >> /data/homeserver.yaml
echo "allow_public_rooms_without_auth: false" >> /data/homeserver.yaml

# Restart Synapse
exit
docker restart voice-stack-synapse
```

## Problem: Users Can Find Each Other Globally

### Symptoms
- User directory shows users from other servers
- Can search for users on matrix.org
- Profile lookup works for external users

### Solution

Add user directory restrictions:
```bash
# Enter Synapse container
docker exec -it voice-stack-synapse bash

# Disable user directory
cat >> /data/homeserver.yaml << 'EOF'
user_directory:
  enabled: false
  search_all_users: false

limit_profile_requests_to_users_who_share_rooms: true
require_auth_for_profile_requests: true
allow_profile_lookup_over_federation: false
EOF

# Restart Synapse
supervisorctl restart synapse
```

## Complete Reset Procedure

If all else fails, do a complete configuration reset:

**Step 1: Stop the Stack**
```bash
# In Portainer or via command line
docker-compose down
```

**Step 2: Remove Configuration Data**
```bash
# Remove only configuration (keeps user data)
docker volume rm voice-stack_synapse_data voice-stack_element_config
```

**Step 3: Update Environment Variables**

Ensure your environment variables are set correctly:
```bash
SERVER_NAME=your-domain.com
REGISTRATION_TOKEN=  # Leave empty for no public registration
REGISTRATION_SECRET=your_secure_secret
```

**Step 4: Restart Stack**
```bash
# Restart - this will regenerate configuration
docker-compose up -d
```

## Verification Checklist

After applying fixes, verify everything is working:

### ✅ Registration Test
1. Go to Element Web
2. Try to register without a token → Should fail
3. Try with external email → Should fail
4. Only admin registration should work

### ✅ Federation Test  
1. Search for users from matrix.org → Should find none
2. Try to join public rooms → Should see none from external servers
3. Room directory should only show local rooms

### ✅ Privacy Test
1. User directory should be empty or only show local users
2. Profile lookup for external users should fail
3. No public spaces should be visible

## Emergency Admin Access

If you get locked out:

```bash
# Create emergency admin account
docker exec -it voice-stack-synapse bash
python -m synapse.app.admin_cmd \
  --config-path /data/homeserver.yaml \
  register_new_matrix_user \
  --user emergency \
  --password emergency_password \
  --admin
```

## Prevention

To prevent these issues:
1. Always set `REGISTRATION_TOKEN=""` (empty) for family-safe mode
2. Wait for all containers to be healthy before testing
3. Check container logs for configuration errors
4. Verify environment variables are set correctly in Portainer

## Getting Help

If issues persist:
1. Check all container logs in Portainer
2. Verify environment variables are correct
3. Ensure no port conflicts with other services
4. Review the homeserver.yaml file manually

The goal is a private, family-only Matrix server with no external access or discovery.
