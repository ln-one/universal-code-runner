# Universal Code Runner - Developer Guide

## Project Structure

```
/ (project root)
├── ucode                # Main entry script
├── _common.zsh          # Common functions and config (core logic)
├── _compile_and_run.zsh # Compilation and execution logic
├── _cache.zsh           # Compilation cache functions
├── _sandbox.zsh         # Sandbox and security functions
├── _ui.zsh              # UI, logging, and message functions
├── test_runner.zsh      # Automated test runner
├── coverage.zsh         # Feature-level coverage analysis
├── install.zsh          # Install script
├── README.md            # User documentation (English)
├── README.zh.md         # User documentation (Chinese)
└── ...                  # Other files (tests, configs, etc.)
```

## Main Scripts & Modules

- **ucode**: Entry point, argument parsing, main workflow.
- **_common.zsh**: Shared functions, global config, language table, logging, validation, etc.
- **_compile_and_run.zsh**: Handles compilation, execution, and cache logic for all supported languages.
- **_cache.zsh**: Functions for cache directory, hash, save/load, clean, etc.
- **_sandbox.zsh**: Functions for running code in a sandbox (firejail, systemd, etc.).
- **_ui.zsh**: Logging, spinner, color, i18n message mapping.
- **test_runner.zsh**: Automated test suite for all features and languages.
- **coverage.zsh**: Checks if all core features are covered by tests.

## Key Functions (by file)

- **_common.zsh**
  - `validate_numeric`, `sanitize_filename`, `validate_args`
  - `log_msg`, `get_msg`, `debug_lang`
  - `run_in_sandbox`, `detect_sandbox_tech`
  - `execute_and_show_output`
- **_compile_and_run.zsh**
  - Compilation and execution logic for each language type
  - Handles cache check/save, timeout, and output
- **_cache.zsh**
  - `get_cache_dir`, `get_source_hash`, `check_cache`, `save_to_cache`, `clean_cache`, `init_cache`
- **_ui.zsh**
  - `highlight_code`, `start_spinner`, `stop_spinner`, `log_msg`

## Development Workflow

1. **Clone and install dependencies**
   ```sh
   git clone https://github.com/ln1/universal-code-runner.git
   cd universal-code-runner
   ./install.zsh
   ```
2. **Run tests**
   ```sh
   ./test_runner.zsh
   ```
3. **Check feature coverage**
   ```sh
   ./coverage.zsh
   ```
4. **Debug/Develop**
   - Edit scripts as needed (prefer modular changes)
   - Use `--verbose`, `--debug` flags for more output
   - Add/modify tests in `test_runner.zsh`

## Contribution Guide

- **Coding style**: Follow existing shell style, use English for code comments and commit messages.
- **Testing**: Add/extend tests for new features in `test_runner.zsh`.
- **Documentation**: Update `README.md` and this developer guide for any user-facing or architectural changes.
- **Pull Requests**: Describe your changes clearly, reference related issues if any.

## Extending the Project

- **Add new language**: Edit `LANG_CONFIG` in `_common.zsh` and add test cases.
- **Add new feature**: Implement in a new or existing module, add tests and documentation.
- **Refactor**: Modularize large files (e.g., split `_common.zsh`), ensure all tests pass.
- **Plugin system**: (Planned) Will require config and module refactor.

## Tips
- Use `set -x` for shell debugging.
- Use `zsh` for all scripts (not bash).
- Keep functions small and focused.
- Prefer POSIX-compatible code where possible.

## Configuration File Support

Universal Code Runner supports user configuration files for default settings.

- Supported locations (checked in order):
  1. `./ucode.conf` (project root)
  2. `~/.ucoderc` (user home)
- Format: simple shell variable assignments, e.g.:
  ```sh
  # ~/.ucoderc or ./ucode.conf
  RUNNER_TIMEOUT=10
  RUNNER_MEMORY_LIMIT=256
  RUNNER_LANGUAGE="zh"
  RUNNER_DISABLE_CACHE=false
  RUNNER_SANDBOX=true
  RUNNER_VERBOSE=true
  ```
- **Priority:** command-line arguments > config file > script defaults
- Loaded automatically before argument parsing in `ucode`.

This enables project-wide or user-wide default settings and paves the way for future extensibility (e.g., plugin config, custom language options).

---

For any questions, open an issue or join the discussion on GitHub! 