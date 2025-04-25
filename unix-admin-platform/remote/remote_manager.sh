#!/bin/bash
#
# remote_manager.sh - Remote system management for the Unix System Administration Platform
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script manages remote systems via SSH

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# Configuration
CONFIG_FILE="config/platform.conf"
LOG_DIR="logs"
DATA_DIR="data"
REMOTE_LOG="$LOG_DIR/remote.log"
REMOTE_HOSTS_FILE="$CONFIG_DIR/remote_hosts.conf"

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
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$REMOTE_LOG"
    echo "$1"
}

# Function to read configuration
read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Read remote settings from config
        ENABLE_REMOTE=$(grep "ENABLE_REMOTE=" "$CONFIG_FILE" | cut -d'=' -f2)
        REMOTE_HOSTS=$(grep "REMOTE_HOSTS=" "$CONFIG_FILE" | cut -d'"' -f2)
        SSH_KEY_PATH=$(grep "SSH_KEY_PATH=" "$CONFIG_FILE" | cut -d'"' -f2)
        
        # Set defaults if not found
        ENABLE_REMOTE=${ENABLE_REMOTE:-false}
        REMOTE_HOSTS=${REMOTE_HOSTS:-""}
        SSH_KEY_PATH=${SSH_KEY_PATH:-"$HOME/.ssh/id_rsa"}
    else
        log_message "Configuration file not found, using default remote settings"
        ENABLE_REMOTE=false
        REMOTE_HOSTS=""
        SSH_KEY_PATH="$HOME/.ssh/id_rsa"
    fi
}

# Function to check if remote management is enabled
check_remote_enabled() {
    if [ "$ENABLE_REMOTE" != "true" ]; then
        log_message "Remote management is disabled in configuration"
        return 1
    fi
    return 0
}

