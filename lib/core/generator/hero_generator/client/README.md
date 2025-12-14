# Client Generator

Generates V modules for clients with factory pattern and Redis persistence.

## Generated Files

- `{name}_factory_.v` - Factory pattern with new/get/set/delete/exists/list
- `{name}_model.v` - Configuration struct
- `{name}_test.v` - Test file
- `README.md` - Documentation
- `CLAUDE.md` - AI instructions

## Features

- **Factory pattern**: new, get, set, delete, exists, list operations
- **Redis persistence**: Session-based caching via herolib context
- **No lifecycle management**: Clients don't have install/start/stop methods

## Usage

```bash
hero generate client -name my_client -path lib/clients/my_client
```

## Templates

Templates are in the `templates/` directory and use V's `$tmpl()` compile-time function.

