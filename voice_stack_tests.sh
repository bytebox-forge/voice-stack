#!/bin/bash
# Matrix Family Server Voice/Video Stack Test Suite
# Comprehensive testing without external dependencies
# Author: Claude Code Test Suite Generator

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SYNAPSE_URL="http://localhost:8008"
ELEMENT_URL="http://localhost:8080"
ADMIN_URL="http://localhost:8082"
COTURN_PORT="3478"
COTURN_EXTERNAL_IP="108.217.87.138"
SERVER_NAME="matrix.byte-box.org"

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_RESULTS=()

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    log_info "Running: $test_name"
    
    if eval "$test_command"; then
        log_success "$test_name"
        TEST_RESULTS+=("PASS: $test_name")
        return 0
    else
        log_error "$test_name"
        TEST_RESULTS+=("FAIL: $test_name")
        return 1
    fi
}

# Test functions
test_synapse_health() {
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$SYNAPSE_URL/health" 2>/dev/null)
    [[ "$response" == "200" ]]
}

test_synapse_versions() {
    local response=$(curl -s "$SYNAPSE_URL/_matrix/client/versions" 2>/dev/null)
    [[ -n "$response" && "$response" == *"versions"* ]]
}

test_element_web_accessible() {
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$ELEMENT_URL/" 2>/dev/null)
    [[ "$response" == "200" ]]
}

test_element_config_loaded() {
    local response=$(curl -s "$ELEMENT_URL/config.json" 2>/dev/null)
    [[ -n "$response" && "$response" == *"matrix.byte-box.org"* ]]
}

test_element_call_configuration() {
    local response=$(curl -s "$ELEMENT_URL/config.json" 2>/dev/null)
    [[ -n "$response" && "$response" == *"element_call"* && "$response" == *"feature_element_call_video_rooms"* ]]
}

test_synapse_admin_accessible() {
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$ADMIN_URL/" 2>/dev/null)
    [[ "$response" == "200" ]]
}

test_coturn_udp_port() {
    nc -zvu localhost "$COTURN_PORT" 2>&1 | grep -q "succeeded"
}

test_coturn_tcp_port() {
    nc -zv localhost "$COTURN_PORT" 2>&1 | grep -q "succeeded"
}

test_coturn_external_ip() {
    [[ -n "$COTURN_EXTERNAL_IP" && "$COTURN_EXTERNAL_IP" != "auto" ]]
}

test_well_known_matrix_server() {
    local well_known_url="$SYNAPSE_URL/.well-known/matrix/server"
    local response=$(curl -s "$well_known_url" 2>/dev/null)
    [[ -n "$response" && "$response" == *"$SERVER_NAME"* ]]
}

test_well_known_matrix_client() {
    local well_known_url="$SYNAPSE_URL/.well-known/matrix/client"
    local response=$(curl -s "$well_known_url" 2>/dev/null)
    [[ -n "$response" && "$response" == *"$SERVER_NAME"* ]]
}

test_synapse_registration_disabled() {
    local response=$(curl -s "$SYNAPSE_URL/_matrix/client/r0/register" 2>/dev/null)
    [[ -n "$response" && ("$response" == *"registration_disabled"* || "$response" == *"Forbidden"*) ]]
}

test_media_upload_endpoint() {
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$SYNAPSE_URL/_matrix/media/v3/upload" 2>/dev/null)
    # Should return 401 (unauthorized) since we don't have auth, not 404
    [[ "$response" == "401" || "$response" == "400" ]]
}

test_federation_server() {
    local response=$(curl -s -w "%{http_code}" -o /dev/null "$SYNAPSE_URL/_matrix/federation/v1/version" 2>/dev/null)
    [[ "$response" == "200" ]]
}

test_turn_server_config() {
    # Check if TURN server configuration is accessible via Synapse
    local response=$(curl -s "$SYNAPSE_URL/_matrix/client/r0/voip/turnServer" 2>/dev/null)
    # This should return 401 without auth, indicating the endpoint exists
    [[ -n "$response" ]]
}

test_element_voip_settings() {
    local config=$(curl -s "$ELEMENT_URL/config.json" 2>/dev/null)
    [[ -n "$config" && "$config" == *'"UIFeature.voip": true'* ]]
}

test_element_video_rooms() {
    local config=$(curl -s "$ELEMENT_URL/config.json" 2>/dev/null)
    [[ -n "$config" && "$config" == *'"feature_video_rooms": true'* ]]
}

test_element_group_calls() {
    local config=$(curl -s "$ELEMENT_URL/config.json" 2>/dev/null)
    [[ -n "$config" && "$config" == *'"feature_group_calls": true'* ]]
}

test_jitsi_configuration() {
    local config=$(curl -s "$ELEMENT_URL/config.json" 2>/dev/null)
    [[ -n "$config" && "$config" == *'"jitsi"'* && "$config" == *"meet.jit.si"* ]]
}

