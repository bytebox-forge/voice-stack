#!/bin/bash

# Registration Token Management Script for Voice Stack
# This script helps you create, list, and delete registration tokens

SYNAPSE_CONTAINER="voice-stack-synapse"
ADMIN_USER="admin"
SERVER_NAME="matrix.byte-box.org"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_help() {
    echo -e "${BLUE}Voice Stack Registration Token Manager${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create [NAME] [USES]    Create a new registration token"
    echo "                          NAME: Optional name/description"
    echo "                          USES: Number of uses (default: 1)"
    echo "  list                    List all registration tokens"
    echo "  delete [TOKEN]          Delete a specific token"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create \"Family Friend\" 1    # Create token for one person"
    echo "  $0 create \"Relatives\" 5        # Create token for 5 people"
    echo "  $0 list                         # Show all tokens"
    echo "  $0 delete abc123xyz             # Delete specific token"
}

get_admin_token() {
    # This would need to be implemented with proper admin authentication
    # For now, we'll use the registration shared secret method
    echo "Checking admin access..."
}

create_token() {
    local name="${1:-New User}"
    local uses="${2:-1}"
    
    echo -e "${YELLOW}Creating registration token...${NC}"
    echo "Name: $name"
    echo "Uses: $uses"
    
    # Generate a random token
    local token=$(openssl rand -hex 16)
    
    # Use the admin API to create the token
    docker exec -it $SYNAPSE_CONTAINER curl -X POST \
        "http://localhost:8008/_synapse/admin/v1/registration_tokens/new" \
        -H "Content-Type: application/json" \
        -d "{
            \"token\": \"$token\",
            \"uses_allowed\": $uses,
            \"pending\": 0,
            \"completed\": 0,
            \"expiry_time\": null
        }" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Token created successfully!${NC}"
        echo -e "${BLUE}Registration Token: ${GREEN}$token${NC}"
        echo -e "${YELLOW}Share this token with: $name${NC}"
        echo ""
        echo -e "${BLUE}Instructions for users:${NC}"
        echo "1. Go to: http://your-server-ip:8080"
        echo "2. Click 'Create Account'"
        echo "3. Enter the registration token: $token"
        echo "4. Complete registration normally"
    else
        echo -e "${RED}❌ Failed to create token${NC}"
    fi
}

list_tokens() {
    echo -e "${YELLOW}Listing all registration tokens...${NC}"
    
    docker exec -it $SYNAPSE_CONTAINER curl -X GET \
        "http://localhost:8008/_synapse/admin/v1/registration_tokens" \
        -H "Content-Type: application/json" 2>/dev/null | jq '.'
}

delete_token() {
    local token="$1"
    
    if [ -z "$token" ]; then
        echo -e "${RED}❌ Please specify a token to delete${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Deleting token: $token${NC}"
    
    docker exec -it $SYNAPSE_CONTAINER curl -X DELETE \
        "http://localhost:8008/_synapse/admin/v1/registration_tokens/$token" \
        -H "Content-Type: application/json" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Token deleted successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to delete token${NC}"
    fi
}

# Main script logic
case "${1:-help}" in
    "create")
        create_token "$2" "$3"
        ;;
    "list")
        list_tokens
        ;;
    "delete")
        delete_token "$2"
        ;;
    "help"|*)
        print_help
        ;;
esac
