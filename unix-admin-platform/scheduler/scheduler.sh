#!/bin/bash
#
# scheduler.sh - Task scheduler for the Unix System Administration Platform
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script schedules and executes periodic tasks

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# Configuration
CONFIG_FILE="config/platform.conf"
LOG_DIR="logs"
DATA_DIR="data"
SCHEDULER_LOG="$LOG_DIR/scheduler.log"
SCHEDULER_PID_FILE="$DATA_DIR/scheduler.pid"
SCHEDULER_TASKS_FILE="$DATA_DIR/scheduled_tasks.json"

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
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$SCHEDULER_LOG"
    echo "$1"
}

# Function to read configuration
read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Read intervals from config
        MONITORING_INTERVAL=$(grep "MONITORING_INTERVAL=" "$CONFIG_FILE" | cut -d'=' -f2)
        SECURITY_SCAN_INTERVAL=$(grep "SECURITY_SCAN_INTERVAL=" "$CONFIG_FILE" | cut -d'=' -f2)
        BACKUP_INTERVAL=$(grep "BACKUP_INTERVAL=" "$CONFIG_FILE" | cut -d'=' -f2)
        
        # Set defaults if not found
        MONITORING_INTERVAL=${MONITORING_INTERVAL:-300}  # 5 minutes
        SECURITY_SCAN_INTERVAL=${SECURITY_SCAN_INTERVAL:-3600}  # 1 hour
        BACKUP_INTERVAL=${BACKUP_INTERVAL:-86400}  # 1 day
    else
        log_message "Configuration file not found, using default intervals"
        MONITORING_INTERVAL=300
        SECURITY_SCAN_INTERVAL=3600
        BACKUP_INTERVAL=86400
    fi
}

# Function to initialize task schedule
initialize_tasks() {
    log_message "Initializing task schedule..."
    
    # Create tasks file if it doesn't exist
    if [ ! -f "$SCHEDULER_TASKS_FILE" ]; then
        cat > "$SCHEDULER_TASKS_FILE" << EOF
{
  "tasks": [
    {
      "name": "system_monitoring",
      "command": "./core/monitor.sh",
      "interval": $MONITORING_INTERVAL,
      "last_run": null,
      "enabled": true
    },
    {
      "name": "security_scan",
      "command": "./security/scanner.sh",
      "interval": $SECURITY_SCAN_INTERVAL,
      "last_run": null,
      "enabled": true
    },
    {
      "name": "backup",
      "command": "./backup/backup.sh",
      "interval": $BACKUP_INTERVAL,
      "last_run": null,
      "enabled": true
    }
  ]
}
EOF
    fi
}

# Function to update task last run time
update_task_time() {
    local task_name="$1"
    local current_time=$(date +%s)
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Update the task's last_run time
    jq --arg name "$task_name" --arg time "$current_time" '
        .tasks = [
            .tasks[] | 
            if .name == $name then 
                . + {"last_run": $time | tonumber} 
            else 
                . 
            end
        ]
    ' "$SCHEDULER_TASKS_FILE" > "$temp_file"
    
    # Replace the original file with the updated one
    mv "$temp_file" "$SCHEDULER_TASKS_FILE"
}

# Function to execute a task
execute_task() {
    local task_name="$1"
    local task_command="$2"
    
    log_message "Executing task: $task_name"
    
    # Execute the command and capture output
    if [ -f "$task_command" ]; then
        output=$($task_command 2>&1)
        exit_code=$?
        
        # Log the result
        if [ $exit_code -eq 0 ]; then
            log_message "Task $task_name completed successfully"
        else
            log_message "Task $task_name failed with exit code $exit_code"
        fi
        
        # Update the task's last run time
        update_task_time "$task_name"
    else
        log_message "Task command not found: $task_command"
    fi
}

