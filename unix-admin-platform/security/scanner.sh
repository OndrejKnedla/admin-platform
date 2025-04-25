#!/bin/bash
#
# scanner.sh - Security scanner for the Unix System Administration Platform
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script performs security scans and checks

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# Configuration
CONFIG_FILE="config/platform.conf"
LOG_DIR="logs"
DATA_DIR="data"
SECURITY_LOG="$LOG_DIR/security.log"
SECURITY_DATA="$DATA_DIR/security_data.json"

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
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$SECURITY_LOG"
    echo "$1"
}

# Function to log security issues
log_security_issue() {
    local severity="$1"
    local message="$2"
    
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$severity] $message" >> "$SECURITY_LOG"
    
    case "$severity" in
        "HIGH")
            print_error "$message"
            ;;
        "MEDIUM")
            print_warning "$message"
            ;;
        "LOW")
            print_message "$message"
            ;;
        *)
            echo "$message"
            ;;
    esac
    
    # Log to security data file
    echo "{\"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"severity\": \"$severity\", \"message\": \"$message\"}" >> "$SECURITY_DATA"
}

# Function to check for weak passwords
check_weak_passwords() {
    log_message "Checking for weak passwords..."
    
    # Check if we have permission to read shadow file
    if [ ! -r "/etc/shadow" ]; then
        log_message "No permission to read /etc/shadow, skipping weak password check"
        return 0
    fi
    
    # Check for users with empty passwords
    EMPTY_PASSWORDS=$(grep '::' /etc/shadow | cut -d: -f1)
    if [ -n "$EMPTY_PASSWORDS" ]; then
        log_security_issue "HIGH" "Users with empty passwords found: $EMPTY_PASSWORDS"
    else
        log_message "No users with empty passwords found"
    fi
    
    # Check for users with no password aging
    NO_AGING=$(grep -v ':\*:' /etc/shadow | grep -v ':\!:' | awk -F: '{if ($5 == "" && $2 != "" && $2 != "*" && $2 != "!") print $1}')
    if [ -n "$NO_AGING" ]; then
        log_security_issue "MEDIUM" "Users with no password aging found: $NO_AGING"
    else
        log_message "No users with missing password aging found"
    fi
}

# Function to check for unauthorized SUID/SGID binaries
check_suid_sgid() {
    log_message "Checking for unauthorized SUID/SGID binaries..."
    
    # Define known SUID/SGID binaries (this is a basic list, should be customized)
    KNOWN_SUID=(
        "/bin/su"
        "/bin/ping"
        "/usr/bin/passwd"
        "/usr/bin/sudo"
        "/usr/bin/newgrp"
        "/usr/bin/chsh"
        "/usr/bin/chfn"
        "/usr/bin/gpasswd"
    )
    
    # Find all SUID binaries
    SUID_BINARIES=$(find / -type f -perm -4000 2>/dev/null)
    
    # Check each binary
    for binary in $SUID_BINARIES; do
        # Check if it's in the known list
        known=0
        for known_binary in "${KNOWN_SUID[@]}"; do
            if [ "$binary" = "$known_binary" ]; then
                known=1
                break
            fi
        done
        
        # Report if not known
        if [ $known -eq 0 ]; then
            log_security_issue "MEDIUM" "Unauthorized SUID binary found: $binary"
        fi
    done
    
    # Find all SGID binaries
    SGID_BINARIES=$(find / -type f -perm -2000 2>/dev/null)
    
    # Report all SGID binaries (customize as needed)
    for binary in $SGID_BINARIES; do
        log_security_issue "LOW" "SGID binary found: $binary"
    done
}

