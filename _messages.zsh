#!/usr/bin/env zsh
# ==============================================================================
# Multi-language Message Support for Universal Code Runner
# ==============================================================================

# Define the language to use for messages
# This can be overridden by the --lang flag
export RUNNER_LANGUAGE="auto"  # auto, en, zh

# Message mapping table for internationalization
typeset -gA MSG_EN MSG_ZH

# English messages
MSG_EN=(
  "time_limit"                 "Time limit: %s"
  "execution_timeout"          "Program execution timed out and was terminated after %s"
  "running_with"               "Running with %s..."
  "checking_cache"             "Checking compilation cache for %s"
  "found_cache"                "Found cached class files at %s"
  "extracting_cache"           "Extracting cached class files to %s"
  "using_cached_compilation"   "Using previously compiled cached class files"
  "using_cached_binary"        "Using previously compiled cached binary"
  "executing"                  "Executing..."
  "no_valid_cache"             "No valid cache found for %s"
  "compiling"                  "Compiling %s..."
  "compiling_with_flags"       "Compiling %s with flags: %s"
  "compilation_successful"     "Compilation successful!"
  "caching_files"              "Attempting to cache class files for %s"
  "found_files_to_cache"       "Found class files to cache in %s"
  "saved_to_cache"             "Class files cached to: %s"
  "failed_to_cache"            "Failed to create cache file: %s"
  "no_files_to_cache"          "No class files found to cache for %s"
  "compilation_failed"         "Compilation failed for %s."
  "unknown_language"           "Unknown language type '%s' with extension '.%s'."
  "no_sandbox_tech"            "No sandbox technology found, code will run without sandbox protection."
  "install_sandbox"            "Please install firejail, nsjail, bubblewrap, or use systemd for sandbox support."
  "missing_timeout_value"      "Missing value for --timeout option"
  "missing_memory_value"       "Missing value for --memory option"
  "cache_cleaned"              "Compilation cache cleaned"
  "validating_args"            "Validating program arguments"
  "unsafe_arg"                 "Potentially unsafe argument detected: %s"
  "args_quoted"                "Arguments containing shell metacharacters will be quoted for safety"
  "using_file"                 "Using specified file: %s"
  "file_not_exist"             "Specified file does not exist: %s"
  "searching_file"             "No file provided or argument is not a file. Searching for most recently modified source code file..."
  "no_supported_files"         "No supported code files found. Supported extensions: %s"
  "auto_selected_file"         "Auto-selected file: %s"
  "file_not_found"             "File not found: %s"
  "preparing_to_execute"       "Preparing to execute: %s"
  "file_type_detected"         "File type detected: %s"
  "unsupported_file_type"      "Unsupported file type: %s"
  "supported_types"            "Supported types are: %s"
  "required_command_not_found" "Required command not found: %s"
  "please_install"             "Please install it and make sure it's in your PATH."
  "sandbox_mode"               "Running in sandbox mode with %s"
  "timeout_not_found"          "Timeout command not found. Running without timeout limit."
  "program_output"             "Program Output"
  "program_completed"          "Program completed successfully"
  "program_timed_out"          "Program execution timed out"
  "program_exited_with_code"   "Program exited with code %s"
  "compiling_file"             "Compiling %s"
  "compiling_with_flags_msg"   "Compiling %s with flags: %s"
  "program_status"             "Program %s"
  "status_completed"           "completed successfully"
  "status_timed_out"           "timed out"
  "status_exited_with_code"    "exited with code %s"
  "program_completed_full"     "Program completed successfully"
  "program_timed_out_full"     "Program execution timed out"
  "program_exited_with_code_full" "Program exited with code %s"
)

