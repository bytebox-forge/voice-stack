#!/bin/bash

set -eu

# Voice Stack Restore Script
# Restores Voice Stack data and configuration from backup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Volume names
POSTGRES_VOLUME="voice-stack_postgres_data"
SYNAPSE_VOLUME="voice-stack_synapse_data"
MEDIA_VOLUME="voice-stack_media_store"
COTURN_VOLUME="voice-stack_coturn_data"

usage() {
    echo "Usage: $0 [options] <backup_path>"
    echo ""
    echo "Arguments:"
    echo "  backup_path            Path to backup directory"
    echo ""
    echo "Options:"
    echo "  --config-only          Restore configuration files only"
    echo "  --volumes-only         Restore volumes only"
    echo "  --force               Skip confirmation prompts"
    echo "  --no-stop             Don't stop running services"
    echo "  --verify              Verify restored data integrity"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ~/voice-stack-backups/voice-stack_20250904_143022"
    echo "  $0 --config-only /backup/voice-stack_pre-migration"
    echo "  $0 --force --verify ~/backups/voice-stack_latest"
}

# Parse command line arguments
CONFIG_ONLY=false
VOLUMES_ONLY=false
FORCE=false
NO_STOP=false
VERIFY=false
BACKUP_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --config-only)
            CONFIG_ONLY=true
            shift
            ;;
        --volumes-only)
            VOLUMES_ONLY=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --no-stop)
            NO_STOP=true
            shift
            ;;
        --verify)
            VERIFY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [ -z "$BACKUP_PATH" ]; then
                BACKUP_PATH="$1"
            else
                error "Multiple backup paths specified"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$BACKUP_PATH" ]; then
    error "Backup path is required"
    usage
    exit 1
fi

if [ ! -d "$BACKUP_PATH" ]; then
    error "Backup path does not exist: $BACKUP_PATH"
    exit 1
fi

if [ ! -f "$BACKUP_PATH/backup-manifest.txt" ]; then
    error "Invalid backup: manifest file not found"
    exit 1
fi

log "Starting Voice Stack restoration..."
log "Backup path: $BACKUP_PATH"

# Show backup information
if [ -f "$BACKUP_PATH/backup-manifest.txt" ]; then
    info "Backup Information:"
    head -10 "$BACKUP_PATH/backup-manifest.txt" | sed 's/^/  /'
fi

# Confirmation prompt
if [ "$FORCE" = false ]; then
    echo ""
    warn "This will restore Voice Stack from backup and may overwrite existing data!"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restoration cancelled"
        exit 0
    fi
fi

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed or not in PATH"
    exit 1
fi

# Stop running services
if [ "$NO_STOP" = false ]; then
    log "Stopping Voice Stack services..."
    
    # Look for deploy script in current directory or backup
    DEPLOY_SCRIPT=""
    if [ -f "$SCRIPT_DIR/deploy.sh" ]; then
        DEPLOY_SCRIPT="$SCRIPT_DIR/deploy.sh"
    elif [ -f "$BACKUP_PATH/config/deploy.sh" ]; then
        DEPLOY_SCRIPT="$BACKUP_PATH/config/deploy.sh"
    fi
    
    if [ -n "$DEPLOY_SCRIPT" ]; then
        cd "$(dirname "$DEPLOY_SCRIPT")"
        bash "$DEPLOY_SCRIPT" stop || warn "Failed to stop services gracefully"
    else
        warn "Deploy script not found, attempting to stop containers manually"
        docker stop $(docker ps -q --filter "name=voice-stack") 2>/dev/null || true
    fi
    
    # Wait for containers to stop
    sleep 5
fi

