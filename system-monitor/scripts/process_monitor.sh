#!/bin/bash
#
# process_monitor.sh - Monitors system processes and alerts on high resource usage
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script monitors processes and can alert when thresholds are exceeded

# Configuration
CPU_THRESHOLD=80  # CPU usage percentage threshold
MEM_THRESHOLD=80  # Memory usage percentage threshold
LOG_DIR="../logs"
DATA_DIR="../data"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ALERT_LOG="$LOG_DIR/alerts_$TIMESTAMP.log"

# Create directories if they don't exist
mkdir -p $LOG_DIR
mkdir -p $DATA_DIR

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_DIR/process_monitor.log"
    echo "$1"
}

# Function to check CPU usage by process
check_cpu_usage() {
    log_message "Checking for processes with high CPU usage..."
    
    # Get processes using more than the threshold CPU percentage
    high_cpu_processes=$(ps aux | awk -v threshold=$CPU_THRESHOLD '$3 > threshold {print $0}')
    
    if [ -n "$high_cpu_processes" ]; then
        {
            echo "=== HIGH CPU USAGE ALERT ==="
            echo "The following processes are using more than ${CPU_THRESHOLD}% CPU:"
            echo "$high_cpu_processes" | awk '{print "PID: " $2 ", User: " $1 ", CPU: " $3 "%, Command: " $11}'
            echo "================================"
        } | tee -a "$ALERT_LOG"
        
        return 1
    else
        log_message "No processes found exceeding CPU threshold of ${CPU_THRESHOLD}%"
        return 0
    fi
}

# Function to check memory usage by process
check_memory_usage() {
    log_message "Checking for processes with high memory usage..."
    
    # Get processes using more than the threshold memory percentage
    high_mem_processes=$(ps aux | awk -v threshold=$MEM_THRESHOLD '$4 > threshold {print $0}')
    
    if [ -n "$high_mem_processes" ]; then
        {
            echo "=== HIGH MEMORY USAGE ALERT ==="
            echo "The following processes are using more than ${MEM_THRESHOLD}% memory:"
            echo "$high_mem_processes" | awk '{print "PID: " $2 ", User: " $1 ", Memory: " $4 "%, Command: " $11}'
            echo "================================"
        } | tee -a "$ALERT_LOG"
        
        return 1
    else
        log_message "No processes found exceeding memory threshold of ${MEM_THRESHOLD}%"
        return 0
    fi
}

# Function to check for zombie processes
check_zombie_processes() {
    log_message "Checking for zombie processes..."
    
    # Get zombie processes
    zombie_processes=$(ps aux | awk '$8 ~ /Z/ {print $0}')
    
    if [ -n "$zombie_processes" ]; then
        {
            echo "=== ZOMBIE PROCESSES ALERT ==="
            echo "The following zombie processes were detected:"
            echo "$zombie_processes" | awk '{print "PID: " $2 ", User: " $1 ", State: " $8 ", Command: " $11}'
            echo "================================"
        } | tee -a "$ALERT_LOG"
        
        return 1
    else
        log_message "No zombie processes found"
        return 0
    fi
}

# Function to check system load average
check_load_average() {
    log_message "Checking system load average..."
    
    # Get number of CPU cores
    cores=$(nproc)
    
    # Get current load average (1 minute)
    load=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk -F',' '{ print $1 }' | tr -d ' ')
    
    # Calculate threshold based on number of cores
    threshold=$(echo "$cores * 0.8" | bc)
    
    if (( $(echo "$load > $threshold" | bc -l) )); then
        {
            echo "=== HIGH LOAD AVERAGE ALERT ==="
            echo "System load average ($load) is higher than threshold ($threshold)"
            echo "Number of CPU cores: $cores"
            echo "Current processes:"
            ps aux --sort=-%cpu | head -6
            echo "================================"
        } | tee -a "$ALERT_LOG"
        
        return 1
    else
        log_message "System load average ($load) is within acceptable range (threshold: $threshold)"
        return 0
    fi
}

# Main function
monitor_processes() {
    log_message "Starting process monitoring..."
    
    # Initialize alert counter
    alerts=0
    
    # Run all checks
    check_cpu_usage
    alerts=$((alerts + $?))
    
    check_memory_usage
    alerts=$((alerts + $?))
    
    check_zombie_processes
    alerts=$((alerts + $?))
    
    check_load_average
    alerts=$((alerts + $?))
    
    # Report summary
    if [ $alerts -gt 0 ]; then
        log_message "Monitoring complete. $alerts alerts were generated. See $ALERT_LOG for details."
    else
        log_message "Monitoring complete. No alerts were generated."
    fi
}

# Execute the main function
monitor_processes
