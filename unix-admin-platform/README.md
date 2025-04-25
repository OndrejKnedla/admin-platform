# Unix System Administration Platform

A comprehensive platform for Unix/Linux system administration, monitoring, security, and management.

## Features

- **System Monitoring**: Real-time monitoring of CPU, memory, disk usage, and system load
- **Process Management**: Monitor and manage system processes
- **Security Scanning**: Identify security vulnerabilities and receive recommendations
- **Backup System**: Automated backup and restore functionality
- **Remote Management**: Manage multiple remote systems from a central location
- **Web Interface**: User-friendly web dashboard for system administration
- **Task Scheduler**: Schedule and automate administrative tasks
- **Logging**: Comprehensive logging of all operations

## Directory Structure

```
unix-admin-platform/
├── admin-platform.sh     # Main entry point script
├── README.md             # Documentation
├── config/               # Configuration files
├── core/                 # Core monitoring scripts
│   └── monitor.sh        # System monitoring script
├── scheduler/            # Task scheduler
│   └── scheduler.sh      # Task scheduling script
├── security/             # Security scanning
│   └── scanner.sh        # Security scanner script
├── backup/               # Backup system
│   └── backup.sh         # Backup script
├── remote/               # Remote management
│   └── remote_manager.sh # Remote system management script
├── web/                  # Web interface
│   ├── server.py         # Web server
│   ├── static/           # Static files (CSS, JS)
│   └── templates/        # HTML templates
├── data/                 # Data storage
└── logs/                 # Log files
```

## Installation

1. Clone or download this repository
2. Make the scripts executable:
   ```
   chmod +x unix-admin-platform/admin-platform.sh
   ```
3. Run the platform:
   ```
   cd unix-admin-platform
   ./admin-platform.sh help
   ```

## Configuration

The platform can be configured by editing the configuration file:

```
unix-admin-platform/config/platform.conf
```

This file is automatically created with default settings when you first run the platform.

## Usage

### Starting the Platform

Start all platform components:

```
./admin-platform.sh start
```

This will start the web interface and the task scheduler.

### Stopping the Platform

Stop all platform components:

```
./admin-platform.sh stop
```

### Checking Platform Status

Check the status of all platform components:

```
./admin-platform.sh status
```

### System Monitoring

Run a system monitoring check:

```
./admin-platform.sh monitor
```

### Security Scanning

Run a security scan:

```
./admin-platform.sh security
```

### Backup Management

Run a backup:

```
./admin-platform.sh backup
```

### Web Interface

The web interface is available at:

```
http://localhost:8080
```

You can change the port in the configuration file.

### Remote Management

List remote hosts:

```
./remote/remote_manager.sh list
```

Add a remote host:

```
./remote/remote_manager.sh add_host webserver 192.168.1.10 admin "Web Server"
```

Check connectivity to a remote host:

```
./remote/remote_manager.sh check_host webserver
```

Execute a command on a remote host:

```
./remote/remote_manager.sh execute_command webserver "uptime"
```

Run a monitoring check on a remote host:

```
./remote/remote_manager.sh monitor_host webserver
```

## Task Scheduler

List scheduled tasks:

```
./scheduler/scheduler.sh list
```

Add a new task:

```
./scheduler/scheduler.sh add backup_home "./backup/backup.sh backup" 86400
```

Enable or disable a task:

```
./scheduler/scheduler.sh enable backup_home
./scheduler/scheduler.sh disable backup_home
```

## Requirements

- Bash shell
- Python 3.6 or higher (for web interface)
- Standard Unix/Linux utilities
- SSH client (for remote management)
- Optional: bc, jq (for advanced features)

## Skills Demonstrated

- Shell scripting (Bash)
- Python programming
- Web development (HTML, CSS, JavaScript)
- System administration
- Security scanning and hardening
- Backup and recovery
- Remote system management
- Process monitoring and management
- Task scheduling and automation
- Web server implementation

## Author

Your Name

## License

This project is licensed under the MIT License - see the LICENSE file for details.
