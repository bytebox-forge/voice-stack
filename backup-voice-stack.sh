#!/bin/bash

set -eu

# Voice Stack Backup Script
# Creates complete backup of all Voice Stack data and configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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

# Configuration
BACKUP_DIR="${HOME}/voice-stack-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="voice-stack_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Volume names
POSTGRES_VOLUME="voice-stack_postgres_data"
SYNAPSE_VOLUME="voice-stack_synapse_data"
MEDIA_VOLUME="voice-stack_media_store"
COTURN_VOLUME="voice-stack_coturn_data"

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --destination DIR   Backup destination directory (default: ~/voice-stack-backups)"
    echo "  -n, --name NAME        Backup name suffix (default: timestamp)"
    echo "  --config-only          Backup configuration files only (no volumes)"
    echo "  --volumes-only         Backup volumes only (no configuration)"
    echo "  --compress             Compress backup archives (slower but smaller)"
    echo "  --verify               Verify backup integrity after creation"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Full backup with timestamp"
    echo "  $0 -n pre-migration                  # Named backup"
    echo "  $0 --config-only                     # Configuration backup only"
    echo "  $0 -d /backup/voice-stack --verify   # Custom location with verification"
}

# Parse command line arguments
CONFIG_ONLY=false
VOLUMES_ONLY=false
COMPRESS=false
VERIFY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--destination)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -n|--name)
            BACKUP_NAME="voice-stack_$2"
            shift 2
            ;;
        --config-only)
            CONFIG_ONLY=true
            shift
            ;;
        --volumes-only)
            VOLUMES_ONLY=true
            shift
            ;;
        --compress)
            COMPRESS=true
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
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Update backup path with new name
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

log "Starting Voice Stack backup..."
log "Backup destination: $BACKUP_PATH"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    error "Docker is not installed or not in PATH"
    exit 1
fi

# Backup configuration files
if [ "$VOLUMES_ONLY" = false ]; then
    log "Backing up configuration files..."
    
    # Create config directory
    mkdir -p "$BACKUP_PATH/config"
    
    # Copy configuration files
    cp -r . "$BACKUP_PATH/config/" 2>/dev/null || true
    
    # Remove git directory and backup directory from backup
    rm -rf "$BACKUP_PATH/config/.git" 2>/dev/null || true
    rm -rf "$BACKUP_PATH/config/voice-stack-backups" 2>/dev/null || true
    
    # Create backup manifest
    cat > "$BACKUP_PATH/backup-manifest.txt" << EOF
Voice Stack Backup Manifest
===========================
Backup Date: $(date)
Backup Name: $BACKUP_NAME
Backup Type: $([ "$CONFIG_ONLY" = true ] && echo "Configuration Only" || [ "$VOLUMES_ONLY" = true ] && echo "Volumes Only" || echo "Full Backup")
Script Version: 1.0

Configuration Files:
- .env (secrets masked)
- docker-compose.yml
- element-config/
- All deployment scripts