# Function to check for open ports
check_open_ports() {
    log_message "Checking for open ports..."
    
    # Check if netstat or ss is available
    if command -v ss &> /dev/null; then
        # Get listening ports using ss
        LISTENING_PORTS=$(ss -tuln | grep LISTEN)
    elif command -v netstat &> /dev/null; then
        # Get listening ports using netstat
        LISTENING_PORTS=$(netstat -tuln | grep LISTEN)
    else
        log_message "Neither ss nor netstat is available, skipping open ports check"
        return 0
    fi
    
    # Log all open ports
    if [ -n "$LISTENING_PORTS" ]; then
        log_message "Open ports found:"
        echo "$LISTENING_PORTS" | while read -r line; do
            # Extract port and protocol
            if echo "$line" | grep -q "ss -tuln"; then
                # Skip header line from ss
                continue
            fi
            
            port=$(echo "$line" | awk '{print $5}' | rev | cut -d: -f1 | rev)
            proto=$(echo "$line" | awk '{print $1}')
            
            # Check for common services
            case "$port" in
                22)
                    log_message "  - SSH service running on port 22"
                    ;;
                80|443)
                    log_message "  - Web server running on port $port"
                    ;;
                25|465|587)
                    log_security_issue "MEDIUM" "Mail server port $port is open"
                    ;;
                3306)
                    log_security_issue "MEDIUM" "MySQL database port 3306 is open"
                    ;;
                5432)
                    log_security_issue "MEDIUM" "PostgreSQL database port 5432 is open"
                    ;;
                *)
                    # Report other open ports
                    log_security_issue "LOW" "Uncommon port $port ($proto) is open"
                    ;;
            esac
        done
    else
        log_message "No open ports found"
    fi
}

# Function to check for world-writable files
check_world_writable() {
    log_message "Checking for world-writable files..."
    
    # Find world-writable files (excluding /proc, /sys, and /dev)
    WORLD_WRITABLE=$(find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type f -perm -0002 -print 2>/dev/null)
    
    # Report world-writable files
    if [ -n "$WORLD_WRITABLE" ]; then
        log_security_issue "HIGH" "World-writable files found:"
        echo "$WORLD_WRITABLE" | while read -r file; do
            log_security_issue "HIGH" "  - $file"
        done
    else
        log_message "No world-writable files found"
    fi
    
    # Find world-writable directories
    WORLD_WRITABLE_DIRS=$(find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type d -perm -0002 -print 2>/dev/null)
    
    # Report world-writable directories
    if [ -n "$WORLD_WRITABLE_DIRS" ]; then
        log_security_issue "MEDIUM" "World-writable directories found:"
        echo "$WORLD_WRITABLE_DIRS" | while read -r dir; do
            log_security_issue "MEDIUM" "  - $dir"
        done
    else
        log_message "No world-writable directories found"
    fi
}

# Function to check for unowned files
check_unowned_files() {
    log_message "Checking for unowned files..."
    
    # Find files with no valid owner
    UNOWNED=$(find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -nouser -o -nogroup -print 2>/dev/null)
    
    # Report unowned files
    if [ -n "$UNOWNED" ]; then
        log_security_issue "MEDIUM" "Unowned files found:"
        echo "$UNOWNED" | while read -r file; do
            log_security_issue "MEDIUM" "  - $file"
        done
    else
        log_message "No unowned files found"
    fi
}

