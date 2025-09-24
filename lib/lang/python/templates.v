module python

import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import os

@[params]
pub struct TemplateArgs {
pub mut:
	name             string = 'herolib-python-project'
	version          string = '0.1.0'
	description      string = 'A Python project managed by Herolib'
	python_version   string = '3.11'
	dependencies     []string
	dev_dependencies []string
	scripts          map[string]string
}

// generate_pyproject_toml creates a pyproject.toml file from template
pub fn (mut py PythonEnv) generate_pyproject_toml(args TemplateArgs) ! {
	template_path := '${@VMODROOT}/lang/python/templates/pyproject.toml'
	mut template_content := os.read_file(template_path)!

	// Format dependencies
	mut deps := []string{}
	for dep in args.dependencies {
		deps << '    "${dep}",'
	}
	dependencies_str := deps.join('\n')

	// Format dev dependencies
	mut dev_deps := []string{}
	for dep in args.dev_dependencies {
		dev_deps << '    "${dep}",'
	}
	dev_dependencies_str := dev_deps.join('\n')

	// Format scripts
	mut scripts := []string{}
	for name, command in args.scripts {
		scripts << '${name} = "${command}"'
	}
	scripts_str := scripts.join('\n')

	// Replace template variables
	content := template_content
		.replace('@{name}', args.name)
		.replace('@{version}', args.version)
		.replace('@{description}', args.description)
		.replace('@{python_version}', args.python_version)
		.replace('@{dependencies}', dependencies_str)
		.replace('@{dev_dependencies}', dev_dependencies_str)
		.replace('@{scripts}', scripts_str)

	// Write to project directory
	mut pyproject_file := py.path.file_get_new('pyproject.toml')!
	pyproject_file.write(content)!
}

// generate_env_script creates an env.sh script from template
pub fn (mut py PythonEnv) generate_env_script(args TemplateArgs) ! {
	template_path := '${@VMODROOT}/lang/python/templates/env.sh'
	mut template_content := os.read_file(template_path)!

	content := template_content
		.replace('@{python_version}', args.python_version)

	mut env_file := py.path.file_get_new('env.sh')!
	env_file.write(content)!
	os.chmod(env_file.path, 0o755)!
}

// generate_install_script creates an install.sh script from template
pub fn (mut py PythonEnv) generate_install_script(args TemplateArgs) ! {
	template_path := '${@VMODROOT}/lang/python/templates/install.sh'
	mut template_content := os.read_file(template_path)!

	content := template_content
		.replace('@{name}', args.name)
		.replace('@{python_version}', args.python_version)

	mut install_file := py.path.file_get_new('install.sh')!
	install_file.write(content)!
	os.chmod(install_file.path, 0o755)!
}

// generate_readme creates a basic README.md file
pub fn (mut py PythonEnv) generate_readme(args TemplateArgs) ! {
	readme_content := '# ${args.name}

${args.description}

## Installation

Run the installation script:

```bash
./install.sh
```

Or manually:

```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create and activate environment
uv venv --python ${args.python_version}
source .venv/bin/activate

# Install dependencies
uv sync
```

## Usage

Activate the environment:

```bash
source env.sh
```

## Dependencies

### Production
${if args.dependencies.len > 0 {
		'- ' + args.dependencies.join('\n- ')
	} else {
		'None'
	}}

### Development
${if args.dev_dependencies.len > 0 {
		'- ' + args.dev_dependencies.join('\n- ')
	} else {
		'None'
	}}
'

	mut readme_file := py.path.file_get_new('README.md')!
	readme_file.write(readme_content)!
}

// generate_all_templates creates all template files for the Python environment
pub fn (mut py PythonEnv) generate_all_templates(args TemplateArgs) ! {
	py.generate_pyproject_toml(args)!
	py.generate_env_script(args)!
	py.generate_install_script(args)!
	py.generate_readme(args)!
}