# Restore configuration files
if [ "$VOLUMES_ONLY" = false ]; then
    if [ -d "$BACKUP_PATH/config" ]; then
        log "Restoring configuration files..."
        
        # Create backup of current config if it exists
        if [ -d "$SCRIPT_DIR" ] && [ "$FORCE" = false ]; then
            CURRENT_BACKUP="$SCRIPT_DIR/../voice-stack-current-$(date +%s)"
            mkdir -p "$CURRENT_BACKUP"
            cp -r "$SCRIPT_DIR"/* "$CURRENT_BACKUP/" 2>/dev/null || true
            log "Current configuration backed up to: $CURRENT_BACKUP"
        fi
        
        # Restore configuration files
        cp -r "$BACKUP_PATH/config"/* "$SCRIPT_DIR/" 2>/dev/null || true
        
        # Make scripts executable
        find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
        
        log "Configuration files restored successfully"
        
        # Check for .env template
        if [ -f "$SCRIPT_DIR/.env.template" ] && [ ! -f "$SCRIPT_DIR/.env" ]; then
            warn "Found .env.template but no .env file"
            warn "Please copy .env.template to .env and configure with actual values"
        fi
    else
        warn "No configuration directory found in backup"
    fi
fi

# Restore Docker volumes
if [ "$CONFIG_ONLY" = false ]; then
    log "Restoring Docker volumes..."
    
    # Create volumes if they don't exist
    create_volume() {
        local volume_name=$1
        if ! docker volume inspect "$volume_name" >/dev/null 2>&1; then
            log "Creating volume: $volume_name"
            docker volume create "$volume_name"
        fi
    }
    
    # Restore volume function
    restore_volume() {
        local volume_name=$1
        local archive_name=$2
        
        # Check for compressed or uncompressed archive
        local archive_file=""
        if [ -f "$BACKUP_PATH/${archive_name}.tar.gz" ]; then
            archive_file="$BACKUP_PATH/${archive_name}.tar.gz"
        elif [ -f "$BACKUP_PATH/${archive_name}.tar" ]; then
            archive_file="$BACKUP_PATH/${archive_name}.tar"
        else
            warn "Archive not found for $archive_name - skipping"
            return 0
        fi
        
        log "Restoring volume: $volume_name from $(basename "$archive_file")"
        
        # Create volume
        create_volume "$volume_name"
        
        # Clear existing volume data
        docker run --rm -v "$volume_name:/target" alpine rm -rf /target/* /target/.[!.]* /target/..?* 2>/dev/null || true
        
        # Restore data
        if [[ "$archive_file" == *.gz ]]; then
            docker run --rm -v "$volume_name:/target" -v "$BACKUP_PATH:/backup" alpine \
                tar xzf "/backup/$(basename "$archive_file")" -C /target
        else
            docker run --rm -v "$volume_name:/target" -v "$BACKUP_PATH:/backup" alpine \
                tar xf "/backup/$(basename "$archive_file")" -C /target
        fi
        
        if [ $? -eq 0 ]; then
            log "Volume $volume_name restored successfully"
        else
            error "Failed to restore volume $volume_name"
            return 1
        fi
    }
    
    # Restore all volumes
    restore_volume "$POSTGRES_VOLUME" "postgres_data"
    restore_volume "$SYNAPSE_VOLUME" "synapse_data"
    restore_volume "$MEDIA_VOLUME" "media_store"
    restore_volume "$COTURN_VOLUME" "coturn_data"
fi

# Verify restored data
if [ "$VERIFY" = true ]; then
    log "Verifying restored data..."
    
    VERIFY_FAILED=false
    
    # Verify configuration
    if [ "$VOLUMES_ONLY" = false ]; then
        if [ ! -f "$SCRIPT_DIR/docker-compose.yml" ]; then
            error "Configuration verification failed: docker-compose.yml not found"
            VERIFY_FAILED=true
        fi
        
        if [ ! -f "$SCRIPT_DIR/.env" ] && [ ! -f "$SCRIPT_DIR/.env.template" ]; then
            error "Configuration verification failed: no .env or .env.template found"
            VERIFY_FAILED=true
        fi
    fi
    
    # Verify volumes
    if [ "$CONFIG_ONLY" = false ]; then
        for volume in "$POSTGRES_VOLUME" "$SYNAPSE_VOLUME" "$MEDIA_VOLUME" "$COTURN_VOLUME"; do
            if docker volume inspect "$volume" >/dev/null 2>&1; then
                # Check if volume has data
                DATA_COUNT=$(docker run --rm -v "$volume:/data" alpine find /data -type f | wc -l)
                if [ "$DATA_COUNT" -gt 0 ]; then
                    log "Volume verification passed: $volume ($DATA_COUNT files)"
                else
                    warn "Volume verification: $volume appears empty"
                fi
            else
                error "Volume verification failed: $volume not found"
                VERIFY_FAILED=true
            fi
        done
    fi
    
    if [ "$VERIFY_FAILED" = true ]; then
        error "Restoration verification failed!"
        exit 1
    else
        log "Restoration verification passed!"
    fi
fi

# Update Element configuration if needed
if [ "$VOLUMES_ONLY" = false ] && [ -f "$SCRIPT_DIR/generate-element-config.sh" ] && [ -f "$SCRIPT_DIR/.env" ]; then
    log "Updating Element configuration for current environment..."
    cd "$SCRIPT_DIR"
    ./generate-element-config.sh || warn "Failed to update Element configuration"
fi

log "Restoration completed successfully!"

# Show next steps
echo ""
info "Next Steps:"
echo "1. Review and update .env file with current environment settings"
echo "2. Update Element configuration if domain has changed:"
echo "   ./generate-element-config.sh"
echo "3. Start services:"
echo "   ./deploy.sh start"
echo "4. Verify service health:"
echo "   ./deploy.sh health"
echo "5. Test functionality:"
echo "   ./voice_stack_tests.sh"

# Show configuration summary
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo ""
    info "Current configuration summary:"
    grep -E "^(SYNAPSE_SERVER_NAME|ELEMENT_PUBLIC_URL|COTURN_EXTERNAL_IP)" "$SCRIPT_DIR/.env" | sed 's/^/  /' || true
elif [ -f "$SCRIPT_DIR/.env.template" ]; then
    warn "Configuration template available at .env.template"
    warn "Copy to .env and configure with actual values before starting services"
fi

log "Restoration process completed!"
echo ""
echo "Restoration summary:"
echo "  Backup source: $BACKUP_PATH"
echo "  Configuration restored: $([ "$VOLUMES_ONLY" = false ] && echo "YES" || echo "NO")"
echo "  Volumes restored: $([ "$CONFIG_ONLY" = false ] && echo "YES" || echo "NO")"
echo "  Verification: $([ "$VERIFY" = true ] && echo "PASSED" || echo "SKIPPED")"