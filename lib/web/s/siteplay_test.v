module site

import incubaid.herolib.core.playbook
import incubaid.herolib.ui.console
import os

// Big comprehensive HeroScript for testing
const test_heroscript = '
!!site.config
    name: "test_docs"
    title: "Test Documentation Site"
    description: "A comprehensive test documentation site"
    tagline: "Testing everything"
    favicon: "img/favicon.png"
    image: "img/test-og.png"
    copyright: "© 2024 Test Organization"
    url: "https://test.example.com"
    base_url: "/"
    url_home: "/docs"

!!site.config_meta
    title: "Test Docs - Advanced"
    image: "img/test-og-alternative.png"
    description: "Advanced test documentation"

!!site.navbar
    title: "Test Documentation"
    logo_alt: "Test Logo"
    logo_src: "img/logo.svg"
    logo_src_dark: "img/logo-dark.svg"

!!site.navbar_item
    label: "Getting Started"
    to: "intro"
    position: "left"

!!site.navbar_item
    label: "API Reference"
    to: "api"
    position: "left"

!!site.navbar_item
    label: "GitHub"
    href: "https://github.com/example/test"
    position: "right"

!!site.navbar_item
    label: "Blog"
    href: "https://blog.example.com"
    position: "right"

!!site.footer
    style: "dark"

!!site.footer_item
    title: "Documentation"
    label: "Introduction"
    to: "intro"

!!site.footer_item
    title: "Documentation"
    label: "Getting Started"
    to: "getting-started"

!!site.footer_item
    title: "Documentation"
    label: "Advanced Topics"
    to: "advanced"

!!site.footer_item
    title: "Community"
    label: "Discord"
    href: "https://discord.gg/example"

!!site.footer_item
    title: "Community"
    label: "Twitter"
    href: "https://twitter.com/example"

!!site.footer_item
    title: "Legal"
    label: "Privacy Policy"
    href: "https://example.com/privacy"

!!site.footer_item
    title: "Legal"
    label: "Terms of Service"
    href: "https://example.com/terms"

!!site.announcement
    id: "v2-release"
    content: "🎉 Version 2.0 is now available! Check out the new features."
    background_color: "#1a472a"
    text_color: "#fff"
    is_closeable: true

!!site.page_category
    name: "getting_started"
    label: "Getting Started"
    position: 10

!!site.page src: "guides:introduction"
    title: "Introduction to Test Docs"
    description: "Learn what this project is about"

!!site.page src: "installation"
    title: "Installation Guide"
    description: "How to install and setup"

!!site.page src: "quick_start"
    title: "Quick Start"
    description: "5 minute quick start guide"

!!site.page_category
    name: "concepts"
    label: "Core Concepts"
    position: 20

!!site.page src: "concepts:architecture"
    title: "Architecture Overview"
    description: "Understanding the system architecture"

!!site.page src: "components"
    title: "Key Components"
    description: "Learn about the main components"

!!site.page src: "workflow"
    title: "Typical Workflow"
    description: "How to use the system"

!!site.page_category
    name: "api"
    label: "API Reference"
    position: 30

!!site.page src: "api:rest"
    title: "REST API"
    description: "Complete REST API reference"

!!site.page src: "graphql"
    title: "GraphQL API"
    description: "GraphQL API documentation"

!!site.page src: "webhooks"
    title: "Webhooks"
    description: "Webhook configuration and examples"

!!site.page_category
    name: "advanced"
    label: "Advanced Topics"
    position: 40

!!site.page src: "advanced:performance"
    title: "Performance Optimization"
    description: "Tips for optimal performance"

!!site.page src: "scaling"
    title: "Scaling Guide"
    description: "How to scale the system"

!!site.page src: "security"
    title: "Security Best Practices"
    description: "Security considerations and best practices"

!!site.page src: "troubleshooting"
    title: "Troubleshooting"
    description: "Common issues and solutions"
    draft: false

!!site.publish
    path: "/var/www/html/docs"
    ssh_name: "production-server"

!!site.publish_dev
    path: "/tmp/docs-dev"
'

