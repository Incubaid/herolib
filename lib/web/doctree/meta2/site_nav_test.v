module meta

import incubaid.herolib.core.playbook
import incubaid.herolib.ui.console

// Comprehensive HeroScript for testing multi-level navigation depths
const test_heroscript_nav_depth = '
!!site.config
    name: "nav_depth_test"
    title: "Navigation Depth Test Site"
    description: "Testing multi-level nested navigation"
    tagline: "Deep navigation structures"

!!site.navbar
    title: "Nav Depth Test"

!!site.navbar_item
    label: "Home"
    to: "/"
    position: "left"

// ============================================================
// LEVEL 1: Simple top-level category
// ============================================================
!!site.page_category
    path: "Why"
    collapsible: true
    collapsed: false

//COLLECTION WILL BE REPEATED, HAS NO INFLUENCE ON NAVIGATION LEVELS
!!site.page src: "mycollection:intro"
    label: "Why Choose Us"
    title: "Why Choose Us"
    description: "Reasons to use this platform"

!!site.page src: "benefits"
    label: "Key Benefits"
    title: "Key Benefits"
    description: "Main benefits overview"

// ============================================================
// LEVEL 1: Simple top-level category
// ============================================================
!!site.page_category
    path: "Tutorials"
    collapsible: true
    collapsed: false

!!site.page src: "getting_started"
    label: "Getting Started"
    title: "Getting Started"
    description: "Basic tutorial to get started"

!!site.page src: "first_steps"
    label: "First Steps"
    title: "First Steps"
    description: "Your first steps with the platform"

// ============================================================
// LEVEL 3: Three-level nested category (Tutorials > Operations > Urgent)
// ============================================================
!!site.page_category
    path: "Tutorials/Operations/Urgent"
    collapsible: true
    collapsed: false

!!site.page src: "emergency_restart"
    label: "Emergency Restart"
    title: "Emergency Restart"
    description: "How to emergency restart the system"

!!site.page src: "critical_fixes"
    label: "Critical Fixes"
    title: "Critical Fixes"
    description: "Apply critical fixes immediately"

!!site.page src: "incident_response"
    label: "Incident Response"
    title: "Incident Response"
    description: "Handle incidents in real-time"

// ============================================================
// LEVEL 2: Two-level nested category (Tutorials > Operations)
// ============================================================
!!site.page_category
    path: "Tutorials/Operations"
    collapsible: true
    collapsed: false

!!site.page src: "daily_checks"
    label: "Daily Checks"
    title: "Daily Checks"
    description: "Daily maintenance checklist"

!!site.page src: "monitoring"
    label: "Monitoring"
    title: "Monitoring"
    description: "System monitoring procedures"

!!site.page src: "backups"
    label: "Backups"
    title: "Backups"
    description: "Backup and restore procedures"

// ============================================================
// LEVEL 1: One-to-two level (Tutorials)
// ============================================================
// Note: This creates a sibling at the Tutorials level (not nested deeper)
!!site.page src: "advanced_concepts"
    label: "Advanced Concepts"
    title: "Advanced Concepts"
    description: "Deep dive into advanced concepts"

!!site.page src: "troubleshooting"
    label: "Troubleshooting"
    title: "Troubleshooting"
    description: "Troubleshooting guide"

// ============================================================
// LEVEL 2: Two-level nested category (Why > FAQ)
// ============================================================
!!site.page_category
    path: "Why/FAQ"
    collapsible: true
    collapsed: false

!!site.page src: "general"
    label: "General Questions"
    title: "General Questions"
    description: "Frequently asked questions"

!!site.page src: "pricing_questions"
    label: "Pricing"
    title: "Pricing Questions"
    description: "Questions about pricing"

!!site.page src: "technical_faq"
    label: "Technical FAQ"
    title: "Technical FAQ"
    description: "Technical frequently asked questions"

