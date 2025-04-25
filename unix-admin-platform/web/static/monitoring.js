/**
 * monitoring.js - JavaScript for the monitoring page
 */

document.addEventListener('DOMContentLoaded', function() {
    // Load monitoring data
    loadMonitoringData();
    
    // Add event listener for run button
    document.getElementById('run-monitor').addEventListener('click', runMonitor);
});

/**
 * Load monitoring data from the API
 */
function loadMonitoringData() {
    fetch('/api/monitoring')
        .then(response => response.json())
        .then(data => {
            // Update charts
            updateCpuChart(data.cpu || []);
            updateMemoryChart(data.memory || []);
            updateDiskChart(data.disk || []);
            updateLoadChart(data.load || []);
            
            // Load alerts
            loadAlerts();
            
            // Load top processes
            loadTopProcesses();
        })
        .catch(error => {
            console.error('Error loading monitoring data:', error);
            alert('Error loading monitoring data: ' + error);
        });
}

/**
 * Update CPU usage chart
 */
function updateCpuChart(cpuData) {
    const cpuChart = document.getElementById('cpu-chart');
    
    if (cpuData.length === 0) {
        cpuChart.innerHTML = '<div class="no-data">No CPU data available</div>';
        return;
    }
    
    // Get the last 20 data points
    const data = cpuData.slice(-20);
    
    // Find the maximum value for scaling
    const maxValue = Math.max(...data.map(item => item.value), 100);
    
    // Create the chart HTML
    let html = '<div class="chart">';
    
    // Add data points
    for (let i = 0; i < data.length; i++) {
        const height = (data[i].value / maxValue) * 100;
        const timestamp = new Date(data[i].timestamp).toLocaleTimeString();
        
        // Determine color based on value
        let barClass = 'normal';
        if (data[i].value >= 80) {
            barClass = 'critical';
        } else if (data[i].value >= 50) {
            barClass = 'warning';
        }
        
        html += `
            <div class="chart-bar" title="${data[i].value.toFixed(1)}% at ${timestamp}">
                <div class="chart-bar-value ${barClass}" style="height: ${height}%"></div>
            </div>
        `;
    }
    
    html += '</div>';
    
    // Add the chart legend
    html += `
        <div class="chart-legend">
            <div class="chart-legend-item">
                <span class="chart-legend-color normal"></span>
                <span class="chart-legend-label">Normal (&lt; 50%)</span>
            </div>
            <div class="chart-legend-item">
                <span class="chart-legend-color warning"></span>
                <span class="chart-legend-label">Warning (50-80%)</span>
            </div>
            <div class="chart-legend-item">
                <span class="chart-legend-color critical"></span>
                <span class="chart-legend-label">Critical (&gt; 80%)</span>
            </div>
        </div>
    `;
    
    cpuChart.innerHTML = html;
}

/**
 * Update memory usage chart
 */
function updateMemoryChart(memoryData) {
    const memoryChart = document.getElementById('memory-chart');
    
    if (memoryData.length === 0) {
        memoryChart.innerHTML = '<div class="no-data">No memory data available</div>';
        return;
    }
    
    // Get the last 20 data points
    const data = memoryData.slice(-20);
    
    // Find the maximum value for scaling
    const maxValue = Math.max(...data.map(item => item.value), 100);
    
    // Create the chart HTML
    let html = '<div class="chart">';
    
    // Add data points
    for (let i = 0; i < data.length; i++) {
        const height = (data[i].value / maxValue) * 100;
        const timestamp = new Date(data[i].timestamp).toLocaleTimeString();
        
        // Determine color based on value
        let barClass = 'normal';
        if (data[i].value >= 80) {
            barClass = 'critical';
        } else if (data[i].value >= 50) {
            barClass = 'warning';
        }
        
        html += `
            <div class="chart-bar" title="${data[i].value.toFixed(1)}% at ${timestamp}">
                <div class="chart-bar-value ${barClass}" style="height: ${height}%"></div>
            </div>
        `;
    }
    
    html += '</div>';
    
    // Add the chart legend
    html += `
        <div class="chart-legend">
            <div class="chart-legend-item">
                <span class="chart-legend-color normal"></span>
                <span class="chart-legend-label">Normal (&lt; 50%)</span>
            </div>
            <div class="chart-legend-item">
                <span class="chart-legend-color warning"></span>
                <span class="chart-legend-label">Warning (50-80%)</span>
            </div>
            <div class="chart-legend-item">
                <span class="chart-legend-color critical"></span>
                <span class="chart-legend-label">Critical (&gt; 80%)</span>
            </div>
        </div>
    `;
    
    memoryChart.innerHTML = html;
}

