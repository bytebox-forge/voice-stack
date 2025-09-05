#!/bin/bash
# Matrix Admin User Creation and Testing Script
# Tests admin user creation and basic Matrix capabilities

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SYNAPSE_URL="http://localhost:8008"
SERVER_NAME="matrix.byte-box.org"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="AdminPassword123!"
REGISTRATION_SHARED_SECRET="ByteBox_Matrix_2025_SuperSecretKey_Family"

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Create admin user function
create_admin_user() {
    log_info "Creating admin user: $ADMIN_USERNAME"
    
    # Generate nonce
    local nonce_response=$(curl -s "$SYNAPSE_URL/_synapse/admin/v1/register" 2>/dev/null)
    local nonce=$(echo "$nonce_response" | grep -o '"nonce":"[^"]*"' | cut -d'"' -f4)
    
    if [[ -z "$nonce" ]]; then
        log_error "Failed to get nonce for admin registration"
        return 1
    fi
    
    log_info "Got nonce: $nonce"
    
    # Calculate HMAC (using openssl if available, otherwise skip)
    if command -v openssl >/dev/null 2>&1; then
        local mac=$(echo -n "${nonce}${ADMIN_USERNAME}${ADMIN_PASSWORD}admin" | openssl dgst -sha1 -hmac "$REGISTRATION_SHARED_SECRET" -binary | base64)
        
        # Register admin user
        local register_data='{
            "nonce": "'$nonce'",
            "username": "'$ADMIN_USERNAME'",
            "password": "'$ADMIN_PASSWORD'",
            "admin": true,
            "mac": "'$mac'"
        }'
        
        local register_response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$register_data" \
            "$SYNAPSE_URL/_synapse/admin/v1/register" 2>/dev/null)
        
        if echo "$register_response" | grep -q "access_token"; then
            log_success "Admin user created successfully"
            # Extract and save access token
            local access_token=$(echo "$register_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
            echo "$access_token" > .admin_token
            return 0
        else
            log_warning "Admin user might already exist or creation failed"
            log_info "Response: $register_response"
            return 1
        fi
    else
        log_warning "OpenSSL not available - cannot create admin user automatically"
        log_info "Please create admin user manually using the registration shared secret"
        return 1
    fi
}

# Test admin login
test_admin_login() {
    log_info "Testing admin user login"
    
    local login_data='{
        "type": "m.login.password",
        "user": "'$ADMIN_USERNAME'",
        "password": "'$ADMIN_PASSWORD'"
    }'
    
    local login_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$login_data" \
        "$SYNAPSE_URL/_matrix/client/r0/login" 2>/dev/null)
    
    if echo "$login_response" | grep -q "access_token"; then
        log_success "Admin login successful"
        local access_token=$(echo "$login_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        echo "$access_token" > .admin_token
        return 0
    else
        log_error "Admin login failed"
        log_info "Response: $login_response"
        return 1
    fi
}

# Test admin capabilities
test_admin_capabilities() {
    if [[ ! -f .admin_token ]]; then
        log_error "No admin token available for testing"
        return 1
    fi
    
    local token=$(cat .admin_token)
    log_info "Testing admin capabilities with token"
    
    # Test user list endpoint
    local users_response=$(curl -s -H "Authorization: Bearer $token" \
        "$SYNAPSE_URL/_synapse/admin/v2/users" 2>/dev/null)
    
    if echo "$users_response" | grep -q "users"; then
        log_success "Admin can access user management endpoints"
    else
        log_error "Admin cannot access user management endpoints"
        return 1
    fi
    
    # Test room list endpoint
    local rooms_response=$(curl -s -H "Authorization: Bearer $token" \
        "$SYNAPSE_URL/_synapse/admin/v1/rooms" 2>/dev/null)
    
    if echo "$rooms_response" | grep -q "rooms"; then
        log_success "Admin can access room management endpoints"
    else
        log_warning "Admin cannot access room management endpoints (might be empty)"
    fi
    
    return 0
}

# Test creating a room
test_room_creation() {
    if [[ ! -f .admin_token ]]; then
        log_error "No admin token available for room testing"
        return 1
    fi
    
    local token=$(cat .admin_token)
    log_info "Testing room creation"
    
    local room_data='{
        "name": "Test Family Room",
        "topic": "Test room for voice/video capabilities",
        "preset": "private_chat"
    }'
    
    local room_response=$(curl -s -X POST \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$room_data" \
        "$SYNAPSE_URL/_matrix/client/r0/createRoom" 2>/dev/null)
    
    if echo "$room_response" | grep -q "room_id"; then
        log_success "Room creation successful"
        local room_id=$(echo "$room_response" | grep -o '"room_id":"[^"]*"' | cut -d'"' -f4)
        log_info "Created room: $room_id"
        echo "$room_id" > .test_room_id
        return 0
    else
        log_error "Room creation failed"
        log_info "Response: $room_response"
        return 1
    fi
}

# Test voice/video call endpoints
test_voip_endpoints() {
    if [[ ! -f .admin_token ]]; then
        log_error "No admin token available for VoIP testing"
        return 1
    fi
    
    local token=$(cat .admin_token)
    log_info "Testing VoIP/TURN server endpoints"
    
    # Test TURN server endpoint
    local turn_response=$(curl -s -H "Authorization: Bearer $token" \
        "$SYNAPSE_URL/_matrix/client/r0/voip/turnServer" 2>/dev/null)
    
    if echo "$turn_response" | grep -q "uris"; then
        log_success "TURN server configuration accessible"
        log_info "TURN Response: $turn_response"
    else
        log_warning "TURN server configuration not accessible or not configured"
        log_info "Response: $turn_response"
    fi
    
    return 0
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test artifacts"
    rm -f .admin_token .test_room_id
}

# Main execution
main() {
    echo "=============================================="
    echo "Matrix Admin User Creation and Testing"
    echo "=============================================="
    echo "Server: $SERVER_NAME"
    echo "Synapse: $SYNAPSE_URL"
    echo "Admin Username: $ADMIN_USERNAME"
    echo "=============================================="
    echo ""
    
    # Try to create admin user first
    if ! create_admin_user; then
        log_info "Attempting to login with existing admin credentials"
        if ! test_admin_login; then
            log_error "Cannot create or login as admin user"
            log_info "Manual admin creation required. Use the following steps:"
            echo ""
            echo "1. Run this command in your Synapse container:"
            echo "   register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008"
            echo ""
            echo "2. Or use the registration shared secret manually"
            echo ""
            exit 1
        fi
    fi
    
    echo ""
    log_info "=== Testing Admin Capabilities ==="
    test_admin_capabilities
    
    echo ""
    log_info "=== Testing Room Creation ==="
    test_room_creation
    
    echo ""
    log_info "=== Testing VoIP/Video Endpoints ==="
    test_voip_endpoints
    
    echo ""
    echo "=============================================="
    echo "Admin Testing Complete"
    echo "=============================================="
    
    if [[ -f .admin_token ]]; then
        log_success "Admin user is functional and ready for family server use"
        log_info "You can now use Element Web at http://localhost:8080 to:"
        echo "  - Login as admin user: $ADMIN_USERNAME"
        echo "  - Create family rooms"
        echo "  - Start voice/video calls"
        echo "  - Manage server settings"
    fi
    
    # Cleanup
    trap cleanup EXIT
}

# Run the tests
main "$@"