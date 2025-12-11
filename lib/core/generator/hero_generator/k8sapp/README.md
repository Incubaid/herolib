# K8sapp Generator

Generates V modules for Kubernetes applications with deployment templates.

## Generated Files

- `{name}_factory_.v` - Factory pattern with new/get/set/delete/exists/list
- `{name}_actions.v` - Kubernetes methods: deploy, destroy
- `{name}_model.v` - Configuration struct
- `{name}_test.v` - Test file
- `README.md` - Documentation
- `CLAUDE.md` - AI instructions
- `templates/deployment.yaml` - Kubernetes deployment template

## Features

- **Kubernetes deployment**: deploy and destroy operations
- **Deployment templates**: YAML templates for K8s resources
- **Factory pattern**: new, get, set, delete, exists, list operations
- **Redis persistence**: Session-based caching via herolib context

## Usage

```bash
hero generate k8sapp -name my_k8app -path lib/k8_apps/my_k8app
```

## Templates

Templates are in the `templates/` directory and use V's `$tmpl()` compile-time function.
The generated module also creates a `templates/` directory with Kubernetes YAML templates.