# Function to list remote hosts
list_hosts() {
    log_message "Listing remote hosts..."
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if remote hosts file exists
    if [ -f "$REMOTE_HOSTS_FILE" ]; then
        echo "Remote Hosts:"
        echo "-------------"
        
        # Read hosts from file
        while IFS='|' read -r hostname address username description status; do
            if [ -z "$hostname" ] || [[ "$hostname" == \#* ]]; then
                continue  # Skip empty lines and comments
            fi
            
            echo "Host: $hostname"
            echo "  Address: $address"
            echo "  Username: $username"
            echo "  Description: $description"
            echo "  Status: $status"
            echo
        done < "$REMOTE_HOSTS_FILE"
    else
        log_message "Remote hosts file not found"
        
        # Create default hosts file
        mkdir -p "$(dirname "$REMOTE_HOSTS_FILE")"
        cat > "$REMOTE_HOSTS_FILE" << EOF
# Remote hosts configuration
# Format: hostname|address|username|description|status
# Example: webserver|192.168.1.10|admin|Web Server|active
EOF
        
        log_message "Created default remote hosts file: $REMOTE_HOSTS_FILE"
        echo "No remote hosts configured. Edit $REMOTE_HOSTS_FILE to add hosts."
    fi
    
    return 0
}

# Function to add a remote host
add_host() {
    local hostname="$1"
    local address="$2"
    local username="$3"
    local description="$4"
    
    log_message "Adding remote host: $hostname ($address)"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if required parameters are provided
    if [ -z "$hostname" ] || [ -z "$address" ] || [ -z "$username" ]; then
        log_message "Missing required parameters"
        echo "Usage: $0 add_host HOSTNAME ADDRESS USERNAME [DESCRIPTION]"
        return 1
    fi
    
    # Set default description if not provided
    description=${description:-"$hostname"}
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        # Create default hosts file
        mkdir -p "$(dirname "$REMOTE_HOSTS_FILE")"
        cat > "$REMOTE_HOSTS_FILE" << EOF
# Remote hosts configuration
# Format: hostname|address|username|description|status
# Example: webserver|192.168.1.10|admin|Web Server|active
EOF
    fi
    
    # Check if host already exists
    if grep -q "^$hostname|" "$REMOTE_HOSTS_FILE"; then
        log_message "Host $hostname already exists"
        echo "Host $hostname already exists. Use update_host to modify it."
        return 1
    fi
    
    # Add host to file
    echo "$hostname|$address|$username|$description|active" >> "$REMOTE_HOSTS_FILE"
    
    log_message "Host $hostname added successfully"
    echo "Host $hostname added successfully"
    
    return 0
}

# Function to remove a remote host
remove_host() {
    local hostname="$1"
    
    log_message "Removing remote host: $hostname"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if hostname is provided
    if [ -z "$hostname" ]; then
        log_message "No hostname provided"
        echo "Usage: $0 remove_host HOSTNAME"
        return 1
    fi
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        log_message "Remote hosts file not found"
        echo "No remote hosts configured."
        return 1
    fi
    
    # Check if host exists
    if ! grep -q "^$hostname|" "$REMOTE_HOSTS_FILE"; then
        log_message "Host $hostname not found"
        echo "Host $hostname not found."
        return 1
    fi
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Remove host from file
    grep -v "^$hostname|" "$REMOTE_HOSTS_FILE" > "$temp_file"
    
    # Replace the original file with the updated one
    mv "$temp_file" "$REMOTE_HOSTS_FILE"
    
    log_message "Host $hostname removed successfully"
    echo "Host $hostname removed successfully"
    
    return 0
}

# Function to update a remote host
update_host() {
    local hostname="$1"
    local field="$2"
    local value="$3"
    
    log_message "Updating remote host: $hostname (field: $field, value: $value)"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if required parameters are provided
    if [ -z "$hostname" ] || [ -z "$field" ] || [ -z "$value" ]; then
        log_message "Missing required parameters"
        echo "Usage: $0 update_host HOSTNAME FIELD VALUE"
        echo "Fields: address, username, description, status"
        return 1
    fi
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        log_message "Remote hosts file not found"
        echo "No remote hosts configured."
        return 1
    fi
    
    # Check if host exists
    if ! grep -q "^$hostname|" "$REMOTE_HOSTS_FILE"; then
        log_message "Host $hostname not found"
        echo "Host $hostname not found."
        return 1
    fi
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Update host in file
    while IFS='|' read -r h address username description status; do
        if [ -z "$h" ] || [[ "$h" == \#* ]]; then
            # Copy comments and empty lines as is
            echo "$h$address$username$description$status" >> "$temp_file"
        elif [ "$h" = "$hostname" ]; then
            # Update the specified field
            case "$field" in
                address)
                    address="$value"
                    ;;
                username)
                    username="$value"
                    ;;
                description)
                    description="$value"
                    ;;
                status)
                    status="$value"
                    ;;
                *)
                    log_message "Invalid field: $field"
                    echo "Invalid field: $field"
                    echo "Fields: address, username, description, status"
                    rm "$temp_file"
                    return 1
                    ;;
            esac
            
            # Write updated host to file
            echo "$h|$address|$username|$description|$status" >> "$temp_file"
        else
            # Copy other hosts as is
            echo "$h|$address|$username|$description|$status" >> "$temp_file"
        fi
    done < "$REMOTE_HOSTS_FILE"
    
    # Replace the original file with the updated one
    mv "$temp_file" "$REMOTE_HOSTS_FILE"
    
    log_message "Host $hostname updated successfully"
    echo "Host $hostname updated successfully"
    
    return 0
}

# Function to check connectivity to a remote host
check_host() {
    local hostname="$1"
    
    log_message "Checking connectivity to remote host: $hostname"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if hostname is provided
    if [ -z "$hostname" ]; then
        log_message "No hostname provided"
        echo "Usage: $0 check_host HOSTNAME"
        return 1
    fi
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        log_message "Remote hosts file not found"
        echo "No remote hosts configured."
        return 1
    fi
    
    # Get host information
    local host_info=$(grep "^$hostname|" "$REMOTE_HOSTS_FILE")
    
    if [ -z "$host_info" ]; then
        log_message "Host $hostname not found"
        echo "Host $hostname not found."
        return 1
    fi
    
    # Extract host information
    IFS='|' read -r h address username description status <<< "$host_info"
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        log_message "SSH key not found: $SSH_KEY_PATH"
        echo "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
    
    # Check connectivity
    log_message "Testing SSH connection to $address as $username"
    echo "Testing SSH connection to $address as $username..."
    
    ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$username@$address" "echo 'Connection successful'"
    
    if [ $? -eq 0 ]; then
        log_message "Connection to $hostname successful"
        echo "Connection to $hostname successful"
        
        # Update host status
        update_host "$hostname" "status" "active"
    else
        log_message "Connection to $hostname failed"
        echo "Connection to $hostname failed"
        
        # Update host status
        update_host "$hostname" "status" "inactive"
        
        return 1
    fi
    
    return 0
}

