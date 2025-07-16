#!/usr/bin/env zsh
# ==============================================================================
# Input Validation Functions for the Universal Code Runner
# ==============================================================================

# Load UI module (for logging functions)
source "${0:A:h}/_ui.zsh"

# ==============================================================================
# Input Validation Functions
# ==============================================================================

# Validate that a value is numeric and within a specified range
# Usage: validate_numeric <value> <min> <max> <param_name>
# Returns: 0 if valid, 1 if invalid
validate_numeric() {
  local value="$1"
  local min="$2"
  local max="$3"
  local param_name="$4"
  
  # Check if the value is a number
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    log_msg ERROR "${param_name} must be a positive integer"
    return 1
  fi
  
  # Check if the value is within the specified range
  if (( value < min )); then
    log_msg ERROR "${param_name} must be at least ${min}"
    return 1
  fi
  
  if (( value > max )); then
    log_msg ERROR "${param_name} must be at most ${max}"
    return 1
  fi
  
  return 0
}

# Validate that a file exists and is readable
# Usage: validate_file <file_path>
# Returns: 0 if valid, 1 if invalid
validate_file() {
  local file_path="$1"
  
  if [[ ! -f "$file_path" ]]; then
    log_msg ERROR "File not found: ${file_path}"
    return 1
  fi
  
  if [[ ! -r "$file_path" ]]; then
    log_msg ERROR "File is not readable: ${file_path}"
    return 1
  fi
  
  return 0
}

# Validate that a directory exists and is writable
# Usage: validate_directory <dir_path>
# Returns: 0 if valid, 1 if invalid
validate_directory() {
  local dir_path="$1"
  
  if [[ ! -d "$dir_path" ]]; then
    log_msg ERROR "Directory not found: ${dir_path}"
    return 1
  fi
  
  if [[ ! -w "$dir_path" ]]; then
    log_msg ERROR "Directory is not writable: ${dir_path}"
    return 1
  fi
  
  return 0
}

# Validate command line arguments
# Usage: validate_args <args_array>
# Returns: 0 if valid, 1 if invalid
validate_args() {
  local -a args=("$@")
  
  # Validate timeout value
  if [[ -n "$RUNNER_TIMEOUT" ]]; then
    validate_numeric "$RUNNER_TIMEOUT" 1 3600 "Timeout"
    if [[ $? -ne 0 ]]; then
      return 1
    fi
  fi
  
  # Validate memory limit
  if [[ -n "$RUNNER_MEMORY_LIMIT" && "$RUNNER_MEMORY_LIMIT" -ne 0 ]]; then
    validate_numeric "$RUNNER_MEMORY_LIMIT" 50 4096 "Memory limit"
    if [[ $? -ne 0 ]]; then
      return 1
    fi
  fi
  
  return 0
}

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
    log_msg WARN "timeout_not_found"
    "$cmd" "${args[@]}"
    return $?
  fi
  
  log_msg INFO "time_limit" "${C_YELLOW}${timeout}s${C_RESET}"
  # Use timeout command with kill-after option to ensure termination
  timeout --kill-after=2 --signal=TERM "$timeout" "$cmd" "${args[@]}"
  local exit_code=$?
  
  # Check if the command was terminated due to timeout
  if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
    log_msg ERROR "execution_timeout" "${C_YELLOW}${timeout}s${C_RESET}"
  fi
  
  return $exit_code
}

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