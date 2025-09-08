# Herolib

Herolib is an opinionated library primarily used by ThreeFold to automate cloud environments. It provides a comprehensive set of tools and utilities for cloud automation, git operations, documentation building, and more.

[![Build on Linux & Run tests](https://github.com/freeflowuniverse/herolib/actions/workflows/test.yml/badge.svg)](https://github.com/freeflowuniverse/herolib/actions/workflows/test.yml)
[![Deploy Documentation to Pages](https://github.com/freeflowuniverse/herolib/actions/workflows/documentation.yml/badge.svg)](https://github.com/freeflowuniverse/herolib/actions/workflows/documentation.yml)

> [Complete Documentation](https://freeflowuniverse.github.io/herolib/)

## Installation

### For Users

The Hero tool can be installed with a single command:

```bash
curl https://raw.githubusercontent.com/freeflowuniverse/herolib/refs/heads/development/install_hero.sh | bash
```

Hero will be installed in:
- `/usr/local/bin` for Linux
- `~/hero/bin` for macOS

After installation on macOS, you may need to do source see below or restart your terminal to ensure the `hero` command is available:

```bash
source ~/.zprofile
```

The Hero tool can be used to work with git, build documentation, interact with Hero AI, and more.

### For Developers

For development purposes, use the automated installation script:

```bash
curl 'https://raw.githubusercontent.com/freeflowuniverse/herolib/refs/heads/development/install_v.sh' > /tmp/install_v.sh
bash /tmp/install_v.sh --analyzer --herolib 

#do not forget to do the following this makes sure vtest and vrun exists
cd ~/code/github/freeflowuniverse/herolib
v install_herolib.vsh

# IMPORTANT: Start a new shell after installation for paths to be set correctly

```

#### Installation Options

```
V & HeroLib Installer Script

Usage: ~/code/github/freeflowuniverse/herolib/install_v.sh [options]

Options:
  -h, --help     Show this help message
  --reset        Force reinstallation of V
  --remove       Remove V installation and exit
  --analyzer     Install/update v-analyzer
  --herolib      Install our herolib

Examples:
  ~/code/github/freeflowuniverse/herolib/install_v.sh
  ~/code/github/freeflowuniverse/herolib/install_v.sh --reset
  ~/code/github/freeflowuniverse/herolib/install_v.sh --remove
  ~/code/github/freeflowuniverse/herolib/install_v.sh --analyzer
  ~/code/github/freeflowuniverse/herolib/install_v.sh --herolib
  ~/code/github/freeflowuniverse/herolib/install_v.sh --reset --analyzer # Fresh install of both
```

## Features

Herolib provides a wide range of functionality:

- Cloud automation tools
- Git operations and management
  ### Offline Mode for Git Operations

  Herolib now supports an `offline` mode for Git operations, which prevents automatic fetching from remote repositories. This can be useful in environments with limited or no internet connectivity, or when you want to avoid network calls during development or testing.

  To enable offline mode:

  -   **Via `GitStructureConfig`**: Set the `offline` field to `true` in the `GitStructureConfig` struct.
  -   **Via `GitStructureArgsNew`**: When creating a new `GitStructure` instance using `gittools.new()`, set the `offline` parameter to `true`.
  -   **Via Environment Variable**: Set the `OFFLINE` environment variable to any value (e.g., `export OFFLINE=true`).

  When offline mode is active, `git fetch --all` operations will be skipped, and a debug message "fetch skipped (offline)" will be printed.
- Documentation building
- Hero AI integration
- System management utilities
- And much more

Check the [cookbook](https://github.com/freeflowuniverse/herolib/tree/development/cookbook) for examples and use cases.

## Testing

Running tests is an essential part of development. To run the basic tests:

```bash
# Run all basic tests
~/code/github/freeflowuniverse/herolib/test_basic.vsh

# Run tests for a specific module
vtest ~/code/github/freeflowuniverse/herolib/lib/osal/package_test.v

# Run tests for an entire directory
vtest ~/code/github/freeflowuniverse/herolib/lib/osal
```

The `vtest` command is an alias for testing functionality.

## Contributing

We welcome contributions to Herolib! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for detailed information on:

- Setting up your development environment
- Understanding the repository structure
- Following our development workflow
- Making pull requests
- CI/CD processes

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

2. Comment out the following lines (around line 612-626):
   ```c
   /* half precision math functions */
   // extern _Float16 __fabsf16(_Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __hypotf16(_Float16, _Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __sqrtf16(_Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __ceilf16(_Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __floorf16(_Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __rintf16(_Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __roundf16(_Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __truncf16(_Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __copysignf16(_Float16, _Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __nextafterf16(_Float16, _Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __fmaxf16(_Float16, _Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __fminf16(_Float16, _Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   // extern _Float16 __fmaf16(_Float16, _Float16, _Float16) __API_AVAILABLE(macos(15.0), ios(18.0), watchos(11.0), tvos(18.0));
   ```

3. Save the file and try compiling again.

## Additional Resources

- [Complete Documentation](https://freeflowuniverse.github.io/herolib/)
- [Cookbook Examples](https://github.com/freeflowuniverse/herolib/tree/development/cookbook)
- [AI Prompts](aiprompts/starter/0_start_here.md)

## Generating Documentation

To generate documentation locally:

```bash
cd ~/code/github/freeflowuniverse/herolib
bash doc.sh
```


<!-- Security scan triggered at 2025-09-02 01:58:41 -->