!!site.page src: "support_faq"
    label: "Support"
    title: "Support FAQ"
    description: "Support-related FAQ"

// ============================================================
// LEVEL 4: Four-level nested category (Tutorials > Operations > Database > Optimization)
// ============================================================
!!site.page_category
    path: "Tutorials/Operations/Database/Optimization"
    collapsible: true
    collapsed: false

!!site.page src: "query_optimization"
    label: "Query Optimization"
    title: "Query Optimization"
    description: "Optimize your database queries"

!!site.page src: "indexing_strategy"
    label: "Indexing Strategy"
    title: "Indexing Strategy"
    description: "Effective indexing strategies"

!!site.page_category
    path: "Tutorials/Operations/Database"
    collapsible: true
    collapsed: false

!!site.page src: "configuration"
    label: "Configuration"
    title: "Database Configuration"
    description: "Configure your database"

!!site.page src: "replication"
    label: "Replication"
    title: "Database Replication"
    description: "Set up database replication"

'

fn check(s2 Site) {
	mut s := Site{
		doctree_path:   ''
		config:         SiteConfig{
			name:        'nav_depth_test'
			title:       'Navigation Depth Test Site'
			description: 'Testing multi-level nested navigation'
			tagline:     'Deep navigation structures'
			favicon:     'img/favicon.png'
			image:       'img/tf_graph.png'
			copyright:   '© 2025 Example Organization'
			footer:      Footer{
				style: 'dark'
				links: []
			}
			menu:        Menu{
				title:         'Nav Depth Test'
				items:         [
					MenuItem{
						href:     ''
						to:       '/'
						label:    'Home'
						position: 'left'
					},
				]
				logo_alt:      ''
				logo_src:      ''
				logo_src_dark: ''
			}
			url:         ''
			base_url:    '/'
			url_home:    ''
			meta_title:  ''
			meta_image:  ''
		}
		pages:          [
			Page{
				src:         'mycollection:intro'
				label:       'Why Choose Us'
				title:       'Why Choose Us'
				description: 'Reasons to use this platform'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 0
			},
			Page{
				src:         'mycollection:benefits'
				label:       'Key Benefits'
				title:       'Key Benefits'
				description: 'Main benefits overview'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 0
			},
			Page{
				src:         'mycollection:getting_started'
				label:       'Getting Started'
				title:       'Getting Started'
				description: 'Basic tutorial to get started'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 1
			},
			Page{
				src:         'mycollection:first_steps'
				label:       'First Steps'
				title:       'First Steps'
				description: 'Your first steps with the platform'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 1
			},
			Page{
				src:         'mycollection:emergency_restart'
				label:       'Emergency Restart'
				title:       'Emergency Restart'
				description: 'How to emergency restart the system'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 2
			},
			Page{
				src:         'mycollection:critical_fixes'
				label:       'Critical Fixes'
				title:       'Critical Fixes'
				description: 'Apply critical fixes immediately'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 2
			},
			Page{
				src:         'mycollection:incident_response'
				label:       'Incident Response'
				title:       'Incident Response'
				description: 'Handle incidents in real-time'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 2
			},
			Page{
				src:         'mycollection:daily_checks'
				label:       'Daily Checks'
				title:       'Daily Checks'
				description: 'Daily maintenance checklist'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 3
			},
			Page{
				src:         'mycollection:monitoring'
				label:       'Monitoring'
				title:       'Monitoring'
				description: 'System monitoring procedures'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 3
			},
			Page{
				src:         'mycollection:backups'
				label:       'Backups'
				title:       'Backups'
				description: 'Backup and restore procedures'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 3
			},
			Page{
				src:         'mycollection:advanced_concepts'
				label:       'Advanced Concepts'
				title:       'Advanced Concepts'
				description: 'Deep dive into advanced concepts'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 3
			},
			Page{
				src:         'mycollection:troubleshooting'
				label:       'Troubleshooting'
				title:       'Troubleshooting'
				description: 'Troubleshooting guide'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 3
			},
			Page{
				src:         'mycollection:general'
				label:       'General Questions'
				title:       'General Questions'
				description: 'Frequently asked questions'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 4
			},
			Page{
				src:         'mycollection:pricing_questions'
				label:       'Pricing'
				title:       'Pricing Questions'
				description: 'Questions about pricing'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 4
			},
			Page{
				src:         'mycollection:technical_faq'
				label:       'Technical FAQ'
				title:       'Technical FAQ'
				description: 'Technical frequently asked questions'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 4
			},
			Page{
				src:         'mycollection:support_faq'
				label:       'Support'
				title:       'Support FAQ'
				description: 'Support-related FAQ'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 4
			},
			Page{
				src:         'mycollection:query_optimization'
				label:       'Query Optimization'
				title:       'Query Optimization'
				description: 'Optimize your database queries'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 5
			},
			Page{
				src:         'mycollection:indexing_strategy'
				label:       'Indexing Strategy'
				title:       'Indexing Strategy'
				description: 'Effective indexing strategies'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 5
			},
			Page{
				src:         'mycollection:configuration'
				label:       'Configuration'
				title:       'Database Configuration'
				description: 'Configure your database'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 6
			},
			Page{
				src:         'mycollection:replication'
				label:       'Replication'
				title:       'Database Replication'
				description: 'Set up database replication'
				draft:       false
				hide_title:  false
				hide:        false
				category_id: 6
			},
		]
		links:          []
		categories:     [
			Category{
				path:        'Why'
				collapsible: true
				collapsed:   false
			},
			Category{
				path:        'Tutorials'
				collapsible: true
				collapsed:   false
			},
			Category{
				path:        'Tutorials/Operations/Urgent'
				collapsible: true
				collapsed:   false
			},
			Category{
				path:        'Tutorials/Operations'
				collapsible: true
				collapsed:   false
			},
			Category{
				path:        'Why/FAQ'
				collapsible: true
				collapsed:   false
			},
			Category{
				path:        'Tutorials/Operations/Database/Optimization'
				collapsible: true
				collapsed:   false
			},
			Category{
				path:        'Tutorials/Operations/Database'
				collapsible: true
				collapsed:   false
			},
		]
		announcements:  []
		imports:        []
		build_dest:     []
		build_dest_dev: []
	}
	assert s == s2
}

