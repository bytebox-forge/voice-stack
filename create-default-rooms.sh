#!/bin/bash
# Default Rooms Creation Script for Voice Stack

echo "Creating default rooms for Voice Stack..."

# Configuration
SERVER_URL="http://localhost:8008"
DOMAIN="matrix.byte-box.org"

# Get admin access token (you'll need to replace this)
echo "You need an admin access token to create rooms via API."
echo "Get your token from Element: Settings → Help & About → Advanced → Access Token"
read -p "Enter your admin access token: " ACCESS_TOKEN

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Access token required"
    exit 1
fi

# Function to create a room
create_room() {
    ROOM_NAME="$1"
    ROOM_ALIAS="$2"
    ROOM_TOPIC="$3"
    IS_PUBLIC="$4"
    
    echo "Creating room: $ROOM_NAME ($ROOM_ALIAS)"
    
    curl -X POST "$SERVER_URL/_matrix/client/r0/createRoom" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$ROOM_NAME\",
            \"room_alias_name\": \"$ROOM_ALIAS\",
            \"topic\": \"$ROOM_TOPIC\",
            \"visibility\": \"$IS_PUBLIC\",
            \"preset\": \"public_chat\",
            \"creation_content\": {
                \"m.federate\": false
            }
        }"
    echo ""
}

# Create default rooms
create_room "General Chat" "general" "Welcome to the general discussion room" "public"
create_room "Family Room" "family" "Private family discussions and updates" "private"  
create_room "Voice Testing" "voice-test" "Test voice and video calling here" "public"
create_room "Tech Support" "support" "Technical help and troubleshooting" "public"
create_room "Announcements" "announcements" "Important server announcements" "public"

echo "Default rooms created! Check your Element interface or Admin panel."
echo ""
echo "Next steps:"
echo "1. Go to Element Web: http://your-server:8080"
echo "2. Join the rooms you created"
echo "3. Test voice calling in the #voice-test room"
echo "4. Invite family members to appropriate rooms"
