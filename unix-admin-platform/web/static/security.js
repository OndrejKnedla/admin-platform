/**
 * security.js - JavaScript for the security page
 */

document.addEventListener('DOMContentLoaded', function() {
    // Load security recommendations
    loadSecurityRecommendations();
    
    // Add event listener for run button
    document.getElementById('run-security').addEventListener('click', runSecurityScan);
});

/**
 * Load security recommendations
 */
function loadSecurityRecommendations() {
    const recommendationsElement = document.getElementById('security-recommendations');
    
    // Get security data from API
    fetch('/api/security')
        .then(response => response.json())
        .then(data => {
            const issues = data.issues || [];
            
            if (issues.length === 0) {
                recommendationsElement.innerHTML = '<div class="no-data">No security issues found</div>';
                return;
            }
            
            // Generate recommendations based on issues
            const recommendations = generateRecommendations(issues);
            
            if (recommendations.length === 0) {
                recommendationsElement.innerHTML = '<div class="no-data">No recommendations available</div>';
                return;
            }
            
            let html = '<ul class="recommendations-list">';
            for (const recommendation of recommendations) {
                html += `
                    <li class="recommendation ${recommendation.severity}">
                        <div class="recommendation-header">
                            <span class="recommendation-title">${recommendation.title}</span>
                            <span class="recommendation-severity">${recommendation.severity.toUpperCase()}</span>
                        </div>
                        <div class="recommendation-body">
                            <p>${recommendation.description}</p>
                            ${recommendation.solution ? `<p><strong>Solution:</strong> ${recommendation.solution}</p>` : ''}
                        </div>
                    </li>
                `;
            }
            html += '</ul>';
            
            recommendationsElement.innerHTML = html;
        })
        .catch(error => {
            console.error('Error loading security data:', error);
            recommendationsElement.innerHTML = '<div class="error">Error loading security recommendations</div>';
        });
}

/**
 * Generate recommendations based on security issues
 */
