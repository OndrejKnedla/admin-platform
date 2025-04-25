/**
 * dashboard.js - JavaScript for the dashboard page
 */

document.addEventListener('DOMContentLoaded', function() {
    // Load monitoring data
    loadMonitoringData();
    
    // Load security data
    loadSecurityData();
    
    // Load backup data
    loadBackupData();
    
    // Add event listeners for buttons
    document.getElementById('run-monitor').addEventListener('click', runMonitor);
    document.getElementById('run-security').addEventListener('click', runSecurityScan);
    document.getElementById('run-backup').addEventListener('click', runBackup);
});

/**
 * Load monitoring data from the API
 */
function loadMonitoringData() {
    fetch('/api/monitoring')
        .then(response => response.json())
        .then(data => {
            const monitoringSummary = document.getElementById('monitoring-summary');
            
            // Get summary data
            const summary = data.summary || {};
            const lastRun = summary.timestamp || 'Never';
            const alerts = summary.alerts || 0;
            
            // Get latest metrics
            let cpuUsage = 'Unknown';
            let memoryUsage = 'Unknown';
            let diskUsage = 'Unknown';
            
            if (data.cpu && data.cpu.length > 0) {
                cpuUsage = `${data.cpu[data.cpu.length - 1].value.toFixed(1)}%`;
            }
            
            if (data.memory && data.memory.length > 0) {
                memoryUsage = `${data.memory[data.memory.length - 1].value.toFixed(1)}%`;
            }
            
            if (data.disk && data.disk.length > 0) {
                diskUsage = `${data.disk[data.disk.length - 1].value.toFixed(1)}%`;
            }
            
            // Create HTML content
            let html = `
                <div class="info-item">
                    <span class="label">Last Run:</span>
                    <span class="value">${lastRun}</span>
                </div>
                <div class="info-item">
                    <span class="label">Alerts:</span>
                    <span class="value">${alerts}</span>
                </div>
                <div class="info-item">
                    <span class="label">CPU Usage:</span>
                    <span class="value">${cpuUsage}</span>
                </div>
                <div class="info-item">
                    <span class="label">Memory Usage:</span>
                    <span class="value">${memoryUsage}</span>
                </div>
                <div class="info-item">
                    <span class="label">Disk Usage:</span>
                    <span class="value">${diskUsage}</span>
                </div>
            `;
            
            monitoringSummary.innerHTML = html;
        })
        .catch(error => {
            console.error('Error loading monitoring data:', error);
            document.getElementById('monitoring-summary').innerHTML = '<p>Error loading monitoring data</p>';
        });
}

/**
 * Load security data from the API
 */
function loadSecurityData() {
    fetch('/api/security')
        .then(response => response.json())
        .then(data => {
            const securitySummary = document.getElementById('security-summary');
            
            // Get summary data
            const summary = data.summary || {};
            const lastScan = summary.timestamp || 'Never';
            const totalIssues = summary.total_issues || 0;
            const highIssues = summary.high_issues || 0;
            const mediumIssues = summary.medium_issues || 0;
            const lowIssues = summary.low_issues || 0;
            
            // Create HTML content
            let html = `
                <div class="info-item">
                    <span class="label">Last Scan:</span>
                    <span class="value">${lastScan}</span>
                </div>
                <div class="info-item">
                    <span class="label">Total Issues:</span>
                    <span class="value">${totalIssues}</span>
                </div>
                <div class="info-item">
                    <span class="label">High:</span>
                    <span class="value">${highIssues}</span>
                </div>
                <div class="info-item">
                    <span class="label">Medium:</span>
                    <span class="value">${mediumIssues}</span>
                </div>
                <div class="info-item">
                    <span class="label">Low:</span>
                    <span class="value">${lowIssues}</span>
                </div>
            `;
            
            securitySummary.innerHTML = html;
        })
        .catch(error => {
            console.error('Error loading security data:', error);
            document.getElementById('security-summary').innerHTML = '<p>Error loading security data</p>';
        });
}

/**
 * Load backup data from the API
 */
function loadBackupData() {
    fetch('/api/backups')
        .then(response => response.json())
        .then(data => {
            const backupSummary = document.getElementById('backup-summary');
            
            // Get last backup data
            const lastBackup = data.last_backup || {};
            const lastBackupTime = lastBackup.timestamp || 'Never';
            const backupLocation = lastBackup.location || 'Unknown';
            const backupDirs = lastBackup.directories || 'None';
            
            // Create HTML content
            let html = `
                <div class="info-item">
                    <span class="label">Last Backup:</span>
                    <span class="value">${lastBackupTime}</span>
                </div>
                <div class="info-item">
                    <span class="label">Location:</span>
                    <span class="value">${backupLocation}</span>
                </div>
                <div class="info-item">
                    <span class="label">Directories:</span>
                    <span class="value">${backupDirs}</span>
                </div>
            `;
            
            backupSummary.innerHTML = html;
        })
        .catch(error => {
            console.error('Error loading backup data:', error);
            document.getElementById('backup-summary').innerHTML = '<p>Error loading backup data</p>';
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
            button.textContent = 'Run Now';
        });
}

/**
 * Run the security scanner
 */
function runSecurityScan() {
    const button = document.getElementById('run-security');
    button.disabled = true;
    button.textContent = 'Running...';
    
    fetch('/api/run_security_scan', { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert('Security scan completed successfully');
                // Reload data
                loadSecurityData();
            } else {
                alert('Security scan failed: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error running security scan:', error);
            alert('Error running security scan: ' + error);
        })
        .finally(() => {
            button.disabled = false;
            button.textContent = 'Run Scan';
        });
}

/**
 * Run the backup script
 */
function runBackup() {
    const button = document.getElementById('run-backup');
    button.disabled = true;
    button.textContent = 'Running...';
    
    fetch('/api/run_backup', { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert('Backup completed successfully');
                // Reload data
                loadBackupData();
            } else {
                alert('Backup failed: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error running backup:', error);
            alert('Error running backup: ' + error);
        })
        .finally(() => {
            button.disabled = false;
            button.textContent = 'Run Backup';
        });
}