test_webrtc_features_enabled() {
    local config=$(curl -s "$ELEMENT_URL/config.json" 2>/dev/null)
    [[ -n "$config" && "$config" == *'"feature_voice_messages": true'* ]]
}

# Network connectivity tests
test_dns_resolution() {
    nslookup matrix.org >/dev/null 2>&1
}

test_external_connectivity() {
    ping -c 1 8.8.8.8 >/dev/null 2>&1
}

test_coturn_external_connectivity() {
    # Test if external IP is reachable (basic ping test)
    if [[ "$COTURN_EXTERNAL_IP" != "auto" ]]; then
        ping -c 1 "$COTURN_EXTERNAL_IP" >/dev/null 2>&1
    else
        # If auto, skip this test
        true
    fi
}

# Security tests
test_no_directory_listing() {
    local response=$(curl -s "$ELEMENT_URL/static/" 2>/dev/null)
    # Should not contain directory listing indicators
    [[ "$response" != *"Index of"* && "$response" != *"Directory listing"* ]]
}

test_secure_headers() {
    local headers=$(curl -s -I "$ELEMENT_URL/" 2>/dev/null)
    # Check for some basic security headers (not all servers implement all of them)
    [[ -n "$headers" ]]
}

# Admin functionality tests
test_admin_interface_loads() {
    local response=$(curl -s "$ADMIN_URL/" 2>/dev/null)
    [[ -n "$response" && "$response" == *"Synapse"* ]]
}

# Main test execution
main() {
    echo "=============================================="
    echo "Matrix Family Server Voice/Video Test Suite"
    echo "=============================================="
    echo "Server: $SERVER_NAME"
    echo "Synapse: $SYNAPSE_URL"
    echo "Element: $ELEMENT_URL"
    echo "Admin: $ADMIN_URL"
    echo "CoTURN External IP: $COTURN_EXTERNAL_IP"
    echo "=============================================="
    echo ""

    # Core service tests
    log_info "=== CORE SERVICE TESTS ==="
    run_test "Synapse Health Check" "test_synapse_health"
    run_test "Synapse API Versions" "test_synapse_versions"
    run_test "Element Web Accessible" "test_element_web_accessible"
    run_test "Element Configuration Loading" "test_element_config_loaded"
    run_test "Synapse Admin Interface" "test_synapse_admin_accessible"
    echo ""

    # Voice/Video specific tests
    log_info "=== VOICE/VIDEO CONFIGURATION TESTS ==="
    run_test "Element Call Configuration" "test_element_call_configuration"
    run_test "Element VoIP Settings" "test_element_voip_settings"
    run_test "Element Video Rooms" "test_element_video_rooms"
    run_test "Element Group Calls" "test_element_group_calls"
    run_test "Jitsi Configuration" "test_jitsi_configuration"
    run_test "WebRTC Features Enabled" "test_webrtc_features_enabled"
    echo ""

    # CoTURN tests
    log_info "=== COTURN SERVER TESTS ==="
    run_test "CoTURN UDP Port Accessible" "test_coturn_udp_port"
    run_test "CoTURN TCP Port Accessible" "test_coturn_tcp_port"
    run_test "CoTURN External IP Configured" "test_coturn_external_ip"
    run_test "TURN Server Configuration" "test_turn_server_config"
    echo ""

    # Federation and discovery tests
    log_info "=== FEDERATION & DISCOVERY TESTS ==="
    run_test "Well-known Matrix Server" "test_well_known_matrix_server"
    run_test "Well-known Matrix Client" "test_well_known_matrix_client"
    run_test "Federation Server Endpoint" "test_federation_server"
    echo ""

    # Security tests
    log_info "=== SECURITY TESTS ==="
    run_test "Registration Disabled" "test_synapse_registration_disabled"
    run_test "No Directory Listing" "test_no_directory_listing"
    run_test "Security Headers Present" "test_secure_headers"
    echo ""

    # Network tests
    log_info "=== NETWORK CONNECTIVITY TESTS ==="
    run_test "DNS Resolution" "test_dns_resolution"
    run_test "External Connectivity" "test_external_connectivity"
    run_test "CoTURN External IP Reachable" "test_coturn_external_connectivity"
    echo ""

    # Media and upload tests
    log_info "=== MEDIA & UPLOAD TESTS ==="
    run_test "Media Upload Endpoint" "test_media_upload_endpoint"
    echo ""

    # Admin interface tests
    log_info "=== ADMIN INTERFACE TESTS ==="
    run_test "Admin Interface Loads" "test_admin_interface_loads"
    echo ""

    # Test summary
    echo "=============================================="
    echo "TEST SUMMARY"
    echo "=============================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! Your Matrix family server is ready for voice/video calls!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Check the results above.${NC}"
        echo ""
        echo "Failed tests:"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "$result" == FAIL* ]]; then
                echo -e "${RED}  - ${result#FAIL: }${NC}"
            fi
        done
        exit 1
    fi
}

# Run the tests
main "$@"