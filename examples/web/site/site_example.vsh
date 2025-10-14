#!/usr/bin/env -S v -n -w -gc none -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.develop.gittools
import incubaid.herolib.web.site
import incubaid.herolib.core.playcmds

// Example 1: Load site configuration from a Git repository
println('=== Example 1: Loading from Git Repository ===')
url := 'https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/ebooks/tech'

mysitepath := gittools.path(
	git_url: url
	git_pull: true
	// git_reset: true  // Uncomment to reset to latest
)!

// Process all HeroScript files in the repository
playcmds.run(heroscript_path: mysitepath.path)!

// Get the configured site
mut mysite := site.get(name: 'tfgrid_tech')!
println('Site loaded: ${mysite.siteconfig.name}')
println('Title: ${mysite.siteconfig.title}')
println('Pages: ${mysite.pages.len}')
println('Sections: ${mysite.sections.len}')
println('')

// Example 2: Inspect site structure
println('=== Example 2: Site Structure ===')
println('Sections:')
for section in mysite.sections {
	println('  - ${section.label} (${section.name})')
}
println('')

println('Pages (first 5):')
for i, page in mysite.pages {
	if i >= 5 {
		break
	}
	println('  - ${page.name}: ${page.description}')
	println('    Section: ${page.section_name}, Position: ${page.position}')
}
println('')

// Example 3: Access menu configuration
println('=== Example 3: Navigation Menu ===')
println('Menu Title: ${mysite.siteconfig.menu.title}')
println('Menu Items:')
for item in mysite.siteconfig.menu.items {
	if item.href != '' {
		println('  - ${item.label} -> ${item.href} (external)')
	} else {
		println('  - ${item.label} -> ${item.to} (internal)')
	}
}
println('')

// Example 4: Access footer configuration
println('=== Example 4: Footer Configuration ===')
println('Footer Style: ${mysite.siteconfig.footer.style}')
println('Footer Links:')
for link in mysite.siteconfig.footer.links {
	println('  ${link.title}:')
	for item in link.items {
		if item.href != '' {
			println('    - ${item.label} -> ${item.href}')
		} else {
			println('    - ${item.label} -> ${item.to}')
		}
	}
}
println('')

// Example 5: List all configured sites
println('=== Example 5: All Configured Sites ===')
all_sites := site.list()
println('Total sites: ${all_sites.len}')
for site_name in all_sites {
	println('  - ${site_name}')
}
println('')

// Example 6: Check if a site exists
println('=== Example 6: Site Existence Check ===')
if site.exists(name: 'tfgrid_tech') {
	println('Site "tfgrid_tech" exists')
} else {
	println('Site "tfgrid_tech" does not exist')
}

if site.exists(name: 'nonexistent_site') {
	println('Site "nonexistent_site" exists')
} else {
	println('Site "nonexistent_site" does not exist')
}
println('')

println('=== Example Complete ===')