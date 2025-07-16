#!/usr/bin/env zsh
# ==============================================================================
# Sandbox Execution Functions for the Universal Code Runner
# ==============================================================================

# Get the current script directory
_THIS_SCRIPT_DIR=${0:A:h}

# ==============================================================================
# Sandbox Execution
# ==============================================================================

# Detect available sandbox technologies
detect_sandbox_tech() {
  if command -v firejail &>/dev/null; then
    echo "firejail"
  elif command -v nsjail &>/dev/null; then
    echo "nsjail"
  elif command -v bubblewrap &>/dev/null; then
    echo "bubblewrap"
  elif command -v systemd-run &>/dev/null; then
    echo "systemd-run"
  else
    echo ""
  fi
}

# Run a command in a sandbox if available
# Usage: run_in_sandbox <cmd> [args...]
run_in_sandbox() {
  local cmd="$1"
  shift
  local args=("$@")
  
  # Return early if sandbox mode is disabled 
  if [[ "$RUNNER_SANDBOX" != "true" ]]; then
    "$cmd" "${args[@]}"
    return $?
  fi
  
  local exit_code=0
  local absolute_pwd=$(pwd)
  
  # Set memory limit (default to 500MB if not specified)
  local memory_limit=${RUNNER_MEMORY_LIMIT:-500}
  if [[ "$memory_limit" -eq 0 ]]; then
    memory_limit=500
  fi
  
  # Use firejail as our primary sandbox technology
  if command -v firejail &>/dev/null; then
    # Note: This relies on the log_msg function from _ui.zsh
    # _common.zsh already sources _ui.zsh and _sandbox.zsh, so the function call order is correct
    log_msg INFO "Running in sandbox mode with ${C_CYAN}firejail${C_RESET}"
    if [[ "$RUNNER_MEMORY_LIMIT" -gt 0 ]]; then
      log_msg INFO "Memory limit: ${C_YELLOW}${memory_limit}MB${C_RESET}"
    fi
    
    # Basic firejail sandbox with network and capabilities restrictions
    firejail \
      --quiet \
      --net=none \
      --caps.drop=all \
      --seccomp \
      --noroot \
      --private-tmp \
      --rlimit-fsize=10000000 \
      --rlimit-nproc=50 \
      --rlimit-nofile=100 \
      --rlimit-as=$((memory_limit * 1024 * 1024)) \
      "$cmd" "${args[@]}"
    exit_code=$?
    
  # Fallback to systemd-run if firejail is not available
  elif command -v systemd-run &>/dev/null; then
    log_msg INFO "Running in sandbox mode with ${C_CYAN}systemd${C_RESET}"
    log_msg WARN "Limited sandbox protection. Install firejail for better security."
    if [[ "$RUNNER_MEMORY_LIMIT" -gt 0 ]]; then
      log_msg INFO "Memory limit: ${C_YELLOW}${memory_limit}MB${C_RESET}"
    fi
    
    # Get absolute paths for better safety
    local cmd_abs="$cmd"
    if [[ -f "$cmd" ]]; then
      cmd_abs=$(realpath "$cmd")
    fi
    
    systemd-run --pipe --collect --quiet \
      --property=NoNewPrivileges=yes \
      --property=PrivateDevices=yes \
      --property=PrivateNetwork=yes \
      --property=PrivateTmp=yes \
      --property=ProtectHome=yes \
      --property=ProtectSystem=strict \
      --property=WorkingDirectory="$absolute_pwd" \
      --property=ReadWritePaths="$absolute_pwd" \
      --property=MemoryMax="${memory_limit}M" \
      --property=CPUQuota=10% \
      "$cmd_abs" "${args[@]}"
    exit_code=$?
    
  else
    # Fallback if no sandbox technology is available
    log_msg WARN "No sandbox technology available, running without sandbox protection."
    log_msg INFO "Install firejail or systemd for sandbox support."
    "$cmd" "${args[@]}"
    exit_code=$?
  fi
  
  return $exit_code
}