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