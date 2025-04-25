/**
 * backups.js - JavaScript for the backups page
 */

document.addEventListener('DOMContentLoaded', function() {
    // Load backup data
    loadBackupData();
    
    // Add event listeners for buttons
    document.getElementById('run-backup').addEventListener('click', runBackup);
    document.getElementById('restore-backup').addEventListener('click', restoreBackup);
});

/**
 * Load backup data from the API
 */
function loadBackupData() {
    fetch('/api/backups')
        .then(response => response.json())
        .then(data => {
            // Populate backup select dropdown
            populateBackupSelect(data);
        })
        .catch(error => {
            console.error('Error loading backup data:', error);
            alert('Error loading backup data: ' + error);
        });
}

/**
 * Populate the backup select dropdown
 */
function populateBackupSelect(data) {
    const backupSelect = document.getElementById('backup-id');
    
    // Clear existing options
    backupSelect.innerHTML = '<option value="">Select a backup</option>';
    
    // Get list of backups
    fetch('/api/run_command', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: 'ls -1 data/backups | grep -v latest'
        })
    })
    .then(response => response.json())
    .then(commandData => {
        if (commandData.success) {
            const backups = commandData.output.split('\n').filter(backup => backup.trim() !== '');
            
            if (backups.length === 0) {
                return;
            }
            
            // Sort backups by date (newest first)
            backups.sort().reverse();
            
            // Add options to select
            for (const backup of backups) {
                const option = document.createElement('option');
                option.value = backup;
                
                // Format the display text
                if (backup.length >= 15 && backup[8] === '_') {
                    const year = backup.substring(0, 4);
                    const month = backup.substring(4, 6);
                    const day = backup.substring(6, 8);
                    const hour = backup.substring(9, 11);
                    const minute = backup.substring(11, 13);
                    const second = backup.substring(13, 15);
                    
                    option.text = `${year}-${month}-${day} ${hour}:${minute}:${second} (${backup})`;
                } else {
                    option.text = backup;
                }
                
                backupSelect.appendChild(option);
            }
        }
    })
    .catch(error => {
        console.error('Error loading backup list:', error);
    });
}

/**
 * Run a backup
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
                // Reload the page to show updated data
                window.location.reload();
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
            button.textContent = 'Run Backup Now';
        });
}

/**
 * Restore a backup
 */
function restoreBackup() {
    const backupId = document.getElementById('backup-id').value;
    const restorePath = document.getElementById('restore-path').value;
    
    if (!backupId) {
        alert('Please select a backup to restore');
        return;
    }
    
    if (!restorePath) {
        alert('Please enter a restore path');
        return;
    }
    
    // Confirm restore
    if (!confirm(`Are you sure you want to restore backup ${backupId} to ${restorePath}?`)) {
        return;
    }
    
    const button = document.getElementById('restore-backup');
    button.disabled = true;
    button.textContent = 'Restoring...';
    
    // Execute restore command
    fetch('/api/run_command', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: `./backup/backup.sh restore ${backupId} ${restorePath}`
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('Backup restored successfully');
        } else {
            alert('Restore failed: ' + data.error);
        }
    })
    .catch(error => {
        console.error('Error restoring backup:', error);
        alert('Error restoring backup: ' + error);
    })
    .finally(() => {
        button.disabled = false;
        button.textContent = 'Restore Backup';
    });
}
