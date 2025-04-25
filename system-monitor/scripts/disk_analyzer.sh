#!/bin/bash
#
# disk_analyzer.sh - Analyzes disk usage and finds large files
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script analyzes disk usage and helps identify large files and directories

# Configuration
LOG_DIR="../logs"
DATA_DIR="../data"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DISK_LOG="$DATA_DIR/disk_analysis_$TIMESTAMP.log"

# Create directories if they don't exist
mkdir -p $LOG_DIR
mkdir -p $DATA_DIR

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_DIR/disk_analyzer.log"
    echo "$1"
}

# Function to check disk usage
check_disk_usage() {
    log_message "Checking disk usage..."
    
    echo "=== DISK USAGE ==="
    df -h
    
    return 0
}

# Function to check inode usage
check_inode_usage() {
    log_message "Checking inode usage..."
    
    echo "=== INODE USAGE ==="
    df -i
    
    return 0
}

# Function to find largest directories
find_largest_directories() {
    if [ -z "$1" ]; then
        path="/"
    else
        path="$1"
    fi
    
    limit="${2:-10}"  # Default to top 10 if not specified
    
    log_message "Finding $limit largest directories in $path..."
    
    echo "=== $limit LARGEST DIRECTORIES IN $path ==="
    du -h "$path" 2>/dev/null | sort -rh | head -n "$limit"
    
    return 0
}

# Function to find largest files
find_largest_files() {
    if [ -z "$1" ]; then
        path="/"
    else
        path="$1"
    fi
    
    limit="${2:-10}"  # Default to top 10 if not specified
    
    log_message "Finding $limit largest files in $path..."
    
    echo "=== $limit LARGEST FILES IN $path ==="
    find "$path" -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -n "$limit"
    
    return 0
}

# Function to find files larger than a specified size
find_files_larger_than() {
    if [ -z "$1" ]; then
        log_message "No size provided"
        echo "Usage: find_files_larger_than SIZE [PATH]"
        return 1
    fi
    
    size="$1"
    
    if [ -z "$2" ]; then
        path="/"
    else
        path="$2"
    fi
    
    log_message "Finding files larger than $size in $path..."
    
    echo "=== FILES LARGER THAN $size IN $path ==="
    find "$path" -type f -size +"$size" -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh
    
    return 0
}

# Function to find old files
find_old_files() {
    if [ -z "$1" ]; then
        days=30  # Default to 30 days if not specified
    else
        days="$1"
    fi
    
    if [ -z "$2" ]; then
        path="/"
    else
        path="$2"
    fi
    
    limit="${3:-20}"  # Default to top 20 if not specified
    
    log_message "Finding files older than $days days in $path..."
    
    echo "=== FILES OLDER THAN $days DAYS IN $path (TOP $limit) ==="
    find "$path" -type f -mtime +"$days" -exec ls -lth {} \; 2>/dev/null | head -n "$limit"
    
    return 0
}

# Function to find recently modified files
find_recent_files() {
    if [ -z "$1" ]; then
        days=1  # Default to 1 day if not specified
    else
        days="$1"
    fi
    
    if [ -z "$2" ]; then
        path="/"
    else
        path="$2"
    fi
    
    limit="${3:-20}"  # Default to top 20 if not specified
    
    log_message "Finding files modified in the last $days days in $path..."
    
    echo "=== FILES MODIFIED IN THE LAST $days DAYS IN $path (TOP $limit) ==="
    find "$path" -type f -mtime -"$days" -exec ls -lth {} \; 2>/dev/null | head -n "$limit"
    
    return 0
}

# Function to check for duplicate files
find_duplicate_files() {
    if [ -z "$1" ]; then
        path="."
    else
        path="$1"
    fi
    
    log_message "Finding duplicate files in $path..."
    
    echo "=== DUPLICATE FILES IN $path ==="
    if command -v fdupes &> /dev/null; then
        fdupes -r "$path"
    else
        echo "The fdupes command is not available. Please install it to find duplicate files."
        return 1
    fi
    
    return 0
}

