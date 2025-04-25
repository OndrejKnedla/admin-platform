/**
 * system.js - JavaScript for the system information page
 */

document.addEventListener('DOMContentLoaded', function() {
    // Load disk usage data
    loadDiskUsage();
    
    // Load network interfaces data
    loadNetworkInterfaces();
    
    // Load running processes data
    loadRunningProcesses();
});

/**
 * Load disk usage data
 */
function loadDiskUsage() {
    // Execute a command to get disk usage
    fetch('/api/system')
        .then(response => response.json())
        .then(data => {
            // Get disk usage from the system command
            const diskUsageElement = document.getElementById('disk-usage');
            
            // Create a table to display disk usage
            let html = `
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Filesystem</th>
                            <th>Size</th>
                            <th>Used</th>
                            <th>Available</th>
                            <th>Use%</th>
                            <th>Mounted on</th>
                        </tr>
                    </thead>
                    <tbody id="disk-usage-data">
                        <tr>
                            <td colspan="6" class="loading">Loading disk usage data...</td>
                        </tr>
                    </tbody>
                </table>
            `;
            
            diskUsageElement.innerHTML = html;
            
            // Execute command to get disk usage
            fetch('/api/run_command', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    command: 'df -h'
                })
            })
            .then(response => response.json())
            .then(commandData => {
                if (commandData.success) {
                    const diskUsageData = document.getElementById('disk-usage-data');
                    const lines = commandData.output.split('\n');
                    
                    // Skip the header line
                    let tableHtml = '';
                    for (let i = 1; i < lines.length; i++) {
                        const line = lines[i].trim();
                        if (line) {
                            const parts = line.split(/\s+/);
                            if (parts.length >= 6) {
                                const filesystem = parts[0];
                                const size = parts[1];
                                const used = parts[2];
                                const available = parts[3];
                                const usePercent = parts[4];
                                const mountPoint = parts.slice(5).join(' ');
                                
                                // Calculate usage percentage for progress bar
                                const usageValue = parseInt(usePercent);
                                let usageClass = 'normal';
                                if (usageValue >= 90) {
                                    usageClass = 'critical';
                                } else if (usageValue >= 75) {
                                    usageClass = 'warning';
                                }
                                
                                tableHtml += `
                                    <tr>
                                        <td>${filesystem}</td>
                                        <td>${size}</td>
                                        <td>${used}</td>
                                        <td>${available}</td>
                                        <td>
                                            <div class="progress-bar">
                                                <div class="progress-value ${usageClass}" style="width: ${usePercent}"></div>
                                                <span>${usePercent}</span>
                                            </div>
                                        </td>
                                        <td>${mountPoint}</td>
                                    </tr>
                                `;
                            }
                        }
                    }
                    
                    diskUsageData.innerHTML = tableHtml || '<tr><td colspan="6">No disk usage data available</td></tr>';
                } else {
                    document.getElementById('disk-usage-data').innerHTML = '<tr><td colspan="6">Error retrieving disk usage data</td></tr>';
                }
            })
            .catch(error => {
                console.error('Error executing command:', error);
                document.getElementById('disk-usage-data').innerHTML = '<tr><td colspan="6">Error retrieving disk usage data</td></tr>';
            });
        })
        .catch(error => {
            console.error('Error loading system data:', error);
            document.getElementById('disk-usage').innerHTML = '<p>Error loading disk usage data</p>';
        });
}

/**
 * Load network interfaces data
 */
