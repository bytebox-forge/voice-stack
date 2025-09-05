#!/bin/bash

set -eu

# Generate Element Web configuration from environment variables
# This solves the hardcoded domain issue in Element config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    error ".env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Validate required variables
if [ -z "${SYNAPSE_SERVER_NAME:-}" ]; then
    error "SYNAPSE_SERVER_NAME is required in .env file"
    exit 1
fi

if [ -z "${ELEMENT_PUBLIC_URL:-}" ]; then
    error "ELEMENT_PUBLIC_URL is required in .env file"
    exit 1
fi

# Determine protocol and port from ELEMENT_PUBLIC_URL
ELEMENT_PROTOCOL=$(echo "$ELEMENT_PUBLIC_URL" | cut -d: -f1)
ELEMENT_DOMAIN=$(echo "$ELEMENT_PUBLIC_URL" | cut -d/ -f3)

# Determine Synapse base URL
if [ "$ELEMENT_PROTOCOL" = "https" ]; then
    SYNAPSE_BASE_URL="https://${SYNAPSE_SERVER_NAME}"
else
    SYNAPSE_BASE_URL="http://${SYNAPSE_SERVER_NAME}:${SYNAPSE_PORT:-8008}"
fi

log "Generating Element Web configuration..."
log "Synapse Server: $SYNAPSE_SERVER_NAME"
log "Element Domain: $ELEMENT_DOMAIN"
log "Synapse Base URL: $SYNAPSE_BASE_URL"
log "Element Protocol: $ELEMENT_PROTOCOL"

# Create element-config directory if it doesn't exist
mkdir -p element-config

# Generate Element configuration file
cat > element-config/config.json << EOF
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "$SYNAPSE_BASE_URL",
            "server_name": "$SYNAPSE_SERVER_NAME"
        },
        "m.identity_server": {
            "base_url": "https://vector.im"
        }
    },
    "default_server_name": "$SYNAPSE_SERVER_NAME",
    "default_theme": "light",
    "disable_custom_urls": false,
    "disable_guests": ${ALLOW_GUEST_ACCESS:-false},
    "disable_login_language_selector": false,
    "disable_3pid_login": false,
    "brand": "Element",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "integrations_widgets_urls": [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ],
    "hosting_signup_link": "https://element.io/matrix-services?utm_source=element-web&utm_medium=web",
    "bug_report_endpoint_url": "https://element.io/bugreports/submit",
    "uisi_autorageshake_app": "element-auto-uisi",
    "showLabsSettings": true,
    "features": {
        "feature_video_rooms": true,
        "feature_element_call_video_rooms": true,
        "feature_group_calls": true,
        "feature_native_group_call_support": true,
        "feature_rust_crypto": false,
        "feature_pinning": true,
        "feature_custom_themes": true,
        "feature_spaces": true,
        "feature_voice_messages": true,
        "feature_location_share": true,
        "feature_poll": true,
        "feature_wysiwyg_composer": true
    },
    "element_call": {
        "url": "https://call.element.io",
        "use_exclusively": false,
        "participant_limit": 8,
        "brand": "Element Call"
    },
    "voice_broadcast": {
        "chunk_length": 120,
        "max_length": 14400
    },
    "map_style_url": "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx",
    "setting_defaults": {
        "breadcrumbs": true,
        "MessageComposerInput.suggestEmoji": true,
        "MessageComposerInput.showStickersButton": true,
        "MessageComposerInput.showPollsButton": true,
        "MessageComposerInput.showLocationShareButton": true,
        "UIFeature.urlPreviews": ${URL_PREVIEW_ENABLED:-true},
        "UIFeature.feedback": false,
        "UIFeature.voip": true,
        "UIFeature.widgets": true,
        "UIFeature.flair": true,
        "UIFeature.communities": true,
        "UIFeature.advancedSettings": true,
        "UIFeature.shareQrCode": true,
        "UIFeature.shareSocial": true,
        "UIFeature.identityServer": true,
        "UIFeature.thirdPartyId": true,
        "UIFeature.registration": ${ENABLE_REGISTRATION:-false},
        "UIFeature.passwordReset": true,
        "UIFeature.deactivate": true,
        "UIFeature.advancedEncryption": false,
        "UIFeature.roomHistorySettings": true,
        "UIFeature.TimelineEnableRelativeDates": false
    },
    "jitsi": {
        "preferred_domain": "${ELEMENT_JITSI_DOMAIN:-meet.jit.si}"
    }
}
EOF

log "Element Web configuration generated successfully!"
log "Configuration file: element-config/config.json"

# Validate JSON syntax
if command -v jq >/dev/null 2>&1; then
    if jq empty element-config/config.json 2>/dev/null; then
        log "JSON syntax validation: PASSED"
    else
        error "JSON syntax validation: FAILED"
        exit 1
    fi
else
    warn "jq not available - skipping JSON syntax validation"
fi

# Show configuration summary
log "Configuration Summary:"
echo "  - Synapse Server: $SYNAPSE_SERVER_NAME"
echo "  - Synapse Base URL: $SYNAPSE_BASE_URL"
echo "  - Element Domain: $ELEMENT_DOMAIN"
echo "  - Guest Access: ${ALLOW_GUEST_ACCESS:-false}"
echo "  - Registration UI: ${ENABLE_REGISTRATION:-false}"
echo "  - URL Previews: ${URL_PREVIEW_ENABLED:-true}"
echo "  - Jitsi Domain: ${ELEMENT_JITSI_DOMAIN:-meet.jit.si}"

log "Remember to rebuild the Element container after configuration changes:"
echo "  docker-compose build element"
echo "  ./deploy.sh restart"