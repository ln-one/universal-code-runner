#!/usr/bin/env zsh

# This script must be run from the project root.
# We source the common file to get access to the new logger.
source "./_common.zsh"

# ==============================================================================
# Installation and Uninstallation script for the Universal Code Runner utility.
#
# Usage:
#   sudo ./install.zsh                    # Install to default location
#   sudo ./install.zsh --uninstall        # Uninstall from default location
#   sudo ./install.zsh --help             # Show help information
#
# Custom installation paths:
#   sudo UCODE_INSTALL_DIR=/opt/ucode UCODE_BIN_DIR=/opt/bin ./install.zsh
#
# Environment Variables:
#   UCODE_INSTALL_DIR  - Application directory (default: /usr/local/lib/ucode)
#   UCODE_BIN_DIR      - Binary directory (default: /usr/local/bin)
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# Support custom installation paths via environment variables
APP_DIR="${UCODE_INSTALL_DIR:-/usr/local/lib/ucode}"
BIN_DIR="${UCODE_BIN_DIR:-/usr/local/bin}"
EXEC_NAME="ucode"

REQUIRED_FILES=("ucode" "_common.zsh" "_compile_and_run.zsh" "_config.zsh" "_messages.zsh" "_ui.zsh" "_cache.zsh" "_sandbox.zsh")


# --- Pre-flight Checks ---
# Allow help to be shown without root privileges
if [[ "$1" != "--help" && "$1" != "-h" && $EUID -ne 0 ]]; then
  log_msg ERROR "This script must be run with root privileges (e.g., 'sudo ./install.zsh')."
  log_msg INFO "Use './install.zsh --help' to see usage information."
  exit 1
fi

for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    log_msg ERROR "Source file '${C_CYAN}$file${C_RESET}' not found. Please run this script from the project's root directory."
    exit 1
  fi
done

# --- Logic Functions ---
do_install() {
  log_msg STEP "Starting Universal Code Runner installation..."

  log_msg INFO "Creating application directory: ${C_CYAN}$APP_DIR${C_RESET}"
  mkdir -p "$APP_DIR"

  log_msg INFO "Copying application files..."
  for file in "${REQUIRED_FILES[@]}"; do
    cp "$file" "$APP_DIR/"
  done

  log_msg INFO "Setting executable permissions for ${C_CYAN}$APP_DIR/ucode${C_RESET}"
  chmod +x "$APP_DIR/ucode"

  log_msg INFO "Creating symbolic link: ${C_CYAN}$BIN_DIR/$EXEC_NAME -> $APP_DIR/ucode${C_RESET}"
  ln -sf "$APP_DIR/ucode" "$BIN_DIR/$EXEC_NAME"

  log_msg SUCCESS "Installation complete! You can now run '${C_BOLD}$EXEC_NAME${C_RESET}' from anywhere."
}

do_uninstall() {
  log_msg STEP "Starting Universal Code Runner uninstallation..."

  if [[ -L "$BIN_DIR/$EXEC_NAME" ]]; then
    log_msg INFO "Removing symbolic link: ${C_CYAN}$BIN_DIR/$EXEC_NAME${C_RESET}"
    rm -f "$BIN_DIR/$EXEC_NAME"
  else
    log_msg WARN "Symbolic link not found, skipping."
  fi

  if [[ -d "$APP_DIR" ]]; then
    log_msg INFO "Removing application directory: ${C_CYAN}$APP_DIR${C_RESET}"
    rm -rf "$APP_DIR"
  else
    log_msg WARN "Application directory not found, skipping."
  fi

  log_msg SUCCESS "Uninstallation complete!"
}

# --- Help Function ---
show_help() {
  cat <<EOF
Universal Code Runner Installation Script

USAGE:
    sudo ./install.zsh [OPTIONS]

OPTIONS:
    --help          Show this help message
    --uninstall     Uninstall Universal Code Runner

CUSTOM INSTALLATION PATHS:
    Use environment variables to customize installation paths:
    
    sudo UCODE_INSTALL_DIR=/opt/ucode UCODE_BIN_DIR=/opt/bin ./install.zsh

ENVIRONMENT VARIABLES:
    UCODE_INSTALL_DIR   Application directory (default: /usr/local/lib/ucode)
    UCODE_BIN_DIR       Binary directory (default: /usr/local/bin)

EXAMPLES:
    # Install to default location
    sudo ./install.zsh
    
    # Install to custom location
    sudo UCODE_INSTALL_DIR=/opt/ucode ./install.zsh
    
    # Uninstall
    sudo ./install.zsh --uninstall

CURRENT CONFIGURATION:
    Application Directory: ${C_CYAN}$APP_DIR${C_RESET}
    Binary Directory:      ${C_CYAN}$BIN_DIR${C_RESET}
    Executable Name:       ${C_CYAN}$EXEC_NAME${C_RESET}
EOF
}

# --- Main Entry Point ---
# The verbose flag doesn't apply here, we always want to see the steps.
export RUNNER_VERBOSE=true

case "$1" in
  --help|-h)
    show_help
    exit 0
    ;;
  --uninstall)
    do_uninstall
    ;;
  "")
    do_install
    ;;
  *)
    log_msg ERROR "Unknown option: $1"
    log_msg INFO "Use --help for usage information"
    exit 1
    ;;
esac 