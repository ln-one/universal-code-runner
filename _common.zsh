#!/usr/bin/env zsh
# ==============================================================================
# Common configuration and functions for the Universal Code Runner scripts.
# ==============================================================================

# 获取脚本所在目录
_COMMON_DIR=${0:A:h}

# 加载所有模块
[[ -f "${_COMMON_DIR}/_config.zsh" ]] && source "${_COMMON_DIR}/_config.zsh"
[[ -f "${_COMMON_DIR}/_ui.zsh" ]] && source "${_COMMON_DIR}/_ui.zsh"
[[ -f "${_COMMON_DIR}/_i18n.zsh" ]] && source "${_COMMON_DIR}/_i18n.zsh"
[[ -f "${_COMMON_DIR}/_validate.zsh" ]] && source "${_COMMON_DIR}/_validate.zsh"
[[ -f "${_COMMON_DIR}/_sandbox.zsh" ]] && source "${_COMMON_DIR}/_sandbox.zsh"
[[ -f "${_COMMON_DIR}/_cache.zsh" ]] && source "${_COMMON_DIR}/_cache.zsh"

# ==============================================================================
# Execute and Show Output
# ==============================================================================

# Execute a command and show its output with formatting
# Usage: execute_and_show_output <cmd> [args...]
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
  
  echo -e "${MAGENTA_OLD}┌────────────────────── ${WHITE_OLD}${program_output}${MAGENTA_OLD} ──────────────────────┐${RESET_OLD}"
  
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
  
  echo -e "${MAGENTA_OLD}└────────────────────────────────────────────────────────────┘${RESET_OLD}"
  if [[ $exit_code -eq 0 ]]; then
    local status_msg=$(get_msg "program_completed_full")
    echo -e "\n${BLUE_OLD}📊 ${GREEN_OLD}${status_msg}${RESET_OLD}"
  elif [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
    local status_msg=$(get_msg "program_timed_out_full")
    echo -e "\n${BLUE_OLD}📊 ${RED_OLD}${status_msg}${RESET_OLD}"
  else
    local status_msg=$(get_msg "program_exited_with_code_full" "$exit_code")
    echo -e "\n${BLUE_OLD}📊 ${YELLOW_OLD}${status_msg}${RESET_OLD}"
  fi
  return $exit_code
} 