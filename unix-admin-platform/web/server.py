#!/usr/bin/env python3
#
# server.py - Web interface for the Unix System Administration Platform
#
# Author: Your Name
# Date: 2023-01-01
# Description: This script provides a web interface for the platform

import os
import sys
import json
import time
import socket
import subprocess
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

# Set paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
LOG_DIR = os.path.join(BASE_DIR, "logs")
CONFIG_DIR = os.path.join(BASE_DIR, "config")
TEMPLATE_DIR = os.path.join(BASE_DIR, "web", "templates")

# Ensure directories exist
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

# Default port
DEFAULT_PORT = 8080

class AdminPlatformHandler(BaseHTTPRequestHandler):
    """HTTP request handler for the Admin Platform web interface."""
    
    def log_message(self, format, *args):
        """Log messages to the platform log file."""
        with open(os.path.join(LOG_DIR, "web_server.log"), "a") as f:
            f.write("%s - - [%s] %s\n" %
                    (self.client_address[0],
                     self.log_date_time_string(),
                     format % args))
    
    def do_GET(self):
        """Handle GET requests."""
        # Route requests
        if self.path == "/" or self.path == "/index.html":
            self.send_dashboard()
        elif self.path == "/system":
            self.send_system_info()
        elif self.path == "/monitoring":
            self.send_monitoring_data()
        elif self.path == "/security":
            self.send_security_data()
        elif self.path == "/backups":
            self.send_backup_data()
        elif self.path.startswith("/static/"):
            self.send_static_file(self.path[8:])
        elif self.path == "/api/system":
            self.send_api_system_info()
        elif self.path == "/api/monitoring":
            self.send_api_monitoring_data()
        elif self.path == "/api/security":
            self.send_api_security_data()
        elif self.path == "/api/backups":
            self.send_api_backup_data()
        else:
            self.send_error(404, "File not found")
    
    def do_POST(self):
        """Handle POST requests."""
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        # Route POST requests
        if self.path == "/api/run_monitor":
            self.run_monitor()
        elif self.path == "/api/run_security_scan":
            self.run_security_scan()
        elif self.path == "/api/run_backup":
            self.run_backup()
        else:
            self.send_error(404, "Endpoint not found")
    
    def send_dashboard(self):
        """Send the dashboard page."""
        # Read the template
        try:
            with open(os.path.join(TEMPLATE_DIR, "dashboard.html"), "r") as f:
                template = f.read()
        except FileNotFoundError:
            # If template doesn't exist, create a basic one
            template = self.generate_default_template("Dashboard")
        
        # Get system information
        hostname = socket.gethostname()
        try:
            with open("/etc/os-release", "r") as f:
                os_info = dict(line.strip().split('=', 1) for line in f if '=' in line)
                os_name = os_info.get('PRETTY_NAME', '').strip('"')
        except:
            os_name = "Unknown"
        
        uptime = self.get_uptime()
        
        # Replace placeholders in template
        content = template.replace("{{hostname}}", hostname)
        content = content.replace("{{os_name}}", os_name)
        content = content.replace("{{uptime}}", uptime)
        content = content.replace("{{current_time}}", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(content.encode())
    
    def send_system_info(self):
        """Send the system information page."""
        # Read the template
        try:
            with open(os.path.join(TEMPLATE_DIR, "system.html"), "r") as f:
                template = f.read()
        except FileNotFoundError:
            # If template doesn't exist, create a basic one
            template = self.generate_default_template("System Information")
        
        # Get system information
        system_info = self.get_system_info_data()
        
        # Format CPU info
        cpu_info = ""
        try:
            with open("/proc/cpuinfo", "r") as f:
                cpu_data = f.read()
            
            model_name = "Unknown"
            for line in cpu_data.split("\n"):
                if "model name" in line:
                    model_name = line.split(":")[1].strip()
                    break
            
            cpu_cores = os.cpu_count() or 0
            cpu_info = f"{model_name} ({cpu_cores} cores)"
        except:
            cpu_info = "Unknown"
        
        # Format memory info
        memory_info = ""
        try:
            with open("/proc/meminfo", "r") as f:
                mem_data = f.read()
            
            total_mem = "Unknown"
            for line in mem_data.split("\n"):
                if "MemTotal" in line:
                    total_mem = line.split(":")[1].strip()
                    break
            
            memory_info = total_mem
        except:
            memory_info = "Unknown"
        
        # Replace placeholders in template
        content = template.replace("{{hostname}}", system_info.get("hostname", "Unknown"))
        content = content.replace("{{os_name}}", system_info.get("os", "Unknown"))
        content = content.replace("{{kernel}}", system_info.get("kernel", "Unknown"))
        content = content.replace("{{uptime}}", system_info.get("uptime", "Unknown"))
        content = content.replace("{{cpu_info}}", cpu_info)
        content = content.replace("{{memory_info}}", memory_info)
        content = content.replace("{{current_time}}", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(content.encode())
    
    def send_monitoring_data(self):
        """Send the monitoring data page."""
        # Read the template
        try:
            with open(os.path.join(TEMPLATE_DIR, "monitoring.html"), "r") as f:
                template = f.read()
        except FileNotFoundError:
            # If template doesn't exist, create a basic one
            template = self.generate_default_template("Monitoring Data")
        
        # Get monitoring data
        monitoring_data = self.get_monitoring_data()
        
        # Format monitoring summary
        summary = monitoring_data.get("summary", {})
        last_run = summary.get("timestamp", "Never")
        alerts = summary.get("alerts", 0)
        
        # Format CPU usage
        cpu_data = monitoring_data.get("cpu", [])
        cpu_usage = "Unknown"
        if cpu_data:
            cpu_usage = f"{cpu_data[-1].get('value', 0):.1f}%"
        
        # Format memory usage
        memory_data = monitoring_data.get("memory", [])
        memory_usage = "Unknown"
        if memory_data:
            memory_usage = f"{memory_data[-1].get('value', 0):.1f}%"
        
        # Format disk usage
        disk_data = monitoring_data.get("disk", [])
        disk_usage = "Unknown"
        if disk_data:
            disk_usage = f"{disk_data[-1].get('value', 0):.1f}%"
        
        # Replace placeholders in template
        content = template.replace("{{last_run}}", last_run)
        content = content.replace("{{alerts}}", str(alerts))
        content = content.replace("{{cpu_usage}}", cpu_usage)
        content = content.replace("{{memory_usage}}", memory_usage)
        content = content.replace("{{disk_usage}}", disk_usage)
        content = content.replace("{{current_time}}", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(content.encode())
    
    def send_security_data(self):
        """Send the security data page."""
        # Read the template
        try:
            with open(os.path.join(TEMPLATE_DIR, "security.html"), "r") as f:
                template = f.read()
        except FileNotFoundError:
            # If template doesn't exist, create a basic one
            template = self.generate_default_template("Security Data")
        
        # Get security data
        security_data = self.get_security_data()
        
        # Format security summary
        summary = security_data.get("summary", {})
        last_scan = summary.get("timestamp", "Never")
        total_issues = summary.get("total_issues", 0)
        high_issues = summary.get("high_issues", 0)
        medium_issues = summary.get("medium_issues", 0)
        low_issues = summary.get("low_issues", 0)
        
        # Format security issues
        issues = security_data.get("issues", [])
        issues_html = ""
        for issue in issues:
            severity = issue.get("severity", "UNKNOWN")
            message = issue.get("message", "Unknown issue")
            timestamp = issue.get("timestamp", "Unknown time")
            
            severity_class = "low"
            if severity == "HIGH":
                severity_class = "high"
            elif severity == "MEDIUM":
                severity_class = "medium"
            
            issues_html += f'<div class="issue {severity_class}">'
            issues_html += f'<span class="severity">{severity}</span>'
            issues_html += f'<span class="message">{message}</span>'
            issues_html += f'<span class="timestamp">{timestamp}</span>'
            issues_html += '</div>'
        
        # Replace placeholders in template
        content = template.replace("{{last_scan}}", last_scan)
        content = content.replace("{{total_issues}}", str(total_issues))
        content = content.replace("{{high_issues}}", str(high_issues))
        content = content.replace("{{medium_issues}}", str(medium_issues))
        content = content.replace("{{low_issues}}", str(low_issues))
        content = content.replace("{{issues}}", issues_html)
        content = content.replace("{{current_time}}", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(content.encode())
    
    def send_backup_data(self):
        """Send the backup data page."""
        # Read the template
        try:
            with open(os.path.join(TEMPLATE_DIR, "backups.html"), "r") as f:
                template = f.read()
        except FileNotFoundError:
            # If template doesn't exist, create a basic one
            template = self.generate_default_template("Backup Data")
        
        # Get backup data
        backup_data = self.get_backup_data()
        
        # Format backup summary
        last_backup = backup_data.get("last_backup", {})
        last_backup_time = last_backup.get("timestamp", "Never")
        backup_location = last_backup.get("location", "Unknown")
        backup_dirs = last_backup.get("directories", "None")
        
        # Get list of backups
        backups_list = ""
        try:
            backup_dir = os.path.join(DATA_DIR, "backups")
            if os.path.exists(backup_dir):
                backups = sorted([d for d in os.listdir(backup_dir) if os.path.isdir(os.path.join(backup_dir, d)) and d != "latest"], reverse=True)
                
                for backup in backups:
                    # Format timestamp
                    if len(backup) >= 15 and backup[8] == "_":
                        year = backup[0:4]
                        month = backup[4:6]
                        day = backup[6:8]
                        hour = backup[9:11]
                        minute = backup[11:13]
                        second = backup[13:15]
                        
                        formatted_date = f"{year}-{month}-{day} {hour}:{minute}:{second}"
                    else:
                        formatted_date = backup
                    
                    # Get backup size
                    backup_path = os.path.join(backup_dir, backup)
                    size = self.get_directory_size(backup_path)
                    formatted_size = self.format_size(size)
                    
                    backups_list += f'<div class="backup">'
                    backups_list += f'<span class="id">{backup}</span>'
                    backups_list += f'<span class="date">{formatted_date}</span>'
                    backups_list += f'<span class="size">{formatted_size}</span>'
                    backups_list += '</div>'
        except:
            backups_list = "<p>Error retrieving backups list</p>"
        
        # Replace placeholders in template
        content = template.replace("{{last_backup_time}}", last_backup_time)
        content = content.replace("{{backup_location}}", backup_location)
        content = content.replace("{{backup_dirs}}", backup_dirs)
        content = content.replace("{{backups_list}}", backups_list)
        content = content.replace("{{current_time}}", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(content.encode())
    
    def send_static_file(self, file_path):
        """Send a static file."""
        # Determine file type
        if file_path.endswith(".css"):
            content_type = "text/css"
        elif file_path.endswith(".js"):
            content_type = "application/javascript"
        elif file_path.endswith(".png"):
            content_type = "image/png"
        elif file_path.endswith(".jpg") or file_path.endswith(".jpeg"):
            content_type = "image/jpeg"
        elif file_path.endswith(".gif"):
            content_type = "image/gif"
        else:
            content_type = "text/plain"
        
        # Read the file
        try:
            with open(os.path.join(BASE_DIR, "web", "static", file_path), "rb") as f:
                content = f.read()
            
            # Send response
            self.send_response(200)
            self.send_header("Content-type", content_type)
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404, "File not found")
    
    def send_api_system_info(self):
        """Send system information as JSON."""
        # Get system information
        system_info = self.get_system_info_data()
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(system_info).encode())
    
    def send_api_monitoring_data(self):
        """Send monitoring data as JSON."""
        # Get monitoring data
        monitoring_data = self.get_monitoring_data()
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(monitoring_data).encode())
    
    def send_api_security_data(self):
        """Send security data as JSON."""
        # Get security data
        security_data = self.get_security_data()
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(security_data).encode())
    
    def send_api_backup_data(self):
        """Send backup data as JSON."""
        # Get backup data
        backup_data = self.get_backup_data()
        
        # Send response
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(backup_data).encode())
    
    def run_monitor(self):
        """Run the monitoring script."""
        try:
            # Run the monitor script
            result = subprocess.run([os.path.join(BASE_DIR, "core", "monitor.sh")], 
                                   capture_output=True, text=True)
            
            # Prepare response
            response = {
                "success": result.returncode == 0,
                "message": "Monitoring completed successfully" if result.returncode == 0 else "Monitoring failed",
                "output": result.stdout,
                "error": result.stderr
            }
            
            # Send response
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        except Exception as e:
            # Send error response
            self.send_response(500)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"success": False, "message": str(e)}).encode())
    
    def run_security_scan(self):
        """Run the security scanner script."""
        try:
            # Run the security scanner script
            result = subprocess.run([os.path.join(BASE_DIR, "security", "scanner.sh")], 
                                   capture_output=True, text=True)
            
            # Prepare response
            response = {
                "success": result.returncode == 0,
                "message": "Security scan completed successfully" if result.returncode == 0 else "Security scan failed",
                "output": result.stdout,
                "error": result.stderr
            }
            
            # Send response
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        except Exception as e:
            # Send error response
            self.send_response(500)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"success": False, "message": str(e)}).encode())
    
    def run_backup(self):
        """Run the backup script."""
        try:
            # Run the backup script
            result = subprocess.run([os.path.join(BASE_DIR, "backup", "backup.sh"), "backup"], 
                                   capture_output=True, text=True)
            
            # Prepare response
            response = {
                "success": result.returncode == 0,
                "message": "Backup completed successfully" if result.returncode == 0 else "Backup failed",
                "output": result.stdout,
                "error": result.stderr
            }
            
            # Send response
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        except Exception as e:
            # Send error response
            self.send_response(500)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"success": False, "message": str(e)}).encode())
    
    def get_system_info_data(self):
        """Get system information data."""
        system_info = {}
        
        # Try to read from system_info.json
        try:
            with open(os.path.join(DATA_DIR, "system_info.json"), "r") as f:
                system_info = json.load(f)
        except:
            # If file doesn't exist or is invalid, get basic system info
            system_info = {
                "hostname": socket.gethostname(),
                "kernel": os.uname().release,
                "uptime": self.get_uptime(),
                "collected_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
            
            # Try to get OS information
            try:
                with open("/etc/os-release", "r") as f:
                    os_info = dict(line.strip().split('=', 1) for line in f if '=' in line)
                    system_info["os"] = os_info.get('PRETTY_NAME', '').strip('"')
            except:
                system_info["os"] = "Unknown"
        
        return system_info
    
    def get_monitoring_data(self):
        """Get monitoring data."""
        monitoring_data = {
            "summary": {},
            "cpu": [],
            "memory": [],
            "disk": [],
            "load": [],
            "zombies": []
        }
        
        # Try to read monitoring summary
        try:
            with open(os.path.join(DATA_DIR, "monitoring_summary.json"), "r") as f:
                monitoring_data["summary"] = json.load(f)
        except:
            pass
        
        # Try to read monitoring data
        try:
            if os.path.exists(os.path.join(DATA_DIR, "monitoring_data.json")):
                with open(os.path.join(DATA_DIR, "monitoring_data.json"), "r") as f:
                    for line in f:
                        try:
                            data = json.loads(line.strip())
                            data_type = data.get("type")
                            
                            if data_type in monitoring_data:
                                monitoring_data[data_type].append(data)
                        except:
                            pass
        except:
            pass
        
        return monitoring_data
    
    def get_security_data(self):
        """Get security data."""
        security_data = {
            "summary": {},
            "issues": []
        }
        
        # Try to read security summary
        try:
            with open(os.path.join(DATA_DIR, "security_summary.json"), "r") as f:
                security_data["summary"] = json.load(f)
        except:
            pass
        
        # Try to read security data
        try:
            if os.path.exists(os.path.join(DATA_DIR, "security_data.json")):
                with open(os.path.join(DATA_DIR, "security_data.json"), "r") as f:
                    for line in f:
                        try:
                            data = json.loads(line.strip())
                            security_data["issues"].append(data)
                        except:
                            pass
        except:
            pass
        
        return security_data
    
    def get_backup_data(self):
        """Get backup data."""
        backup_data = {
            "last_backup": {}
        }
        
        # Try to read last backup info
        try:
            with open(os.path.join(DATA_DIR, "last_backup_info.json"), "r") as f:
                backup_data["last_backup"] = json.load(f)
        except:
            pass
        
        return backup_data
    
    def get_uptime(self):
        """Get system uptime."""
        try:
            with open("/proc/uptime", "r") as f:
                uptime_seconds = float(f.readline().split()[0])
            
            # Format uptime
            days, remainder = divmod(uptime_seconds, 86400)
            hours, remainder = divmod(remainder, 3600)
            minutes, seconds = divmod(remainder, 60)
            
            if days > 0:
                return f"{int(days)} days, {int(hours)} hours, {int(minutes)} minutes"
            elif hours > 0:
                return f"{int(hours)} hours, {int(minutes)} minutes"
            else:
                return f"{int(minutes)} minutes"
        except:
            return "Unknown"
    
    def get_directory_size(self, path):
        """Get the size of a directory in bytes."""
        total_size = 0
        for dirpath, dirnames, filenames in os.walk(path):
            for f in filenames:
                fp = os.path.join(dirpath, f)
                if os.path.exists(fp):
                    total_size += os.path.getsize(fp)
        return total_size
    
    def format_size(self, size_bytes):
        """Format size in bytes to human-readable format."""
        if size_bytes == 0:
            return "0B"
        
        size_names = ("B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB")
        i = 0
        while size_bytes >= 1024 and i < len(size_names) - 1:
            size_bytes /= 1024
            i += 1
        
        return f"{size_bytes:.2f} {size_names[i]}"
    
    def generate_default_template(self, title):
        """Generate a default HTML template."""
        return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unix Admin Platform - {title}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }}
        header {{
            background-color: #333;
            color: white;
            padding: 1rem;
            text-align: center;
        }}
        nav {{
            background-color: #444;
            padding: 0.5rem;
        }}
        nav a {{
            color: white;
            text-decoration: none;
            padding: 0.5rem 1rem;
            margin: 0 0.2rem;
        }}
        nav a:hover {{
            background-color: #555;
        }}
        main {{
            padding: 1rem;
            max-width: 1200px;
            margin: 0 auto;
        }}
        .card {{
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            padding: 1rem;
            margin-bottom: 1rem;
        }}
        footer {{
            background-color: #333;
            color: white;
            text-align: center;
            padding: 1rem;
            position: fixed;
            bottom: 0;
            width: 100%;
        }}
        .issue {{
            padding: 0.5rem;
            margin: 0.5rem 0;
            border-radius: 3px;
        }}
        .issue.high {{
            background-color: #ffdddd;
            border-left: 5px solid #f44336;
        }}
        .issue.medium {{
            background-color: #ffffcc;
            border-left: 5px solid #ffeb3b;
        }}
        .issue.low {{
            background-color: #e7f3fe;
            border-left: 5px solid #2196F3;
        }}
        .severity {{
            font-weight: bold;
            margin-right: 1rem;
        }}
        .backup {{
            padding: 0.5rem;
            margin: 0.5rem 0;
            background-color: #f9f9f9;
            border-left: 5px solid #2196F3;
            display: flex;
            justify-content: space-between;
        }}
    </style>