# Function to execute a command on a remote host
execute_command() {
    local hostname="$1"
    local command="$2"
    
    log_message "Executing command on remote host: $hostname (command: $command)"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if required parameters are provided
    if [ -z "$hostname" ] || [ -z "$command" ]; then
        log_message "Missing required parameters"
        echo "Usage: $0 execute_command HOSTNAME COMMAND"
        return 1
    fi
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        log_message "Remote hosts file not found"
        echo "No remote hosts configured."
        return 1
    fi
    
    # Get host information
    local host_info=$(grep "^$hostname|" "$REMOTE_HOSTS_FILE")
    
    if [ -z "$host_info" ]; then
        log_message "Host $hostname not found"
        echo "Host $hostname not found."
        return 1
    fi
    
    # Extract host information
    IFS='|' read -r h address username description status <<< "$host_info"
    
    # Check if host is active
    if [ "$status" != "active" ]; then
        log_message "Host $hostname is not active"
        echo "Host $hostname is not active. Check connectivity first."
        return 1
    fi
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        log_message "SSH key not found: $SSH_KEY_PATH"
        echo "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
    
    # Execute command
    log_message "Executing command on $address as $username: $command"
    echo "Executing command on $address as $username..."
    
    ssh -i "$SSH_KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no "$username@$address" "$command"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_message "Command executed successfully on $hostname"
        echo "Command executed successfully on $hostname"
    else
        log_message "Command execution failed on $hostname (exit code: $exit_code)"
        echo "Command execution failed on $hostname (exit code: $exit_code)"
        return 1
    fi
    
    return 0
}

# Function to copy a file to a remote host
copy_to_host() {
    local hostname="$1"
    local local_file="$2"
    local remote_path="$3"
    
    log_message "Copying file to remote host: $hostname (local: $local_file, remote: $remote_path)"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if required parameters are provided
    if [ -z "$hostname" ] || [ -z "$local_file" ] || [ -z "$remote_path" ]; then
        log_message "Missing required parameters"
        echo "Usage: $0 copy_to_host HOSTNAME LOCAL_FILE REMOTE_PATH"
        return 1
    fi
    
    # Check if local file exists
    if [ ! -f "$local_file" ]; then
        log_message "Local file not found: $local_file"
        echo "Local file not found: $local_file"
        return 1
    fi
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        log_message "Remote hosts file not found"
        echo "No remote hosts configured."
        return 1
    fi
    
    # Get host information
    local host_info=$(grep "^$hostname|" "$REMOTE_HOSTS_FILE")
    
    if [ -z "$host_info" ]; then
        log_message "Host $hostname not found"
        echo "Host $hostname not found."
        return 1
    fi
    
    # Extract host information
    IFS='|' read -r h address username description status <<< "$host_info"
    
    # Check if host is active
    if [ "$status" != "active" ]; then
        log_message "Host $hostname is not active"
        echo "Host $hostname is not active. Check connectivity first."
        return 1
    fi
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        log_message "SSH key not found: $SSH_KEY_PATH"
        echo "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
    
    # Copy file
    log_message "Copying $local_file to $address:$remote_path as $username"
    echo "Copying $local_file to $address:$remote_path as $username..."
    
    scp -i "$SSH_KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no "$local_file" "$username@$address:$remote_path"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_message "File copied successfully to $hostname"
        echo "File copied successfully to $hostname"
    else
        log_message "File copy failed to $hostname (exit code: $exit_code)"
        echo "File copy failed to $hostname (exit code: $exit_code)"
        return 1
    fi
    
    return 0
}

