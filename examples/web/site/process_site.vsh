#!/usr/bin/env -S v -n -w -gc none -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.playbook
import incubaid.herolib.web.site
import incubaid.herolib.ui.console
import os

// Process a site configuration from HeroScript files

println(console.color_fg(.green) + '=== Site Configuration Processor ===' + console.reset())

// Get directory from command line or use default
mut config_dir := './docs'
if os.args.len > 1 {
	config_dir = os.args[1]
}

if !os.exists(config_dir) {
	console.print_stderr('Error: Directory not found: ${config_dir}')
	exit(1)
}

console.print_item('Processing HeroScript files from: ${config_dir}')

// Find all heroscript files
mut heroscript_files := []string{}
entries := os.ls(config_dir) or {
	console.print_stderr('Error reading directory: ${err}')
	exit(1)
}

for entry in entries {
	if entry.ends_with('.heroscript') {
		heroscript_files << entry
	}
}

// Sort files (to ensure numeric prefix order)
heroscript_files.sort()

if heroscript_files.len == 0 {
	console.print_stderr('No .heroscript files found in ${config_dir}')
	exit(1)
}

console.print_item('Found ${heroscript_files.len} HeroScript file(s):')
for file in heroscript_files {
	console.print_item('  - ${file}')
}

// Process each file
mut site_names := []string{}
for file in heroscript_files {
	full_path := os.join_path(config_dir, file)
	console.print_lf(1)
	console.print_header('Processing: ${file}')

	mut plbook := playbook.new(path: full_path) or {
		console.print_stderr('Error loading ${file}: ${err}')
		continue
	}

	site.play(mut plbook) or {
		console.print_stderr('Error processing ${file}: ${err}')
		continue
	}
}

// Get all configured sites
site_names = site.list()

if site_names.len == 0 {
	console.print_stderr('No sites were configured')
	exit(1)
}

console.print_lf(2)
console.print_green('=== Configuration Complete ===')

// Display configured sites
for site_name in site_names {
	mut configured_site := site.get(name: site_name) or { continue }

	console.print_header('Site: ${site_name}')
	console.print_item('Title: ${configured_site.siteconfig.title}')
	console.print_item('Pages: ${configured_site.pages.len}')
	console.print_item('Description: ${configured_site.siteconfig.description}')

	// Show pages organized by category
	if configured_site.nav.my_sidebar.len > 0 {
		console.print_item('Navigation structure:')
		for nav_item in configured_site.nav.my_sidebar {
			match nav_item {
				site.NavDoc {
					console.print_item('  - [Page] ${nav_item.label}')
				}
				site.NavCat {
					console.print_item('  - [Category] ${nav_item.label}')
					for sub_item in nav_item.items {
						match sub_item {
							site.NavDoc {
								console.print_item('    - ${sub_item.label}')
							}
							else {}
						}
					}
				}
				else {}
			}
		}
	}

	console.print_lf(1)
}

println(console.color_fg(.green) + '✓ Site configuration ready for deployment' + console.reset())