fn test_site1() ! {
	console.print_header('Site Module Comprehensive Test')
	console.lf()

	// ========================================================
	// TEST 1: Create playbook from heroscript
	// ========================================================
	console.print_item('TEST 1: Creating playbook from HeroScript')
	mut plbook := playbook.new(text: test_heroscript)!
	console.print_green('✓ Playbook created successfully')
	console.lf()

	// ========================================================
	// TEST 2: Process site configuration
	// ========================================================
	console.print_item('TEST 2: Processing site.play()')
	site.play(mut plbook)!
	console.print_green('✓ Site configuration processed successfully')
	console.lf()

	// ========================================================
	// TEST 3: Retrieve site and validate
	// ========================================================
	console.print_item('TEST 3: Retrieving configured site')
	mut test_site := site.get(name: 'test_docs')!
	console.print_green('✓ Site retrieved successfully')
	console.lf()

	// ========================================================
	// TEST 4: Validate SiteConfig
	// ========================================================
	console.print_header('Validating SiteConfig')
	mut config := &test_site.siteconfig

	help_test_string('Site Name', config.name, 'test_docs')
	help_test_string('Site Title', config.title, 'Test Documentation Site')
	help_test_string('Site Description', config.description, 'A comprehensive test documentation site')
	help_test_string('Site Tagline', config.tagline, 'Testing everything')
	help_test_string('Copyright', config.copyright, '© 2024 Test Organization')
	help_test_string('Base URL', config.base_url, '/')
	help_test_string('URL Home', config.url_home, '/docs')

	help_test_string('Meta Title', config.meta_title, 'Test Docs - Advanced')
	help_test_string('Meta Image', config.meta_image, 'img/test-og-alternative.png')

	assert config.build_dest.len == 1, 'Should have 1 production build destination'
	console.print_green('✓ Production build dest: ${config.build_dest[0].path}')

	assert config.build_dest_dev.len == 1, 'Should have 1 dev build destination'
	console.print_green('✓ Dev build dest: ${config.build_dest_dev[0].path}')

	console.lf()

	// ========================================================
	// TEST 5: Validate Menu Configuration
	// ========================================================
	console.print_header('Validating Menu Configuration')
	mut menu := config.menu

	help_test_string('Menu Title', menu.title, 'Test Documentation')
	help_test_string('Menu Logo Alt', menu.logo_alt, 'Test Logo')
	help_test_string('Menu Logo Src', menu.logo_src, 'img/logo.svg')
	help_test_string('Menu Logo Src Dark', menu.logo_src_dark, 'img/logo-dark.svg')

	assert menu.items.len == 4, 'Should have 4 navbar items, got ${menu.items.len}'
	console.print_green('✓ Menu has 4 navbar items')

	// Validate navbar items
	help_test_navbar_item(menu.items[0], 'Getting Started', 'intro', '', 'left')
	help_test_navbar_item(menu.items[1], 'API Reference', 'api', '', 'left')
	help_test_navbar_item(menu.items[2], 'GitHub', '', 'https://github.com/example/test',
		'right')
	help_test_navbar_item(menu.items[3], 'Blog', '', 'https://blog.example.com', 'right')

	console.lf()

	// ========================================================
	// TEST 6: Validate Footer Configuration
	// ========================================================
	console.print_header('Validating Footer Configuration')
	mut footer := config.footer

	help_test_string('Footer Style', footer.style, 'dark')
	assert footer.links.len == 3, 'Should have 3 footer link groups, got ${footer.links.len}'
	console.print_green('✓ Footer has 3 link groups')

	// Validate footer structure
	for link_group in footer.links {
		console.print_item('Footer group: "${link_group.title}" has ${link_group.items.len} items')
	}

	// Detailed footer validation
	mut doc_links := footer.links.filter(it.title == 'Documentation')
	assert doc_links.len == 1, 'Should have 1 Documentation link group'
	assert doc_links[0].items.len == 3, 'Documentation should have 3 items'
	console.print_green('✓ Documentation footer: 3 items')

	mut community_links := footer.links.filter(it.title == 'Community')
	assert community_links.len == 1, 'Should have 1 Community link group'
	assert community_links[0].items.len == 2, 'Community should have 2 items'
	console.print_green('✓ Community footer: 2 items')

	mut legal_links := footer.links.filter(it.title == 'Legal')
	assert legal_links.len == 1, 'Should have 1 Legal link group'
	assert legal_links[0].items.len == 2, 'Legal should have 2 items'
	console.print_green('✓ Legal footer: 2 items')

	console.lf()

	// ========================================================
	// TEST 7: Validate Announcement Bar
	// ========================================================
	console.print_header('Validating Announcement Bar')
	mut announcement := config.announcement

	help_test_string('Announcement ID', announcement.id, 'v2-release')
	help_test_string('Announcement Content', announcement.content, '🎉 Version 2.0 is now available! Check out the new features.')
	help_test_string('Announcement BG Color', announcement.background_color, '#1a472a')
	help_test_string('Announcement Text Color', announcement.text_color, '#fff')
	assert announcement.is_closeable == true, 'Announcement should be closeable'
	console.print_green('✓ Announcement bar configured correctly')

	console.lf()

	// ========================================================
	// TEST 8: Validate Pages
	// ========================================================
	console.print_header('Validating Pages')
	mut pages := test_site.pages.clone()

	assert pages.len == 13, 'Should have 13 pages, got ${pages.len}'
	console.print_green('✓ Total pages: ${pages.len}')

	// List and validate pages
	mut page_ids := pages.keys()
	page_ids.sort()

	for page_id in page_ids {
		mut page := pages[page_id]
		console.print_debug('  Page: ${page_id} - "${page.title}"')
	}

	// Validate specific pages
	assert 'guides:introduction' in pages, 'guides:introduction page not found'
	console.print_green('✓ Found guides:introduction')

	assert 'concepts:architecture' in pages, 'concepts:architecture page not found'
	console.print_green('✓ Found concepts:architecture')

	assert 'api:rest' in pages, 'api:rest page not found'
	console.print_green('✓ Found api:rest')

	console.lf()

	// ========================================================
	// TEST 9: Validate Navigation Structure
	// ========================================================
	console.print_header('Validating Navigation Structure')
	mut sidebar := unsafe { test_site.nav.my_sidebar.clone() }

	console.print_item('Navigation sidebar has ${sidebar.len} items')

	// Count categories
	mut category_count := 0
	mut doc_count := 0

	for item in sidebar {
		match item {
			site.NavCat {
				category_count++
				console.print_debug('  Category: "${item.label}" with ${item.items.len} sub-items')
			}
			site.NavDoc {
				doc_count++
				console.print_debug('  Doc: "${item.label}" (${item.id})')
			}
			site.NavLink {
				console.print_debug('  Link: "${item.label}" -> ${item.href}')
			}
		}
	}

	assert category_count == 4, 'Should have 4 categories, got ${category_count}'
	console.print_green('✓ Navigation has 4 categories')

	// Validate category structure
	for item in sidebar {
		match item {
			site.NavCat {
				console.print_item('Category: "${item.label}"')
				println('    Collapsible: ${item.collapsible}, Collapsed: ${item.collapsed}')
				println('    Items: ${item.items.len}')

				// Validate sub-items
				for sub_item in item.items {
					match sub_item {
						site.NavDoc {
							println('      - ${sub_item.label} (${sub_item.id})')
						}
						else {
							println('      - Unexpected item type')
						}
					}
				}
			}
			else {}
		}
	}

	console.lf()

	// ========================================================
	// TEST 10: Validate Site Factory
	// ========================================================
	console.print_header('Validating Site Factory')

	mut all_sites := site.list()
	console.print_item('Total sites registered: ${all_sites.len}')
	for site_name in all_sites {
		console.print_debug('  - ${site_name}')
	}

	assert all_sites.contains('test_docs'), 'test_docs should be in sites list'
	console.print_green('✓ test_docs found in factory')

	assert site.exists(name: 'test_docs'), 'test_docs should exist'
	console.print_green('✓ test_docs verified to exist')

	console.lf()

	// ========================================================
	// FINAL SUMMARY
	// ========================================================
	console.print_header('Test Summary')
	console.print_green('✓ All tests passed successfully!')
	console.print_item('Site Name: ${config.name}')
	console.print_item('Pages: ${pages.len}')
	console.print_item('Navigation Categories: ${category_count}')
	console.print_item('Navbar Items: ${menu.items.len}')
	console.print_item('Footer Groups: ${footer.links.len}')
	console.print_item('Announcement: Active')
	console.print_item('Build Destinations: ${config.build_dest.len} prod, ${config.build_dest_dev.len} dev')

	console.lf()
	console.print_green('All validations completed successfully!')
}

// ============================================================
// Helper Functions for Testing
// ============================================================

fn help_test_string(label string, actual string, expected string) {
	if actual == expected {
		console.print_green('✓ ${label}: "${actual}"')
	} else {
		console.print_stderr('✗ ${label}: expected "${expected}", got "${actual}"')
		panic('Test failed: ${label}')
	}
}

fn help_test_navbar_item(item MenuItem, label string, to string, href string, position string) {
	assert item.label == label, 'Expected label "${label}", got "${item.label}"'
	assert item.to == to, 'Expected to "${to}", got "${item.to}"'
	assert item.href == href, 'Expected href "${href}", got "${item.href}"'
	assert item.position == position, 'Expected position "${position}", got "${item.position}"'
	console.print_green('✓ Navbar item: "${label}"')
}
