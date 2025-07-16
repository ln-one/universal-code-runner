#!/usr/bin/env zsh
# ==============================================================================
# Common configuration and functions for the Universal Code Runner scripts.
# ==============================================================================

# Get the directory of the current script
_THIS_SCRIPT_DIR=${0:A:h}

# Load dedicated modules
source "${_THIS_SCRIPT_DIR}/_config.zsh"   # Configuration and language definitions
source "${_THIS_SCRIPT_DIR}/_messages.zsh" # Message and internationalization functions
source "${_THIS_SCRIPT_DIR}/_ui.zsh"      # UI and logging functions
source "${_THIS_SCRIPT_DIR}/_cache.zsh"    # Cache functions
source "${_THIS_SCRIPT_DIR}/_sandbox.zsh"  # Sandbox functions

# ==============================================================================
# Input Validation Functions
# ==============================================================================

# Validate a numeric input
# Usage: validate_numeric <value> <param_name> <min> <max>
validate_numeric() {
  local value="$1"
  local param_name="$2"
  local min="$3"
  local max="$4"
  
  # Check if the value is a number
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    log_msg ERROR "${param_name} must be a positive number"
    return 1
  fi
  
  # Check if the value is within range
  if [[ -n "$min" && "$value" -lt "$min" ]]; then
    log_msg ERROR "${param_name} must be at least ${min}"
    return 1
  fi
  
  if [[ -n "$max" && "$value" -gt "$max" ]]; then
    log_msg ERROR "${param_name} must be at most ${max}"
    return 1
  fi
  
  return 0
}

