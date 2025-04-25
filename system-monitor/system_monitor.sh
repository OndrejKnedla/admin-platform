#!/bin/bash
#
# system_monitor.sh - Main script for the System Monitoring and Management Tool
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This is the main entry point for the system monitoring tool

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Configuration
LOG_DIR="logs"
DATA_DIR="data"
SCRIPTS_DIR="scripts"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$DATA_DIR"

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_DIR/system_monitor.log"
    echo "$1"
}

# Function to check if scripts are executable
check_scripts() {
    log_message "Checking script permissions..."
    
    # Make all scripts executable
    chmod +x "$SCRIPTS_DIR"/*.sh
    
    log_message "All scripts are now executable"
}

# Function to display help
display_help() {
    echo "System Monitoring and Management Tool"
    echo "-------------------------------------"
    echo
    echo "Usage: $0 [COMMAND] [ARGS]"
    echo
    echo "Commands:"
    echo "  system-info                  Collect and display system information"
    echo "  process-monitor              Monitor processes and alert on high resource usage"
    echo "  service SUBCOMMAND [ARGS]    Manage system services"
    echo "  network SUBCOMMAND [ARGS]    Monitor network and perform diagnostics"
    echo "  disk SUBCOMMAND [ARGS]       Analyze disk usage and find large files"
    echo "  help                         Display this help message"
    echo
    echo "Examples:"
    echo "  $0 system-info               Display system information"
    echo "  $0 process-monitor           Monitor processes"
    echo "  $0 service list              List all services"
    echo "  $0 service check apache2     Check status of apache2 service"
    echo "  $0 network all               Collect all network information"
    echo "  $0 network ping google.com   Ping google.com"
    echo "  $0 disk usage                Show disk usage"
    echo "  $0 disk full /home           Perform full disk analysis on /home"
    echo
}

# Main function
main() {
    # Check script permissions
    check_scripts
    
    # Process command line arguments
    case "$1" in
        system-info)
            log_message "Running system information script..."
            "$SCRIPTS_DIR/system_info.sh"
            ;;
        process-monitor)
            log_message "Running process monitor script..."
            "$SCRIPTS_DIR/process_monitor.sh"
            ;;
        service)
            log_message "Running service manager script with args: ${*:2}"
            "$SCRIPTS_DIR/service_manager.sh" "${@:2}"
            ;;
        network)
            log_message "Running network monitor script with args: ${*:2}"
            "$SCRIPTS_DIR/network_monitor.sh" "${@:2}"
            ;;
        disk)
            log_message "Running disk analyzer script with args: ${*:2}"
            "$SCRIPTS_DIR/disk_analyzer.sh" "${@:2}"
            ;;
        help|--help|-h)
            display_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