# Function to copy a file from a remote host
copy_from_host() {
    local hostname="$1"
    local remote_file="$2"
    local local_path="$3"
    
    log_message "Copying file from remote host: $hostname (remote: $remote_file, local: $local_path)"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if required parameters are provided
    if [ -z "$hostname" ] || [ -z "$remote_file" ] || [ -z "$local_path" ]; then
        log_message "Missing required parameters"
        echo "Usage: $0 copy_from_host HOSTNAME REMOTE_FILE LOCAL_PATH"
        return 1
    fi
    
    # Check if local path exists
    local_dir=$(dirname "$local_path")
    if [ ! -d "$local_dir" ]; then
        log_message "Local directory not found: $local_dir"
        echo "Local directory not found: $local_dir"
        return 1
    fi
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        log_message "Remote hosts file not found"
        echo "No remote hosts configured."
        return 1
    fi
    
    # Get host information
    local host_info=$(grep "^$hostname|" "$REMOTE_HOSTS_FILE")
    
    if [ -z "$host_info" ]; then
        log_message "Host $hostname not found"
        echo "Host $hostname not found."
        return 1
    fi
    
    # Extract host information
    IFS='|' read -r h address username description status <<< "$host_info"
    
    # Check if host is active
    if [ "$status" != "active" ]; then
        log_message "Host $hostname is not active"
        echo "Host $hostname is not active. Check connectivity first."
        return 1
    fi
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        log_message "SSH key not found: $SSH_KEY_PATH"
        echo "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
    
    # Copy file
    log_message "Copying $address:$remote_file to $local_path as $username"
    echo "Copying $address:$remote_file to $local_path as $username..."
    
    scp -i "$SSH_KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no "$username@$address:$remote_file" "$local_path"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_message "File copied successfully from $hostname"
        echo "File copied successfully from $hostname"
    else
        log_message "File copy failed from $hostname (exit code: $exit_code)"
        echo "File copy failed from $hostname (exit code: $exit_code)"
        return 1
    fi
    
    return 0
}

# Function to run a monitoring check on a remote host
monitor_host() {
    local hostname="$1"
    
    log_message "Running monitoring check on remote host: $hostname"
    
    # Check if remote management is enabled
    check_remote_enabled || return 1
    
    # Check if hostname is provided
    if [ -z "$hostname" ]; then
        log_message "No hostname provided"
        echo "Usage: $0 monitor_host HOSTNAME"
        return 1
    fi
    
    # Check if remote hosts file exists
    if [ ! -f "$REMOTE_HOSTS_FILE" ]; then
        log_message "Remote hosts file not found"
        echo "No remote hosts configured."
        return 1
    fi
    
    # Get host information
    local host_info=$(grep "^$hostname|" "$REMOTE_HOSTS_FILE")
    
    if [ -z "$host_info" ]; then
        log_message "Host $hostname not found"
        echo "Host $hostname not found."
        return 1
    fi
    
    # Extract host information
    IFS='|' read -r h address username description status <<< "$host_info"
    
    # Check if host is active
    if [ "$status" != "active" ]; then
        log_message "Host $hostname is not active"
        echo "Host $hostname is not active. Check connectivity first."
        return 1
    fi
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        log_message "SSH key not found: $SSH_KEY_PATH"
        echo "SSH key not found: $SSH_KEY_PATH"
        return 1
    fi
    
    # Create a temporary directory for monitoring data
    local temp_dir=$(mktemp -d)
    
    # Create a monitoring script
    cat > "$temp_dir/monitor.sh" << 'EOF'
#!/bin/bash

# Get system information
hostname=$(hostname)
kernel=$(uname -r)
uptime=$(uptime -p)

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

# Get memory usage
memory_total=$(free | grep Mem | awk '{print $2}')
memory_used=$(free | grep Mem | awk '{print $3}')
memory_usage=$(echo "scale=2; $memory_used * 100 / $memory_total" | bc)

# Get disk usage
disk_usage=$(df -h | grep -v "Filesystem" | awk '{print $1 "," $5 "," $6}')

# Get load average
load_avg=$(uptime | awk -F'[a-z]:' '{ print $2 }' | awk -F',' '{ print $1 "," $2 "," $3 }' | tr -d ' ')

# Get running processes
processes=$(ps aux --sort=-%cpu | head -6)

# Output results
echo "=== SYSTEM INFORMATION ==="
echo "Hostname: $hostname"
echo "Kernel: $kernel"
echo "Uptime: $uptime"
echo

echo "=== CPU USAGE ==="
echo "$cpu_usage%"
echo

echo "=== MEMORY USAGE ==="
echo "$memory_usage%"
echo

echo "=== DISK USAGE ==="
echo "$disk_usage"
echo

echo "=== LOAD AVERAGE ==="
echo "$load_avg"
echo

echo "=== TOP PROCESSES ==="
echo "$processes"
echo
EOF
    
    # Make the script executable
    chmod +x "$temp_dir/monitor.sh"
    
    # Copy the script to the remote host
    log_message "Copying monitoring script to $hostname"
    scp -i "$SSH_KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no "$temp_dir/monitor.sh" "$username@$address:/tmp/monitor.sh"
    
    if [ $? -ne 0 ]; then
        log_message "Failed to copy monitoring script to $hostname"
        echo "Failed to copy monitoring script to $hostname"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Execute the script on the remote host
    log_message "Executing monitoring script on $hostname"
    echo "Monitoring results for $hostname:"
    echo "=================================="
    
    ssh -i "$SSH_KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no "$username@$address" "bash /tmp/monitor.sh"
    
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_message "Monitoring check failed on $hostname (exit code: $exit_code)"
        echo "Monitoring check failed on $hostname (exit code: $exit_code)"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    ssh -i "$SSH_KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no "$username@$address" "rm -f /tmp/monitor.sh"
    rm -rf "$temp_dir"
    
    log_message "Monitoring check completed on $hostname"
    
    return 0
}

