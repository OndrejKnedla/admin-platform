#!/bin/bash
#
# monitor.sh - Core system monitoring script
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script monitors system resources and logs alerts

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# Configuration
CONFIG_FILE="config/platform.conf"
LOG_DIR="logs"
DATA_DIR="data"
ALERT_LOG="$LOG_DIR/alerts.log"
MONITORING_DATA="$DATA_DIR/monitoring_data.json"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$DATA_DIR"

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
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_DIR/monitor.log"
    echo "$1"
}

# Function to log alerts
log_alert() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$ALERT_LOG"
    print_warning "$1"
}

# Function to read configuration
read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Read thresholds from config
        CPU_THRESHOLD=$(grep "CPU_THRESHOLD=" "$CONFIG_FILE" | cut -d'=' -f2)
        MEMORY_THRESHOLD=$(grep "MEMORY_THRESHOLD=" "$CONFIG_FILE" | cut -d'=' -f2)
        DISK_THRESHOLD=$(grep "DISK_THRESHOLD=" "$CONFIG_FILE" | cut -d'=' -f2)
        
        # Set defaults if not found
        CPU_THRESHOLD=${CPU_THRESHOLD:-80}
        MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
        DISK_THRESHOLD=${DISK_THRESHOLD:-90}
    else
        log_message "Configuration file not found, using default thresholds"
        CPU_THRESHOLD=80
        MEMORY_THRESHOLD=80
        DISK_THRESHOLD=90
    fi
}

# Function to check CPU usage
check_cpu() {
    log_message "Checking CPU usage..."
    
    # Get CPU usage (average of last minute)
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    
    # Log CPU usage to data file
    echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"cpu\", \"value\": $CPU_USAGE}" >> "$MONITORING_DATA"
    
    # Check if CPU usage exceeds threshold
    if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
        log_alert "HIGH CPU USAGE ALERT: CPU usage is $CPU_USAGE% (threshold: $CPU_THRESHOLD%)"
        
        # Get top CPU consuming processes
        TOP_PROCESSES=$(ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print "  - " $11 " (PID: " $2 ", CPU: " $3 "%, MEM: " $4 "%)"}')
        log_alert "Top CPU consuming processes:\n$TOP_PROCESSES"
        
        return 1
    else
        log_message "CPU usage is $CPU_USAGE% (threshold: $CPU_THRESHOLD%)"
        return 0
    fi
}

# Function to check memory usage
check_memory() {
    log_message "Checking memory usage..."
    
    # Get memory usage
    MEMORY_TOTAL=$(free | grep Mem | awk '{print $2}')
    MEMORY_USED=$(free | grep Mem | awk '{print $3}')
    MEMORY_USAGE=$(echo "scale=2; $MEMORY_USED * 100 / $MEMORY_TOTAL" | bc)
    
    # Log memory usage to data file
    echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"memory\", \"value\": $MEMORY_USAGE}" >> "$MONITORING_DATA"
    
    # Check if memory usage exceeds threshold
    if (( $(echo "$MEMORY_USAGE > $MEMORY_THRESHOLD" | bc -l) )); then
        log_alert "HIGH MEMORY USAGE ALERT: Memory usage is $MEMORY_USAGE% (threshold: $MEMORY_THRESHOLD%)"
        
        # Get top memory consuming processes
        TOP_PROCESSES=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{print "  - " $11 " (PID: " $2 ", MEM: " $4 "%, CPU: " $3 "%)"}')
        log_alert "Top memory consuming processes:\n$TOP_PROCESSES"
        
        return 1
    else
        log_message "Memory usage is $MEMORY_USAGE% (threshold: $MEMORY_THRESHOLD%)"
        return 0
    fi
}