function loadNetworkInterfaces() {
    const networkInterfacesElement = document.getElementById('network-interfaces');
    
    // Create a table to display network interfaces
    let html = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>Interface</th>
                    <th>IP Address</th>
                    <th>MAC Address</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody id="network-interfaces-data">
                <tr>
                    <td colspan="4" class="loading">Loading network interface data...</td>
                </tr>
            </tbody>
        </table>
    `;
    
    networkInterfacesElement.innerHTML = html;
    
    // Execute command to get network interfaces
    fetch('/api/run_command', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: 'ip -o addr show'
        })
    })
    .then(response => response.json())
    .then(commandData => {
        if (commandData.success) {
            const networkInterfacesData = document.getElementById('network-interfaces-data');
            const lines = commandData.output.split('\n');
            
            // Process the output
            let tableHtml = '';
            const interfaces = {};
            
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (line) {
                    const parts = line.split(/\s+/);
                    if (parts.length >= 4) {
                        const interfaceIndex = parts[0];
                        const interfaceName = parts[1];
                        const interfaceInfo = line;
                        
                        // Extract IP address
                        const ipMatch = interfaceInfo.match(/inet\s+([0-9.]+)/);
                        const ipAddress = ipMatch ? ipMatch[1] : 'N/A';
                        
                        // Extract MAC address
                        const macMatch = interfaceInfo.match(/link\/ether\s+([0-9a-f:]+)/i);
                        const macAddress = macMatch ? macMatch[1] : 'N/A';
                        
                        // Extract status
                        const statusMatch = interfaceInfo.match(/state\s+(\w+)/i);
                        const status = statusMatch ? statusMatch[1] : 'Unknown';
                        
                        // Store interface data
                        if (!interfaces[interfaceName]) {
                            interfaces[interfaceName] = {
                                name: interfaceName,
                                ipAddress: ipAddress,
                                macAddress: macAddress,
                                status: status
                            };
                        }
                    }
                }
            }
            
            // Generate table rows
            for (const interfaceName in interfaces) {
                const interfaceData = interfaces[interfaceName];
                
                let statusClass = 'normal';
                if (interfaceData.status.toLowerCase() === 'up') {
                    statusClass = 'success';
                } else if (interfaceData.status.toLowerCase() === 'down') {
                    statusClass = 'critical';
                }
                
                tableHtml += `
                    <tr>
                        <td>${interfaceData.name}</td>
                        <td>${interfaceData.ipAddress}</td>
                        <td>${interfaceData.macAddress}</td>
                        <td><span class="status ${statusClass}">${interfaceData.status}</span></td>
                    </tr>
                `;
            }
            
            networkInterfacesData.innerHTML = tableHtml || '<tr><td colspan="4">No network interfaces found</td></tr>';
        } else {
            document.getElementById('network-interfaces-data').innerHTML = '<tr><td colspan="4">Error retrieving network interface data</td></tr>';
        }
    })
    .catch(error => {
        console.error('Error executing command:', error);
        document.getElementById('network-interfaces-data').innerHTML = '<tr><td colspan="4">Error retrieving network interface data</td></tr>';
    });
}

/**
 * Load running processes data
 */
function loadRunningProcesses() {
    const runningProcessesElement = document.getElementById('running-processes');
    
    // Create a table to display running processes
    let html = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>PID</th>
                    <th>User</th>
                    <th>CPU%</th>
                    <th>MEM%</th>
                    <th>Command</th>
                </tr>
            </thead>
            <tbody id="running-processes-data">
                <tr>
                    <td colspan="5" class="loading">Loading process data...</td>
                </tr>
            </tbody>
        </table>
    `;
    
    runningProcessesElement.innerHTML = html;
    
    // Execute command to get running processes
    fetch('/api/run_command', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: 'ps aux --sort=-%cpu | head -11'
        })
    })
    .then(response => response.json())
    .then(commandData => {
        if (commandData.success) {
            const runningProcessesData = document.getElementById('running-processes-data');
            const lines = commandData.output.split('\n');
            
            // Skip the header line
            let tableHtml = '';
            for (let i = 1; i < lines.length; i++) {
                const line = lines[i].trim();
                if (line) {
                    const parts = line.split(/\s+/);
                    if (parts.length >= 11) {
                        const user = parts[0];
                        const pid = parts[1];
                        const cpu = parts[2];
                        const mem = parts[3];
                        const command = parts.slice(10).join(' ');
                        
                        // Calculate CPU usage for color coding
                        const cpuValue = parseFloat(cpu);
                        let cpuClass = 'normal';
                        if (cpuValue >= 50) {
                            cpuClass = 'critical';
                        } else if (cpuValue >= 20) {
                            cpuClass = 'warning';
                        }
                        
                        // Calculate memory usage for color coding
                        const memValue = parseFloat(mem);
                        let memClass = 'normal';
                        if (memValue >= 50) {
                            memClass = 'critical';
                        } else if (memValue >= 20) {
                            memClass = 'warning';
                        }
                        
                        tableHtml += `
                            <tr>
                                <td>${pid}</td>
                                <td>${user}</td>
                                <td class="${cpuClass}">${cpu}%</td>
                                <td class="${memClass}">${mem}%</td>
                                <td>${command}</td>
                            </tr>
                        `;
                    }
                }
            }
            
            runningProcessesData.innerHTML = tableHtml || '<tr><td colspan="5">No process data available</td></tr>';
        } else {
            document.getElementById('running-processes-data').innerHTML = '<tr><td colspan="5">Error retrieving process data</td></tr>';
        }
    })
    .catch(error => {
        console.error('Error executing command:', error);
        document.getElementById('running-processes-data').innerHTML = '<tr><td colspan="5">Error retrieving process data</td></tr>';
    });
}