/**
 * Update disk usage chart
 */
function updateDiskChart(diskData) {
    const diskChart = document.getElementById('disk-chart');
    
    if (diskData.length === 0) {
        diskChart.innerHTML = '<div class="no-data">No disk data available</div>';
        return;
    }
    
    // Group data by filesystem
    const filesystems = {};
    for (const item of diskData) {
        const filesystem = item.filesystem || 'unknown';
        if (!filesystems[filesystem]) {
            filesystems[filesystem] = [];
        }
        filesystems[filesystem].push(item);
    }
    
    // Create the chart HTML
    let html = '';
    
    // Add a chart for each filesystem
    for (const filesystem in filesystems) {
        const data = filesystems[filesystem].slice(-5); // Get the last 5 data points
        
        // Get the latest value
        const latestValue = data[data.length - 1].value;
        
        // Determine color based on value
        let barClass = 'normal';
        if (latestValue >= 90) {
            barClass = 'critical';
        } else if (latestValue >= 75) {
            barClass = 'warning';
        }
        
        // Get the mountpoint
        const mountpoint = data[data.length - 1].mountpoint || filesystem;
        
        html += `
            <div class="disk-usage-item">
                <div class="disk-usage-info">
                    <span class="disk-name">${mountpoint}</span>
                    <span class="disk-value">${latestValue}%</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-value ${barClass}" style="width: ${latestValue}%"></div>
                </div>
            </div>
        `;
    }
    
    diskChart.innerHTML = html;
}

/**
 * Update system load chart
 */
function updateLoadChart(loadData) {
    const loadChart = document.getElementById('load-chart');
    
    if (loadData.length === 0) {
        loadChart.innerHTML = '<div class="no-data">No load data available</div>';
        return;
    }
    
    // Get the last 20 data points
    const data = loadData.slice(-20);
    
    // Find the maximum value for scaling
    const maxLoad1 = Math.max(...data.map(item => item.load1));
    const maxLoad5 = Math.max(...data.map(item => item.load5));
    const maxLoad15 = Math.max(...data.map(item => item.load15));
    const maxValue = Math.max(maxLoad1, maxLoad5, maxLoad15, data[0].cores);
    
    // Create the chart HTML
    let html = '<div class="load-chart">';
    
    // Add data points
    for (let i = 0; i < data.length; i++) {
        const height1 = (data[i].load1 / maxValue) * 100;
        const height5 = (data[i].load5 / maxValue) * 100;
        const height15 = (data[i].load15 / maxValue) * 100;
        const timestamp = new Date(data[i].timestamp).toLocaleTimeString();
        
        html += `
            <div class="load-chart-bar" title="Load at ${timestamp}">
                <div class="load-bar-group">
                    <div class="load-bar load1" style="height: ${height1}%" title="1 min: ${data[i].load1.toFixed(2)}"></div>
                    <div class="load-bar load5" style="height: ${height5}%" title="5 min: ${data[i].load5.toFixed(2)}"></div>
                    <div class="load-bar load15" style="height: ${height15}%" title="15 min: ${data[i].load15.toFixed(2)}"></div>
                </div>
            </div>
        `;
    }
    
    html += '</div>';
    
    // Add the chart legend
    html += `
        <div class="chart-legend">
            <div class="chart-legend-item">
                <span class="chart-legend-color load1"></span>
                <span class="chart-legend-label">1 min</span>
            </div>
            <div class="chart-legend-item">
                <span class="chart-legend-color load5"></span>
                <span class="chart-legend-label">5 min</span>
            </div>
            <div class="chart-legend-item">
                <span class="chart-legend-color load15"></span>
                <span class="chart-legend-label">15 min</span>
            </div>
            <div class="chart-legend-item">
                <span class="chart-legend-label">Cores: ${data[0].cores}</span>
            </div>
        </div>
    `;
    
    loadChart.innerHTML = html;
}