# Chinese messages
MSG_ZH=(
  "time_limit"                 "时间限制: %s"
  "execution_timeout"          "程序执行超时，已在 %s 后终止"
  "running_with"               "使用 %s 运行..."
  "checking_cache"             "正在检查 %s 的编译缓存"
  "found_cache"                "在 %s 找到缓存的类文件"
  "extracting_cache"           "正在将缓存的类文件解压到 %s"
  "using_cached_compilation"   "使用之前编译的缓存类文件"
  "using_cached_binary"        "使用之前编译的缓存二进制文件"
  "executing"                  "正在执行..."
  "no_valid_cache"             "没有找到 %s 的有效缓存"
  "compiling"                  "正在编译 %s..."
  "compiling_with_flags"       "正在使用以下选项编译 %s: %s"
  "compilation_successful"     "编译成功！"
  "caching_files"              "正在尝试缓存 %s 的类文件"
  "found_files_to_cache"       "在 %s 中找到要缓存的类文件"
  "saved_to_cache"             "类文件已缓存到: %s"
  "failed_to_cache"            "创建缓存文件失败: %s"
  "no_files_to_cache"          "没有找到 %s 的类文件可缓存"
  "compilation_failed"         "%s 编译失败。"
  "unknown_language"           "未知的语言类型 '%s'，扩展名为 '.%s'。"
  "no_sandbox_tech"            "未找到沙箱技术，代码将在无沙箱保护的情况下运行。"
  "install_sandbox"            "请安装 firejail、nsjail、bubblewrap 或使用 systemd 以获得沙箱支持。"
  "missing_timeout_value"      "--timeout 选项缺少值"
  "missing_memory_value"       "--memory 选项缺少值"
  "cache_cleaned"              "编译缓存已清理"
  "validating_args"            "正在验证程序参数"
  "unsafe_arg"                 "检测到潜在不安全的参数: %s"
  "args_quoted"                "包含 shell 元字符的参数将被引用以确保安全"
  "using_file"                 "使用指定的文件: %s"
  "file_not_exist"             "指定的文件不存在: %s"
  "searching_file"             "未提供文件或参数不是文件。正在搜索最近修改的源代码文件..."
  "no_supported_files"         "未找到支持的代码文件。支持的扩展名: %s"
  "auto_selected_file"         "自动选择的文件: %s"
  "file_not_found"             "文件不存在: %s"
  "preparing_to_execute"       "准备执行: %s"
  "file_type_detected"         "检测到文件类型: %s"
  "unsupported_file_type"      "不支持的文件类型: %s"
  "supported_types"            "支持的类型有: %s"
  "required_command_not_found" "未找到所需命令: %s"
  "please_install"             "请安装它并确保它在您的 PATH 中。"
  "sandbox_mode"               "在沙箱模式下运行，使用 %s"
  "timeout_not_found"          "未找到 timeout 命令。将在无超时限制的情况下运行。"
  "program_output"             "程序输出"
  "program_completed"          "程序成功完成"
  "program_timed_out"          "程序执行超时"
  "program_exited_with_code"   "程序退出，返回代码 %s"
  "compiling_file"             "正在编译 %s"
  "compiling_with_flags_msg"   "正在使用以下选项编译 %s: %s"
  "program_status"             "程序%s"
  "status_completed"           "成功完成"
  "status_timed_out"           "执行超时"
  "status_exited_with_code"    "退出，返回代码 %s"
  "program_completed_full"     "程序成功完成"
  "program_timed_out_full"     "程序执行超时"
  "program_exited_with_code_full" "程序退出，返回代码 %s"
)

# Get message in the current language
# Usage: get_msg <message_key> [arg1] [arg2] ...
get_msg() {
  local msg_key="$1"
  shift
  local msg_template=""
  local effective_lang="en"  # Default to English
  
  # Determine the language to use
  if [[ "$RUNNER_LANGUAGE" == "zh" ]]; then
    effective_lang="zh"
  elif [[ "$RUNNER_LANGUAGE" == "auto" ]]; then
    if [[ "$LANG" == "zh_CN"* ]]; then
      effective_lang="zh"
    fi
  fi
  
  # Get the message template in the appropriate language
  if [[ "$effective_lang" == "zh" ]]; then
    msg_template="${MSG_ZH[$msg_key]}"
  else
    msg_template="${MSG_EN[$msg_key]}"
  fi
  
  # If the message key doesn't exist, return the key itself
  if [[ -z "$msg_template" ]]; then
    echo "$msg_key"
    return
  fi
  
  # If there are no arguments, just return the template
  if [[ $# -eq 0 ]]; then
    echo "$msg_template"
    return
  fi
  
  # Otherwise, format the message with the arguments
  # This is a simple implementation that only handles %s placeholders
  local result="$msg_template"
  for arg in "$@"; do
    result=${result/\%s/$arg}
  done
  
  echo "$result"
}

# Debug function to show current language setting
debug_lang() {
  echo "Current language: $RUNNER_LANGUAGE"
  echo "LANG environment: $LANG"
  echo "Effective language: $(if [[ "$RUNNER_LANGUAGE" == "zh" || ("$RUNNER_LANGUAGE" == "auto" && "$LANG" == "zh_CN"*) ]]; then echo "zh"; else echo "en"; fi)"
}