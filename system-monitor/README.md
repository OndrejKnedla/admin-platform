# Unix System Monitoring and Management Tool

A comprehensive system monitoring and management tool built with shell scripts to demonstrate Unix/Linux system administration skills.

## Features

- **System Information Collection**: Gather detailed system metrics and information
- **Process Monitoring**: Monitor processes and alert on high resource usage
- **Service Management**: Manage system services (start, stop, restart, etc.)
- **Network Monitoring**: Monitor network connections, traffic, and perform diagnostics
- **Disk Analysis**: Analyze disk usage and find large files and directories
- **Logging**: All operations are logged for future reference

## Directory Structure

```
system-monitor/
├── system_monitor.sh     # Main script (entry point)
├── README.md             # Documentation
├── scripts/              # Individual tool scripts
│   ├── system_info.sh    # System information collection
│   ├── process_monitor.sh # Process monitoring
│   ├── service_manager.sh # Service management
│   ├── network_monitor.sh # Network monitoring
│   └── disk_analyzer.sh  # Disk usage analysis
├── data/                 # Data storage directory
└── logs/                 # Log files directory
```

## Installation

1. Clone or download this repository
2. Make the scripts executable:
   ```
   chmod +x system-monitor/system_monitor.sh
   ```
3. Run the main script:
   ```
   ./system-monitor/system_monitor.sh help
   ```

## Usage

### System Information

Collect and display system information:

```
./system_monitor.sh system-info
```

### Process Monitoring

Monitor processes and alert on high resource usage:

```
./system_monitor.sh process-monitor
```

### Service Management

List all services:

```
./system_monitor.sh service list
```

Check status of a specific service:

```
./system_monitor.sh service check apache2
```

Start a service:

```
./system_monitor.sh service start apache2
```

Stop a service:

```
./system_monitor.sh service stop apache2
```

Restart a service:

```
./system_monitor.sh service restart apache2
```

Enable a service at boot:

```
./system_monitor.sh service enable apache2
```

Disable a service at boot:

```
./system_monitor.sh service disable apache2
```

### Network Monitoring

Collect all network information:

```
./system_monitor.sh network all
```

List network interfaces:

```
./system_monitor.sh network interfaces
```

Show IP addresses:

```
./system_monitor.sh network ip
```

Show routing table:

```
./system_monitor.sh network routes
```

Show active connections:

```
./system_monitor.sh network connections
```

Show DNS settings:

```
./system_monitor.sh network dns
```

Ping a host:

```
./system_monitor.sh network ping google.com 4
```

Trace route to a host:

```
./system_monitor.sh network trace google.com
```

Check open ports:

```
./system_monitor.sh network ports google.com 80,443
```

Monitor network traffic:

```
./system_monitor.sh network traffic 10
```

### Disk Analysis

Show disk usage:

```
./system_monitor.sh disk usage
```

Show inode usage:

```
./system_monitor.sh disk inodes
```

Find largest directories:

```
./system_monitor.sh disk dirs /home 10
```

Find largest files:

```
./system_monitor.sh disk files /home 10
```

Find files larger than a specified size:

```
./system_monitor.sh disk larger-than 100M /home
```

Find old files:

```
./system_monitor.sh disk old 30 /home 20
```

Find recently modified files:

```
./system_monitor.sh disk recent 1 /home 20
```

Find duplicate files:

```
./system_monitor.sh disk duplicates /home
```

Analyze disk usage by file type:

```
./system_monitor.sh disk by-type /home
```

Perform full disk analysis:

```
./system_monitor.sh disk full /home
```

## Requirements

- Bash shell
- Standard Unix/Linux utilities (ps, top, df, du, etc.)
- Optional: fdupes (for finding duplicate files)
- Optional: iftop, nethogs, or tcpdump (for network traffic monitoring)

## Skills Demonstrated

- Shell scripting (Bash)
- System administration
- Process management
- Service management
- Network monitoring and diagnostics
- Disk usage analysis
- Log management
- Command-line interface design
- Error handling and input validation

## Author

Ondřej Knedla

## License

This project is licensed under the MIT License - see the LICENSE file for details.