# Sanitize a filename to prevent path traversal attacks
# Usage: sanitize_filename <filename>
sanitize_filename() {
  local filename="$1"
  
  # Remove any leading path components
  filename=$(basename "$filename")
  
  # Remove any special characters
  filename=${filename//[^a-zA-Z0-9._-]/}
  
  echo "$filename"
}

# Validate command line arguments to prevent injection attacks
# Usage: validate_args <args...>
validate_args() {
  local args=("$@")
  local sanitized_args=()
  
  for arg in "${args[@]}"; do
    # Check for potentially dangerous characters
    if echo "$arg" | grep -q '[;&|<>$()\\`]'; then
      log_msg WARN "Potentially unsafe argument detected: ${C_YELLOW}${arg}${C_RESET}"
      log_msg INFO "Arguments containing shell metacharacters will be quoted"
      # Quote the argument to prevent interpretation
      arg="'${arg//\'/\'\\\'\'}'"
    fi
    
    sanitized_args+=("$arg")
  done
  
  echo "${sanitized_args[@]}"
}

# Note: Global configuration is now in _config.zsh to avoid duplication

# ==============================================================================
# Resource Limiting Functions
# ==============================================================================

# Run a command with timeout
# Usage: run_with_timeout <timeout_seconds> <cmd> [args...]
run_with_timeout() {
  local timeout="$1"
  shift
  local cmd="$1"
  shift
  local args=("$@")
  
  # If timeout is 0 or not set, run without timeout
  if [[ -z "$timeout" || "$timeout" -eq 0 ]]; then
    "$cmd" "${args[@]}"
    return $?
  fi
  
  # Check if timeout command is available
  if ! command -v timeout &>/dev/null; then
    log_msg WARN "Timeout command not found. Running without timeout limit."
    "$cmd" "${args[@]}"
    return $?
  fi
  
  log_msg INFO "Running with ${C_YELLOW}${timeout}s${C_RESET} timeout limit"
  # Use timeout command with kill-after option to ensure termination
  timeout --kill-after=2 --signal=TERM "$timeout" "$cmd" "${args[@]}"
  local exit_code=$?
  
  # Check if the command was terminated due to timeout
  if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
    log_msg ERROR "Program execution timed out after ${C_YELLOW}${timeout}s${C_RESET}"
  fi
  
  return $exit_code
}

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

# Note: Color definitions are now in _ui.zsh to avoid duplication

# Note: UI functions (spinner, highlighting) are now in _ui.zsh to avoid duplication

# Note: log_msg function is defined in _ui.zsh to avoid duplication

# Wrapper for `check_dependencies` to use the new logger.
check_dependencies_new() {
  for dep in "$@"; do
    if ! command -v "$dep" &> /dev/null; then
      log_msg ERROR "required_command_not_found" "${C_YELLOW}${dep}${C_RESET}"
      log_msg INFO "please_install"
      exit 1
    fi
  done
}

# Note: Message support functions are now in _messages.zsh to avoid duplication

# ==============================================================================
# Original untouched logic
# ==============================================================================
# This section contains the original helper functions and variables
# to ensure the core logic of the scripts remains unchanged as requested.

# Note: Old color definitions removed - now using unified colors from _ui.zsh

# Note: Language configuration (LANG_CONFIG) is now in _config.zsh to avoid duplication

check_dependencies() {
  for dep in "$@"; do
    if ! command -v "$dep" &> /dev/null; then
      echo -e "${C_RED}❌ Error: Dependency not found: ${C_CYAN}${dep}${C_RESET}"
      echo -e "${C_YELLOW}Please install ${C_CYAN}${dep}${C_YELLOW} and try again.${C_RESET}"
      exit 1
    fi
  done
}

execute_and_show_output() {
  local cmd="$1"
  shift
  local args=("$@")
  local ext=""
  
  # Try to detect the language from the command or first argument for highlighting
  case "$cmd" in
    *python*|*py*)
      ext="py"
      ;;
    *node*)
      ext="js"
      ;;
    *perl*)
      ext="pl"
      ;;
    *ruby*)
      ext="rb"
      ;;
    *bash*|*sh*)
      ext="sh"
      ;;
    *php*)
      ext="php"
      ;;
    *java*)
      ext="java"
      ;;
    *)
      # Try to detect from file extension of the first argument
      if [[ -n "$1" && "$1" == *.* ]]; then
        ext="${1##*.}"
      fi
      ;;
  esac
  
  # Get program output header in the current language
  local program_output=$(get_msg "program_output")
  
  echo -e "${C_MAGENTA}┌────────────────────── ${C_WHITE}${program_output}${C_MAGENTA} ──────────────────────┐${C_RESET}"
  
  # Capture program output - use run_in_sandbox if sandbox mode is enabled
  local output
  local exit_code=0
  
  # Show timeout info if enabled
  if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
    log_msg INFO "time_limit" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
  fi
  
  # When running in sandbox mode, show a notification and run in sandbox
  if [[ "$RUNNER_SANDBOX" == "true" && "$(detect_sandbox_tech)" != "" ]]; then
    local sandbox_tech=$(detect_sandbox_tech)
    log_msg INFO "sandbox_mode" "${C_CYAN}${sandbox_tech}${C_RESET}"
    
    # Apply timeout if set
    if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
      # We need to capture output differently when using timeout
      output=$(run_with_timeout "$RUNNER_TIMEOUT" run_in_sandbox "$cmd" "${args[@]}" 2>&1)
    else
      output=$(run_in_sandbox "$cmd" "${args[@]}" 2>&1)
    fi
  else
    # Apply timeout if set
    if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
      # Direct call to timeout command for better control
      if command -v timeout &>/dev/null; then
        output=$(timeout --kill-after=2 "$RUNNER_TIMEOUT" "$cmd" "${args[@]}" 2>&1)
        exit_code=$?
        # Check if the command was terminated due to timeout
        if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
          log_msg ERROR "execution_timeout" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
        fi
      else
        log_msg WARN "timeout_not_found"
        output=$("$cmd" "${args[@]}" 2>&1)
      fi
    else
      output=$("$cmd" "${args[@]}" 2>&1)
    fi
  fi
  
  exit_code=$?
  
  # Apply syntax highlighting if possible
  if [[ -n "$ext" && "$(detect_highlighter)" != "" ]]; then
    highlight_code "$output" "$ext"
  else
    echo "$output"
  fi
  
  echo -e "${C_MAGENTA}└────────────────────────────────────────────────────────────┘${C_RESET}"
  if [[ $exit_code -eq 0 ]]; then
    local status_msg=$(get_msg "program_completed_full")
    echo -e "\n${C_BLUE}📊 ${C_GREEN}${status_msg}${C_RESET}"
  elif [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
    local status_msg=$(get_msg "program_timed_out_full")
    echo -e "\n${C_BLUE}📊 ${C_RED}${status_msg}${C_RESET}"
  else
    local status_msg=$(get_msg "program_exited_with_code_full" "$exit_code")
    echo -e "\n${C_BLUE}📊 ${C_YELLOW}${status_msg}${C_RESET}"
  fi
  return $exit_code
}

# Initialize cache system
init_cache 
