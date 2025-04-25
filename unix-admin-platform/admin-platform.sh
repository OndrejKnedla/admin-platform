#!/bin/bash
#
# admin-platform.sh - Main entry point for the Unix System Administration Platform
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script serves as the main entry point for the Unix System Administration Platform

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Configuration
CONFIG_DIR="config"
LOG_DIR="logs"
DATA_DIR="data"
MODULES_DIR=("core" "scheduler" "security" "web" "remote" "backup")

# Create necessary directories
mkdir -p "$LOG_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$CONFIG_DIR"

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check for required dependencies
check_dependencies() {
    print_message "Checking for required dependencies..."
    
    MISSING_DEPS=()
    
    # Check for basic commands
    for cmd in bash ps top df du find grep awk sort head tail; do
        if ! command_exists "$cmd"; then
            MISSING_DEPS+=("$cmd")
        fi
    done
    
    # Check for web server dependencies
    if ! command_exists "python3"; then
        MISSING_DEPS+=("python3")
    fi
    
    # Report missing dependencies
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        print_error "The following required dependencies are missing:"
        for dep in "${MISSING_DEPS[@]}"; do
            echo "  - $dep"
        done
        print_error "Please install these dependencies before continuing."
        return 1
    fi
    
    print_message "All required dependencies are installed."
    return 0
}

# Function to initialize the platform
initialize_platform() {
    print_message "Initializing the Unix System Administration Platform..."
    
    # Make all module scripts executable
    for module in "${MODULES_DIR[@]}"; do
        if [ -d "$module" ]; then
            find "$module" -name "*.sh" -exec chmod +x {} \;
        fi
    done
    
    # Create default configuration if it doesn't exist
    if [ ! -f "$CONFIG_DIR/platform.conf" ]; then
        print_message "Creating default configuration..."
        cat > "$CONFIG_DIR/platform.conf" << EOF
# Unix System Administration Platform Configuration

# General Settings
PLATFORM_NAME="Unix Admin Platform"
ADMIN_EMAIL="admin@example.com"

# Monitoring Settings
MONITORING_INTERVAL=300  # seconds
CPU_THRESHOLD=80         # percentage
MEMORY_THRESHOLD=80      # percentage
DISK_THRESHOLD=90        # percentage

# Web Interface Settings
WEB_PORT=8080
WEB_HOST=localhost
ENABLE_WEB_INTERFACE=true

# Security Settings
ENABLE_SECURITY_SCANS=true
SECURITY_SCAN_INTERVAL=3600  # seconds

# Backup Settings
BACKUP_DIRS="/etc /home /var/www"
BACKUP_INTERVAL=86400  # seconds (daily)
BACKUP_RETENTION=7     # days

# Remote Management Settings
ENABLE_REMOTE=false
REMOTE_HOSTS=""
SSH_KEY_PATH=""
EOF
    fi
    
    print_message "Platform initialized successfully."
    return 0
}

# Function to start the web interface
start_web_interface() {
    print_message "Starting web interface..."
    
    # Check if web interface is enabled in config
    if grep -q "ENABLE_WEB_INTERFACE=true" "$CONFIG_DIR/platform.conf"; then
        # Extract port from config
        WEB_PORT=$(grep "WEB_PORT=" "$CONFIG_DIR/platform.conf" | cut -d'=' -f2)
        WEB_PORT=${WEB_PORT:-8080}  # Default to 8080 if not found
        
        # Check if port is already in use
        if netstat -tuln | grep -q ":$WEB_PORT "; then
            print_error "Port $WEB_PORT is already in use. Please configure a different port."
            return 1
        fi
        
        # Start the web server in the background
        if [ -f "web/server.py" ]; then
            nohup python3 web/server.py "$WEB_PORT" > "$LOG_DIR/web_server.log" 2>&1 &
            WEB_PID=$!
            echo "$WEB_PID" > "$DATA_DIR/web_server.pid"
            print_message "Web interface started on http://localhost:$WEB_PORT (PID: $WEB_PID)"
        else
            print_error "Web server script not found."
            return 1
        fi
    else
        print_warning "Web interface is disabled in configuration."
    fi
    
    return 0
}

# Function to stop the web interface
stop_web_interface() {
    print_message "Stopping web interface..."
    
    if [ -f "$DATA_DIR/web_server.pid" ]; then
        WEB_PID=$(cat "$DATA_DIR/web_server.pid")
        if ps -p "$WEB_PID" > /dev/null; then
            kill "$WEB_PID"
            print_message "Web interface stopped (PID: $WEB_PID)"
        else
            print_warning "Web server process not found."
        fi
        rm -f "$DATA_DIR/web_server.pid"
    else
        print_warning "Web server PID file not found."
    fi
    
    return 0
}

# Function to start the scheduler
start_scheduler() {
    print_message "Starting task scheduler..."
    
    if [ -f "scheduler/scheduler.sh" ]; then
        nohup ./scheduler/scheduler.sh start > "$LOG_DIR/scheduler.log" 2>&1 &
        SCHEDULER_PID=$!
        echo "$SCHEDULER_PID" > "$DATA_DIR/scheduler.pid"
        print_message "Task scheduler started (PID: $SCHEDULER_PID)"
    else
        print_error "Scheduler script not found."
        return 1
    fi
    
    return 0
}

# Function to stop the scheduler
stop_scheduler() {
    print_message "Stopping task scheduler..."
    
    if [ -f "$DATA_DIR/scheduler.pid" ]; then
        SCHEDULER_PID=$(cat "$DATA_DIR/scheduler.pid")
        if ps -p "$SCHEDULER_PID" > /dev/null; then
            kill "$SCHEDULER_PID"
            print_message "Task scheduler stopped (PID: $SCHEDULER_PID)"
        else
            print_warning "Scheduler process not found."
        fi
        rm -f "$DATA_DIR/scheduler.pid"
    else
        print_warning "Scheduler PID file not found."
    fi
    
    return 0
}

