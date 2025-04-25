#!/bin/bash
#
# network_monitor.sh - Monitors network connections and traffic
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script monitors network connections, traffic, and can perform basic diagnostics

# Configuration
LOG_DIR="../logs"
DATA_DIR="../data"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
NETWORK_LOG="$DATA_DIR/network_$TIMESTAMP.log"

# Create directories if they don't exist
mkdir -p $LOG_DIR
mkdir -p $DATA_DIR

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_DIR/network_monitor.log"
    echo "$1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to get network interfaces
get_interfaces() {
    log_message "Getting network interfaces..."
    
    echo "=== NETWORK INTERFACES ==="
    ip -brief link show
    
    return 0
}

# Function to get IP addresses
get_ip_addresses() {
    log_message "Getting IP addresses..."
    
    echo "=== IP ADDRESSES ==="
    ip -brief addr show
    
    return 0
}

# Function to get routing table
get_routing_table() {
    log_message "Getting routing table..."
    
    echo "=== ROUTING TABLE ==="
    ip route
    
    return 0
}

# Function to get active connections
get_connections() {
    log_message "Getting active connections..."
    
    echo "=== ACTIVE CONNECTIONS ==="
    if command_exists ss; then
        ss -tuln
    elif command_exists netstat; then
        netstat -tuln
    else
        echo "Neither ss nor netstat commands are available"
        return 1
    fi
    
    return 0
}

# Function to get DNS settings
get_dns_settings() {
    log_message "Getting DNS settings..."
    
    echo "=== DNS SETTINGS ==="
    if [ -f /etc/resolv.conf ]; then
        cat /etc/resolv.conf
    else
        echo "No /etc/resolv.conf file found"
    fi
    
    return 0
}

# Function to ping a host
ping_host() {
    if [ -z "$1" ]; then
        log_message "No host provided"
        echo "Usage: ping_host HOSTNAME"
        return 1
    fi
    
    host="$1"
    count="${2:-4}"  # Default to 4 pings if not specified
    
    log_message "Pinging host: $host ($count times)"
    
    echo "=== PING TEST: $host ==="
    ping -c "$count" "$host"
    
    return $?
}

# Function to trace route to a host
trace_route() {
    if [ -z "$1" ]; then
        log_message "No host provided"
        echo "Usage: trace_route HOSTNAME"
        return 1
    fi
    
    host="$1"
    
    log_message "Tracing route to host: $host"
    
    echo "=== TRACEROUTE: $host ==="
    if command_exists traceroute; then
        traceroute "$host"
    elif command_exists tracepath; then
        tracepath "$host"
    else
        echo "Neither traceroute nor tracepath commands are available"
        return 1
    fi
    
    return $?
}

# Function to check for open ports
check_ports() {
    if [ -z "$1" ]; then
        log_message "No host provided"
        echo "Usage: check_ports HOSTNAME [PORT1,PORT2,...]"
        return 1
    fi
    
    host="$1"
    ports="${2:-22,80,443}"  # Default ports if not specified
    
    log_message "Checking ports on host: $host (ports: $ports)"
    
    echo "=== PORT SCAN: $host (ports: $ports) ==="
    if command_exists nc; then
        IFS=',' read -ra PORT_ARRAY <<< "$ports"
        for port in "${PORT_ARRAY[@]}"; do
            echo -n "Port $port: "
            timeout 2 nc -zv "$host" "$port" 2>&1 | grep -q "succeeded" && echo "OPEN" || echo "CLOSED"
        done
    else
        echo "The nc (netcat) command is not available"
        return 1
    fi
    
    return 0
}

# Function to monitor network traffic
monitor_traffic() {
    duration="${1:-10}"  # Default to 10 seconds if not specified
    
    log_message "Monitoring network traffic for $duration seconds..."
    
    echo "=== NETWORK TRAFFIC MONITOR ($duration seconds) ==="
    if command_exists iftop; then
        echo "Using iftop to monitor traffic (press q to quit):"
        iftop -t -s "$duration"
    elif command_exists nethogs; then
        echo "Using nethogs to monitor traffic (press q to quit):"
        nethogs -t -d "$duration"
    elif command_exists tcpdump; then
        echo "Using tcpdump to capture packets for $duration seconds:"
        timeout "$duration" tcpdump -c 100 -n
    else
        echo "No suitable traffic monitoring tool found (iftop, nethogs, or tcpdump)"
        return 1
    fi
    
    return 0
}

# Function to collect all network information
collect_network_info() {
    log_message "Collecting all network information..."
    
    {
        echo "==================================="
        echo "NETWORK INFORMATION REPORT"
        echo "Generated on: $(date)"
        echo "==================================="
        echo
        
        get_interfaces
        echo
        
        get_ip_addresses
        echo
        
        get_routing_table
        echo
        
        get_connections
        echo
        
        get_dns_settings
        echo
        
        # Ping a few common hosts
        ping_host "8.8.8.8" 3
        echo
        
        ping_host "1.1.1.1" 3
        echo
        
        echo "==================================="
        echo "END OF REPORT"
        echo "==================================="
    } | tee "$NETWORK_LOG"
    
    log_message "Network information collected and saved to $NETWORK_LOG"
    
    return 0
}

# Main function to handle command line arguments
main() {
    case "$1" in
        interfaces)
            get_interfaces
            ;;
        ip)
            get_ip_addresses
            ;;
        routes)
            get_routing_table
            ;;
        connections)
            get_connections
            ;;
        dns)
            get_dns_settings
            ;;
        ping)
            ping_host "$2" "$3"
            ;;
        trace)
            trace_route "$2"
            ;;
        ports)
            check_ports "$2" "$3"
            ;;
        traffic)
            monitor_traffic "$2"
            ;;
        all)
            collect_network_info
            ;;
        *)
            echo "Usage: $0 {interfaces|ip|routes|connections|dns|ping|trace|ports|traffic|all} [ARGS]"
            echo
            echo "Commands:"
            echo "  interfaces             List network interfaces"
            echo "  ip                     Show IP addresses"
            echo "  routes                 Show routing table"
            echo "  connections            Show active connections"
            echo "  dns                    Show DNS settings"
            echo "  ping HOSTNAME [COUNT]  Ping a host (default 4 pings)"
            echo "  trace HOSTNAME         Trace route to a host"
            echo "  ports HOST [PORTS]     Check open ports (comma-separated, default: 22,80,443)"
            echo "  traffic [DURATION]     Monitor network traffic (default 10 seconds)"
            echo "  all                    Collect all network information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
