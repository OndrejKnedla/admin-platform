#!/bin/bash
#
# service_manager.sh - Manages system services
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script provides functions to manage system services

# Configuration
LOG_DIR="../logs"
mkdir -p $LOG_DIR

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_DIR/service_manager.log"
    echo "$1"
}

# Function to check if user has sudo privileges
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        log_message "This operation requires sudo privileges. Please run with sudo."
        echo "This operation requires sudo privileges. Please run with sudo."
        return 1
    fi
    return 0
}

# Function to list all services
list_services() {
    log_message "Listing all services..."
    
    if command -v systemctl &> /dev/null; then
        echo "=== SYSTEMD SERVICES ==="
        systemctl list-units --type=service --all
    elif command -v service &> /dev/null; then
        echo "=== SYSTEM V SERVICES ==="
        service --status-all
    else
        log_message "No supported service manager found"
        echo "No supported service manager found (systemd or SysV init)"
        return 1
    fi
    
    return 0
}

# Function to check status of a specific service
check_service() {
    if [ -z "$1" ]; then
        log_message "No service name provided"
        echo "Usage: $0 check_service SERVICE_NAME"
        return 1
    fi
    
    service_name="$1"
    log_message "Checking status of service: $service_name"
    
    if command -v systemctl &> /dev/null; then
        systemctl status "$service_name"
    elif command -v service &> /dev/null; then
        service "$service_name" status
    else
        log_message "No supported service manager found"
        echo "No supported service manager found (systemd or SysV init)"
        return 1
    fi
    
    return $?
}

# Function to start a service
start_service() {
    if [ -z "$1" ]; then
        log_message "No service name provided"
        echo "Usage: $0 start_service SERVICE_NAME"
        return 1
    fi
    
    service_name="$1"
    
    # Check for sudo privileges
    check_sudo || return 1
    
    log_message "Starting service: $service_name"
    
    if command -v systemctl &> /dev/null; then
        systemctl start "$service_name"
    elif command -v service &> /dev/null; then
        service "$service_name" start
    else
        log_message "No supported service manager found"
        echo "No supported service manager found (systemd or SysV init)"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Service $service_name started successfully"
        echo "Service $service_name started successfully"
    else
        log_message "Failed to start service $service_name"
        echo "Failed to start service $service_name"
    fi
    
    return $?
}

# Function to stop a service
stop_service() {
    if [ -z "$1" ]; then
        log_message "No service name provided"
        echo "Usage: $0 stop_service SERVICE_NAME"
        return 1
    fi
    
    service_name="$1"
    
    # Check for sudo privileges
    check_sudo || return 1
    
    log_message "Stopping service: $service_name"
    
    if command -v systemctl &> /dev/null; then
        systemctl stop "$service_name"
    elif command -v service &> /dev/null; then
        service "$service_name" stop
    else
        log_message "No supported service manager found"
        echo "No supported service manager found (systemd or SysV init)"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Service $service_name stopped successfully"
        echo "Service $service_name stopped successfully"
    else
        log_message "Failed to stop service $service_name"
        echo "Failed to stop service $service_name"
    fi
    
    return $?
}

# Function to restart a service
restart_service() {
    if [ -z "$1" ]; then
        log_message "No service name provided"
        echo "Usage: $0 restart_service SERVICE_NAME"
        return 1
    fi
    
    service_name="$1"
    
    # Check for sudo privileges
    check_sudo || return 1
    
    log_message "Restarting service: $service_name"
    
    if command -v systemctl &> /dev/null; then
        systemctl restart "$service_name"
    elif command -v service &> /dev/null; then
        service "$service_name" restart
    else
        log_message "No supported service manager found"
        echo "No supported service manager found (systemd or SysV init)"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Service $service_name restarted successfully"
        echo "Service $service_name restarted successfully"
    else
        log_message "Failed to restart service $service_name"
        echo "Failed to restart service $service_name"
    fi
    
    return $?
}

# Function to enable a service at boot
enable_service() {
    if [ -z "$1" ]; then
        log_message "No service name provided"
        echo "Usage: $0 enable_service SERVICE_NAME"
        return 1
    fi
    
    service_name="$1"
    
    # Check for sudo privileges
    check_sudo || return 1
    
    log_message "Enabling service at boot: $service_name"
    
    if command -v systemctl &> /dev/null; then
        systemctl enable "$service_name"
    else
        log_message "Service enabling is only supported with systemd"
        echo "Service enabling is only supported with systemd"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Service $service_name enabled successfully"
        echo "Service $service_name enabled successfully"
    else
        log_message "Failed to enable service $service_name"
        echo "Failed to enable service $service_name"
    fi
    
    return $?
}

# Function to disable a service at boot
disable_service() {
    if [ -z "$1" ]; then
        log_message "No service name provided"
        echo "Usage: $0 disable_service SERVICE_NAME"
        return 1
    fi
    
    service_name="$1"
    
    # Check for sudo privileges
    check_sudo || return 1
    
    log_message "Disabling service at boot: $service_name"
    
    if command -v systemctl &> /dev/null; then
        systemctl disable "$service_name"
    else
        log_message "Service disabling is only supported with systemd"
        echo "Service disabling is only supported with systemd"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_message "Service $service_name disabled successfully"
        echo "Service $service_name disabled successfully"
    else
        log_message "Failed to disable service $service_name"
        echo "Failed to disable service $service_name"
    fi
    
    return $?
}

# Main function to handle command line arguments
main() {
    case "$1" in
        list)
            list_services
            ;;
        check)
            check_service "$2"
            ;;
        start)
            start_service "$2"
            ;;
        stop)
            stop_service "$2"
            ;;
        restart)
            restart_service "$2"
            ;;
        enable)
            enable_service "$2"
            ;;
        disable)
            disable_service "$2"
            ;;
        *)
            echo "Usage: $0 {list|check|start|stop|restart|enable|disable} [SERVICE_NAME]"
            echo
            echo "Commands:"
            echo "  list                  List all services"
            echo "  check SERVICE_NAME    Check status of a specific service"
            echo "  start SERVICE_NAME    Start a service"
            echo "  stop SERVICE_NAME     Stop a service"
            echo "  restart SERVICE_NAME  Restart a service"
            echo "  enable SERVICE_NAME   Enable a service at boot"
            echo "  disable SERVICE_NAME  Disable a service at boot"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