pub fn test_navigation_depth() ! {
	console.print_header('🧭 Navigation Depth Multi-Level Test')
	console.lf()

	// ========================================================
	// SETUP: Create and process playbook
	// ========================================================
	console.print_item('Creating playbook from HeroScript')
	mut plbook := playbook.new(text: test_heroscript_nav_depth)!
	console.print_green('✓ Playbook created')
	console.lf()

	console.print_item('Processing site configuration')
	play(mut plbook)!
	console.print_green('✓ Site processed')
	console.lf()

	console.print_item('Retrieving configured site')
	mut nav_site := get(name: 'nav_depth_test')!
	console.print_green('✓ Site retrieved')
	console.lf()

	check(nav_site)

	// ========================================================
	// TEST 1: Validate Categories Structure
	// ========================================================
	console.print_header('TEST 1: Validate Categories Structure')
	console.print_item('Total categories: ${nav_site.categories.len}')

	for i, category in nav_site.categories {
		depth := calculate_category_depth(category.path)
		console.print_debug('  [${i}] Path: "${category.path}" (Depth: ${depth})')
	}

	// Assertions for category structure
	mut all_paths := nav_site.categories.map(it.path)

	assert all_paths.contains('Why'), 'Missing "Why" category'
	console.print_green('✓ Level 1: "Why" found')

	assert all_paths.contains('Tutorials'), 'Missing "Tutorials" category'
	console.print_green('✓ Level 1: "Tutorials" found')

	assert all_paths.contains('Why/FAQ'), 'Missing "Why/FAQ" category'
	console.print_green('✓ Level 2: "Why/FAQ" found')

	assert all_paths.contains('Tutorials/Operations'), 'Missing "Tutorials/Operations" category'
	console.print_green('✓ Level 2: "Tutorials/Operations" found')

	assert all_paths.contains('Tutorials/Operations/Urgent'), 'Missing "Tutorials/Operations/Urgent" category'
	console.print_green('✓ Level 3: "Tutorials/Operations/Urgent" found')

	assert all_paths.contains('Tutorials/Operations/Database'), 'Missing "Tutorials/Operations/Database" category'
	console.print_green('✓ Level 3: "Tutorials/Operations/Database" found')

	assert all_paths.contains('Tutorials/Operations/Database/Optimization'), 'Missing "Tutorials/Operations/Database/Optimization" category'

	console.print_green('✓ Level 4: "Tutorials/Operations/Database/Optimization" found')

	console.lf()

	// ========================================================
	// TEST 2: Validate Pages Distribution
	// ========================================================
	console.print_header('TEST 2: Validate Pages Distribution')
	console.print_item('Total pages: ${nav_site.pages.len}')

	mut pages_by_category := map[int]int{}
	for page in nav_site.pages {
		cat_id := page.category_id
		if cat_id !in pages_by_category {
			pages_by_category[cat_id] = 0
		}
		pages_by_category[cat_id]++
	}

	console.print_debug('Pages per category:')
	for cat_id, count in pages_by_category {
		mut cat_name := 'Root (Uncategorized)'
		// category_id is 1-based, index is 0-based
		if cat_id > 0 && cat_id <= nav_site.categories.len {
			cat_name = nav_site.categories[cat_id - 1].path
		}
		console.print_debug('  Category ${cat_id} [${cat_name}]: ${count} pages')
	}

	// Validate we have pages in multiple categories
	assert pages_by_category.len >= 5, 'Should have pages in at least 5 categories'
	console.print_green('✓ Pages distributed across multiple category levels')

	console.lf()

	// ========================================================
	// TEST 3: Validate Navigation Structure (Sidebar)
	// ========================================================
	console.print_header('TEST 3: Navigation Structure Analysis')

	mut sidebar := nav_site.sidebar()!
	console.print_item('Sidebar root items: ${sidebar.my_sidebar.len}')
	console.lf()

	// Analyze structure
	mut stats := analyze_sidebar_structure(sidebar.my_sidebar)
	console.print_debug('Structure Analysis:')
	console.print_debug('  Total root items: ${stats.root_items}')
	console.print_debug('  Categories: ${stats.categories}')
	console.print_debug('  Pages: ${stats.pages}')
	console.print_debug('  Links: ${stats.links}')
	console.print_debug('  Max nesting depth: ${stats.max_depth}')

	println(nav_site.sidebar_str())
	println(sidebar)

	assert stats.categories >= 6, 'Should have at least 6 categories'
	console.print_green('✓ Multiple category levels present')

	assert stats.max_depth >= 4, 'Should have nesting depth of at least 4 levels (0-indexed root, so 3+1)'
	console.print_green('✓ Deep nesting verified (depth: ${stats.max_depth})')

	console.lf()

	// ========================================================
	// TEST 4: Validate Specific Path Hierarchies
	// ========================================================
	console.print_header('TEST 4: Path Hierarchy Validation')

	// Find categories and check parent-child relationships
	let_test_hierarchy(nav_site.categories)

	console.lf()

	// ========================================================
	// TEST 5: Print Sidebar Structure
	// ========================================================
	console.print_header('📑 COMPLETE SIDEBAR STRUCTURE')
	console.lf()
	println(nav_site.sidebar_str())

	console.print_header('✅ All Navigation Depth Tests Passed!')
}

