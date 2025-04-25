#!/bin/bash
#
# install.sh - Installation script for the System Monitoring and Management Tool
#
# Author: Your Name
# Date: $(date +%Y-%m-%d)
# Description: This script installs the system monitoring tool

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is run as root
if [ "$(id -u)" -eq 0 ]; then
    print_warning "You are running this script as root. This is not necessary and not recommended."
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Installation aborted."
        exit 1
    fi
fi

# Welcome message
echo "============================================="
echo "  System Monitoring Tool Installation Script"
echo "============================================="
echo

# Check for required commands
print_message "Checking for required commands..."

MISSING_COMMANDS=()

# Check for basic commands
for cmd in bash ps top df du find grep awk sort head tail; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_COMMANDS+=($cmd)
    fi
done

# Check for optional commands
OPTIONAL_MISSING=()
for cmd in fdupes iftop nethogs tcpdump; do
    if ! command -v $cmd &> /dev/null; then
        OPTIONAL_MISSING+=($cmd)
    fi
done

# Report missing commands
if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
    print_error "The following required commands are missing:"
    for cmd in "${MISSING_COMMANDS[@]}"; do
        echo "  - $cmd"
    done
    print_error "Please install these commands before continuing."
    exit 1
fi

if [ ${#OPTIONAL_MISSING[@]} -gt 0 ]; then
    print_warning "The following optional commands are missing:"
    for cmd in "${OPTIONAL_MISSING[@]}"; do
        echo "  - $cmd"
    done
    print_warning "The tool will work without these, but some features may be limited."
    print_warning "Consider installing these packages for full functionality."
fi

# Create installation directory
print_message "Setting up installation directory..."

# Default installation directory
DEFAULT_INSTALL_DIR="$HOME/system-monitor"
read -p "Enter installation directory [$DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

# Create directory if it doesn't exist
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory $INSTALL_DIR already exists."
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Installation aborted."
        exit 1
    fi
    rm -rf "$INSTALL_DIR"
fi

# Create directory structure
print_message "Creating directory structure..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/scripts"
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/logs"

# Copy files
print_message "Copying files..."
cp system-monitor/system_monitor.sh "$INSTALL_DIR/"
cp system-monitor/README.md "$INSTALL_DIR/"
cp system-monitor/scripts/*.sh "$INSTALL_DIR/scripts/"

# Make scripts executable
print_message "Making scripts executable..."
chmod +x "$INSTALL_DIR/system_monitor.sh"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Create symbolic link in /usr/local/bin if possible
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    print_message "Creating symbolic link in /usr/local/bin..."
    ln -sf "$INSTALL_DIR/system_monitor.sh" /usr/local/bin/system-monitor
    print_message "You can now run the tool by typing 'system-monitor' from anywhere."
else
    print_warning "Cannot create symbolic link in /usr/local/bin (permission denied)."
    print_message "To use the tool, run $INSTALL_DIR/system_monitor.sh"
    
    # Add to user's PATH in .bashrc if they want
    read -p "Do you want to add the tool to your PATH in .bashrc? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "# System Monitor Tool" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
        print_message "Added to PATH in .bashrc. Please restart your terminal or run 'source ~/.bashrc'."
    fi
fi

# Installation complete
echo
echo "============================================="
echo "  Installation Complete!"
echo "============================================="
echo
print_message "The System Monitoring Tool has been installed to $INSTALL_DIR"
print_message "To get started, run: $INSTALL_DIR/system_monitor.sh help"
echo

# Offer to run the tool now
read -p "Do you want to run the tool now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$INSTALL_DIR/system_monitor.sh" help
fi
