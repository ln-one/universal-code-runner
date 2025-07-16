#!/usr/bin/env zsh

_THIS_SCRIPT_DIR=${0:A:h}
source "${_THIS_SCRIPT_DIR}/_common.zsh"

SRC_FILE=$1
shift

# Check if the second argument is a language extension (passed from ucode shebang detection)
if [[ -n "$1" && -z "${1##*([a-z])}" && ${#1} -le 3 ]]; then
    SRC_EXT=$1
    shift
else
    SRC_EXT="${SRC_FILE##*.}"
fi

PROG_ARGS=("$@")
SRC_FILENAME=$(basename "$SRC_FILE")

# --- Language Configuration Parsing ---
local config_string=${LANG_CONFIG[$SRC_EXT]}
if [[ -z "$config_string" ]]; then
  log_msg ERROR "unknown_language" "N/A" "$SRC_EXT"
  exit 1
fi

local -a config_parts
config_parts=("${(@s/:/)config_string}")

TYPE=${config_parts[1]}
COMPILER=${config_parts[2]}
FLAGS_VAR_NAME=${config_parts[3]}
DEFAULT_FLAGS=${config_parts[4]}
RUNNER=${config_parts[5]}

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
cd "$TEMP_DIR" || exit 1

# --- Direct Execution ---
if [[ "$TYPE" == "direct" ]]; then
    check_dependencies_new "$RUNNER"
    log_msg INFO "running_with" "${C_CYAN}${RUNNER}${C_RESET}"
    
    # Direct execution with timeout if enabled
    if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]] && command -v timeout &>/dev/null; then
        log_msg INFO "time_limit" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
        
        # Get program output header in the current language
        local program_output=$(get_msg "program_output")
        
        echo -e "${C_MAGENTA}┌────────────────────── ${C_WHITE}${program_output}${C_MAGENTA} ──────────────────────┐${C_RESET}"
        
        # Run with timeout
        timeout --kill-after=2 "$RUNNER_TIMEOUT" "$RUNNER" "$SRC_FILE" "${PROG_ARGS[@]}"
        local exit_code=$?
        
        echo -e "${C_MAGENTA}└────────────────────────────────────────────────────────────┘${C_RESET}"
        
        # Check if timeout occurred
        if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
            log_msg ERROR "execution_timeout" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
            local status_msg=$(get_msg "program_timed_out_full")
            echo -e "
${C_BLUE}📊 ${C_RED}${status_msg}${C_RESET}"
        elif [[ $exit_code -eq 0 ]]; then
            local status_msg=$(get_msg "program_completed_full")
            echo -e "
${C_BLUE}📊 ${C_GREEN}${status_msg}${C_RESET}"
        else
            local status_msg=$(get_msg "program_exited_with_code_full" "$exit_code")
            echo -e "
${C_BLUE}📊 ${C_YELLOW}${status_msg}${C_RESET}"
        fi
    else
        # Normal execution without timeout
        execute_and_show_output "$RUNNER" "$SRC_FILE" "${PROG_ARGS[@]}"
    fi
    
    exit $?
fi

OUT_NAME=$(basename "$SRC_FILENAME" ".$SRC_EXT")

# --- JVM Compilation ---
if [[ "$TYPE" == "compile_jvm" ]]; then
    local jvm_runner=$(get_jvm_runner "$SRC_EXT")
    local cache_pattern=$(get_jvm_cache_pattern "$SRC_EXT")
    check_dependencies_new "$COMPILER" "$jvm_runner"
    check_dependencies_new "zip" "unzip"  
    
    # For JVM languages, we need to handle caching differently
    # since the output is a .class file, not a binary
    local src_dir=$(dirname "$SRC_FILE")
    
    # Check if we have a cached class file
    if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
        debug_log "checking_cache" "${SRC_FILENAME}"
        
        # Generate hash for the source file
        local cache_dir=$(get_cache_dir)
        local src_hash=$(get_source_hash "$SRC_FILE" "$COMPILER")
        local cached_zip="${cache_dir}/${src_hash}.zip"  
        
        # Check if cached zip exists
        if [[ -f "$cached_zip" ]]; then
            debug_log "found_cache" "${cached_zip}"
            
            # Extract the cached class files directly to the source directory
            debug_log "extracting_cache" "${src_dir}"
            
            unzip -q -o -j "$cached_zip" "$cache_pattern" -d "$src_dir"
            
            log_msg SUCCESS "using_cached_compilation"
            log_msg INFO "executing"
            
            # For Java, the runner must be executed from the directory containing the class files
            if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
                (cd "$src_dir" && execute_and_show_output timeout "--kill-after=2" "$RUNNER_TIMEOUT" "$jvm_runner" "$OUT_NAME" "${PROG_ARGS[@]}")
            else
                (cd "$src_dir" && execute_and_show_output "$jvm_runner" "$OUT_NAME" "${PROG_ARGS[@]}")
            fi
            exit $?
        else
            debug_log "no_valid_cache" "${SRC_FILENAME}"
        fi
    fi
    
    # No cache hit, need to compile
    log_msg INFO "compiling" "${C_CYAN}${SRC_FILENAME}${C_RESET}"
    start_spinner "${SRC_FILENAME}"
    if compile_output=$("$COMPILER" "$SRC_FILE" 2>&1); then
        stop_spinner
        log_msg SUCCESS "compilation_successful"
        
        # Save the class files to cache if caching is enabled
        if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
            debug_log "caching_files" "${SRC_FILENAME}"
            # For Java, we need to zip all the class files and cache the zip
            local cache_dir=$(get_cache_dir)
            local src_hash=$(get_source_hash "$SRC_FILE" "$COMPILER")
            local cached_zip="${cache_dir}/${src_hash}.zip"
            
            # Check if there are any output files to cache
            if ls "$src_dir"/$cache_pattern &>/dev/null; then
                debug_log "found_files_to_cache" "${src_dir}"
                
                local current_dir=$(pwd)
                
                cd "$src_dir" || exit 1
                
                zip -q "${cached_zip}" $cache_pattern
                
                cd "$current_dir" || exit 1
                
                # Check if zip was created successfully
                if [[ -f "${cached_zip}" ]]; then
                    # Make sure the zip file is readable
                    chmod 644 "${cached_zip}"
                    debug_log "saved_to_cache" "${cached_zip}"
                else
                    debug_log "failed_to_cache" "${cached_zip}"
                fi
            else
                debug_log "no_files_to_cache" "${SRC_FILENAME}"
            fi
        fi
        
        log_msg INFO "executing"
        # For Java, the runner must be executed from the directory containing the class files.
        if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
            (cd "$(dirname "$SRC_FILE")" && execute_and_show_output timeout "--kill-after=2" "$RUNNER_TIMEOUT" "$jvm_runner" "$OUT_NAME" "${PROG_ARGS[@]}")
        else
            (cd "$(dirname "$SRC_FILE")" && execute_and_show_output "$jvm_runner" "$OUT_NAME" "${PROG_ARGS[@]}")
        fi
        exit $?
    else
        stop_spinner
        log_msg ERROR "compilation_failed" "${C_CYAN}${SRC_FILENAME}${C_RESET}"
        echo "$compile_output"
        exit 1
    fi
fi

# --- Standard Compilation ---
if [[ "$TYPE" == "compile" ]]; then
    check_dependencies_new "$COMPILER"
    
    # Use indirect parameter expansion to get the value of CFLAGS, CXXFLAGS, etc.
    FLAGS_VALUE=${(P)FLAGS_VAR_NAME:-$DEFAULT_FLAGS}
    
    # Use 'zsheval' to split the flags string into an array of arguments
    local -a flags_array
    flags_array=("${(z)FLAGS_VALUE}")
    
    # Check if we have a cached binary
    local cached_binary=""
    if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
        cached_binary=$(check_cache "$SRC_FILE" "$COMPILER" "${flags_array[@]}")
    fi
    
    # If we have a valid cached binary, use it
    if [[ -n "$cached_binary" && -x "$cached_binary" ]]; then
        log_msg SUCCESS "using_cached_binary"
        log_msg INFO "executing"
        if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
            execute_and_show_output timeout "--kill-after=2" "$RUNNER_TIMEOUT" "$cached_binary" "${PROG_ARGS[@]}"
        else
            execute_and_show_output "$cached_binary" "${PROG_ARGS[@]}"
        fi
        exit $?
    fi
    
    # No cache hit, need to compile
    log_msg INFO "compiling_with_flags_msg" "${C_CYAN}${SRC_FILENAME}${C_RESET}" "${C_YELLOW}${FLAGS_VALUE}${C_RESET}"
    start_spinner "${SRC_FILENAME}"
    if compile_output=$("$COMPILER" "${flags_array[@]}" "$SRC_FILE" -o "$OUT_NAME" 2>&1); then
        stop_spinner
        log_msg SUCCESS "compilation_successful"
        
        # Save the binary to cache if caching is enabled
        if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
            save_to_cache "$OUT_NAME" "$SRC_FILE" "$COMPILER" "${flags_array[@]}" >/dev/null
        fi
        
        log_msg INFO "executing"
        if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
            execute_and_show_output timeout "--kill-after=2" "$RUNNER_TIMEOUT" "./$OUT_NAME" "${PROG_ARGS[@]}"
        else
            execute_and_show_output "./$OUT_NAME" "${PROG_ARGS[@]}"
        fi
        exit $?
    else
        stop_spinner
        log_msg ERROR "compilation_failed" "${C_CYAN}${SRC_FILENAME}${C_RESET}"
        echo "$compile_output"
        exit 1
    fi
fi

# This should not be reached due to the check at the top, but serves as a final fallback.
log_msg ERROR "unsupported_file_type" "$SRC_EXT"
exit 1
