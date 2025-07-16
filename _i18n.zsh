#!/usr/bin/env zsh
# ==============================================================================
# Internationalization and Message Functions for the Universal Code Runner
# ==============================================================================

# Load UI module (for color definitions)
source "${0:A:h}/_ui.zsh"

# ==============================================================================
# Message Definitions
# ==============================================================================

# Define messages in English
declare -A MSG_EN
MSG_EN=(
  # Help messages
  help_header "Universal Code Runner - Smart compilation and execution tool"
  help_usage "USAGE: ucode [OPTIONS] [FILE] [ARGS...]"
  help_description "Automatically detects file type, compiles if needed, and runs the code."
  help_options "OPTIONS:"
  help_option_help "--help, -h: Show this help message"
  help_option_verbose "--verbose, -v: Show detailed output"
  help_option_timeout "--timeout, -t <seconds>: Set execution timeout (default: 10s)"
  help_option_memory "--memory, -m <MB>: Set memory limit in MB (default: 500MB)"
  help_option_sandbox "--sandbox, -s: Run in sandbox mode for better security"
  help_option_no_cache "--no-cache, -n: Disable compilation cache"
  help_option_clean_cache "--clean-cache: Clean the compilation cache"
  help_option_ascii "--ascii, -a: Use ASCII characters instead of Unicode"
  help_option_lang "--lang <language>: Set language (en, zh)"
  help_examples "EXAMPLES:"
  help_example_1 "  ucode myfile.c arg1 arg2    # Run C file with arguments"
  help_example_2 "  ucode --verbose script.py   # Run Python script with verbose output"
  help_example_3 "  ucode --sandbox code.js     # Run JavaScript in sandbox mode"
  help_example_4 "  ucode                       # Auto-detect and run the most recently modified file"
  help_footer "For more information, visit: https://github.com/lonelyenvoy/universal-code-runner"
  
  # Error messages
  error_no_file "No file specified and no suitable files found."
  error_file_not_found "File not found:"
  error_unknown_ext "Unknown file extension:"
  error_compilation_failed "Compilation failed."
  error_execution_failed "Execution failed."
  error_timeout "Program execution timed out after"
  error_invalid_option "Invalid option:"
  error_missing_arg "Missing argument for option:"
  
  # Info messages
  info_using_file "Using specified file:"
  info_using_latest "Using most recently modified file:"
  info_file_type "File type detected:"
  info_compiling "Compiling"
  info_running "Running with"
  info_running_args "Arguments:"
  info_cache_used "Using cached binary from previous compilation"
  info_cache_cleaned "Cache cleaned successfully"
  info_sandbox "Running in sandbox mode"
  info_sandbox_unavailable "Sandbox mode requested but no sandbox technology available"
  info_memory_limit "Memory limit:"
  info_time_limit "Time limit:"
  
  # Success messages
  success_compilation "Compilation successful"
  success_execution "Program completed successfully"
  success_with_time "Program completed successfully in"
  
  # Warning messages
  warn_no_sandbox "No sandbox technology available, running without protection"
  warn_limited_sandbox "Limited sandbox protection. Install firejail for better security."
  warn_unsafe_arg "Potentially unsafe argument detected:"
  
  # Misc messages
  args_quoted "Arguments will be quoted for safety."
  seconds "seconds"
)

