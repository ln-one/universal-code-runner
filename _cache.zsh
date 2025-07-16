#!/usr/bin/env zsh
# ==============================================================================
# Compilation Cache Functions for the Universal Code Runner
# ==============================================================================

# Get the current script directory
_THIS_SCRIPT_DIR=${0:A:h}

# ==============================================================================
# Compilation Cache Functions
# ==============================================================================

# Get the cache directory path, creating it if it doesn't exist
# Returns the path to the cache directory
get_cache_dir() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ucode"
  
  # Create the cache directory if it doesn't exist
  if [[ ! -d "$cache_dir" ]]; then
    mkdir -p "$cache_dir"
    # Note: This depends on the log_msg function in _ui.zsh
    # _common.zsh already sources _ui.zsh and _cache.zsh, so the function call order is correct
    debug_log "Created cache directory" "${cache_dir}"
  fi
  
  echo "$cache_dir"
}

# Generate a hash for a source file based on its content and compilation flags
# Usage: get_source_hash <source_file> <compiler> <flags...>
get_source_hash() {
  local src_file="$1"
  local compiler="$2"
  shift 2
  local flags=("$@")
  
  # Get the absolute path of the compiler to ensure consistency
  local compiler_path=$(command -v "$compiler")
  
  # Combine source file content, compiler path, and flags to create a unique hash
  {
    cat "$src_file"
    echo "$compiler_path"
    echo "${flags[@]}"
  } | sha256sum | cut -d' ' -f1 | cut -c1-32  # Only use the first 32 characters to avoid long filenames
}

# Check if a cached binary exists and is valid
# Usage: check_cache <source_file> <compiler> <flags...>
# Returns: Path to cached binary if exists, empty string otherwise
check_cache() {
  local src_file="$1"
  local compiler="$2"
  shift 2
  local flags=("$@")
  
  # Skip cache if disabled
  if [[ "$RUNNER_DISABLE_CACHE" == "true" ]]; then
    return 1
  fi
  
  # Generate hash for the source file
  local src_hash=$(get_source_hash "$src_file" "$compiler" "${flags[@]}")
  local cache_dir=$(get_cache_dir)
  local cached_binary="${cache_dir}/${src_hash}"
  
  # Check if cached binary exists and is executable
  if [[ -f "$cached_binary" && -x "$cached_binary" ]]; then
    # Check if the cache is too old (default: 7 days)
    local max_cache_age=${RUNNER_MAX_CACHE_AGE:-604800}  # 7 days in seconds
    local current_time=$(date +%s)
    local cache_time=$(stat -c %Y "$cached_binary" 2>/dev/null)
    
    if [[ $((current_time - cache_time)) -gt $max_cache_age ]]; then
      debug_log "Cache expired for" "$(basename "$src_file")"
      rm -f "$cached_binary"
      return 1
    fi
    
    debug_log "Using cached binary for" "$(basename "$src_file")"
    echo "$cached_binary"
    return 0
  fi
  
  return 1
}

# Save a compiled binary to the cache
# Usage: save_to_cache <binary_path> <source_file> <compiler> <flags...>
save_to_cache() {
  local binary_path="$1"
  local src_file="$2"
  local compiler="$3"
  shift 3
  local flags=("$@")
  
  # Skip cache if disabled
  if [[ "$RUNNER_DISABLE_CACHE" == "true" ]]; then
    return 1
  fi
  
  # Generate hash for the source file
  local src_hash=$(get_source_hash "$src_file" "$compiler" "${flags[@]}")
  local cache_dir=$(get_cache_dir)
  local cached_binary="${cache_dir}/${src_hash}"
  
  # Copy the binary to the cache
  cp "$binary_path" "$cached_binary"
  chmod +x "$cached_binary"
  
  debug_log "Saved binary to cache" "${cached_binary}"
  echo "$cached_binary"
}

# Clean old cache files
# Usage: clean_cache [max_age_in_seconds] [force]
clean_cache() {
  local max_age=${1:-604800}  # Default: 7 days
  local force=${2:-false}     # Default: don't force clean
  local cache_dir=$(get_cache_dir)
  
  if [[ "$force" == "true" ]]; then
    # Force clean all cache files
    rm -rf "${cache_dir:?}"/* 2>/dev/null
    debug_log "Forced cleaning of all cache files" ""
  else
    # Find and remove cache files older than max_age
    find "$cache_dir" -type f -mtime +$((max_age / 86400)) -delete 2>/dev/null
    debug_log "Cleaned cache files older than" "$((max_age / 86400)) days"
  fi
}

# Initialize cache system
init_cache() {
  # Clean cache on startup (once per session)
  if [[ "$RUNNER_CACHE_CLEANED" != "true" ]]; then
    clean_cache
    export RUNNER_CACHE_CLEANED="true"
  fi
}

# Do not call init_cache here, call it in _common.zsh
# This prevents duplicate initialization when _common.zsh sources _cache.zsh
# init_cache