// ============================================================
// Helper Structures
// ============================================================

struct SidebarStats {
pub mut:
	root_items int
	categories int
	pages      int
	links      int
	max_depth  int // Max nesting depth including root as depth 1
}

// ============================================================
// Helper Functions
// ============================================================

fn calculate_category_depth(path string) int {
	if path.len == 0 {
		return 0 // Or handle as an error/special case
	}
	// Count slashes + 1 for the depth
	// "Why" -> 1
	// "Why/FAQ" -> 2
	return path.split('/').len
}

fn analyze_sidebar_structure(items []NavItem) SidebarStats {
	mut stats := SidebarStats{}

	stats.root_items = items.len

	for item in items {
		// Calculate depth for the current item and update max_depth
		// The calculate_nav_item_depth function correctly handles recursion for NavCat
		// and returns current_depth for leaf nodes (NavDoc, NavLink).
		// We start at depth 1 for root-level items.
		depth := calculate_nav_item_depth(item, 1)
		if depth > stats.max_depth {
			stats.max_depth = depth
		}

		// Now categorize and count based on item type
		if item is NavCat {
			stats.categories++
			// Recursively count pages and categories within this NavCat
			stats.pages += count_nested_pages_in_navcat(item)
			stats.categories += count_nested_categories_in_navcat(item)
		} else if item is NavDoc {
			stats.pages++
		} else if item is NavLink {
			stats.links++
		}
	}

	return stats
}

