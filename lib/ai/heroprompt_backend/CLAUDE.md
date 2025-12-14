# HeropromptBackend Module

This is a HeroLib client module for HeropromptBackend.

## Important Commands

```bash
# Run tests for this module
v -enable-globals test .

# Format code
v -enable-globals fmt -w .

# Generate/regenerate module files (from herolib root)
hero generate client -path lib/clients/heroprompt_backend
```

## Code Style

- Use V language idioms and conventions
- All public functions must have documentation comments
- Use `!` suffix for functions that can fail (return Result type)
- Use `$[heap]` attribute for structs that need heap allocation
- Use `$[params]` for function parameter structs
- Configuration secrets should use `$[secret]` attribute

## Module Structure

```
heroprompt_backend/
├── heroprompt_backend_model.v      # Data model and config struct
├── heroprompt_backend_factory_.v   # Factory pattern (new, get, set, delete, list)
├── heroprompt_backend_test.v       # Unit tests
├── README.md                 # Documentation
└── CLAUDE.md                 # This file
```

## Key Patterns

### Factory Pattern
- Use `new(name: 'myname')!` to create a new instance
- Use `get(name: 'myname')!` to retrieve an existing instance
- Use `set(obj)!` to store an instance
- Use `delete(name: 'myname')!` to remove an instance
- Use `list()!` to get all instances
- Use `exists(name: 'myname')!` to check existence

### HeroScript Integration
- Use `play(heroscript: script)!` to execute HeroScript actions
- Use `heroscript_loads(script)!` to parse config from HeroScript
- Actions are prefixed with `!!heroprompt_backend.`

## Testing

When writing tests:
1. Use `testsuite_begin()` and `testsuite_end()` for setup/teardown
2. Test names should be descriptive: `test_<function>_<scenario>`
3. Clean up test data in `testsuite_end()`
4. Use `base.context(reload: true)!` to reset context between tests

## Common Issues

- Ensure Redis is running for configuration storage
- Check `~/hero/var/` for cached data

## Related Files

- `lib/core/base/context.v` - Base context and session management
- `lib/core/base/factory.v` - Factory pattern base implementation