# Function to display help
display_help() {
    echo "Remote System Management for Unix System Administration Platform"
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  list                                List remote hosts"
    echo "  add_host HOSTNAME ADDRESS USERNAME [DESCRIPTION]  Add a remote host"
    echo "  remove_host HOSTNAME               Remove a remote host"
    echo "  update_host HOSTNAME FIELD VALUE   Update a remote host"
    echo "  check_host HOSTNAME                Check connectivity to a remote host"
    echo "  execute_command HOSTNAME COMMAND   Execute a command on a remote host"
    echo "  copy_to_host HOSTNAME LOCAL_FILE REMOTE_PATH  Copy a file to a remote host"
    echo "  copy_from_host HOSTNAME REMOTE_FILE LOCAL_PATH  Copy a file from a remote host"
    echo "  monitor_host HOSTNAME              Run a monitoring check on a remote host"
    echo "  help                               Display this help message"
    echo
    echo "Fields for update_host:"
    echo "  address, username, description, status"
    echo
    echo "Examples:"
    echo "  $0 list                            List all remote hosts"
    echo "  $0 add_host webserver 192.168.1.10 admin \"Web Server\"  Add a remote host"
    echo "  $0 check_host webserver            Check connectivity to webserver"
    echo "  $0 execute_command webserver \"uptime\"  Execute uptime command on webserver"
    echo "  $0 monitor_host webserver          Run a monitoring check on webserver"
    echo
}

# Main function
main() {
    # Read configuration
    read_config
    
    # Process command line arguments
    case "$1" in
        list)
            list_hosts
            ;;
        add_host)
            add_host "$2" "$3" "$4" "$5"
            ;;
        remove_host)
            remove_host "$2"
            ;;
        update_host)
            update_host "$2" "$3" "$4"
            ;;
        check_host)
            check_host "$2"
            ;;
        execute_command)
            execute_command "$2" "${@:3}"
            ;;
        copy_to_host)
            copy_to_host "$2" "$3" "$4"
            ;;
        copy_from_host)
            copy_from_host "$2" "$3" "$4"
            ;;
        monitor_host)
            monitor_host "$2"
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
