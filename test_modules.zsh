#!/usr/bin/env zsh
# Test module refactoring success
# This script tests if each module can be correctly loaded and used

# Import common module (which should automatically import all other modules)
source "${0:A:h}/_common.zsh"

# Set up test environment
RUNNER_VERBOSE=true

# Test log_msg function
echo "Testing log_msg function..."
log_msg INFO "This is an info message"
log_msg WARN "This is a warning message"
log_msg ERROR "This is an error message"
log_msg SUCCESS "This is a success message"

# Debug messages are only displayed when RUNNER_DEBUG=true
echo "Testing debug message (should not appear)..."
log_msg DEBUG "This is a debug message"
RUNNER_DEBUG=true
log_msg DEBUG "This is a debug message (should appear)"

# Test get_msg function
echo "Testing get_msg function..."
echo "Message in English: $(get_msg info_using_file)"
RUNNER_LANG=zh
echo "Message in Chinese: $(get_msg info_using_file)"
RUNNER_LANG=en

# Test validate_numeric function
echo "Testing validate_numeric function..."
validate_numeric 5 1 10 "Test parameter"
echo "Valid numeric: $?"
validate_numeric 15 1 10 "Test parameter"
echo "Invalid numeric (too large): $?"
validate_numeric -5 1 10 "Test parameter"
echo "Invalid numeric (negative): $?"
validate_numeric abc 1 10 "Test parameter"
echo "Invalid numeric (not a number): $?"

# Test run_with_timeout function
echo "Testing run_with_timeout function..."
run_with_timeout 2 echo "This should complete within timeout"
echo "Exit code: $?"
run_with_timeout 1 sleep 3
echo "Exit code after timeout: $?"

# Test detect_sandbox_tech function
echo "Testing detect_sandbox_tech function..."
echo "Available sandbox technology: $(detect_sandbox_tech)"

# Test get_cache_dir function
echo "Testing get_cache_dir function..."
cache_dir=$(get_cache_dir)
echo "Cache directory: $cache_dir"

# Test execute_and_show_output function
echo "Testing execute_and_show_output function..."
execute_and_show_output echo "This is a test output"

echo "All tests completed!"
exit 0 