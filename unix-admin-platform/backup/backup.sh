#!/bin/bash
#
# backup.sh - Backup system for the Unix System Administration Platform
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script performs system backups

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# Configuration
CONFIG_FILE="config/platform.conf"
LOG_DIR="logs"
DATA_DIR="data"
BACKUP_LOG="$LOG_DIR/backup.log"
BACKUP_DIR="$DATA_DIR/backups"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$BACKUP_DIR"

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$BACKUP_LOG"
    echo "$1"
}

# Function to read configuration
read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Read backup settings from config
        BACKUP_DIRS=$(grep "BACKUP_DIRS=" "$CONFIG_FILE" | cut -d'"' -f2)
        BACKUP_RETENTION=$(grep "BACKUP_RETENTION=" "$CONFIG_FILE" | cut -d'=' -f2)
        
        # Set defaults if not found
        BACKUP_DIRS=${BACKUP_DIRS:-"/etc /home /var/www"}
        BACKUP_RETENTION=${BACKUP_RETENTION:-7}  # 7 days
    else
        log_message "Configuration file not found, using default backup settings"
        BACKUP_DIRS="/etc /home /var/www"
        BACKUP_RETENTION=7
    fi
}

# Function to create a backup
create_backup() {
    log_message "Creating backup..."
    
    # Create timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Create backup directory for this run
    CURRENT_BACKUP_DIR="$BACKUP_DIR/$TIMESTAMP"
    mkdir -p "$CURRENT_BACKUP_DIR"
    
    # Create a file with system information
    log_message "Saving system information..."
    {
        echo "System Backup - $TIMESTAMP"
        echo "======================="
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "OS: $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)"
        echo "Uptime: $(uptime -p)"
        echo "======================="
    } > "$CURRENT_BACKUP_DIR/system_info.txt"
    
    # Backup each directory
    for dir in $BACKUP_DIRS; do
        if [ -d "$dir" ]; then
            log_message "Backing up directory: $dir"
            
            # Create directory name (replace / with _)
            DIR_NAME=$(echo "$dir" | tr '/' '_')
            
            # Create tar archive
            tar -czf "$CURRENT_BACKUP_DIR/${DIR_NAME}.tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")" 2>/dev/null
            
            # Check if backup was successful
            if [ $? -eq 0 ]; then
                log_message "Backup of $dir completed successfully"
                
                # Get file size
                SIZE=$(du -h "$CURRENT_BACKUP_DIR/${DIR_NAME}.tar.gz" | cut -f1)
                log_message "Backup size: $SIZE"
            else
                log_message "Backup of $dir failed"
            fi
        else
            log_message "Directory $dir does not exist, skipping"
        fi
    done
    
    # Create a manifest file
    log_message "Creating backup manifest..."
    {
        echo "Backup Manifest - $TIMESTAMP"
        echo "======================="
        echo "Backup Location: $CURRENT_BACKUP_DIR"
        echo "Directories Backed Up:"
        for dir in $BACKUP_DIRS; do
            echo "  - $dir"
        done
        echo "Files:"
        ls -la "$CURRENT_BACKUP_DIR" | while read -r line; do
            echo "  $line"
        done
        echo "======================="
    } > "$CURRENT_BACKUP_DIR/manifest.txt"
    
    # Create a symlink to the latest backup
    ln -sf "$CURRENT_BACKUP_DIR" "$BACKUP_DIR/latest"
    
    # Save backup information
    echo "{\"timestamp\": \"$TIMESTAMP\", \"location\": \"$CURRENT_BACKUP_DIR\", \"directories\": \"$BACKUP_DIRS\"}" > "$DATA_DIR/last_backup_info.json"
    
    log_message "Backup completed successfully"
    return 0
}

