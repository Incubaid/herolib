# Hero Generator Module

Code generator for creating V modules in the HeroLib context.

## Architecture

```
lib/core/generator/
└── hero_generator/           # Main generator module
    ├── model.v               # Types: Cat, ModuleMeta, GenerateArgs
    ├── generator.v           # prepare_meta() - prepares metadata
    ├── heroscript.v          # args_get(), create_heroscript()
    ├── interactive.v         # prompt_interactive() - interactive mode
    ├── scanner.v             # scan_modules(), register_in_factory()
    ├── installer/            # Installer-specific generator
    │   ├── generate.v        # generate_exec()
    │   └── templates/        # Installer templates
    ├── client/               # Client-specific generator
    │   ├── generate.v        # generate_exec()
    │   └── templates/        # Client templates
    └── k8sapp/               # K8s app-specific generator
        ├── generate.v        # generate_exec()
        └── templates/        # K8sapp templates
```

## Flow

```
CLI (herocmds/generator.v)
    │
    ├── Non-interactive mode:
    │   1. Parse flags
    │   2. hero_generator.prepare_meta() → creates .heroscript, returns ModuleMeta
    │   3. run_generator() → routes to type-specific generator
    │
    └── Interactive mode:
        1. hero_generator.prompt_interactive() → prompts user, returns ModuleMeta
        2. run_generator() → routes to type-specific generator

run_generator(meta, reset):
    match meta.cat:
        .installer → installer.generate_exec()
        .client    → client.generate_exec()
        .k8sapp    → k8sapp.generate_exec()

    register_in_factory(meta)  # Auto-registers module in factory.v
```

## Usage

```bash
# Generate an installer module
hero generate installer -name my_installer -path lib/installers/my_installer

# Generate a client module
hero generate client -name my_client -path lib/clients/my_client

# Generate a k8s app module
hero generate k8sapp -name my_k8app -path lib/k8_apps/my_k8app

# Interactive mode
hero generate installer -path lib/installers/my_installer -i

# Scan and regenerate all modules
hero generate scan -g
```

## Module Types

### Installer
- Lifecycle management: install, start, stop, restart, destroy
- Startup manager integration
- Optional templates for configuration files

### Client
- Factory pattern with Redis-based persistence
- CRUD operations: new, get, set, delete, exists, list
- No lifecycle management

### K8sapp
- Kubernetes deployment templates
- Deploy/destroy operations
- Always includes templates directory

## Automatic Registration

When a module is generated, it is automatically registered in `lib/core/playcmds/factory.v`:
1. An import statement is added
2. A `module.play(mut plbook)!` call is inserted before the empty check

This allows the module to be immediately usable via HeroScript without manual registration.