# Function to check disk usage
check_disk() {
    log_message "Checking disk usage..."
    
    # Get disk usage for all mounted filesystems
    DISK_USAGE=$(df -h | grep -v "Filesystem" | awk '{print $1 "," $5 "," $6}')
    
    # Initialize alert flag
    DISK_ALERT=0
    
    # Check each filesystem
    while IFS=',' read -r FILESYSTEM USAGE MOUNTPOINT; do
        # Remove % from usage
        USAGE_PCT=${USAGE/\%/}
        
        # Log disk usage to data file
        echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"disk\", \"filesystem\": \"$FILESYSTEM\", \"mountpoint\": \"$MOUNTPOINT\", \"value\": $USAGE_PCT}" >> "$MONITORING_DATA"
        
        # Check if usage exceeds threshold
        if [ "$USAGE_PCT" -gt "$DISK_THRESHOLD" ]; then
            log_alert "HIGH DISK USAGE ALERT: $FILESYSTEM ($MOUNTPOINT) is $USAGE_PCT% full (threshold: $DISK_THRESHOLD%)"
            DISK_ALERT=1
            
            # Get largest directories in this mountpoint
            if [ "$MOUNTPOINT" != "/" ]; then
                TOP_DIRS=$(du -h "$MOUNTPOINT" 2>/dev/null | sort -rh | head -5 | awk '{print "  - " $2 " (" $1 ")"}')
                if [ -n "$TOP_DIRS" ]; then
                    log_alert "Largest directories in $MOUNTPOINT:\n$TOP_DIRS"
                fi
            fi
        else
            log_message "Disk usage for $FILESYSTEM ($MOUNTPOINT) is $USAGE_PCT% (threshold: $DISK_THRESHOLD%)"
        fi
    done <<< "$DISK_USAGE"
    
    return $DISK_ALERT
}

# Function to check for zombie processes
check_zombies() {
    log_message "Checking for zombie processes..."
    
    # Get zombie processes
    ZOMBIE_COUNT=$(ps aux | awk '$8 ~ /Z/ {print $0}' | wc -l)
    
    # Log zombie count to data file
    echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"zombies\", \"value\": $ZOMBIE_COUNT}" >> "$MONITORING_DATA"
    
    # Check if there are zombie processes
    if [ "$ZOMBIE_COUNT" -gt 0 ]; then
        ZOMBIE_PROCESSES=$(ps aux | awk '$8 ~ /Z/ {print "  - PID: " $2 ", PPID: " $3 ", User: " $1}')
        log_alert "ZOMBIE PROCESSES ALERT: Found $ZOMBIE_COUNT zombie processes:\n$ZOMBIE_PROCESSES"
        return 1
    else
        log_message "No zombie processes found"
        return 0
    fi
}

# Function to check system load
check_load() {
    log_message "Checking system load..."
    
    # Get number of CPU cores
    CPU_CORES=$(nproc)
    
    # Get load averages
    LOAD_1=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk -F',' '{ print $1 }' | tr -d ' ')
    LOAD_5=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk -F',' '{ print $2 }' | tr -d ' ')
    LOAD_15=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk -F',' '{ print $3 }' | tr -d ' ')
    
    # Log load averages to data file
    echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"load\", \"load1\": $LOAD_1, \"load5\": $LOAD_5, \"load15\": $LOAD_15, \"cores\": $CPU_CORES}" >> "$MONITORING_DATA"
    
    # Calculate threshold based on number of cores (80% of cores)
    LOAD_THRESHOLD=$(echo "$CPU_CORES * 0.8" | bc)
    
    # Check if 1-minute load average exceeds threshold
    if (( $(echo "$LOAD_1 > $LOAD_THRESHOLD" | bc -l) )); then
        log_alert "HIGH SYSTEM LOAD ALERT: Load average (1m) is $LOAD_1 (threshold: $LOAD_THRESHOLD for $CPU_CORES cores)"
        
        # Get top CPU consuming processes
        TOP_PROCESSES=$(ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print "  - " $11 " (PID: " $2 ", CPU: " $3 "%, MEM: " $4 "%)"}')
        log_alert "Top CPU consuming processes:\n$TOP_PROCESSES"
        
        return 1
    else
        log_message "System load averages: $LOAD_1 (1m), $LOAD_5 (5m), $LOAD_15 (15m) - threshold: $LOAD_THRESHOLD"
        return 0
    fi
}