</head>
<body>
    <header>
        <h1>Unix System Administration Platform</h1>
    </header>
    <nav>
        <a href="/">Dashboard</a>
        <a href="/system">System</a>
        <a href="/monitoring">Monitoring</a>
        <a href="/security">Security</a>
        <a href="/backups">Backups</a>
    </nav>
    <main>
        <h2>{title}</h2>
        <div class="card">
            <p>This is a placeholder page. The actual content will be populated when data is available.</p>
        </div>
    </main>
    <footer>
        <p>Unix System Administration Platform | Current Time: {{current_time}}</p>
    </footer>
</body>
</html>
"""


def run_server(port=DEFAULT_PORT):
    """Run the web server."""
    try:
        server_address = ('', port)
        httpd = HTTPServer(server_address, AdminPlatformHandler)
        print(f"Starting web server on port {port}...")
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("Stopping web server...")
        httpd.server_close()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    # Get port from command line arguments
    port = DEFAULT_PORT
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port: {sys.argv[1]}")
            sys.exit(1)
    
    # Create template directory if it doesn't exist
    os.makedirs(TEMPLATE_DIR, exist_ok=True)
    
    # Create default templates if they don't exist
    if not os.path.exists(os.path.join(TEMPLATE_DIR, "dashboard.html")):
        handler = AdminPlatformHandler(None, None, None)
        with open(os.path.join(TEMPLATE_DIR, "dashboard.html"), "w") as f:
            f.write(handler.generate_default_template("Dashboard"))
    
    # Run the server
    run_server(port)