# Function to analyze disk usage by file type
analyze_by_file_type() {
    if [ -z "$1" ]; then
        path="."
    else
        path="$1"
    fi
    
    log_message "Analyzing disk usage by file type in $path..."
    
    echo "=== DISK USAGE BY FILE TYPE IN $path ==="
    echo "This may take a while for large directories..."
    
    # Create a temporary file to store results
    temp_file=$(mktemp)
    
    # Find all files and extract extensions
    find "$path" -type f | while read -r file; do
        # Get file extension
        ext="${file##*.}"
        if [ "$ext" = "$file" ]; then
            ext="no_extension"
        fi
        
        # Get file size in bytes
        size=$(stat -c %s "$file" 2>/dev/null)
        
        # Write extension and size to temp file
        echo "$ext $size" >> "$temp_file"
    done
    
    # Sum up sizes by extension and sort
    echo "Extension | Size | Count"
    echo "---------|------|------"
    awk '{
        ext[$1] += $2;
        count[$1]++;
    }
    END {
        for (e in ext) {
            printf "%s | %.2f MB | %d\n", e, ext[e]/(1024*1024), count[e];
        }
    }' "$temp_file" | sort -k3 -rn
    
    # Remove temporary file
    rm "$temp_file"
    
    return 0
}

# Function to perform a full disk analysis
full_disk_analysis() {
    if [ -z "$1" ]; then
        path="/"
    else
        path="$1"
    fi
    
    log_message "Performing full disk analysis..."
    
    {
        echo "==================================="
        echo "DISK ANALYSIS REPORT"
        echo "Generated on: $(date)"
        echo "Path analyzed: $path"
        echo "==================================="
        echo
        
        check_disk_usage
        echo
        
        check_inode_usage
        echo
        
        find_largest_directories "$path" 15
        echo
        
        find_largest_files "$path" 15
        echo
        
        find_old_files 90 "$path" 15
        echo
        
        find_recent_files 1 "$path" 15
        echo
        
        echo "==================================="
        echo "END OF REPORT"
        echo "==================================="
    } | tee "$DISK_LOG"
    
    log_message "Disk analysis completed and saved to $DISK_LOG"
    
    return 0
}

# Main function to handle command line arguments
main() {
    case "$1" in
        usage)
            check_disk_usage
            ;;
        inodes)
            check_inode_usage
            ;;
        dirs)
            find_largest_directories "$2" "$3"
            ;;
        files)
            find_largest_files "$2" "$3"
            ;;
        larger-than)
            find_files_larger_than "$2" "$3"
            ;;
        old)
            find_old_files "$2" "$3" "$4"
            ;;
        recent)
            find_recent_files "$2" "$3" "$4"
            ;;
        duplicates)
            find_duplicate_files "$2"
            ;;
        by-type)
            analyze_by_file_type "$2"
            ;;
        full)
            full_disk_analysis "$2"
            ;;
        *)
            echo "Usage: $0 {usage|inodes|dirs|files|larger-than|old|recent|duplicates|by-type|full} [ARGS]"
            echo
            echo "Commands:"
            echo "  usage                    Show disk usage"
            echo "  inodes                   Show inode usage"
            echo "  dirs [PATH] [LIMIT]      Find largest directories (default: / and top 10)"
            echo "  files [PATH] [LIMIT]     Find largest files (default: / and top 10)"
            echo "  larger-than SIZE [PATH]  Find files larger than SIZE (e.g., 100M)"
            echo "  old [DAYS] [PATH] [LIMIT] Find files older than DAYS days (default: 30 days, / and top 20)"
            echo "  recent [DAYS] [PATH] [LIMIT] Find files modified in the last DAYS days (default: 1 day, / and top 20)"
            echo "  duplicates [PATH]        Find duplicate files (requires fdupes)"
            echo "  by-type [PATH]           Analyze disk usage by file type"
            echo "  full [PATH]              Perform full disk analysis (default: /)"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