function generateRecommendations(issues) {
    const recommendations = [];
    const issueTypes = {};
    
    // Group issues by type
    for (const issue of issues) {
        const message = issue.message || '';
        const severity = issue.severity || 'LOW';
        
        // Categorize issues
        if (message.includes('empty password')) {
            if (!issueTypes.emptyPasswords) {
                issueTypes.emptyPasswords = { count: 0, severity: severity };
            }
            issueTypes.emptyPasswords.count++;
        } else if (message.includes('password aging')) {
            if (!issueTypes.passwordAging) {
                issueTypes.passwordAging = { count: 0, severity: severity };
            }
            issueTypes.passwordAging.count++;
        } else if (message.includes('SUID')) {
            if (!issueTypes.suidBinaries) {
                issueTypes.suidBinaries = { count: 0, severity: severity };
            }
            issueTypes.suidBinaries.count++;
        } else if (message.includes('open port')) {
            if (!issueTypes.openPorts) {
                issueTypes.openPorts = { count: 0, severity: severity };
            }
            issueTypes.openPorts.count++;
        } else if (message.includes('world-writable')) {
            if (!issueTypes.worldWritable) {
                issueTypes.worldWritable = { count: 0, severity: severity };
            }
            issueTypes.worldWritable.count++;
        } else if (message.includes('unowned')) {
            if (!issueTypes.unownedFiles) {
                issueTypes.unownedFiles = { count: 0, severity: severity };
            }
            issueTypes.unownedFiles.count++;
        } else if (message.includes('suspicious') && message.includes('cron')) {
            if (!issueTypes.suspiciousCron) {
                issueTypes.suspiciousCron = { count: 0, severity: severity };
            }
            issueTypes.suspiciousCron.count++;
        } else if (message.includes('suspicious') && message.includes('process')) {
            if (!issueTypes.suspiciousProcesses) {
                issueTypes.suspiciousProcesses = { count: 0, severity: severity };
            }
            issueTypes.suspiciousProcesses.count++;
        } else if (message.includes('SSH') && message.includes('root login')) {
            if (!issueTypes.sshRootLogin) {
                issueTypes.sshRootLogin = { count: 0, severity: severity };
            }
            issueTypes.sshRootLogin.count++;
        } else if (message.includes('failed login')) {
            if (!issueTypes.failedLogins) {
                issueTypes.failedLogins = { count: 0, severity: severity };
            }
            issueTypes.failedLogins.count++;
        } else if (message.includes('rootkit')) {
            if (!issueTypes.rootkits) {
                issueTypes.rootkits = { count: 0, severity: severity };
            }
            issueTypes.rootkits.count++;
        } else if (message.includes('firewall')) {
            if (!issueTypes.firewall) {
                issueTypes.firewall = { count: 0, severity: severity };
            }
            issueTypes.firewall.count++;
        } else if (message.includes('security update')) {
            if (!issueTypes.securityUpdates) {
                issueTypes.securityUpdates = { count: 0, severity: severity };
            }
            issueTypes.securityUpdates.count++;
        }
    }
    
    // Generate recommendations for each issue type
    if (issueTypes.emptyPasswords && issueTypes.emptyPasswords.count > 0) {
        recommendations.push({
            title: 'Users with Empty Passwords',
            severity: issueTypes.emptyPasswords.severity.toLowerCase(),
            description: `Found ${issueTypes.emptyPasswords.count} user(s) with empty passwords. This is a serious security risk as it allows anyone to log in without authentication.`,
            solution: 'Set strong passwords for all user accounts using the passwd command.'
        });
    }
    
    if (issueTypes.passwordAging && issueTypes.passwordAging.count > 0) {
        recommendations.push({
            title: 'Password Aging Not Configured',
            severity: issueTypes.passwordAging.severity.toLowerCase(),
            description: `Found ${issueTypes.passwordAging.count} user(s) without password aging policies. Password aging ensures that users change their passwords periodically.`,
            solution: 'Configure password aging using the chage command to enforce regular password changes.'
        });
    }
    
    if (issueTypes.suidBinaries && issueTypes.suidBinaries.count > 0) {
        recommendations.push({
            title: 'Unauthorized SUID Binaries',
            severity: issueTypes.suidBinaries.severity.toLowerCase(),
            description: `Found ${issueTypes.suidBinaries.count} unauthorized SUID binary/binaries. SUID binaries run with the permissions of the file owner, which can be a security risk if exploited.`,
            solution: 'Review all SUID binaries and remove the SUID bit from unauthorized files using chmod u-s command.'
        });
    }
    
    if (issueTypes.openPorts && issueTypes.openPorts.count > 0) {
        recommendations.push({
            title: 'Unnecessary Open Ports',
            severity: issueTypes.openPorts.severity.toLowerCase(),
            description: `Found ${issueTypes.openPorts.count} potentially unnecessary open port(s). Open ports can be entry points for attackers.`,
            solution: 'Close unnecessary ports by stopping the associated services or configuring the firewall to block them.'
        });
    }
    
    if (issueTypes.worldWritable && issueTypes.worldWritable.count > 0) {
        recommendations.push({
            title: 'World-Writable Files',
            severity: issueTypes.worldWritable.severity.toLowerCase(),
            description: `Found ${issueTypes.worldWritable.count} world-writable file(s) or directory/directories. World-writable files can be modified by any user on the system.`,
            solution: 'Restrict permissions on these files using chmod o-w command to remove write access for others.'
        });
    }
    
    if (issueTypes.unownedFiles && issueTypes.unownedFiles.count > 0) {
        recommendations.push({
            title: 'Unowned Files',
            severity: issueTypes.unownedFiles.severity.toLowerCase(),
            description: `Found ${issueTypes.unownedFiles.count} file(s) with no valid owner or group. Unowned files may indicate compromised or deleted user accounts.`,
            solution: 'Assign proper ownership to these files using chown command or remove them if they are not needed.'
        });
    }
    
    if (issueTypes.suspiciousCron && issueTypes.suspiciousCron.count > 0) {
        recommendations.push({
            title: 'Suspicious Cron Jobs',
            severity: issueTypes.suspiciousCron.severity.toLowerCase(),
            description: `Found ${issueTypes.suspiciousCron.count} suspicious cron job(s). Suspicious cron jobs may indicate unauthorized activities or malware.`,
            solution: 'Review all cron jobs and remove any unauthorized or suspicious entries.'
        });
    }
    
    if (issueTypes.suspiciousProcesses && issueTypes.suspiciousProcesses.count > 0) {
        recommendations.push({
            title: 'Suspicious Processes',
            severity: issueTypes.suspiciousProcesses.severity.toLowerCase(),
            description: `Found ${issueTypes.suspiciousProcesses.count} suspicious process(es) running on the system. Suspicious processes may indicate unauthorized activities or malware.`,
            solution: 'Investigate these processes and terminate any unauthorized ones using the kill command.'
        });
    }
    
    if (issueTypes.sshRootLogin && issueTypes.sshRootLogin.count > 0) {
        recommendations.push({
            title: 'SSH Root Login Allowed',
            severity: issueTypes.sshRootLogin.severity.toLowerCase(),
            description: 'SSH is configured to allow direct root login, which is a security risk. Root login should be disabled to prevent brute force attacks against the root account.',
            solution: 'Edit /etc/ssh/sshd_config, set "PermitRootLogin no", and restart the SSH service.'
        });
    }
    
    if (issueTypes.failedLogins && issueTypes.failedLogins.count > 0) {
        recommendations.push({
            title: 'High Number of Failed Login Attempts',
            severity: issueTypes.failedLogins.severity.toLowerCase(),
            description: 'Detected a high number of failed login attempts, which may indicate a brute force attack.',
            solution: 'Consider implementing fail2ban or similar tools to block IP addresses with multiple failed login attempts.'
        });
    }
    
    if (issueTypes.rootkits && issueTypes.rootkits.count > 0) {
        recommendations.push({
            title: 'Possible Rootkit Detected',
            severity: issueTypes.rootkits.severity.toLowerCase(),
            description: 'Possible rootkit or malware detected on the system. This is a critical security issue that requires immediate attention.',
            solution: 'Isolate the system, perform a full security audit, and consider reinstalling the operating system from trusted media.'
        });
    }
    
    if (issueTypes.firewall && issueTypes.firewall.count > 0) {
        recommendations.push({
            title: 'Firewall Not Configured',
            severity: issueTypes.firewall.severity.toLowerCase(),
            description: 'The system firewall is not properly configured or is inactive. A firewall is essential for protecting the system from unauthorized access.',
            solution: 'Configure and enable the firewall using iptables, ufw, or firewalld depending on your distribution.'
        });
    }
    
    if (issueTypes.securityUpdates && issueTypes.securityUpdates.count > 0) {
        recommendations.push({
            title: 'Security Updates Available',
            severity: issueTypes.securityUpdates.severity.toLowerCase(),
            description: `${issueTypes.securityUpdates.count} security update(s) available. Keeping the system updated is crucial for security.`,
            solution: 'Install available security updates using your package manager (apt, dnf, etc.).'
        });
    }
    
    return recommendations;
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
                // Reload the page to show updated data
                window.location.reload();
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
            button.textContent = 'Run Security Scan';
        });
}
