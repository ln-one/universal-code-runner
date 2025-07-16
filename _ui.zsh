#!/usr/bin/env zsh
# ==============================================================================
# UI and Logging Functions for the Universal Code Runner
# ==============================================================================

# Get the current script directory
_THIS_SCRIPT_DIR=${0:A:h}

# ==============================================================================
# Colors and Styling (tput for compatibility)
# ==============================================================================
# Using raw ANSI codes for better compatibility and more vibrant colors.
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'
    C_RED=$'\033[1;31m'
    C_GREEN=$'\033[1;32m'
    C_YELLOW=$'\033[1;33m'
    C_BLUE=$'\033[1;34m'
    C_MAGENTA=$'\033[1;35m'
    C_CYAN=$'\033[1;36m'
    C_WHITE=$'\033[1;97m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_MAGENTA="" C_CYAN="" C_WHITE="" C_BOLD="" C_DIM=""
fi

# ==============================================================================
# Standardized UI / Logging Functions
# ==============================================================================

# Spinner animation for long-running operations
# Usage: start_spinner <file_name>
start_spinner() {
  local file_name="$1"
  # Note: This relies on the get_msg function from _common.zsh
  # The get_msg function is already sourced in _ui.zsh, so it's available when start_spinner is called.
  local msg=$(get_msg "compiling_file" "$file_name")
  
  # Set the spin characters according to terminal support
  local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
  if [[ "$RUNNER_ASCII_MODE" == "true" ]]; then
    chars="|/-\\"
  fi

  # Store spinner PID so we can kill it later
  # Use subshell to avoid messing with the current shell settings
  (
    # Hide cursor
    printf "\033[?25l"
    
    # Setup cleanup trap
    trap 'printf "\033[?25h"; exit 0' INT TERM EXIT
    
    local i=0
    local len=${#chars}
    while true; do
      local char="${chars:$i:1}"
      # Print spinner character and message
      printf "${C_BLUE}%s${C_RESET} %s\r" "$char" "$msg"
      sleep 0.1
      # Move to next character
      i=$(( (i + 1) % len ))
    done
  ) &
  SPINNER_PID=$!
}

# Stop the spinner
stop_spinner() {
  # Kill spinner process
  if [[ -n "$SPINNER_PID" ]]; then
    kill "$SPINNER_PID" &>/dev/null
    wait "$SPINNER_PID" &>/dev/null || true
    unset SPINNER_PID
    # Show cursor again
    printf "\033[?25h"
    # Clear the line
    printf "\r\033[K"
  fi
}

# Detect available syntax highlighting tools
detect_highlighter() {
  if command -v pygmentize &>/dev/null; then
    echo "pygmentize"
  elif command -v highlight &>/dev/null; then
    echo "highlight"
  elif command -v bat &>/dev/null; then
    echo "bat"
  else
    echo ""
  fi
}

# Apply syntax highlighting to code snippets if available tools exist
# Usage: highlight_code <file_content> <extension>
highlight_code() {
  local content="$1"
  local extension="$2"
  local highlighter=$(detect_highlighter)
  
  # Skip if no highlighter available or not a terminal
  if [[ -z "$highlighter" || ! -t 1 ]]; then
    echo "$content"
    return
  fi
  
  case "$highlighter" in
    pygmentize)
      # Use a temporary file for pygmentize to properly detect syntax
      local tmp_file=$(mktemp)
      echo "$content" > "$tmp_file"
      pygmentize -f terminal -l "$extension" "$tmp_file" || cat "$tmp_file"
      rm "$tmp_file"
      ;;
    highlight)
      echo "$content" | highlight --syntax="$extension" --out-format=ansi || echo "$content"
      ;;
    bat)
      echo "$content" | bat --color=always --language="$extension" --plain || echo "$content"
      ;;
    *)
      echo "$content"
      ;;
  esac
}

# A standardized logging function.
# Usage: log_msg <TYPE> <message_key> [arg1] [arg2] ...
# TYPE can be: STEP, INFO, SUCCESS, WARN, ERROR, DEBUG
log_msg() {
    local type="$1"
    local msg_key="$2"
    shift 2
    local color_prefix=""
    local msg_style=""
    local icon=""

    # Select icon based on mode
    if [[ "$RUNNER_ASCII_MODE" == "true" ]]; then
        case "$type" in
            STEP)    icon="==>"   ;;
            INFO)    icon="->"    ;;
            SUCCESS) icon="[+]"   ;;
            WARN)    icon="[!]"   ;;
            ERROR)   icon="[x]"   ;;
            DEBUG)   icon="[d]"   ;;
        esac
    else
        case "$type" in
            STEP)    icon="🚀" ;;
            INFO)    icon="ℹ️" ;;
            SUCCESS) icon="✨" ;;
            WARN)    icon="⚠️" ;;
            ERROR)   icon="❌" ;;
            DEBUG)   icon="🐞" ;;
        esac
    fi

    case "$type" in
        STEP)
            color_prefix="${C_BLUE}${icon}${C_RESET}"
            msg_style="${C_BOLD}"
            ;;
        INFO)
            color_prefix="${C_CYAN}${icon}${C_RESET}"
            msg_style="${C_DIM}"
            # Only print INFO messages in verbose mode.
            if [[ "$RUNNER_VERBOSE" != "true" ]]; then return 0; fi
            ;;
        SUCCESS)
            color_prefix="${C_GREEN}${icon}${C_RESET}"
            msg_style="${C_BOLD}${C_GREEN}"
            ;;
        WARN)
            color_prefix="${C_YELLOW}${icon}${C_RESET}"
            msg_style="${C_BOLD}${C_YELLOW}"
            ;;
        ERROR)
            color_prefix="${C_RED}${icon}${C_RESET}"
            msg_style="${C_BOLD}${C_RED}"
            ;;
        DEBUG)
            # Only print if RUNNER_DEBUG is set to "true"
            if [[ "$RUNNER_DEBUG" != "true" ]]; then return 0; fi
            color_prefix="${C_MAGENTA}${icon}${C_RESET}"
            msg_style="${C_DIM}"
            ;;
        *)
            color_prefix=""
            msg_style=""
            ;;
    esac

    # Get the message in the current language
    # Note: This relies on the get_msg function from _common.zsh
    local msg=$(get_msg "$msg_key" "$@")

    # If a message style is defined, we must ensure it persists even if the
    # message string contains its own C_RESET codes. We do this by replacing
    # every C_RESET in the msg with "C_RESET followed by the base message style".
    if [[ -n "$msg_style" ]]; then
      # Zsh parameter expansion for global substitution: ${name//pattern/repl}
      msg=${msg//"$C_RESET"/"$C_RESET$msg_style"}
    fi

    # Print the message with appropriate styling
    echo -e "${color_prefix} ${msg_style}${msg}${C_RESET}"
}

# Simplified debug logging function for common patterns
# Usage: debug_log <message_key> <highlighted_value>
debug_log() {
  local msg_key="$1"
  local value="$2"
  
  # Only proceed if debug mode is enabled
  if [[ "$RUNNER_DEBUG" != "true" ]]; then
    return 0
  fi
  
  # Use the standard log_msg function with cyan highlighting
  log_msg DEBUG "$msg_key" "${C_CYAN}${value}${C_RESET}"
}