/**
 * Load alerts from the log file
 */
function loadAlerts() {
    // Execute command to get alerts
    fetch('/api/run_command', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: 'tail -n 20 logs/alerts.log'
        })
    })
    .then(response => response.json())
    .then(data => {
        const alertsList = document.getElementById('alerts-list');
        
        if (data.success) {
            const lines = data.output.split('\n');
            
            if (lines.length === 0 || (lines.length === 1 && lines[0] === '')) {
                alertsList.innerHTML = '<div class="no-data">No alerts found</div>';
                return;
            }
            
            let html = '';
            for (const line of lines) {
                if (line.trim() === '') continue;
                
                // Parse the alert line
                const timestampMatch = line.match(/\[(.*?)\]/);
                const timestamp = timestampMatch ? timestampMatch[1] : '';
                
                // Determine severity
                let severity = 'low';
                if (line.includes('HIGH') || line.includes('CRITICAL')) {
                    severity = 'high';
                } else if (line.includes('MEDIUM') || line.includes('WARNING')) {
                    severity = 'medium';
                }
                
                // Extract message
                const message = line.replace(/\[.*?\]/g, '').trim();
                
                html += `
                    <div class="alert ${severity}">
                        <span class="alert-timestamp">${timestamp}</span>
                        <span class="alert-message">${message}</span>
                    </div>
                `;
            }
            
            alertsList.innerHTML = html;
        } else {
            alertsList.innerHTML = '<div class="error">Error loading alerts</div>';
        }
    })
    .catch(error => {
        console.error('Error loading alerts:', error);
        document.getElementById('alerts-list').innerHTML = '<div class="error">Error loading alerts</div>';
    });
}

/**
 * Load top processes
 */
function loadTopProcesses() {
    // Execute command to get top processes
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
    .then(data => {
        const topProcesses = document.getElementById('top-processes');
        
        if (data.success) {
            const lines = data.output.split('\n');
            
            if (lines.length <= 1) {
                topProcesses.innerHTML = '<div class="no-data">No process data available</div>';
                return;
            }
            
            // Create a table to display processes
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
                    <tbody>
            `;
            
            // Skip the header line
            for (let i = 1; i < lines.length; i++) {
                const line = lines[i].trim();
                if (line === '') continue;
                
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
                    
                    html += `
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
            
            html += `
                    </tbody>
                </table>
            `;
            
            topProcesses.innerHTML = html;
        } else {
            topProcesses.innerHTML = '<div class="error">Error loading process data</div>';
        }
    })
    .catch(error => {
        console.error('Error loading top processes:', error);
        document.getElementById('top-processes').innerHTML = '<div class="error">Error loading process data</div>';
    });
}

/**
 * Run the monitoring script
 */
function runMonitor() {
    const button = document.getElementById('run-monitor');
    button.disabled = true;
    button.textContent = 'Running...';
    
    fetch('/api/run_monitor', { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert('Monitoring completed successfully');
                // Reload data
                loadMonitoringData();
            } else {
                alert('Monitoring failed: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error running monitor:', error);
            alert('Error running monitor: ' + error);
        })
        .finally(() => {
            button.disabled = false;
            button.textContent = 'Run Monitoring Check';
        });
}
