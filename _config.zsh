#!/usr/bin/env zsh
# ==============================================================================
# Configuration for the Universal Code Runner
# ==============================================================================

# ==============================================================================
# Global Configuration
# ==============================================================================
# Default resource limits
export RUNNER_TIMEOUT=0       # Default: no timeout (in seconds)
export RUNNER_MEMORY_LIMIT=0  # Default: no memory limit (in MB)
export RUNNER_VERBOSE=false   # Verbose mode
export RUNNER_ASCII_MODE=false # ASCII mode for compatibility
export RUNNER_SANDBOX=false   # Sandbox mode
export RUNNER_DEBUG=false     # Debug mode
export RUNNER_DISABLE_CACHE=false # Cache disable flag
export RUNNER_LANGUAGE="auto" # UI language (auto, en, zh)

# ==============================================================================
# Language Configurations
# ==============================================================================
# Language configuration format:
# ext => "type:compiler:flags_var:default_flags:runner"
#
# type: Type of execution (compile, compile_jvm, direct)
# compiler: Command to compile the code
# flags_var: Environment variable for compiler flags
# default_flags: Default flags for the compiler
# runner: Command to run the code (for direct execution)

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

# Original Colors (for backwards compatibility if needed by old logic)
BOLD_OLD=$'\033[1m'
RED_OLD=$'\033[1;31m'
GREEN_OLD=$'\033[1;32m'
YELLOW_OLD=$'\033[1;33m'
BLUE_OLD=$'\033[1;34m'
MAGENTA_OLD=$'\033[1;35m'
CYAN_OLD=$'\033[0;36m'
GRAY_OLD=$'\033[0;90m'
WHITE_OLD=$'\033[1;97m'
RESET_OLD=$'\033[0m'

# Simple function to check for installed dependencies (backwards compatibility)
# Note: It's recommended to use check_dependencies_new from _validate.zsh instead
check_dependencies() {
  for dep in "$@"; do
    if ! command -v "$dep" &> /dev/null; then
      echo -e "${RED_OLD}❌ Error: Dependency not found: ${CYAN_OLD}${dep}${RESET_OLD}"
      echo -e "${YELLOW_OLD}Please install ${CYAN_OLD}${dep}${YELLOW_OLD} and try again.${RESET_OLD}"
      exit 1
    fi
  done
} 