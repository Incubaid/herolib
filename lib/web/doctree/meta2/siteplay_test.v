module meta

import incubaid.herolib.core.playbook
import incubaid.herolib.ui.console

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
    content: "🎉 Version 2.0 is now available! Check out the new features."
    background_color: "#1a472a"
    text_color: "#fff"
    is_closeable: true

!!site.page_category
    path: "Getting Started"
    collapsible: true
    collapsed: false

!!site.page src: "guides:introduction"
    label: "Introduction to Test Docs"
    title: "Introduction to Test Docs"
    description: "Learn what this project is about"

!!site.page src: "installation"
    label: "Installation Guide"
    title: "Installation Guide"
    description: "How to install and setup"

!!site.page src: "quick_start"
    label: "Quick Start"
    title: "Quick Start"
    description: "5 minute quick start guide"

!!site.page_category
    path: "Core Concepts"
    collapsible: true
    collapsed: false

!!site.page src: "concepts:architecture"
    label: "Architecture Overview"
    title: "Architecture Overview"
    description: "Understanding the system architecture"

!!site.page src: "components"
    label: "Key Components"
    title: "Key Components"
    description: "Learn about the main components"

!!site.page src: "workflow"
    label: "Typical Workflow"
    title: "Typical Workflow"
    description: "How to use the system"

!!site.page_category
    path: "API Reference"
    collapsible: true
    collapsed: false

!!site.page src: "api:rest"
    label: "REST API"
    title: "REST API"
    description: "Complete REST API reference"

!!site.page src: "graphql"
    label: "GraphQL API"
    title: "GraphQL API"
    description: "GraphQL API documentation"

!!site.page src: "webhooks"
    label: "Webhooks"
    title: "Webhooks"
    description: "Webhook configuration and examples"

!!site.page_category
    path: "Advanced Topics"
    collapsible: true
    collapsed: false

!!site.page src: "advanced:performance"
    label: "Performance Optimization"
    title: "Performance Optimization"
    description: "Tips for optimal performance"

!!site.page src: "scaling"
    label: "Scaling Guide"
    title: "Scaling Guide"

!!site.page src: "security"
    label: "Security Best Practices"
    title: "Security Best Practices"
    description: "Security considerations and best practices"

!!site.page src: "troubleshooting"
    label: "Troubleshooting"
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
	console.print_header('Site Module Comprehensive Test - Part 1')
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
	play(mut plbook)!
	console.print_green('✓ Site configuration processed successfully')
	console.lf()

	// ========================================================
	// TEST 3: Retrieve site and validate
	// ========================================================
	console.print_item('TEST 3: Retrieving configured site')
	mut test_site := get(name: 'test_docs')!
	console.print_green('✓ Site retrieved successfully')
	console.lf()

	// ========================================================
	// TEST 4: Validate SiteConfig
	// ========================================================
	console.print_header('Validating SiteConfig')
	mut config := &test_site.config

	help_test_string('Site Name', config.name, 'test_docs')
	help_test_string('Site Title', config.title, 'Test Documentation Site')
	help_test_string('Site Description', config.description, 'Advanced test documentation')
	help_test_string('Site Tagline', config.tagline, 'Testing everything')
	help_test_string('Copyright', config.copyright, '© 2024 Test Organization')
	help_test_string('Base URL', config.base_url, '/')
	help_test_string('URL Home', config.url_home, '/docs')

	help_test_string('Meta Title', config.meta_title, 'Test Docs - Advanced')
	help_test_string('Meta Image', config.meta_image, 'img/test-og-alternative.png')

	assert test_site.build_dest.len == 1, 'Should have 1 production build destination'
	console.print_green('✓ Production build dest: ${test_site.build_dest[0].path}')

	assert test_site.build_dest_dev.len == 1, 'Should have 1 dev build destination'
	console.print_green('✓ Dev build dest: ${test_site.build_dest_dev[0].path}')

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
	assert test_site.announcements.len == 1, 'Should have 1 announcement, got ${test_site.announcements.len}'
	console.print_green('✓ Announcement bar present')

	mut announcement := test_site.announcements[0]

	help_test_string('Announcement Content', announcement.content, '🎉 Version 2.0 is now available! Check out the new features.')
	help_test_string('Announcement BG Color', announcement.background_color, '#1a472a')
	help_test_string('Announcement Text Color', announcement.text_color, '#fff')
	assert announcement.is_closeable == true, 'Announcement should be closeable'
	console.print_green('✓ Announcement bar configured correctly')

	console.lf()
}