# Function to check and run due tasks
check_tasks() {
    log_message "Checking for due tasks..."
    
    # Get current time
    current_time=$(date +%s)
    
    # Read tasks from file
    if [ -f "$SCHEDULER_TASKS_FILE" ]; then
        # Get the number of tasks
        task_count=$(jq '.tasks | length' "$SCHEDULER_TASKS_FILE")
        
        # Iterate through tasks
        for ((i=0; i<$task_count; i++)); do
            # Extract task information
            task_name=$(jq -r ".tasks[$i].name" "$SCHEDULER_TASKS_FILE")
            task_command=$(jq -r ".tasks[$i].command" "$SCHEDULER_TASKS_FILE")
            task_interval=$(jq -r ".tasks[$i].interval" "$SCHEDULER_TASKS_FILE")
            task_last_run=$(jq -r ".tasks[$i].last_run" "$SCHEDULER_TASKS_FILE")
            task_enabled=$(jq -r ".tasks[$i].enabled" "$SCHEDULER_TASKS_FILE")
            
            # Skip disabled tasks
            if [ "$task_enabled" != "true" ]; then
                continue
            fi
            
            # Check if task is due
            if [ "$task_last_run" = "null" ]; then
                # Task has never run, execute it
                execute_task "$task_name" "$task_command"
            else
                # Calculate next run time
                next_run=$((task_last_run + task_interval))
                
                # Check if it's time to run
                if [ $current_time -ge $next_run ]; then
                    execute_task "$task_name" "$task_command"
                fi
            fi
        done
    else
        log_message "Task file not found: $SCHEDULER_TASKS_FILE"
    fi
}

# Function to start the scheduler
start_scheduler() {
    log_message "Starting task scheduler..."
    
    # Check if scheduler is already running
    if [ -f "$SCHEDULER_PID_FILE" ]; then
        pid=$(cat "$SCHEDULER_PID_FILE")
        if ps -p "$pid" > /dev/null; then
            log_message "Scheduler is already running with PID $pid"
            return 1
        else
            log_message "Removing stale PID file"
            rm -f "$SCHEDULER_PID_FILE"
        fi
    fi
    
    # Save PID
    echo $$ > "$SCHEDULER_PID_FILE"
    
    # Read configuration
    read_config
    
    # Initialize tasks
    initialize_tasks
    
    # Run initial task check
    check_tasks
    
    # Main loop
    log_message "Entering main scheduler loop"
    while true; do
        # Sleep for a minute
        sleep 60
        
        # Check for tasks
        check_tasks
    done
}

# Function to stop the scheduler
stop_scheduler() {
    log_message "Stopping task scheduler..."
    
    # Check if scheduler is running
    if [ -f "$SCHEDULER_PID_FILE" ]; then
        pid=$(cat "$SCHEDULER_PID_FILE")
        if ps -p "$pid" > /dev/null; then
            kill "$pid"
            log_message "Scheduler stopped (PID: $pid)"
        else
            log_message "Scheduler is not running (stale PID file)"
        fi
        rm -f "$SCHEDULER_PID_FILE"
    else
        log_message "Scheduler is not running (no PID file)"
    fi
}

# Function to list scheduled tasks
list_tasks() {
    log_message "Listing scheduled tasks..."
    
    # Check if tasks file exists
    if [ -f "$SCHEDULER_TASKS_FILE" ]; then
        # Get the number of tasks
        task_count=$(jq '.tasks | length' "$SCHEDULER_TASKS_FILE")
        
        # Print header
        echo "Scheduled Tasks:"
        echo "----------------"
        
        # Iterate through tasks
        for ((i=0; i<$task_count; i++)); do
            # Extract task information
            task_name=$(jq -r ".tasks[$i].name" "$SCHEDULER_TASKS_FILE")
            task_command=$(jq -r ".tasks[$i].command" "$SCHEDULER_TASKS_FILE")
            task_interval=$(jq -r ".tasks[$i].interval" "$SCHEDULER_TASKS_FILE")
            task_last_run=$(jq -r ".tasks[$i].last_run" "$SCHEDULER_TASKS_FILE")
            task_enabled=$(jq -r ".tasks[$i].enabled" "$SCHEDULER_TASKS_FILE")
            
            # Format interval
            if [ $task_interval -ge 86400 ]; then
                interval_formatted="$((task_interval / 86400)) days"
            elif [ $task_interval -ge 3600 ]; then
                interval_formatted="$((task_interval / 3600)) hours"
            elif [ $task_interval -ge 60 ]; then
                interval_formatted="$((task_interval / 60)) minutes"
            else
                interval_formatted="$task_interval seconds"
            fi
            
            # Format last run
            if [ "$task_last_run" = "null" ]; then
                last_run_formatted="Never"
                next_run_formatted="Immediately"
            else
                last_run_formatted=$(date -d "@$task_last_run" "+%Y-%m-%d %H:%M:%S")
                next_run=$((task_last_run + task_interval))
                next_run_formatted=$(date -d "@$next_run" "+%Y-%m-%d %H:%M:%S")
            fi
            
            # Format status
            if [ "$task_enabled" = "true" ]; then
                status="Enabled"
            else
                status="Disabled"
            fi
            
            # Print task information
            echo "Task: $task_name"
            echo "  Command: $task_command"
            echo "  Interval: $interval_formatted"
            echo "  Last Run: $last_run_formatted"
            echo "  Next Run: $next_run_formatted"
            echo "  Status: $status"
            echo
        done
    else
        log_message "Task file not found: $SCHEDULER_TASKS_FILE"
    fi
}

