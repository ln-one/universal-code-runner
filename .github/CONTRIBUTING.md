# Contributing to Universal Code Runner

First off, thank you for considering contributing! Every contribution helps make Universal Code Runner better.

## How to Contribute

There are many ways to contribute, from reporting bugs to submitting new features.

### Reporting Bugs

If you find a bug, please create a new [Issue](https://github.com/ln-one/universal-code-runner/issues) on our GitHub page. Please be as detailed as possible, including:
- Your operating system and version.
- The version of Zsh you are using (`zsh --version`).
- The exact command you ran.
- The full output, including any error messages.
- Steps to reproduce the issue.

### Suggesting Enhancements

If you have an idea for a new feature, feel free to create an [Issue](https://github.com/ln-one/universal-code-runner/issues) to discuss it. Include:
- A clear description of what you want to accomplish.
- Why it would be useful to the project.
- Any implementation ideas you have.

### Submitting Pull Requests

If you'd like to contribute code, please follow these steps:

1. **Fork the repository** on GitHub.
2. **Clone your fork** to your local machine.
3. **Create a new branch** for your changes (`git checkout -b feature/your-awesome-feature`).
4. **Make your changes**. 
   - If you add a new language, please also add a test case for it in `test_runner.zsh`.
   - Make sure your code follows the project style.
   - Add comments where necessary.
5. **Run the test suite** to ensure everything works correctly:
   ```bash
   ./test_runner.zsh
   ```
6. **Commit your changes** with a clear and descriptive commit message.
   - Use present tense ("Add feature" not "Added feature")
   - Reference issues or pull requests when applicable (e.g., "Fix #123: ...")
7. **Push your branch** to your fork on GitHub.
8. **Create a Pull Request** from your fork to the main repository.

## Continuous Integration

This project uses GitHub Actions for continuous integration. When you submit a pull request, the CI system automatically:

1. Runs the test suite on multiple platforms (Ubuntu, macOS)
2. Performs static code analysis using ShellCheck
3. Runs performance tests (on main branch)

A pull request must pass all required CI checks before it can be merged. If the CI fails, check the logs to understand what went wrong and fix the issues.

## Code Standards

- Write idiomatic Zsh code.
- Add comments for non-trivial code.
- Ensure all functions have a clear purpose.
- Follow the existing structure and naming conventions.
- Update documentation when adding or changing features.

## Adding Support for a New Language

To add support for a new programming language:

1. Update the `LANG_CONFIG` array in `_common.zsh`.
2. Add appropriate compiler/interpreter commands and flags.
3. Add a test case in `test_runner.zsh` to verify it works.
4. Test both compilation and execution of the language.
5. Update documentation to mention the new language.

## License

By contributing, you agree that your contributions will be licensed under the project's MIT License.

We will review your PR as soon as possible. Thank you for your contribution! 