fn test_site2() ! {
	console.print_header('Site Module Comprehensive Test - Part 2')
	console.lf()

	reset()

	mut plbook := playbook.new(text: test_heroscript)!
	play(mut plbook)!
	mut test_site := get(name: 'test_docs')!

	// ========================================================
	// TEST 8: Validate Pages
	// ========================================================
	console.print_header('Validating Pages')

	println(test_site)

	assert test_site.pages.len == 13, 'Should have 13 pages, got ${test_site.pages.len}'
	console.print_green('✓ Total pages: ${test_site.pages.len}')

	// List and validate pages
	for i, page in test_site.pages {
		console.print_debug('  Page ${i}: "${page.src}" - "${page.label}"')
	}

	// Validate specific pages exist by src
	mut src_exists := false
	for page in test_site.pages {
		if page.src == 'guides:introduction' {
			src_exists = true
			break
		}
	}
	assert src_exists, 'guides:introduction page not found'
	console.print_green('✓ Found guides:introduction')

	src_exists = false
	for page in test_site.pages {
		if page.src == 'concepts:architecture' {
			src_exists = true
			break
		}
	}
	assert src_exists, 'concepts:architecture page not found'
	console.print_green('✓ Found concepts:architecture')

	src_exists = false
	for page in test_site.pages {
		if page.src == 'api:rest' {
			src_exists = true
			break
		}
	}
	assert src_exists, 'api:rest page not found'
	console.print_green('✓ Found api:rest')

	console.lf()

	// ========================================================
	// TEST 9: Validate Categories
	// ========================================================
	console.print_header('Validating Categories')

	assert test_site.categories.len == 4, 'Should have 4 categories, got ${test_site.categories.len}'
	console.print_green('✓ Total categories: ${test_site.categories.len}')

	for i, category in test_site.categories {
		console.print_debug('  Category ${i}: "${category.path}" (collapsible: ${category.collapsible}, collapsed: ${category.collapsed})')
	}

	// Validate category paths
	mut category_paths := test_site.categories.map(it.path)
	assert category_paths.contains('Getting Started'), 'Missing "Getting Started" category'
	console.print_green('✓ Found "Getting Started" category')

	assert category_paths.contains('Core Concepts'), 'Missing "Core Concepts" category'
	console.print_green('✓ Found "Core Concepts" category')

	assert category_paths.contains('API Reference'), 'Missing "API Reference" category'
	console.print_green('✓ Found "API Reference" category')

	assert category_paths.contains('Advanced Topics'), 'Missing "Advanced Topics" category'
	console.print_green('✓ Found "Advanced Topics" category')

	console.lf()

	// ========================================================
	// TEST 10: Validate Navigation Structure (Sidebar)
	// ========================================================
	console.print_header('Validating Navigation Structure (Sidebar)')

	mut sidebar := test_site.sidebar()!

	console.print_item('Sidebar has ${sidebar.my_sidebar.len} root items')
	assert sidebar.my_sidebar.len > 0, 'Sidebar should not be empty'
	console.print_green('✓ Sidebar generated successfully')

	// Count categories in sidebar
	mut sidebar_category_count := 0
	mut sidebar_doc_count := 0

	for item in sidebar.my_sidebar {
		match item {
			NavCat {
				sidebar_category_count++
			}
			NavDoc {
				sidebar_doc_count++
			}
			else {
				// Other types
			}
		}
	}

	console.print_item('Sidebar contains: ${sidebar_category_count} categories, ${sidebar_doc_count} docs')

	// Detailed sidebar validation
	for i, item in sidebar.my_sidebar {
		match item {
			NavCat {
				console.print_debug('  Category ${i}: "${item.label}" (${item.items.len} items)')
				for sub_item in item.items {
					match sub_item {
						NavDoc {
							console.print_debug('    └─ Doc: "${sub_item.label}" (${sub_item.path})')
						}
						else {}
					}
				}
			}
			NavDoc {
				console.print_debug('  Doc ${i}: "${item.label}" (${item.path})')
			}
			else {}
		}
	}

	console.lf()

	// ========================================================
	// TEST 11: Validate Site Factory
	// ========================================================
	console.print_header('Validating Site Factory')

	mut all_sites := list()
	console.print_item('Total sites registered: ${all_sites.len}')
	for site_name in all_sites {
		console.print_debug('  - ${site_name}')
	}

	assert all_sites.contains('test_docs'), 'test_docs should be in sites list'
	console.print_green('✓ test_docs found in factory')

	assert exists(name: 'test_docs'), 'test_docs should exist'
	console.print_green('✓ test_docs verified to exist')

	console.lf()

	// ========================================================
	// TEST 12: Validate Print Output
	// ========================================================
	console.print_header('Site Sidebar String Output')
	println(test_site.sidebar_str())
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