# Function to check for failed services
check_services() {
    log_message "Checking for failed services..."
    
    # Check if systemctl is available
    if command -v systemctl &> /dev/null; then
        # Get failed services
        FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
        
        # Log failed services count to data file
        echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"failed_services\", \"value\": $FAILED_SERVICES}" >> "$MONITORING_DATA"
        
        # Check if there are failed services
        if [ "$FAILED_SERVICES" -gt 0 ]; then
            SERVICES_LIST=$(systemctl --failed --no-legend | awk '{print "  - " $1 " (" $2 ")"}')
            log_alert "FAILED SERVICES ALERT: Found $FAILED_SERVICES failed services:\n$SERVICES_LIST"
            return 1
        else
            log_message "No failed services found"
            return 0
        fi
    else
        log_message "systemctl not available, skipping service check"
        return 0
    fi
}

# Function to check for available updates
check_updates() {
    log_message "Checking for available updates..."
    
    # Check for apt (Debian/Ubuntu)
    if command -v apt &> /dev/null; then
        # Update package lists
        apt update -qq &> /dev/null
        
        # Get number of available updates
        UPDATES_COUNT=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)
        
        # Log updates count to data file
        echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"updates\", \"value\": $UPDATES_COUNT}" >> "$MONITORING_DATA"
        
        # Check if there are available updates
        if [ "$UPDATES_COUNT" -gt 0 ]; then
            log_alert "UPDATES AVAILABLE: Found $UPDATES_COUNT packages that can be upgraded"
            return 1
        else
            log_message "No updates available"
            return 0
        fi
    # Check for dnf (Fedora/RHEL)
    elif command -v dnf &> /dev/null; then
        # Get number of available updates
        UPDATES_COUNT=$(dnf check-update --quiet | grep -v "^$" | wc -l)
        
        # Log updates count to data file
        echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"type\": \"updates\", \"value\": $UPDATES_COUNT}" >> "$MONITORING_DATA"
        
        # Check if there are available updates
        if [ "$UPDATES_COUNT" -gt 0 ]; then
            log_alert "UPDATES AVAILABLE: Found $UPDATES_COUNT packages that can be upgraded"
            return 1
        else
            log_message "No updates available"
            return 0
        fi
    else
        log_message "No supported package manager found, skipping updates check"
        return 0
    fi
}

# Function to collect system information
collect_system_info() {
    log_message "Collecting system information..."
    
    # Get system information
    HOSTNAME=$(hostname)
    KERNEL=$(uname -r)
    OS=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
    UPTIME=$(uptime -p)
    
    # Log system information
    log_message "System Information:"
    log_message "  - Hostname: $HOSTNAME"
    log_message "  - OS: $OS"
    log_message "  - Kernel: $KERNEL"
    log_message "  - Uptime: $UPTIME"
    
    # Save system information to data file
    cat > "$DATA_DIR/system_info.json" << EOF
{
  "hostname": "$HOSTNAME",
  "os": "$OS",
  "kernel": "$KERNEL",
  "uptime": "$UPTIME",
  "cpu_cores": $(nproc),
  "memory_total": "$(free -h | grep Mem | awk '{print $2}')",
  "collected_at": "$(date +"%Y-%m-%d %H:%M:%S")"
}
EOF
}

# Main function
main() {
    log_message "Starting system monitoring check..."
    
    # Read configuration
    read_config
    
    # Collect system information
    collect_system_info
    
    # Initialize alert counter
    ALERTS=0
    
    # Run all checks
    check_cpu
    ALERTS=$((ALERTS + $?))
    
    check_memory
    ALERTS=$((ALERTS + $?))
    
    check_disk
    ALERTS=$((ALERTS + $?))
    
    check_zombies
    ALERTS=$((ALERTS + $?))
    
    check_load
    ALERTS=$((ALERTS + $?))
    
    check_services
    ALERTS=$((ALERTS + $?))
    
    check_updates
    ALERTS=$((ALERTS + $?))
    
    # Report summary
    if [ $ALERTS -gt 0 ]; then
        log_message "Monitoring check complete. $ALERTS alerts were generated. See $ALERT_LOG for details."
    else
        log_message "Monitoring check complete. No alerts were generated."
    fi
    
    # Save monitoring summary
    echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"alerts\": $ALERTS}" > "$DATA_DIR/monitoring_summary.json"
    
    return $ALERTS
}

# Execute main function
main