fn calculate_nav_item_depth(item NavItem, current_depth int) int {
	mut max_depth_in_branch := current_depth

	if item is NavCat {
		for sub_item in item.items {
			depth := calculate_nav_item_depth(sub_item, current_depth + 1)
			if depth > max_depth_in_branch {
				max_depth_in_branch = depth
			}
		}
	}
	// NavDoc and NavLink are leaf nodes, their depth is current_depth
	return max_depth_in_branch
}

fn count_nested_pages_in_navcat(cat NavCat) int {
	mut count := 0
	for item in cat.items {
		if item is NavDoc {
			count++
		} else if item is NavCat {
			count += count_nested_pages_in_navcat(item)
		}
	}
	return count
}

fn count_nested_categories_in_navcat(cat NavCat) int {
	mut count := 0
	for item in cat.items {
		if item is NavCat {
			count++
			count += count_nested_categories_in_navcat(item)
		}
	}
	return count
}

fn let_test_hierarchy(categories []Category) {
	console.print_item('Validating path hierarchies:')

	// Group by depth
	mut by_depth := map[int][]string{}
	for category in categories {
		depth := calculate_category_depth(category.path)
		if depth !in by_depth {
			by_depth[depth] = []string{}
		}
		by_depth[depth] << category.path
	}

	// Print organized by depth
	// Assuming max depth is 4 based on the script
	for depth := 1; depth <= 4; depth++ {
		if depth in by_depth {
			console.print_debug('  Depth ${depth}:')
			for path in by_depth[depth] {
				console.print_debug('    └─ ${path}')
			}
		}
	}

	// Validate specific hierarchies
	mut all_paths := categories.map(it.path)

	// Hierarchy: Why -> Why/FAQ
	if all_paths.contains('Why') && all_paths.contains('Why/FAQ') {
		console.print_green('✓ Hierarchy verified: Why → Why/FAQ')
	}

	// Hierarchy: Tutorials -> Tutorials/Operations -> Tutorials/Operations/Urgent
	if all_paths.contains('Tutorials') && all_paths.contains('Tutorials/Operations')
		&& all_paths.contains('Tutorials/Operations/Urgent') {
		console.print_green('✓ Hierarchy verified: Tutorials → Operations → Urgent')
	}

	// Hierarchy: Tutorials/Operations -> Tutorials/Operations/Database -> Tutorials/Operations/Database/Optimization
	if all_paths.contains('Tutorials/Operations/Database')
		&& all_paths.contains('Tutorials/Operations/Database/Optimization') {
		console.print_green('✓ Hierarchy verified: Operations → Database → Optimization')
	}
}
