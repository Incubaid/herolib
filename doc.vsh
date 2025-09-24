#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import os

abs_dir_of_script := dir(@FILE)

// Format code
println('Formatting code...')
if os.system('v fmt -w ${abs_dir_of_script}/examples') != 0 {
	eprintln('Warning: Failed to format examples')
	exit(1)
}

if os.system('v fmt -w ${abs_dir_of_script}/lib') != 0 {
	eprintln('Warning: Failed to format herolib')
	exit(1)
}

// Clean existing docs
println('Cleaning existing documentation...')

os.rmdir_all('_docs') or {}
os.rmdir_all('docs') or {}
os.rmdir_all('vdocs') or {}

herolib_path := os.join_path(abs_dir_of_script, 'lib')
os.chdir(herolib_path) or { panic('Failed to change directory to herolib: ${err}') }

os.mkdir_all('_docs') or {}
os.mkdir_all('docs') or {}
os.mkdir_all('vdocs') or {}

// Generate HTML documentation
println('Generating HTML documentation...')
if os.system('v doc -m -f html . -readme -comments -no-timestamp -o ../docs') != 0 {
	panic('Failed to generate HTML documentation')
}

if os.system('v doc -m -f md . -no-color  -o ../vdocs/') != 0 {
	panic('Failed to generate Hero markdown documentation')
}

os.chdir(abs_dir_of_script) or { panic('Failed to change directory to abs_dir_of_script: ${err}') }

// Generate Markdown documentation
println('Generating Markdown documentation...')

// if os.system('v doc -m -no-color -f md -o ../vdocs/v/') != 0 {
//     panic('Failed to generate V markdown documentation')
// }

// if os.system('v doc -m -no-color -f md . -o vdocs/') != 0 {
//     panic('Failed to generate Hero markdown documentation')
// }

// Open documentation in browser on non-Linux systems
$if !linux {
	os.chdir(abs_dir_of_script) or { panic('Failed to change directory: ${err}') }
	if os.system('open docs/index.html') != 0 {
		eprintln('Warning: Failed to open documentation in browser')
	}
}

// Create Jekyll required files
println('Creating Jekyll files...')
os.mkdir_all('docs/assets/css') or {}

// Create style.scss
style_content := '---\n---\n\n@import "{{ site.theme }}";'
os.write_file('docs/assets/css/style.scss', style_content) or {
	panic('Failed to create style.scss: ${err}')
}

// Create _config.yml
config_content := 'title: HeroLib Documentation
description: Documentation for the HeroLib project
theme: jekyll-theme-primer
baseurl: /herolib

exclude:
  - Gemfile
  - Gemfile.lock
  - node_modules
  - vendor/bundle/
  - vendor/cache/
  - vendor/gems/
  - vendor/ruby/'

os.write_file('docs/_config.yml', config_content) or {
	panic('Failed to create _config.yml: ${err}')
}

println('Documentation generation completed successfully!')
