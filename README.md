# Universal Code Runner

[![Test Suite](https://github.com/ln-one/universal-code-runner/actions/workflows/ci.yml/badge.svg)](https://github.com/ln-one/universal-code-runner/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**`Universal Code Runner` is a smart, zero-configuration command-line tool for compiling and running code in over 10 different languages, designed for speed and elegance.**

It's built for developers, students, and competitive programmers who want to test a piece of code quickly without the hassle of typing long compilation commands or creating project files.

---

## ✨ Core Features

-   **Elegant Output**: A modern, clean interface with icons and colors that makes output readable and visually appealing.
-   **Concise & Verbose Modes**: By default, it runs in a concise mode for clean output. Use the `--verbose` flag to get detailed compilation and runtime information.
-   **Multi-Language Support**: Works out of the box with C, C++, Java, Go, Rust, Python, JavaScript, TypeScript, PHP, Ruby, and more.
-   **Auto-Detection**: If you don't specify a file, `ucode` automatically finds and executes the most recently modified source file.
-   **Seamless Argument Passing**: All arguments provided after the filename are passed directly to your program.
-   **Zero Dependencies**: Besides Zsh and the language toolchains themselves, the script is fully self-contained.
-   **Compilation Caching**: Automatically caches compilation results to avoid unnecessary recompilation of unchanged source files.
-   **Sandbox Execution**: Optional sandbox mode for secure code execution with limited permissions.
-   **Resource Limits**: Set memory and time limits for program execution.

---

## 💅 Showcase

**Concise Mode (Default)**

Clean, minimal, and to the point.

```
$ ucode hello.py
🚀 Preparing to execute: /path/to/your/project/hello.py
┌────────────────────── PROGRAM OUTPUT ──────────────────────┐
Hello from Python! 👋
└────────────────────────────────────────────────────────────┘
📊 Program completed successfully
```

**Verbose Mode (`--verbose`)**

Get all the details you need for debugging.

```
$ ucode --verbose hello.cpp
🚀 Preparing to execute: /path/to/your/project/hello.cpp
ℹ️ File type detected: .cpp
ℹ️ Compiling hello.cpp with flags: -std=c++17 -Wall -Wextra -O2
ℹ️ Compilation successful. Executing...
┌────────────────────── PROGRAM OUTPUT ──────────────────────┐
Hello from C++!
└────────────────────────────────────────────────────────────┘
📊 Program completed successfully
```
---

## 🚀 Installation

The provided `install.zsh` script handles everything for you. It installs the scripts to `/usr/local/lib/ucode` and creates a symbolic link at `/usr/local/bin/ucode`.

```bash
# Make sure you have zsh and git installed first
git clone https://github.com/ln1/universal-code-runner.git
cd universal-code-runner
sudo ./install.zsh
```
*You may need to provide your password for the `sudo` command.*

---

## 💻 Usage

#### 1. Run the most recently modified file
```bash
# Modified main.go a second ago? This will run it.
ucode
```

#### 2. Run a specific file with arguments
```bash
ucode my_app.rs --user "Alice" --level 10
```

#### 3. Run in Verbose Mode

Use the `-v` or `--verbose` flag before specifying a file.

```bash
ucode -v my_program.c
```

#### 4. Use Compilation Caching

By default, `ucode` caches compilation results to avoid unnecessary recompilation of unchanged source files. You can disable caching with the `--no-cache` flag.

```bash
# Run with caching disabled (will force recompilation)
ucode --no-cache my_program.cpp

# Clean the compilation cache
ucode --clean-cache
```

#### 5. Run with Resource Limits

```bash
# Run with a 5-second timeout
ucode --timeout 5 my_program.c

# Run with a 100MB memory limit
ucode --memory 100 my_program.c
```

#### 6. Run in Sandbox Mode

```bash
# Run in a restricted sandbox environment
ucode --sandbox my_program.py
```

---

## 🔧 Extending Language Support

Adding a new language is incredibly simple. All configuration is stored in associative arrays in the `_common.zsh` file. Simply add your language's compiler, runner, and flags to the appropriate arrays.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details. 