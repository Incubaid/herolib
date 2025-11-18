# Contributing to Herolib

Thank you for your interest in contributing to Herolib! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
  - [Setting Up Development Environment](#setting-up-development-environment)
  - [Repository Structure](#repository-structure)
- [Development Workflow](#development-workflow)
  - [Branching Strategy](#branching-strategy)
  - [Making Changes](#making-changes)
  - [Testing](#testing)
  - [Pull Requests](#pull-requests)
- [Code Guidelines](#code-guidelines)
- [CI/CD Process](#cicd-process)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)

## Getting Started

### Setting Up Development Environment

For developers, you can use the automated installation script:

```bash
curl 'https://raw.githubusercontent.com/incubaid/herolib/refs/heads/development/scripts/install_v.sh' > /tmp/install_v.sh
bash /tmp/install_v.sh --analyzer --herolib 
# IMPORTANT: Start a new shell after installation for paths to be set correctly
```

Alternatively, you can manually set up the environment:

```bash
mkdir -p ~/code/github/incubaid
cd ~/code/github/incubaid
git clone git@github.com:incubaid/herolib.git
cd herolib
# checkout development branch for most recent changes
git checkout development 
bash install.sh
```

### Repository Structure

Herolib is an opinionated library primarily used by ThreeFold to automate cloud environments. The repository is organized into several key directories:

- `/lib`: Core library code
- `/cli`: Command-line interface tools, including the Hero tool
- `/cookbook`: Examples and guides for using Herolib
- `/scripts`: Installation and utility scripts
- `/docs`: Generated documentation

## Development Workflow

### Branching Strategy

- `development`: Main development branch where all features and fixes are merged
- `main`: Stable release branch

For new features or bug fixes, create a branch from `development` with a descriptive name.

### Making Changes

1. Create a new branch from `development`:

   ```bash
   git checkout development
   git pull
   git checkout -b feature/your-feature-name
   ```

2. Make your changes, following the code guidelines.

3. Run tests to ensure your changes don't break existing functionality:

   ```bash
   ./test_basic.vsh
   ```

4. Commit your changes with clear, descriptive commit messages.

### Testing

Before submitting a pull request, ensure all tests pass:

```bash
# Run all basic tests
./test_basic.vsh

# Run tests for a specific module
vtest ~/code/github/incubaid/herolib/lib/osal/package_test.v

# Run tests for an entire directory
vtest ~/code/github/incubaid/herolib/lib/osal
```

The test script (`test_basic.vsh`) manages test execution and caching to optimize performance. It automatically skips tests listed in the ignore or error sections of the script.

### Pull Requests

1. Push your branch to the repository:

   ```bash
   git push origin feature/your-feature-name
   ```

2. Create a pull request against the `development` branch.

3. Ensure your PR includes:
   - A clear description of the changes
   - Any related issue numbers
   - Documentation updates if applicable

4. Wait for CI checks to pass and address any feedback from reviewers.

## Code Guidelines

- Follow the existing code style and patterns in the repository
- Write clear, concise code with appropriate comments
- Keep modules separate and focused on specific functionality
- Maintain separation between the jsonschema and jsonrpc modules rather than merging them

## CI/CD Process

The repository uses GitHub Actions for continuous integration and deployment:

### 1. Testing Workflow (`test.yml`)

This workflow runs on every push and pull request to ensure code quality:

- Sets up V and Herolib
- Runs all basic tests using `test_basic.vsh`

All tests must pass before a PR can be merged to the `development` branch.

### 2. Hero Build Workflow (`hero_build.yml`)

This workflow builds the Hero tool for multiple platforms when a new tag is created:

- Builds for Linux (x86_64, aarch64) and macOS (x86_64, aarch64)
- Runs all basic tests
- Creates GitHub releases with the built binaries

### 3. Documentation Workflow (`documentation.yml`)

This workflow automatically updates the documentation on GitHub Pages when changes are pushed to the `development` branch:

- Generates documentation using `doc.vsh`
- Deploys the documentation to GitHub Pages

## Documentation

To generate documentation locally:

```bash
cd ~/code/github/incubaid/herolib
bash doc.sh
```

The documentation is automatically published to [https://incubaid.github.io/herolib/](https://incubaid.github.io/herolib/) when changes are pushed to the `development` branch.

## Troubleshooting

### TCC Compiler Error on macOS

If you encounter the following error when using TCC compiler on macOS:

```
In file included from /Users/timurgordon/code/github/vlang/v/thirdparty/cJSON/cJSON.c:42:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/math.h:614: error: ';' expected (got "__fabsf16")
```

This is caused by incompatibility between TCC and the half precision math functions in the macOS SDK. To fix this issue:

1. Open the math.h file:

   ```bash
   sudo nano /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/math.h
   ```

2. Comment out the half precision math functions (around line 612-626).

For more details, see the [README.md](README.md) troubleshooting section.

## Additional Resources

- [Herolib Documentation](https://incubaid.github.io/herolib/)
- [Cookbook Examples](https://github.com/incubaid/herolib/tree/development/cookbook)
- [AI Prompts](aiprompts/starter/0_start_here.md)
