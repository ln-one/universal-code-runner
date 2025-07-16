#!/usr/bin/env zsh
# ==============================================================================
# Input Validation Functions for the Universal Code Runner
# ==============================================================================

# 加载UI模块（用于日志功能）
[[ -f "${0:A:h}/_ui.zsh" ]] && source "${0:A:h}/_ui.zsh"

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
      log_msg WARN "unsafe_arg" "${C_YELLOW}${arg}${C_RESET}"
      log_msg INFO "args_quoted"
      # Quote the argument to prevent interpretation
      arg="'${arg//\'/\'\\\'\'}'"
    fi
    
    sanitized_args+=("$arg")
  done
  
  echo "${sanitized_args[@]}"
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