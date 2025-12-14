# Installer Generator

Generates V modules for installers with lifecycle management.

## Generated Files

- `{name}_factory_.v` - Factory pattern with new/get/set/delete/exists/list
- `{name}_actions.v` - Lifecycle methods: install, start, stop, restart, destroy
- `{name}_model.v` - Configuration struct
- `{name}_test.v` - Test file
- `README.md` - Documentation
- `CLAUDE.md` - AI instructions

## Features

- **Lifecycle management**: install, start, stop, restart, destroy
- **Startup manager integration**: Optional systemd/launchd service management
- **Configuration templates**: Optional templates directory for config files
- **Redis persistence**: Factory pattern with session-based caching

## Usage

```bash
hero generate installer -name my_app -path lib/installers/my_app
```

## Templates

Templates are in the `templates/` directory and use V's `$tmpl()` compile-time function.