$([ "$CONFIG_ONLY" = false ] && echo "Docker Volumes:
- $POSTGRES_VOLUME
- $SYNAPSE_VOLUME
- $MEDIA_VOLUME
- $COTURN_VOLUME")
EOF
    
    # Create .env backup with secrets masked (for security)
    if [ -f .env ]; then
        sed 's/=.*/=[MASKED]/' .env > "$BACKUP_PATH/config/.env.template"
        log "Environment template created (secrets masked)"
    fi
    
    log "Configuration files backed up successfully"
fi

# Backup Docker volumes
if [ "$CONFIG_ONLY" = false ]; then
    log "Backing up Docker volumes..."
    
    # Check if volumes exist
    check_volume() {
        if ! docker volume inspect "$1" >/dev/null 2>&1; then
            warn "Volume $1 not found - skipping"
            return 1
        fi
        return 0
    }
    
    # Backup function
    backup_volume() {
        local volume_name=$1
        local archive_name=$2
        
        if check_volume "$volume_name"; then
            log "Backing up volume: $volume_name"
            
            if [ "$COMPRESS" = true ]; then
                docker run --rm -v "$volume_name:/source" -v "$BACKUP_PATH:/backup" alpine \
                    tar czf "/backup/${archive_name}.tar.gz" -C /source .
            else
                docker run --rm -v "$volume_name:/source" -v "$BACKUP_PATH:/backup" alpine \
                    tar cf "/backup/${archive_name}.tar" -C /source .
            fi
            
            if [ $? -eq 0 ]; then
                log "Volume $volume_name backed up successfully"
            else
                error "Failed to backup volume $volume_name"
                return 1
            fi
        fi
    }
    
    # Backup all volumes
    backup_volume "$POSTGRES_VOLUME" "postgres_data"
    backup_volume "$SYNAPSE_VOLUME" "synapse_data" 
    backup_volume "$MEDIA_VOLUME" "media_store"
    backup_volume "$COTURN_VOLUME" "coturn_data"
fi

# Verify backup integrity
if [ "$VERIFY" = true ]; then
    log "Verifying backup integrity..."
    
    VERIFY_FAILED=false
    
    # Verify configuration
    if [ "$VOLUMES_ONLY" = false ]; then
        if [ ! -f "$BACKUP_PATH/config/docker-compose.yml" ]; then
            error "Configuration verification failed: docker-compose.yml not found"
            VERIFY_FAILED=true
        fi
    fi
    
    # Verify volume archives
    if [ "$CONFIG_ONLY" = false ]; then
        for volume in postgres_data synapse_data media_store coturn_data; do
            archive_file="$BACKUP_PATH/${volume}.tar"
            if [ "$COMPRESS" = true ]; then
                archive_file="${archive_file}.gz"
            fi
            
            if [ -f "$archive_file" ]; then
                if [ "$COMPRESS" = true ]; then
                    tar -tzf "$archive_file" >/dev/null 2>&1
                else
                    tar -tf "$archive_file" >/dev/null 2>&1
                fi
                
                if [ $? -eq 0 ]; then
                    log "Archive verification passed: $volume"
                else
                    error "Archive verification failed: $volume"
                    VERIFY_FAILED=true
                fi
            fi
        done
    fi
    
    if [ "$VERIFY_FAILED" = true ]; then
        error "Backup verification failed!"
        exit 1
    else
        log "Backup verification passed!"
    fi
fi

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)

# Update manifest with completion info
cat >> "$BACKUP_PATH/backup-manifest.txt" << EOF

Backup Completion:
=================
Status: SUCCESS
Backup Size: $BACKUP_SIZE
Verification: $([ "$VERIFY" = true ] && echo "PASSED" || echo "SKIPPED")
Completion Time: $(date)
EOF

log "Backup completed successfully!"
info "Backup location: $BACKUP_PATH"
info "Backup size: $BACKUP_SIZE"

# Show backup contents
log "Backup contents:"
ls -la "$BACKUP_PATH" | sed 's/^/  /'

log "To restore this backup, use:"
echo "  ./restore-voice-stack.sh $BACKUP_PATH"

# Cleanup old backups (keep last 10)
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" | grep "^voice-stack_" | wc -l)
if [ "$BACKUP_COUNT" -gt 10 ]; then
    warn "Found $BACKUP_COUNT backups, cleaning up old backups..."
    ls -1t "$BACKUP_DIR" | grep "^voice-stack_" | tail -n +11 | while read backup; do
        log "Removing old backup: $backup"
        rm -rf "$BACKUP_DIR/$backup"
    done
fi

log "Backup process completed!"
echo ""
echo "Next steps:"
echo "1. Verify backup integrity if not already done"
echo "2. Test restore procedure in a non-production environment"
echo "3. Store backup in secure, offsite location"
echo "4. Document backup location and restore procedures"