#!/bin/bash
#
# system_info.sh - Collects and displays system information
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script gathers key system metrics and information

# Set output directory
DATA_DIR="../data"
LOG_DIR="../logs"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="$DATA_DIR/system_info_$TIMESTAMP.log"

# Create directories if they don't exist
mkdir -p $DATA_DIR
mkdir -p $LOG_DIR

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_DIR/script.log"
    echo "$1"
}

# Function to get system uptime
get_uptime() {
    log_message "Collecting system uptime..."
    uptime
}

# Function to get memory usage
get_memory_usage() {
    log_message "Collecting memory usage..."
    free -h
}

# Function to get disk usage
get_disk_usage() {
    log_message "Collecting disk usage..."
    df -h
}

# Function to get CPU information
get_cpu_info() {
    log_message "Collecting CPU information..."
    lscpu | grep -E 'Model name|^CPU\(s\)|Thread|Core|Socket|MHz'
}

# Function to get current users
get_current_users() {
    log_message "Collecting current user information..."
    who
}

# Function to get top processes by CPU usage
get_top_processes() {
    log_message "Collecting top processes by CPU usage..."
    ps aux --sort=-%cpu | head -11
}

# Function to get network information
get_network_info() {
    log_message "Collecting network information..."
    ip addr show
    echo -e "\nNetwork connections:"
    netstat -tuln
}

# Main function to collect all information
collect_all_info() {
    {
        echo "==================================="
        echo "SYSTEM INFORMATION REPORT"
        echo "Generated on: $(date)"
        echo "==================================="
        echo
        
        echo "=== SYSTEM UPTIME ==="
        get_uptime
        echo
        
        echo "=== MEMORY USAGE ==="
        get_memory_usage
        echo
        
        echo "=== DISK USAGE ==="
        get_disk_usage
        echo
        
        echo "=== CPU INFORMATION ==="
        get_cpu_info
        echo
        
        echo "=== CURRENT USERS ==="
        get_current_users
        echo
        
        echo "=== TOP PROCESSES ==="
        get_top_processes
        echo
        
        echo "=== NETWORK INFORMATION ==="
        get_network_info
        echo
        
        echo "==================================="
        echo "END OF REPORT"
        echo "==================================="
    } | tee "$OUTPUT_FILE"
    
    log_message "System information collected and saved to $OUTPUT_FILE"
}

# Execute the main function
collect_all_info