# Function to clean up old backups
cleanup_old_backups() {
    log_message "Cleaning up old backups..."
    
    # Get current date in seconds since epoch
    CURRENT_DATE=$(date +%s)
    
    # Calculate cutoff date
    CUTOFF_DATE=$((CURRENT_DATE - (BACKUP_RETENTION * 86400)))
    
    # Find and remove old backups
    find "$BACKUP_DIR" -maxdepth 1 -type d -not -path "$BACKUP_DIR" | while read -r backup_dir; do
        # Extract timestamp from directory name
        DIR_NAME=$(basename "$backup_dir")
        
        # Skip if not a timestamp directory
        if ! [[ $DIR_NAME =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
            continue
        fi
        
        # Convert timestamp to date in seconds
        YEAR=${DIR_NAME:0:4}
        MONTH=${DIR_NAME:4:2}
        DAY=${DIR_NAME:6:2}
        HOUR=${DIR_NAME:9:2}
        MINUTE=${DIR_NAME:11:2}
        SECOND=${DIR_NAME:13:2}
        
        BACKUP_DATE=$(date -d "$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND" +%s 2>/dev/null)
        
        # Skip if date conversion failed
        if [ -z "$BACKUP_DATE" ]; then
            continue
        fi
        
        # Check if backup is older than retention period
        if [ "$BACKUP_DATE" -lt "$CUTOFF_DATE" ]; then
            log_message "Removing old backup: $backup_dir"
            rm -rf "$backup_dir"
        fi
    done
    
    log_message "Cleanup completed"
    return 0
}

# Function to list backups
list_backups() {
    log_message "Listing available backups..."
    
    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        log_message "No backups found"
        return 0
    fi
    
    # Find backup directories
    BACKUPS=$(find "$BACKUP_DIR" -maxdepth 1 -type d -not -path "$BACKUP_DIR" | sort)
    
    # Check if any backups exist
    if [ -z "$BACKUPS" ]; then
        log_message "No backups found"
        return 0
    fi
    
    # Print header
    echo "Available Backups:"
    echo "-----------------"
    
    # List each backup
    echo "$BACKUPS" | while read -r backup_dir; do
        # Extract timestamp from directory name
        DIR_NAME=$(basename "$backup_dir")
        
        # Skip if not a timestamp directory
        if ! [[ $DIR_NAME =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
            continue
        fi
        
        # Format timestamp
        YEAR=${DIR_NAME:0:4}
        MONTH=${DIR_NAME:4:2}
        DAY=${DIR_NAME:6:2}
        HOUR=${DIR_NAME:9:2}
        MINUTE=${DIR_NAME:11:2}
        SECOND=${DIR_NAME:13:2}
        
        FORMATTED_DATE="$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND"
        
        # Get backup size
        SIZE=$(du -sh "$backup_dir" | cut -f1)
        
        # Get number of files
        FILE_COUNT=$(find "$backup_dir" -type f | wc -l)
        
        # Print backup information
        echo "Backup: $DIR_NAME"
        echo "  Date: $FORMATTED_DATE"
        echo "  Size: $SIZE"
        echo "  Files: $FILE_COUNT"
        echo "  Path: $backup_dir"
        echo
    done
    
    return 0
}

# Function to restore a backup
restore_backup() {
    local backup_id="$1"
    local target_dir="$2"
    
    log_message "Restoring backup $backup_id to $target_dir..."
    
    # Check if backup ID is provided
    if [ -z "$backup_id" ]; then
        log_message "No backup ID provided"
        return 1
    fi
    
    # Check if target directory is provided
    if [ -z "$target_dir" ]; then
        log_message "No target directory provided"
        return 1
    fi
    
    # Check if backup exists
    BACKUP_PATH="$BACKUP_DIR/$backup_id"
    if [ ! -d "$BACKUP_PATH" ]; then
        log_message "Backup $backup_id not found"
        return 1
    fi
    
    # Check if target directory exists
    if [ ! -d "$target_dir" ]; then
        log_message "Creating target directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Find all tar.gz files in the backup
    ARCHIVES=$(find "$BACKUP_PATH" -name "*.tar.gz")
    
    # Check if any archives exist
    if [ -z "$ARCHIVES" ]; then
        log_message "No archives found in backup $backup_id"
        return 1
    fi
    
    # Extract each archive
    echo "$ARCHIVES" | while read -r archive; do
        log_message "Extracting $archive to $target_dir"
        tar -xzf "$archive" -C "$target_dir"
        
        # Check if extraction was successful
        if [ $? -eq 0 ]; then
            log_message "Extraction of $archive completed successfully"
        else
            log_message "Extraction of $archive failed"
        fi
    done
    
    log_message "Restore completed"
    return 0
}

# Function to display help
display_help() {
    echo "Backup System for Unix System Administration Platform"
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  backup        Create a new backup"
    echo "  list          List available backups"
    echo "  restore ID DIR  Restore backup ID to directory DIR"
    echo "  cleanup       Clean up old backups"
    echo "  help          Display this help message"
    echo
    echo "Examples:"
    echo "  $0 backup                         Create a new backup"
    echo "  $0 list                           List available backups"
    echo "  $0 restore 20230101_120000 /tmp/restore  Restore backup to /tmp/restore"
    echo "  $0 cleanup                        Clean up old backups"
    echo
}

# Main function
main() {
    # Read configuration
    read_config
    
    # Process command line arguments
    case "$1" in
        backup)
            create_backup
            ;;
        list)
            list_backups
            ;;
        restore)
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo "Error: Missing arguments for restore command"
                display_help
                exit 1
            fi
            restore_backup "$2" "$3"
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        help|--help|-h)
            display_help
            ;;
        *)
            echo "Error: Unknown command: $1"
            display_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