# Function to display platform status
display_status() {
    print_header "===== Unix System Administration Platform Status ====="
    
    # Check if web interface is running
    if [ -f "$DATA_DIR/web_server.pid" ]; then
        WEB_PID=$(cat "$DATA_DIR/web_server.pid")
        if ps -p "$WEB_PID" > /dev/null; then
            WEB_PORT=$(grep "WEB_PORT=" "$CONFIG_DIR/platform.conf" | cut -d'=' -f2)
            WEB_PORT=${WEB_PORT:-8080}
            print_message "Web Interface: RUNNING (PID: $WEB_PID, URL: http://localhost:$WEB_PORT)"
        else
            print_warning "Web Interface: STOPPED (stale PID file)"
        fi
    else
        print_warning "Web Interface: STOPPED"
    fi
    
    # Check if scheduler is running
    if [ -f "$DATA_DIR/scheduler.pid" ]; then
        SCHEDULER_PID=$(cat "$DATA_DIR/scheduler.pid")
        if ps -p "$SCHEDULER_PID" > /dev/null; then
            print_message "Task Scheduler: RUNNING (PID: $SCHEDULER_PID)"
        else
            print_warning "Task Scheduler: STOPPED (stale PID file)"
        fi
    else
        print_warning "Task Scheduler: STOPPED"
    fi
    
    # Display last monitoring run
    if [ -f "$DATA_DIR/last_monitoring_run" ]; then
        LAST_RUN=$(cat "$DATA_DIR/last_monitoring_run")
        print_message "Last Monitoring Run: $LAST_RUN"
    else
        print_warning "Monitoring: No previous runs found"
    fi
    
    # Display last security scan
    if [ -f "$DATA_DIR/last_security_scan" ]; then
        LAST_SCAN=$(cat "$DATA_DIR/last_security_scan")
        print_message "Last Security Scan: $LAST_SCAN"
    else
        print_warning "Security Scanner: No previous scans found"
    fi
    
    # Display last backup
    if [ -f "$DATA_DIR/last_backup" ]; then
        LAST_BACKUP=$(cat "$DATA_DIR/last_backup")
        print_message "Last Backup: $LAST_BACKUP"
    else
        print_warning "Backup System: No previous backups found"
    fi
    
    print_header "===================================================="
}

# Function to run a system monitoring check
run_monitoring() {
    print_message "Running system monitoring check..."
    
    if [ -f "core/monitor.sh" ]; then
        ./core/monitor.sh
        echo "$(date)" > "$DATA_DIR/last_monitoring_run"
        print_message "Monitoring check completed."
    else
        print_error "Monitoring script not found."
        return 1
    fi
    
    return 0
}

# Function to run a security scan
run_security_scan() {
    print_message "Running security scan..."
    
    if [ -f "security/scanner.sh" ]; then
        ./security/scanner.sh
        echo "$(date)" > "$DATA_DIR/last_security_scan"
        print_message "Security scan completed."
    else
        print_error "Security scanner script not found."
        return 1
    fi
    
    return 0
}

# Function to run a backup
run_backup() {
    print_message "Running backup..."
    
    if [ -f "backup/backup.sh" ]; then
        ./backup/backup.sh
        echo "$(date)" > "$DATA_DIR/last_backup"
        print_message "Backup completed."
    else
        print_error "Backup script not found."
        return 1
    fi
    
    return 0
}

# Function to display help
display_help() {
    print_header "Unix System Administration Platform"
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start         Start all platform components"
    echo "  stop          Stop all platform components"
    echo "  restart       Restart all platform components"
    echo "  status        Display platform status"
    echo "  web start     Start only the web interface"
    echo "  web stop      Stop only the web interface"
    echo "  scheduler start  Start only the task scheduler"
    echo "  scheduler stop   Stop only the task scheduler"
    echo "  monitor       Run a system monitoring check"
    echo "  security      Run a security scan"
    echo "  backup        Run a backup"
    echo "  help          Display this help message"
    echo
}

# Main function
main() {
    # Check dependencies
    check_dependencies || exit 1
    
    # Initialize platform if needed
    initialize_platform
    
    # Process command line arguments
    case "$1" in
        start)
            print_header "Starting Unix System Administration Platform..."
            start_web_interface
            start_scheduler
            print_message "Platform started successfully."
            display_status
            ;;
        stop)
            print_header "Stopping Unix System Administration Platform..."
            stop_web_interface
            stop_scheduler
            print_message "Platform stopped successfully."
            ;;
        restart)
            print_header "Restarting Unix System Administration Platform..."
            stop_web_interface
            stop_scheduler
            sleep 2
            start_web_interface
            start_scheduler
            print_message "Platform restarted successfully."
            display_status
            ;;
        status)
            display_status
            ;;
        web)
            case "$2" in
                start)
                    start_web_interface
                    ;;
                stop)
                    stop_web_interface
                    ;;
                *)
                    print_error "Unknown web command: $2"
                    display_help
                    exit 1
                    ;;
            esac
            ;;
        scheduler)
            case "$2" in
                start)
                    start_scheduler
                    ;;
                stop)
                    stop_scheduler
                    ;;
                *)
                    print_error "Unknown scheduler command: $2"
                    display_help
                    exit 1
                    ;;
            esac
            ;;
        monitor)
            run_monitoring
            ;;
        security)
            run_security_scan
            ;;
        backup)
            run_backup
            ;;
        help|--help|-h)
            display_help
            ;;
        *)
            if [ -z "$1" ]; then
                display_help
            else
                print_error "Unknown command: $1"
                display_help
                exit 1
            fi
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
