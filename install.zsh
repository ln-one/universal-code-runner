#!/usr/bin/env zsh

# This script must be run from the project root.
# We source the common file to get access to the new logger.
source "./_common.zsh"

# ==============================================================================
# Installation and Uninstallation script for the Universal Code Runner utility.
#
# Usage:
#   sudo ./install.zsh        # To install or update
#   sudo ./install.zsh --uninstall  # To uninstall
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
APP_DIR="/usr/local/lib/ucode"
BIN_DIR="/usr/local/bin"
EXEC_NAME="ucode"
REQUIRED_FILES=("ucode" "_common.zsh" "_compile_and_run.zsh")

# --- Pre-flight Checks ---
if [[ $EUID -ne 0 ]]; then
  log_msg ERROR "This script must be run with root privileges (e.g., 'sudo ./install.zsh')."
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

# --- Main Entry Point ---
# The verbose flag doesn't apply here, we always want to see the steps.
export RUNNER_VERBOSE=true
if [[ "$1" == "--uninstall" ]]; then
  do_uninstall
else
  do_install
fi 