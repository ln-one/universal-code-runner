#!/usr/bin/env zsh

_THIS_SCRIPT_DIR=${0:A:h}
source "${_THIS_SCRIPT_DIR}/_common.zsh"

SRC_FILE=$1
shift
PROG_ARGS=("$@")

SRC_FILENAME=$(basename "$SRC_FILE")
SRC_EXT="${SRC_FILENAME##*.}"
TYPE=${LANG_TYPE[$SRC_EXT]}
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$TEMP_DIR" || exit 1

# Helper function to run a command with timeout if enabled
run_with_timeout_if_enabled() {
    local cmd="$1"
    shift
    local args=("$@")
    
    # Check if timeout is enabled and available
    if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]] && command -v timeout &>/dev/null; then
        log_msg INFO "time_limit" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
        timeout --kill-after=2 "$RUNNER_TIMEOUT" "$cmd" "${args[@]}"
        local exit_code=$?
        if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
            log_msg ERROR "execution_timeout" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
        fi
        return $exit_code
    else
        "$cmd" "${args[@]}"
        return $?
    fi
}


# --- Direct Execution ---
if [[ "$TYPE" == "direct" ]]; then
    RUNNER=${LANG_RUNNER[$SRC_EXT]}
    check_dependencies_new "$RUNNER"
    log_msg INFO "running_with" "${C_CYAN}${RUNNER}${C_RESET}"
    
    # Direct execution with timeout if enabled
    if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]] && command -v timeout &>/dev/null; then
        log_msg INFO "time_limit" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
        
        # Get program output header in the current language
        local program_output=$(get_msg "program_output")
        
        echo -e "${MAGENTA_OLD}┌────────────────────── ${WHITE_OLD}${program_output}${MAGENTA_OLD} ──────────────────────┐${RESET_OLD}"
        
        # Run with timeout
        timeout --kill-after=2 "$RUNNER_TIMEOUT" "$RUNNER" "$SRC_FILE" "${PROG_ARGS[@]}"
        local exit_code=$?
        
        echo -e "${MAGENTA_OLD}└────────────────────────────────────────────────────────────┘${RESET_OLD}"
        
        # Check if timeout occurred
        if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
            log_msg ERROR "execution_timeout" "${C_YELLOW}${RUNNER_TIMEOUT}s${C_RESET}"
            local status_msg=$(get_msg "program_timed_out_full")
            echo -e "\n${BLUE_OLD}📊 ${RED_OLD}${status_msg}${RESET_OLD}"
        elif [[ $exit_code -eq 0 ]]; then
            local status_msg=$(get_msg "program_completed_full")
            echo -e "\n${BLUE_OLD}📊 ${GREEN_OLD}${status_msg}${RESET_OLD}"
        else
            local status_msg=$(get_msg "program_exited_with_code_full" "$exit_code")
            echo -e "\n${BLUE_OLD}📊 ${YELLOW_OLD}${status_msg}${RESET_OLD}"
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
    COMPILER=${LANG_COMPILER[$SRC_EXT]:-javac}
    RUNNER=${LANG_RUNNER[$SRC_EXT]:-java}
    check_dependencies_new "$COMPILER" "$RUNNER"
    check_dependencies_new "zip" "unzip"  # 确保有zip和unzip命令
    
    # For JVM languages, we need to handle caching differently
    # since the output is a .class file, not a binary
    local src_dir=$(dirname "$SRC_FILE")
    local class_file="${src_dir}/${OUT_NAME}.class"
    local cached_class=""
    
    # Check if we have a cached class file
    if [[ "$RUNNER_DISABLE_CACHE" != "true" ]]; then
        log_msg DEBUG "checking_cache" "${C_CYAN}${SRC_FILENAME}${C_RESET}"
        
        # Generate hash for the source file
        local cache_dir=$(get_cache_dir)
        local src_hash=$(get_source_hash "$SRC_FILE" "$COMPILER")
        local cached_zip="${cache_dir}/${src_hash}.zip"  # 添加.zip扩展名
        
        # Check if cached zip exists
        if [[ -f "$cached_zip" ]]; then
            log_msg DEBUG "found_cache" "${C_CYAN}${cached_zip}${C_RESET}"
            
            # Extract the cached class files directly to the source directory
            log_msg DEBUG "extracting_cache" "${C_CYAN}${src_dir}${C_RESET}"
            # 使用-j选项来忽略目录结构，直接解压到目标目录
            unzip -q -o -j "$cached_zip" "*.class" -d "$src_dir"
            
            log_msg SUCCESS "using_cached_compilation"
            log_msg INFO "executing"
            
            # For Java, the runner must be executed from the directory containing the class files
            if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
                (cd "$src_dir" && execute_and_show_output timeout "--kill-after=2" "$RUNNER_TIMEOUT" "$RUNNER" "$OUT_NAME" "${PROG_ARGS[@]}")
            else
                (cd "$src_dir" && execute_and_show_output "$RUNNER" "$OUT_NAME" "${PROG_ARGS[@]}")
            fi
            exit $?
        else
            log_msg DEBUG "no_valid_cache" "${C_CYAN}${SRC_FILENAME}${C_RESET}"
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
            log_msg DEBUG "caching_files" "${C_CYAN}${SRC_FILENAME}${C_RESET}"
            # For Java, we need to zip all the class files and cache the zip
            local cache_dir=$(get_cache_dir)
            local src_hash=$(get_source_hash "$SRC_FILE" "$COMPILER")
            local cached_zip="${cache_dir}/${src_hash}.zip"
            
            # Check if there are any class files to cache
            if ls "$src_dir"/*.class &>/dev/null; then
                log_msg DEBUG "found_files_to_cache" "${C_CYAN}${src_dir}${C_RESET}"
                # 保存当前目录
                local current_dir=$(pwd)
                # 切换到源代码目录
                cd "$src_dir" || exit 1
                # 使用相对路径创建zip文件，只包含类文件名而不包含完整路径
                zip -q "${cached_zip}" *.class
                # 返回原始目录
                cd "$current_dir" || exit 1
                
                # Check if zip was created successfully
                if [[ -f "${cached_zip}" ]]; then
                    # Make sure the zip file is readable
                    chmod 644 "${cached_zip}"
                    log_msg DEBUG "saved_to_cache" "${C_CYAN}${cached_zip}${C_RESET}"
                else
                    log_msg DEBUG "failed_to_cache" "${C_CYAN}${cached_zip}${C_RESET}"
                fi
            else
                log_msg DEBUG "no_files_to_cache" "${C_CYAN}${SRC_FILENAME}${C_RESET}"
            fi
        fi
        
        log_msg INFO "executing"
        # For Java, the runner must be executed from the directory containing the class files.
        if [[ -n "$RUNNER_TIMEOUT" && "$RUNNER_TIMEOUT" -gt 0 ]]; then
            (cd "$(dirname "$SRC_FILE")" && execute_and_show_output timeout "--kill-after=2" "$RUNNER_TIMEOUT" "$RUNNER" "$OUT_NAME" "${PROG_ARGS[@]}")
        else
            (cd "$(dirname "$SRC_FILE")" && execute_and_show_output "$RUNNER" "$OUT_NAME" "${PROG_ARGS[@]}")
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
    COMPILER=${LANG_COMPILER[$SRC_EXT]}
    check_dependencies_new "$COMPILER"
    
    FLAGS_VAR_NAME=${LANG_FLAGS_VAR[$SRC_EXT]}
    DEFAULT_FLAGS=${LANG_DEFAULT_FLAGS[$SRC_EXT]}
    
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

log_msg ERROR "unknown_language" "$TYPE" "$SRC_EXT"
exit 1 