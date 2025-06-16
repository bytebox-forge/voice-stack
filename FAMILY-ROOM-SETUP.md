# Family Setup Guide - Rooms & Kid Accounts

This guide covers creating default rooms and setting up accounts for family members, especially kids.

## 🏠 Creating Default Rooms

### Method 1: Element Web Interface (Easiest)
1. **Go to Element**: `http://your-server:8080`
2. **Login as admin**
3. **Click "+" next to Rooms**
4. **Create Room** and configure:

**Suggested Family Rooms:**
- **#general** - Main family chat
- **#kids** - Kids-only space  
- **#parents** - Parent coordination
- **#voice-test** - Testing voice/video
- **#games** - Gaming discussions
- **#homework** - Homework help

### Method 2: Bulk Room Creation Script

Save this as `create-rooms.sh`:

```bash
#!/bin/bash

# Configuration
SERVER="http://your-server:8008"
ADMIN_TOKEN="your_admin_access_token"  # Get from Element Settings → Advanced
DOMAIN="matrix.byte-box.org"

# Room definitions (name:topic:public/private)
ROOMS=(
    "general:Main family chat room:public"
    "kids:Kids only - have fun!:private"
    "parents:Parent coordination:private"
    "voice-test:Test voice and video calls:public"
    "games:Gaming discussions:public"
    "homework:Homework help and study:private"
)

echo "Creating family rooms..."

for room_def in "${ROOMS[@]}"; do
    IFS=':' read -r name topic visibility <<< "$room_def"
    
    echo "Creating room: #$name"
    
    curl -X POST "$SERVER/_matrix/client/r0/createRoom" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$name\",
            \"topic\": \"$topic\",
            \"room_alias_name\": \"$name\",
            \"visibility\": \"$visibility\",
            \"preset\": \"trusted_private_chat\"
        }"
    
    echo ""
done

echo "Rooms created! Check Element to see them."
```

## 👶 Creating Kid Accounts

### Method 1: Using register_new_matrix_user (Recommended)

```bash
# Create accounts for each kid
docker exec voice-stack-synapse register_new_matrix_user \
    -u kidname1 -p SecureKidPassword1 \
    -c /data/homeserver.yaml http://localhost:8008

docker exec voice-stack-synapse register_new_matrix_user \
    -u kidname2 -p SecureKidPassword2 \
    -c /data/homeserver.yaml http://localhost:8008

# Continue for each child...
```

### Method 2: Bulk Account Creation Script

Save this as `create-kid-accounts.sh`:

```bash
#!/bin/bash

# Kid account definitions (username:password:displayname)
KIDS=(
    "alice:AliceSecure123:Alice Smith"
    "bob:BobSecure123:Bob Smith"
    "charlie:CharlieSecure123:Charlie Smith"
)

echo "Creating kid accounts..."

for kid_def in "${KIDS[@]}"; do
    IFS=':' read -r username password displayname <<< "$kid_def"
    
    echo "Creating account for: $displayname ($username)"
    
    docker exec voice-stack-synapse register_new_matrix_user \
        -u "$username" -p "$password" \
        -c /data/homeserver.yaml http://localhost:8008
        
    if [ $? -eq 0 ]; then
        echo "✅ Account created for $displayname"
    else
        echo "❌ Failed to create account for $displayname"
    fi
    
    echo ""
done

echo "Kid accounts created! They can now login to Element."
```

## 🔐 Kid Account Security & Management

### Setting Up Kid-Safe Environment

1. **Create Kid-Only Rooms** with restricted permissions
2. **Set Room Permissions** to prevent kids from inviting strangers
3. **Monitor Activity** through admin panel
4. **Set Display Names** appropriately

### Room Permission Settings (via Element)
1. **Go to Room Settings** → Advanced
2. **Set Power Levels**:
   - **Kids**: 0 (can chat, can't invite)
   - **Parents**: 50+ (can moderate)
   - **Admin**: 100 (full control)

### Managing Kids Through Admin Panel
1. **Go to**: `http://your-server:8082`
2. **Users section**: See all kid accounts
3. **Room section**: Monitor room activity
4. **Can deactivate** accounts if needed

## 📱 Kid Login Instructions

Give your kids these simple steps:

1. **Go to**: `http://your-server:8080`
2. **Click**: "Sign In"  
3. **Homeserver**: Make sure it shows your server
4. **Username**: Their username (e.g., `alice`)
5. **Password**: Their password

## 🎮 Family-Friendly Room Setup

### General Room Settings
- **Encryption**: Enable for privacy
- **History**: Visible to joined members
- **Joining**: Invite only
- **Guest Access**: Disabled

### Kid Rooms Specific Settings
- **No external invites** allowed
- **Parents as moderators**
- **Appropriate room topics/descriptions**

## 🔧 Quick Setup Commands

### Get Your Admin Token (for scripts)
1. **Login to Element** as admin
2. **Settings** → Help & About → Advanced
3. **Copy Access Token**
4. **Update scripts** with your token

### Test Room Creation Manually
```bash
# Get your admin token first, then:
curl -X POST "http://your-server:8008/_matrix/client/r0/createRoom" \
    -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Test Room",
        "topic": "Testing room creation",
        "room_alias_name": "test",
        "visibility": "private"
    }'
```

## 📋 Family Setup Checklist

- [ ] Create admin accounts (✅ Done)
- [ ] Create default family rooms
- [ ] Create kid accounts with secure passwords
- [ ] Set appropriate room permissions
- [ ] Test voice/video calling
- [ ] Brief kids on usage rules
- [ ] Set up monitoring routine

## 🎯 Next Steps

1. **Create the rooms** using Element interface
2. **Create kid accounts** using the register command
3. **Test voice calling** in the voice-test room
4. **Set family rules** for Matrix usage
5. **Enjoy your private family communication server!**

---

**Note**: Always supervise kids' online activity and establish clear rules for digital communication, even on your private server.
