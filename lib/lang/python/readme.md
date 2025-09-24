# Python Environment Management with UV

This module provides modern Python environment management using `uv` - a fast Python package installer and resolver written in Rust.

## Features

- **Modern Tooling**: Uses `uv` instead of legacy pip for fast package management
- **Template-Based**: Generates `pyproject.toml`, `env.sh`, and `install.sh` from templates
- **No Database Dependencies**: Relies on Python's native package management instead of manual state tracking
- **Backward Compatible**: Legacy `pip()` methods still work but use `uv` under the hood
- **Project-Based**: Each environment is a proper Python project with `pyproject.toml`

## Quick Start

```v
import freeflowuniverse.herolib.lang.python

// Create a new Python environment
py := python.new(
    name: 'my_project'
    dependencies: ['requests', 'click', 'pydantic']
    dev_dependencies: ['pytest', 'black', 'mypy']
    python_version: '3.11'
)!

// Add more dependencies
py.add_dependencies(['fastapi'], false)! // production dependency
py.add_dependencies(['pytest-asyncio'], true)! // dev dependency

// Execute Python code
result := py.exec(cmd: '''
import requests
response = requests.get("https://api.github.com")
print("==RESULT==")
print(response.status_code)
''')!

println('Status code: ${result}')
```

## Environment Structure

Each Python environment creates:

```
~/hero/python/{name}/
├── .venv/              # Virtual environment (created by uv)
├── pyproject.toml      # Project configuration
├── uv.lock            # Dependency lock file
├── env.sh             # Environment activation script
├── install.sh         # Installation script
└── README.md          # Project documentation
```

## API Reference

### Creating Environments

```v
// Basic environment
py := python.new()! // Creates 'default' environment

// Custom environment with dependencies
py := python.new(
    name: 'web_scraper'
    dependencies: ['requests', 'beautifulsoup4', 'lxml']
    dev_dependencies: ['pytest', 'black']
    python_version: '3.11'
    description: 'Web scraping project'
    reset: true // Force recreation
)!
```

### Package Management

```v
// Add production dependencies
py.add_dependencies(['numpy', 'pandas'], false)!

// Add development dependencies  
py.add_dependencies(['jupyter', 'matplotlib'], true)!

// Remove dependencies
py.remove_dependencies(['old_package'], false)!

// Legacy methods (still work)
py.pip('requests,click')! // Comma-separated
py.pip_uninstall('old_package')!

// Update all dependencies
py.update()!

// Sync dependencies (install from pyproject.toml)
py.sync()!
```

### Environment Information

```v
// Check if environment exists
if py.exists() {
    println('Environment is ready')
}

// List installed packages
packages := py.list_packages()!
for package in packages {
    println(package)
}
```

### Freeze/Export Functionality

```v
// Export current environment
requirements := py.freeze()!
py.freeze_to_file('requirements.txt')!

// Export with exact versions (from uv.lock)
lock_content := py.export_lock()!
py.export_lock_to_file('requirements-lock.txt')!

// Install from requirements
py.install_from_requirements('requirements.txt')!

// Restore exact environment from lock
py.restore_from_lock()!
```

### Shell Access

```v
// Open interactive shell in environment
py.shell()!

// Open Python REPL
py.python_shell()!

// Open IPython (if available)
py.ipython_shell()!

// Run Python script
result := py.run_script('my_script.py')!

// Run any command in environment
result := py.run('python -m pytest')!

// Run uv commands
result := py.uv_run('add --dev mypy')!
```

### Python Code Execution

```v
// Execute Python code with result capture
result := py.exec(
    cmd: '''
import json
data = {"hello": "world"}
print("==RESULT==")
print(json.dumps(data))
'''
)!

// Execute with custom delimiters
result := py.exec(
    cmd: 'print("Hello World")'
    result_delimiter: '==OUTPUT=='
    ok_delimiter: '==DONE=='
)!

// Save script to file in environment
py.exec(
    cmd: 'print("Hello World")'
    python_script_name: 'hello'  // Saves as hello.py
)!
```

## Migration from Old Implementation

### Before (Database-based)
```v
py := python.new(name: 'test')!
py.update()! // Manual pip upgrade
py.pip('requests')! // Manual package tracking
```

### After (UV-based)
```v
py := python.new(
    name: 'test'
    dependencies: ['requests']
)! // Automatic setup with uv
```

### Key Changes

1. **No Database**: Removed all `dbfs.DB` usage
2. **Automatic Setup**: Environment initialization is automatic
3. **Modern Tools**: Uses `uv` instead of `pip`
4. **Project Files**: Generates proper Python project structure
5. **Faster**: `uv` is significantly faster than pip
6. **Better Dependency Resolution**: `uv` has superior dependency resolution

## Shell Script Usage

Each environment generates shell scripts for manual use:

```bash
# Activate environment
cd ~/hero/python/my_project
source env.sh

# Or run installation
./install.sh
```

## Requirements

- **uv**: Install with `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Python 3.11+**: Recommended Python version

## Examples

See `examples/lang/python/` for complete working examples.

## Performance Notes

- `uv` is 10-100x faster than pip for most operations
- Dependency resolution is significantly improved
- Lock files ensure reproducible environments
- No manual state tracking reduces complexity and errors