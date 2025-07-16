#!/usr/bin/env zsh
# ==============================================================================
# Configuration and Language Support for Universal Code Runner
# ==============================================================================

# ==============================================================================
# Global Configuration
# ==============================================================================
# Default resource limits
export RUNNER_TIMEOUT=0       # Default: no timeout (in seconds)
export RUNNER_MEMORY_LIMIT=0  # Default: no memory limit (in MB)

# ==============================================================================
# Language Configuration
# ==============================================================================

# Language configuration mapping
# Format: extension -> "type:compiler:flags_var:default_flags:runner"
typeset -gA LANG_CONFIG
LANG_CONFIG=(
  # ext   type         compiler   flags_var  default_flags                     runner
  c       "compile:gcc:CFLAGS:-std=c17 -Wall -Wextra -O2:"
  cpp     "compile:g++:CXXFLAGS:-std=c++17 -Wall -Wextra -O2:"
  rs      "compile:rustc:RUSTFLAGS:-C opt-level=2:"
  java    "compile_jvm:javac:::-"
  py      "direct::::python3"
  js      "direct::::node"
  php     "direct::::php"
  rb      "direct::::ruby"
  sh      "direct::::bash"
  pl      "direct::::perl"
  lua     "direct::::lua"
)

# ==============================================================================
# Configuration Helper Functions
# ==============================================================================

# Get supported file extensions
get_supported_extensions() {
  local extensions=""
  for ext in ${(k)LANG_CONFIG}; do
    extensions+=".$ext "
  done
  echo "$extensions"
}

# Check if a file extension is supported
is_supported_extension() {
  local ext="$1"
  [[ -n "${LANG_CONFIG[$ext]}" ]]
}

# Get language configuration for an extension
get_lang_config() {
  local ext="$1"
  echo "${LANG_CONFIG[$ext]}"
}

# Parse language configuration string
# Usage: parse_lang_config <config_string>
# Returns: type compiler flags_var default_flags runner (space-separated)
parse_lang_config() {
  local config_string="$1"
  local -a config_parts
  config_parts=("${(@s/:/)config_string}")
  
  echo "${config_parts[1]}" "${config_parts[2]}" "${config_parts[3]}" "${config_parts[4]}" "${config_parts[5]}"
}