# Define messages in Chinese
declare -A MSG_ZH
MSG_ZH=(
  # Help messages
  help_header "通用代码运行器 - 智能的编译与运行工具"
  help_usage "用法: ucode [选项] [文件] [参数...]"
  help_description "自动检测文件类型，根据需要编译，并运行代码。"
  help_options "选项:"
  help_option_help "--help, -h: 显示此帮助信息"
  help_option_verbose "--verbose, -v: 显示详细输出"
  help_option_timeout "--timeout, -t <秒>: 设置执行超时时间 (默认: 10秒)"
  help_option_memory "--memory, -m <MB>: 设置内存限制 (默认: 500MB)"
  help_option_sandbox "--sandbox, -s: 在沙箱模式下运行以提高安全性"
  help_option_no_cache "--no-cache, -n: 禁用编译缓存"
  help_option_clean_cache "--clean-cache: 清理编译缓存"
  help_option_ascii "--ascii, -a: 使用ASCII字符而不是Unicode"
  help_option_lang "--lang <语言>: 设置语言 (en, zh)"
  help_examples "示例:"
  help_example_1 "  ucode myfile.c arg1 arg2    # 带参数运行C文件"
  help_example_2 "  ucode --verbose script.py   # 以详细模式运行Python脚本"
  help_example_3 "  ucode --sandbox code.js     # 在沙箱模式下运行JavaScript"
  help_example_4 "  ucode                       # 自动检测并运行最近修改的文件"
  help_footer "更多信息，请访问: https://github.com/lonelyenvoy/universal-code-runner"
  
  # Error messages
  error_no_file "未指定文件且未找到合适的文件。"
  error_file_not_found "文件未找到:"
  error_unknown_ext "未知的文件扩展名:"
  error_compilation_failed "编译失败。"
  error_execution_failed "执行失败。"
  error_timeout "程序执行超时，已运行"
  error_invalid_option "无效选项:"
  error_missing_arg "选项缺少参数:"
  
  # Info messages
  info_using_file "使用指定文件:"
  info_using_latest "使用最近修改的文件:"
  info_file_type "检测到文件类型:"
  info_compiling "正在编译"
  info_running "使用以下方式运行"
  info_running_args "参数:"
  info_cache_used "使用之前编译的缓存二进制文件"
  info_cache_cleaned "缓存已成功清理"
  info_sandbox "在沙箱模式下运行"
  info_sandbox_unavailable "已请求沙箱模式，但没有可用的沙箱技术"
  info_memory_limit "内存限制:"
  info_time_limit "时间限制:"
  
  # Success messages
  success_compilation "编译成功"
  success_execution "程序成功完成"
  success_with_time "程序在以下时间内成功完成"
  
  # Warning messages
  warn_no_sandbox "没有可用的沙箱技术，将在无保护的情况下运行"
  warn_limited_sandbox "有限的沙箱保护。安装firejail以获得更好的安全性。"
  warn_unsafe_arg "检测到潜在不安全的参数:"
  
  # Misc messages
  args_quoted "参数将被引用以确保安全。"
  seconds "秒"
)

# ==============================================================================
# Message Handling Functions
# ==============================================================================

# Get a message in the current language
# Usage: get_msg <message_key>
get_msg() {
  local key="$1"
  local lang="${RUNNER_LANG:-en}"
  local message=""
  
  # Get the message in the specified language
  if [[ "$lang" == "zh" ]]; then
    message="${MSG_ZH[$key]}"
  else
    message="${MSG_EN[$key]}"
  fi
  
  # Fallback to English if the message doesn't exist in the specified language
  if [[ -z "$message" ]]; then
    message="${MSG_EN[$key]}"
  fi
  
  echo "$message"
}

# Display the help message
show_help() {
  local lang="${RUNNER_LANG:-en}"
  
  echo "$(get_msg help_header)"
  echo
  echo "$(get_msg help_usage)"
  echo
  echo "$(get_msg help_description)"
  echo
  echo "$(get_msg help_options)"
  echo "  $(get_msg help_option_help)"
  echo "  $(get_msg help_option_verbose)"
  echo "  $(get_msg help_option_timeout)"
  echo "  $(get_msg help_option_memory)"
  echo "  $(get_msg help_option_sandbox)"
  echo "  $(get_msg help_option_no_cache)"
  echo "  $(get_msg help_option_clean_cache)"
  echo "  $(get_msg help_option_ascii)"
  echo "  $(get_msg help_option_lang)"
  echo
  echo "$(get_msg help_examples)"
  echo "$(get_msg help_example_1)"
  echo "$(get_msg help_example_2)"
  echo "$(get_msg help_example_3)"
  echo "$(get_msg help_example_4)"
  echo
  echo "$(get_msg help_footer)"
} 