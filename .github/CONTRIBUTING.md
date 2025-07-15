# Contributing to CodeRunner

First off, thank you for considering contributing! Every contribution helps make CodeRunner better.

## How to Contribute

There are many ways to contribute, from reporting bugs to submitting new features.

### Reporting Bugs

If you find a bug, please create a new [Issue](https://github.com/<YOUR_USERNAME>/<YOUR_REPONAME>/issues) on our GitHub page. Please be as detailed as possible, including:
- Your operating system.
- The version of Zsh you are using (`zsh --version`).
- The exact command you ran.
- The full output, including any error messages.

### Suggesting Enhancements

If you have an idea for a new feature, feel free to create an [Issue](https://github.com/<YOUR_USERNAME>/<YOUR_REPONAME>/issues) to discuss it.

### Submitting Pull Requests

If you'd like to contribute code, please follow these steps:

1.  **Fork the repository** on GitHub.
2.  **Clone your fork** to your local machine.
3.  **Create a new branch** for your changes (`git checkout -b feature/your-awesome-feature`).
4.  **Make your changes**. If you add a new language, please also add a test case for it in `test_runner.zsh`.
5.  **Run the test suite** to ensure everything still works correctly:
    ```bash
    ./test_runner.zsh
    ```
6.  **Commit your changes** with a clear and descriptive commit message.
7.  **Push your branch** to your fork on GitHub.
8.  **Create a Pull Request** from your fork to the main CodeRunner repository.

We will review your PR as soon as possible. Thank you for your contribution! 