# Function to check for suspicious cron jobs
check_cron_jobs() {
    log_message "Checking for suspicious cron jobs..."
    
    # Check system cron directories
    CRON_DIRS=(
        "/etc/cron.d"
        "/etc/cron.daily"
        "/etc/cron.hourly"
        "/etc/cron.monthly"
        "/etc/cron.weekly"
    )
    
    # Check each cron directory
    for dir in "${CRON_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            # Check for suspicious scripts (this is a basic check, customize as needed)
            SUSPICIOUS=$(grep -l "curl\|wget\|nc\|netcat\|bash -i" "$dir"/* 2>/dev/null)
            if [ -n "$SUSPICIOUS" ]; then
                log_security_issue "HIGH" "Suspicious cron jobs found in $dir:"
                echo "$SUSPICIOUS" | while read -r file; do
                    log_security_issue "HIGH" "  - $file"
                done
            fi
        fi
    done
    
    # Check crontab file
    if [ -f "/etc/crontab" ]; then
        SUSPICIOUS=$(grep "curl\|wget\|nc\|netcat\|bash -i" /etc/crontab 2>/dev/null)
        if [ -n "$SUSPICIOUS" ]; then
            log_security_issue "HIGH" "Suspicious entries found in /etc/crontab:"
            echo "$SUSPICIOUS" | while read -r line; do
                log_security_issue "HIGH" "  - $line"
            done
        fi
    fi
}

# Function to check for suspicious processes
check_suspicious_processes() {
    log_message "Checking for suspicious processes..."
    
    # Look for processes with suspicious command lines
    SUSPICIOUS=$(ps aux | grep -E "nc -l|netcat -l|bash -i|/dev/tcp|/dev/udp" | grep -v grep)
    
    # Report suspicious processes
    if [ -n "$SUSPICIOUS" ]; then
        log_security_issue "HIGH" "Suspicious processes found:"
        echo "$SUSPICIOUS" | while read -r line; do
            log_security_issue "HIGH" "  - $line"
        done
    else
        log_message "No suspicious processes found"
    fi
}

# Function to check SSH configuration
check_ssh_config() {
    log_message "Checking SSH configuration..."
    
    # Check if SSH config file exists
    if [ -f "/etc/ssh/sshd_config" ]; then
        # Check for root login
        if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
            log_security_issue "HIGH" "SSH allows root login"
        fi
        
        # Check for password authentication
        if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
            log_security_issue "MEDIUM" "SSH allows password authentication"
        fi
        
        # Check for empty passwords
        if grep -q "PermitEmptyPasswords yes" /etc/ssh/sshd_config; then
            log_security_issue "HIGH" "SSH allows empty passwords"
        fi
        
        # Check for protocol version
        if grep -q "Protocol 1" /etc/ssh/sshd_config; then
            log_security_issue "HIGH" "SSH uses insecure protocol version 1"
        fi
    else
        log_message "SSH configuration file not found"
    fi
}

# Function to check for failed login attempts
check_failed_logins() {
    log_message "Checking for failed login attempts..."
    
    # Check auth.log for failed logins
    if [ -f "/var/log/auth.log" ]; then
        # Count failed SSH logins
        FAILED_SSH=$(grep "Failed password" /var/log/auth.log | wc -l)
        if [ "$FAILED_SSH" -gt 10 ]; then
            log_security_issue "MEDIUM" "High number of failed SSH login attempts: $FAILED_SSH"
            
            # Get the top IP addresses
            TOP_IPS=$(grep "Failed password" /var/log/auth.log | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | sort -nr | head -5)
            log_security_issue "MEDIUM" "Top IP addresses with failed login attempts:"
            echo "$TOP_IPS" | while read -r line; do
                log_security_issue "MEDIUM" "  - $line"
            done
        else
            log_message "Normal number of failed SSH login attempts: $FAILED_SSH"
        fi
    else
        log_message "Auth log file not found"
    fi
}

# Function to check for rootkits
check_rootkits() {
    log_message "Checking for rootkits..."
    
    # Check if chkrootkit is available
    if command -v chkrootkit &> /dev/null; then
        log_message "Running chkrootkit..."
        ROOTKIT_CHECK=$(chkrootkit 2>&1)
        
        # Check for suspicious results
        if echo "$ROOTKIT_CHECK" | grep -q "INFECTED"; then
            log_security_issue "HIGH" "Possible rootkit detected by chkrootkit:"
            echo "$ROOTKIT_CHECK" | grep "INFECTED" | while read -r line; do
                log_security_issue "HIGH" "  - $line"
            done
        else
            log_message "No rootkits detected by chkrootkit"
        fi
    else
        log_message "chkrootkit not available, skipping rootkit check"
    fi
    
    # Check if rkhunter is available
    if command -v rkhunter &> /dev/null; then
        log_message "Running rkhunter..."
        RKHUNTER_CHECK=$(rkhunter --check --skip-keypress --quiet)
        
        # Check for warnings
        if echo "$RKHUNTER_CHECK" | grep -q "Warning:"; then
            log_security_issue "HIGH" "Possible security issues detected by rkhunter:"
            echo "$RKHUNTER_CHECK" | grep "Warning:" | while read -r line; do
                log_security_issue "HIGH" "  - $line"
            done
        else
            log_message "No issues detected by rkhunter"
        fi
    else
        log_message "rkhunter not available, skipping rootkit check"
    fi
}

# Function to check firewall status
check_firewall() {
    log_message "Checking firewall status..."
    
    # Check if iptables is available
    if command -v iptables &> /dev/null; then
        # Check if firewall is enabled
        IPTABLES_RULES=$(iptables -L -n 2>/dev/null)
        
        # Count rules
        RULE_COUNT=$(echo "$IPTABLES_RULES" | grep -v "Chain" | grep -v "target" | grep -v "^$" | wc -l)
        
        if [ "$RULE_COUNT" -eq 0 ]; then
            log_security_issue "HIGH" "Firewall (iptables) has no rules configured"
        else
            log_message "Firewall (iptables) is configured with $RULE_COUNT rules"
        fi
    elif command -v ufw &> /dev/null; then
        # Check UFW status
        UFW_STATUS=$(ufw status 2>/dev/null)
        
        if echo "$UFW_STATUS" | grep -q "Status: inactive"; then
            log_security_issue "HIGH" "Firewall (ufw) is inactive"
        else
            log_message "Firewall (ufw) is active"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        # Check firewalld status
        FIREWALLD_STATUS=$(firewall-cmd --state 2>/dev/null)
        
        if [ "$FIREWALLD_STATUS" != "running" ]; then
            log_security_issue "HIGH" "Firewall (firewalld) is not running"
        else
            log_message "Firewall (firewalld) is running"
        fi
    else
        log_security_issue "MEDIUM" "No firewall management tool found (iptables, ufw, firewalld)"
    fi
}

# Function to check for available security updates
check_security_updates() {
    log_message "Checking for security updates..."
    
    # Check for apt (Debian/Ubuntu)
    if command -v apt &> /dev/null; then
        # Update package lists
        apt update -qq &> /dev/null
        
        # Check for security updates
        if command -v apt-get &> /dev/null; then
            SECURITY_UPDATES=$(apt-get --simulate --show-upgraded dist-upgrade | grep "^Inst" | grep -i securi | wc -l)
            
            if [ "$SECURITY_UPDATES" -gt 0 ]; then
                log_security_issue "HIGH" "$SECURITY_UPDATES security updates available"
            else
                log_message "No security updates available"
            fi
        fi
    # Check for dnf (Fedora/RHEL)
    elif command -v dnf &> /dev/null; then
        # Check for security updates
        SECURITY_UPDATES=$(dnf updateinfo list security 2>/dev/null | grep -v "Last metadata" | grep -v "^$" | wc -l)
        
        if [ "$SECURITY_UPDATES" -gt 0 ]; then
            log_security_issue "HIGH" "$SECURITY_UPDATES security updates available"
        else
            log_message "No security updates available"
        fi
    else
        log_message "No supported package manager found, skipping security updates check"
    fi
}

# Main function
main() {
    log_message "Starting security scan..."
    
    # Initialize issue counter
    ISSUES=0
    
    # Run all security checks
    check_weak_passwords
    check_suid_sgid
    check_open_ports
    check_world_writable
    check_unowned_files
    check_cron_jobs
    check_suspicious_processes
    check_ssh_config
    check_failed_logins
    check_rootkits
    check_firewall
    check_security_updates
    
    # Count issues
    HIGH_ISSUES=$(grep -c "\[HIGH\]" "$SECURITY_LOG")
    MEDIUM_ISSUES=$(grep -c "\[MEDIUM\]" "$SECURITY_LOG")
    LOW_ISSUES=$(grep -c "\[LOW\]" "$SECURITY_LOG")
    TOTAL_ISSUES=$((HIGH_ISSUES + MEDIUM_ISSUES + LOW_ISSUES))
    
    # Report summary
    log_message "Security scan complete."
    log_message "Issues found: $TOTAL_ISSUES ($HIGH_ISSUES high, $MEDIUM_ISSUES medium, $LOW_ISSUES low)"
    
    # Save security summary
    cat > "$DATA_DIR/security_summary.json" << EOF
{
  "timestamp": "$(date +"%Y-%m-%d %H:%M:%S")",
  "total_issues": $TOTAL_ISSUES,
  "high_issues": $HIGH_ISSUES,
  "medium_issues": $MEDIUM_ISSUES,
  "low_issues": $LOW_ISSUES
}
EOF
    
    return $TOTAL_ISSUES
}

# Execute main function
main
