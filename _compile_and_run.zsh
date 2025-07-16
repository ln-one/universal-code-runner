#!/usr/bin/env zsh
# ==============================================================================
# Compilation and Execution Functions for the Universal Code Runner
# ==============================================================================

# Get the script directory
SCRIPT_DIR=${0:A:h}

# Load required modules
source "${SCRIPT_DIR}/_ui.zsh"
source "${SCRIPT_DIR}/_cache.zsh"
source "${SCRIPT_DIR}/_i18n.zsh"

# ==============================================================================
# Core Compilation and Execution Functions
# ==============================================================================

# Main function to compile and run a source file
# Usage: compile_and_run <source_file> [<detected_ext>] [args...]
compile_and_run() {
  local SRC_FILE="$1"
  shift
  
  # Check if the second argument is a language extension (passed from shebang detection)
  if [[ -n "$1" && -z "${1##*([a-z])}" && ${#1} -le 3 ]]; then
    local SRC_EXT="$1"
    shift
  else
    local SRC_EXT="${SRC_FILE##*.}"
  fi
  
  local PROG_ARGS=("$@")
  local SRC_FILENAME=$(basename "$SRC_FILE")
  
  # Parse language configuration
  local config_string=${LANG_CONFIG[$SRC_EXT]}
  if [[ -z "$config_string" ]]; then
    log_msg ERROR "Unknown file extension: .${SRC_EXT}"
    exit 1
  fi
  
  local -a config_parts
  config_parts=("${(@s/:/)config_string}")
  
  local TYPE=${config_parts[1]}
  local COMPILER=${config_parts[2]}
  local FLAGS_VAR_NAME=${config_parts[3]}
  local DEFAULT_FLAGS=${config_parts[4]}
  local RUNNER=${config_parts[5]}
  
  local TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
  cd "$TEMP_DIR" || exit 1
  
  # Handle different execution types
  if [[ "$TYPE" == "direct" ]]; then
    # Direct execution (interpreted languages)
    check_dependencies_new "$RUNNER"
    log_msg INFO "Running with ${C_CYAN}${RUNNER}${C_RESET}"
    
    execute_and_show_output "$RUNNER" "$SRC_FILE" "${PROG_ARGS[@]}"
    return $?
    
  elif [[ "$TYPE" == "compile_jvm" ]]; then
    # JVM compilation (Java, Kotlin, etc.)
    local jvm_runner="java"
    check_dependencies_new "$COMPILER" "$jvm_runner" "zip" "unzip"
    
    local src_dir=$(dirname "$SRC_FILE")
    local OUT_NAME=$(basename "$SRC_FILENAME" ".$SRC_EXT")
    
    # Check for cached class files
    if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
      local cache_dir=$(get_cache_dir)
      local src_hash=$(get_source_hash "$SRC_FILE" "$COMPILER")
      local cached_zip="${cache_dir}/${src_hash}.zip"
      
      if [[ -f "$cached_zip" ]]; then
        log_msg INFO "Using cached compilation"
        unzip -q -o -j "$cached_zip" "*.class" -d "$src_dir"
        
        # Execute the program
        (cd "$src_dir" && execute_and_show_output "$jvm_runner" "$OUT_NAME" "${PROG_ARGS[@]}")
        return $?
      fi
    fi
    
    # No cache hit, need to compile
    log_msg INFO "Compiling ${C_CYAN}${SRC_FILENAME}${C_RESET}"
    start_spinner "Compiling..."
    
    if compile_output=$("$COMPILER" "$SRC_FILE" 2>&1); then
      stop_spinner
      log_msg SUCCESS "Compilation successful"
      
      # Cache the compiled class files
      if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
        local cache_dir=$(get_cache_dir)
        local src_hash=$(get_source_hash "$SRC_FILE" "$COMPILER")
        local cached_zip="${cache_dir}/${src_hash}.zip"
        
        if ls "$src_dir"/*.class &>/dev/null; then
          (cd "$src_dir" && zip -q "${cached_zip}" *.class)
          chmod 644 "${cached_zip}" 2>/dev/null
        fi
      fi
      
      # Execute the program
      (cd "$src_dir" && execute_and_show_output "$jvm_runner" "$OUT_NAME" "${PROG_ARGS[@]}")
      return $?
    else
      stop_spinner
      log_msg ERROR "Compilation failed for ${C_CYAN}${SRC_FILENAME}${C_RESET}"
      echo "$compile_output"
      return 1
    fi
    
  elif [[ "$TYPE" == "compile" ]]; then
    # Standard compilation (C, C++, etc.)
    check_dependencies_new "$COMPILER"
    
    local OUT_NAME=$(basename "$SRC_FILENAME" ".$SRC_EXT")
    
    # Get compiler flags
    local FLAGS_VALUE=${(P)FLAGS_VAR_NAME:-$DEFAULT_FLAGS}
    local -a flags_array
    flags_array=("${(z)FLAGS_VALUE}")
    
    # Check for cached binary
    local cached_binary=""
    if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
      cached_binary=$(check_cache "$SRC_FILE" "$COMPILER" "${flags_array[@]}")
    fi
    
    # Use cached binary if available
    if [[ -n "$cached_binary" && -x "$cached_binary" ]]; then
      log_msg INFO "Using cached binary from previous compilation"
      execute_and_show_output "$cached_binary" "${PROG_ARGS[@]}"
      return $?
    fi
    
    # No cache hit, need to compile
    log_msg INFO "Compiling ${C_CYAN}${SRC_FILENAME}${C_RESET} with flags: ${C_YELLOW}${FLAGS_VALUE}${C_RESET}"
    start_spinner "Compiling..."
    
    if compile_output=$("$COMPILER" "${flags_array[@]}" "$SRC_FILE" -o "$OUT_NAME" 2>&1); then
      stop_spinner
      log_msg SUCCESS "Compilation successful"
      
      # Save binary to cache
      if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
        save_to_cache "$OUT_NAME" "$SRC_FILE" "$COMPILER" "${flags_array[@]}" >/dev/null
      fi
      
      # Execute the program
      execute_and_show_output "./$OUT_NAME" "${PROG_ARGS[@]}"
      return $?
    else
      stop_spinner
      log_msg ERROR "Compilation failed for ${C_CYAN}${SRC_FILENAME}${C_RESET}"
      echo "$compile_output"
      return 1
    fi
  else
    log_msg ERROR "Unsupported file type: ${SRC_EXT}"
    return 1
  fi
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
    log_msg WARN "Timeout command not found, running without timeout limit"
    "$cmd" "${args[@]}"
    return $?
  fi
  
  log_msg INFO "Time limit: ${C_YELLOW}${timeout}s${C_RESET}"
  # Use timeout command with kill-after option to ensure termination
  timeout --kill-after=2 --signal=TERM "$timeout" "$cmd" "${args[@]}"
  local exit_code=$?
  
  # Check if the command was terminated due to timeout
  if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
    log_msg ERROR "Program execution timed out after ${C_YELLOW}${timeout}s${C_RESET}"
  fi
  
  return $exit_code
}

# Detect language from shebang line
# Usage: detect_lang_from_shebang <file_path>
# Returns: Language extension (e.g., "py", "sh") if found, otherwise empty string
detect_lang_from_shebang() {
  local file_path="$1"
  local shebang_line
  
  # Ensure the file exists and is readable
  if [[ -r "$file_path" ]]; then
    shebang_line=$(head -n 1 "$file_path")
    
    # Check if the line starts with #!
    if [[ "$shebang_line" == "#!"* ]]; then
      case "$shebang_line" in
        *python*)  echo "py"; return ;;
        *node*)    echo "js"; return ;;
        *bash*)    echo "sh"; return ;;
        *zsh*)     echo "sh"; return ;;
        *sh*)      echo "sh"; return ;;
        *perl*)    echo "pl"; return ;;
        *ruby*)    echo "rb"; return ;;
        *php*)     echo "php"; return ;;
        *)         echo ""; return ;;
      esac
    fi
  fi
  
  echo ""
  return 1
}

# Check for required dependencies
check_dependencies_new() {
  for dep in "$@"; do
    if ! command -v "$dep" &> /dev/null; then
      log_msg ERROR "Required command not found: ${C_YELLOW}${dep}${C_RESET}"
      log_msg INFO "Please install it and ensure it's in your PATH."
      exit 1
    fi
  done
}