# Function to add a new task
add_task() {
    local name="$1"
    local command="$2"
    local interval="$3"
    
    log_message "Adding new task: $name"
    
    # Check if tasks file exists
    if [ -f "$SCHEDULER_TASKS_FILE" ]; then
        # Create a temporary file
        local temp_file=$(mktemp)
        
        # Add the new task
        jq --arg name "$name" --arg command "$command" --arg interval "$interval" '
            .tasks += [{
                "name": $name,
                "command": $command,
                "interval": $interval | tonumber,
                "last_run": null,
                "enabled": true
            }]
        ' "$SCHEDULER_TASKS_FILE" > "$temp_file"
        
        # Replace the original file with the updated one
        mv "$temp_file" "$SCHEDULER_TASKS_FILE"
        
        log_message "Task added successfully"
    else
        log_message "Task file not found: $SCHEDULER_TASKS_FILE"
    fi
}

# Function to remove a task
remove_task() {
    local name="$1"
    
    log_message "Removing task: $name"
    
    # Check if tasks file exists
    if [ -f "$SCHEDULER_TASKS_FILE" ]; then
        # Create a temporary file
        local temp_file=$(mktemp)
        
        # Remove the task
        jq --arg name "$name" '
            .tasks = [.tasks[] | select(.name != $name)]
        ' "$SCHEDULER_TASKS_FILE" > "$temp_file"
        
        # Replace the original file with the updated one
        mv "$temp_file" "$SCHEDULER_TASKS_FILE"
        
        log_message "Task removed successfully"
    else
        log_message "Task file not found: $SCHEDULER_TASKS_FILE"
    fi
}

# Function to enable or disable a task
toggle_task() {
    local name="$1"
    local enabled="$2"
    
    log_message "Toggling task: $name (enabled: $enabled)"
    
    # Check if tasks file exists
    if [ -f "$SCHEDULER_TASKS_FILE" ]; then
        # Create a temporary file
        local temp_file=$(mktemp)
        
        # Update the task's enabled status
        jq --arg name "$name" --arg enabled "$enabled" '
            .tasks = [
                .tasks[] | 
                if .name == $name then 
                    . + {"enabled": ($enabled == "true")} 
                else 
                    . 
                end
            ]
        ' "$SCHEDULER_TASKS_FILE" > "$temp_file"
        
        # Replace the original file with the updated one
        mv "$temp_file" "$SCHEDULER_TASKS_FILE"
        
        log_message "Task updated successfully"
    else
        log_message "Task file not found: $SCHEDULER_TASKS_FILE"
    fi
}

# Function to display help
display_help() {
    echo "Task Scheduler for Unix System Administration Platform"
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start         Start the scheduler daemon"
    echo "  stop          Stop the scheduler daemon"
    echo "  list          List all scheduled tasks"
    echo "  add NAME COMMAND INTERVAL  Add a new task"
    echo "  remove NAME   Remove a task"
    echo "  enable NAME   Enable a task"
    echo "  disable NAME  Disable a task"
    echo "  help          Display this help message"
    echo
    echo "Examples:"
    echo "  $0 start                                Start the scheduler"
    echo "  $0 add backup_home ./backup/backup.sh 86400  Add a daily backup task"
    echo "  $0 disable backup_home                  Disable the backup_home task"
    echo
}

# Main function
main() {
    # Process command line arguments
    case "$1" in
        start)
            start_scheduler
            ;;
        stop)
            stop_scheduler
            ;;
        list)
            list_tasks
            ;;
        add)
            if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
                echo "Error: Missing arguments for add command"
                display_help
                exit 1
            fi
            add_task "$2" "$3" "$4"
            ;;
        remove)
            if [ -z "$2" ]; then
                echo "Error: Missing task name for remove command"
                display_help
                exit 1
            fi
            remove_task "$2"
            ;;
        enable)
            if [ -z "$2" ]; then
                echo "Error: Missing task name for enable command"
                display_help
                exit 1
            fi
            toggle_task "$2" "true"
            ;;
        disable)
            if [ -z "$2" ]; then
                echo "Error: Missing task name for disable command"
                display_help
                exit 1
            fi
            toggle_task "$2" "false"
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
