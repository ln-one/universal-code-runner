# 通用代码运行器（Universal Code Runner）

[English README](./README.md)

**`Universal Code Runner` 是一个智能、零配置的命令行工具，支持 10+ 种主流编程语言的编译与运行，追求极致的速度与优雅体验。**

适用于开发者、学生、竞赛选手，快速测试代码片段，无需繁琐的编译命令或项目文件。

---

## ✨ 核心特性

-   **优雅输出**：现代化界面，图标与配色让输出更清晰美观。
-   **简洁/详细模式**：默认简洁输出，`--verbose` 查看详细编译与运行信息。
-   **多语言支持**：开箱即用，支持 C、C++、Java、Rust、Python、JavaScript、PHP、Ruby、Shell、Perl、Lua 等。
-   **自动检测**：不指定文件时，自动查找并运行最近修改的源文件。
-   **智能文件匹配**：无需输入完整文件名，`ucode hello` 会自动查找并运行 `hello.cpp` 或 `hello.py` 等支持的文件。
-   **参数无缝传递**：文件名后的所有参数直接传递给你的程序。
-   **零依赖**：除 Zsh 及各语言工具链外，脚本本身无额外依赖。
-   **编译缓存**：自动缓存编译结果，未变更代码无需重复编译。
-   **沙箱执行**：可选沙箱模式，安全限制程序权限。
-   **资源限制**：可设置程序运行的内存与时间限制。

---

## 💅 展示

**简洁模式（默认）**

```
$ ucode hello.py
🚀 Preparing to execute: /path/to/your/project/hello.py
┌────────────────────── PROGRAM OUTPUT ──────────────────────┐
Hello from Python! 👋
└────────────────────────────────────────────────────────────┘
📊 Program completed successfully
```

**详细模式（`--verbose`）**

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

## 🚀 安装

使用 `install.zsh` 一键安装，脚本会自动部署到 `/usr/local/lib/ucode` 并创建 `/usr/local/bin/ucode` 的软链接。

```bash
# 需先安装 zsh 和 git
git clone https://github.com/ln1/universal-code-runner.git
cd universal-code-runner
sudo ./install.zsh
```
*如需 sudo 权限，请输入密码。*

---

## 💻 用法

#### 1. 运行最近修改的文件
```bash
ucode
```

#### 2. 运行指定文件并传参
```bash
ucode my_app.rs --user "Alice" --level 10
```

#### 3. 详细模式
```bash
ucode -v my_program.c
```

#### 4. 使用编译缓存
```bash
ucode --no-cache my_program.cpp
ucode --clean-cache
```

#### 5. 资源限制
```bash
ucode --timeout 5 my_program.c
ucode --memory 100 my_program.c
```

#### 6. 沙箱模式
```bash
ucode --sandbox my_program.py
```

---

## 🔧 扩展语言支持

所有配置均在 `_common.zsh` 的关联数组中，添加新语言极为简单。

---

## 🤝 贡献

欢迎 PR！

## 📄 许可证

MIT License，详见 LICENSE 文件。
