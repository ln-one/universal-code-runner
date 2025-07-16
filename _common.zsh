#!/usr/bin/env zsh
# ==============================================================================
# Common Functions for the Universal Code Runner
# ==============================================================================

# Get the script directory
SCRIPT_DIR=${0:A:h}

# Load all modules
source "${SCRIPT_DIR}/_ui.zsh"
source "${SCRIPT_DIR}/_i18n.zsh"
source "${SCRIPT_DIR}/_validate.zsh"
source "${SCRIPT_DIR}/_config.zsh"
source "${SCRIPT_DIR}/_cache.zsh"
source "${SCRIPT_DIR}/_sandbox.zsh"

# ==============================================================================
# Core Execution Function
# ==============================================================================

# Execute a command and display its output
# Usage: execute_and_show_output <cmd> [args...]
execute_and_show_output() {
  local cmd="$1"
  shift
  local args=("$@")
  local exit_code=0
  local output=""
  local start_time=$(date +%s.%N)
  
  # Start the spinner if in verbose mode
  if [[ "$RUNNER_VERBOSE" == "true" ]]; then
    start_spinner "$(get_msg info_running) ${C_CYAN}${cmd}${C_RESET}"
  fi
  
  # Run the command with timeout if specified
  if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
    # Check if timeout command is available
    if command -v timeout &>/dev/null; then
      # Use timeout command to limit execution time
      output=$(timeout --kill-after=2 "$RUNNER_TIMEOUT" "$cmd" "${args[@]}" 2>&1)
      exit_code=$?
      
      # Check if the command timed out (exit code 124)
      if [[ $exit_code -eq 124 ]]; then
        log_msg WARN "$(get_msg error_timeout) ${RUNNER_TIMEOUT}s"
      fi
    else
      # Fallback if timeout command is not available
      log_msg WARN "timeout command not found, running without timeout limit"
      output=$("$cmd" "${args[@]}" 2>&1)
      exit_code=$?
    fi
  else
    # Run without timeout
    output=$("$cmd" "${args[@]}" 2>&1)
    exit_code=$?
  fi
  
  # Stop the spinner if it was started
  if [[ "$RUNNER_VERBOSE" == "true" ]]; then
    stop_spinner
  fi
  
  # Calculate execution time
  local end_time=$(date +%s.%N)
  local execution_time=$(printf "%.2f" $(echo "$end_time - $start_time" | bc))
  
  # Get terminal width
  local term_width=$(tput cols)
  local line=$(printf '%*s' "$term_width" | tr ' ' '─')
  
  # Display the output in a box
  echo -e "${C_BLUE}┌${line} PROGRAM OUTPUT ${line}┐${C_RESET}"
  echo -e "$output"
  echo -e "${C_BLUE}└${line}${line}${line}┘${C_RESET}"
  echo
  
  # Display the status message
  if [[ $exit_code -eq 0 ]]; then
    log_msg SUCCESS "$(get_msg success_execution) (${execution_time}s)"
  elif [[ $exit_code -eq 124 ]]; then
    log_msg ERROR "$(get_msg error_timeout) ${RUNNER_TIMEOUT}s"
  else
    log_msg ERROR "$(get_msg error_execution_failed) (${C_RED}${exit_code}${C_RESET})"
  fi
  
  return $exit_code
}

# ==============================================================================
# Core Utility Functions
# ==============================================================================

# Find the most recently modified file with a given extension pattern
# Usage: find_latest_file <extension_pattern> [directory]
find_latest_file() {
  local ext_pattern="$1"
  local directory="${2:-.}"
  
  # Find the most recently modified file matching the pattern
  find "$directory" -type f -name "$ext_pattern" -not -path "*/\.*" -printf "%T@ %p\n" 2>/dev/null | \
    sort -rn | head -n 1 | cut -d' ' -f2-
}

# Find the most recently modified code file
# Usage: find_latest_code_file [directory]
find_latest_code_file() {
  local directory="${1:-.}"
  local supported_extensions="*.{c,cpp,java,py,js,rb,php,pl,sh,rs,lua,go,ts}"
  
  # Find the most recently modified file with a supported extension
  find_latest_file "$supported_extensions" "$directory"
}

# Initialize the runner environment
init_runner() {
  # Set default values for configuration variables
  RUNNER_VERBOSE=${RUNNER_VERBOSE:-false}
  RUNNER_TIMEOUT=${RUNNER_TIMEOUT:-10}
  RUNNER_MEMORY_LIMIT=${RUNNER_MEMORY_LIMIT:-500}
  RUNNER_SANDBOX=${RUNNER_SANDBOX:-false}
  RUNNER_DISABLE_CACHE=${RUNNER_DISABLE_CACHE:-false}
  RUNNER_LANG=${RUNNER_LANG:-en}
  RUNNER_ASCII_MODE=${RUNNER_ASCII_MODE:-false}
  
  # Validate configuration
  validate_args
}

# Initialize the runner environment
init_runner 