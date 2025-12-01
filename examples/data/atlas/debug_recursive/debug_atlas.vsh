#!/usr/bin/env -S vrun

import incubaid.herolib.data.doctree
import incubaid.herolib.ui.console
import os

fn main() {
	println('=== ATLAS DEBUG SCRIPT ===\n')

	// Create and scan doctree
	mut a := doctree.new(name: 'main')!

	// Scan the collections
	println('Scanning collections...\n')
	a.scan(
		path: '/Users/despiegk/code/git.ourworld.tf/geomind/docs_geomind/collections/mycelium_nodes_tiers'
	)!
	a.scan(
		path: '/Users/despiegk/code/git.ourworld.tf/geomind/docs_geomind/collections/geomind_compare'
	)!
	a.scan(path: '/Users/despiegk/code/git.ourworld.tf/geomind/docs_geomind/collections/geoaware')!
	a.scan(
		path: '/Users/despiegk/code/git.ourworld.tf/tfgrid/docs_tfgrid4/collections/mycelium_economics'
	)!
	a.scan(
		path: '/Users/despiegk/code/git.ourworld.tf/tfgrid/docs_tfgrid4/collections/mycelium_concepts'
	)!
	a.scan(
		path: '/Users/despiegk/code/git.ourworld.tf/tfgrid/docs_tfgrid4/collections/mycelium_cloud_tech'
	)!

	// Initialize doctree (post-scanning validation)
	a.init_post()!

	// Print all pages per collection
	println('\n=== COLLECTIONS & PAGES ===\n')
	for col_name, col in a.collections {
		println('Collection: ${col_name}')
		println('  Pages (${col.pages.len}):')
		if col.pages.len > 0 {
			for page_name, _ in col.pages {
				println('    - ${page_name}')
			}
		} else {
			println('    (empty)')
		}
		println('  Files/Images (${col.files.len}):')
		if col.files.len > 0 {
			for file_name, _ in col.files {
				println('    - ${file_name}')
			}
		} else {
			println('    (empty)')
		}
	}

	// Validate links (this will recursively find links across collections)
	println('\n=== VALIDATING LINKS (RECURSIVE) ===\n')
	a.validate_links()!
	println('✓ Link validation complete\n')

	// Check for broken links
	println('\n=== BROKEN LINKS ===\n')
	mut total_errors := 0
	for col_name, col in a.collections {
		if col.has_errors() {
			println('Collection: ${col_name} (${col.errors.len} errors)')
			for err in col.errors {
				println('  [${err.category_str()}] Page: ${err.page_key}')
				println('    Message: ${err.message}')
				println('')
				total_errors++
			}
		}
	}

	if total_errors == 0 {
		println('✓ No broken links found!')
	} else {
		println('\n❌ Total broken link errors: ${total_errors}')
	}

	// Show discovered links per page (validates recursive discovery)
	println('\n\n=== DISCOVERED LINKS (RECURSIVE RESOLUTION) ===\n')
	println('Checking for files referenced by cross-collection pages...\n')
	mut total_links := 0
	for col_name, col in a.collections {
		mut col_has_links := false
		for page_name, page in col.pages {
			if page.links.len > 0 {
				if !col_has_links {
					println('Collection: ${col_name}')
					col_has_links = true
				}
				println('  Page: ${page_name} (${page.links.len} links)')
				for link in page.links {
					target_col := if link.target_collection_name != '' {
						link.target_collection_name
					} else {
						col_name
					}
					println('    → ${target_col}:${link.target_item_name} [${link.file_type}]')
					total_links++
				}
			}
		}
	}
	println('\n✓ Total links discovered: ${total_links}')

	// List pages that need investigation
	println('\n=== CHECKING SPECIFIC MISSING PAGES ===\n')

	missing_pages := [
		'compare_electricity',
		'internet_basics',
		'centralization_risk',
		'gdp_negative',
	]

	// Check in geoaware collection
	if 'geoaware' in a.collections {
		mut geoaware := a.get_collection('geoaware')!

		println('Collection: geoaware')
		if geoaware.pages.len > 0 {
			println('  All pages in collection:')
			for page_name, _ in geoaware.pages {
				println('    - ${page_name}')
			}
		} else {
			println('  (No pages found)')
		}

		println('\n  Checking for specific missing pages:')
		for page_name in missing_pages {
			exists := page_name in geoaware.pages
			status := if exists { '✓' } else { '✗' }
			println('  ${status} ${page_name}')
		}
	}

	// Check for pages across all collections
	println('\n\n=== LOOKING FOR MISSING PAGES ACROSS ALL COLLECTIONS ===\n')

	for missing_page in missing_pages {
		println('Searching for "${missing_page}":')
		mut found := false
		for col_name, col in a.collections {
			if missing_page in col.pages {
				println('  ✓ Found in: ${col_name}')
				found = true
			}
		}
		if !found {
			println('  ✗ Not found in any collection')
		}
	}

	// Check for the solution page
	println('\n\n=== CHECKING FOR "solution" PAGE ===\n')
	for col_name in ['mycelium_nodes_tiers', 'geomind_compare', 'geoaware', 'mycelium_economics',
		'mycelium_concepts', 'mycelium_cloud_tech'] {
		if col_name in a.collections {
			mut col := a.get_collection(col_name)!
			exists := col.page_exists('solution')!
			status := if exists { '✓' } else { '✗' }
			println('${status} ${col_name}: "solution" page')
		}
	}

	// Print error summary
	println('\n\n=== ERROR SUMMARY BY CATEGORY ===\n')
	mut category_counts := map[string]int{}
	for _, col in a.collections {
		for err in col.errors {
			cat_str := err.category_str()
			category_counts[cat_str]++
		}
	}

	if category_counts.len == 0 {
		println('✓ No errors found!')
	} else {
		for cat, count in category_counts {
			println('${cat}: ${count}')
		}
	}

	// ===== EXPORT AND FILE VERIFICATION TEST =====
	println('\n\n=== EXPORT AND FILE VERIFICATION TEST ===\n')

	// Create export directory
	export_path := '/tmp/doctree_debug_export'
	if os.exists(export_path) {
		os.rmdir_all(export_path)!
	}
	os.mkdir_all(export_path)!

	println('Exporting to: ${export_path}\n')
	a.export(destination: export_path)!
	println('✓ Export completed\n')

	// Collect all files found during link validation
	mut expected_files := map[string]string{} // key: file_name, value: collection_name
	mut file_count := 0
	for col_name, col in a.collections {
		for page_name, page in col.pages {
			for link in page.links {
				if link.status == .found && (link.file_type == .file || link.file_type == .image) {
					file_key := link.target_item_name
					expected_files[file_key] = link.target_collection_name
					file_count++
				}
			}
		}
	}

	println('Expected to find ${file_count} file references in links\n')
	println('=== VERIFYING FILES IN EXPORT DIRECTORY ===\n')

	// Get the first collection name (the primary exported collection)
	mut primary_col_name := ''
	for col_name, _ in a.collections {
		primary_col_name = col_name
		break
	}

	if primary_col_name == '' {
		println('❌ No collections found')
	} else {
		mut verified_count := 0
		mut missing_count := 0
		mut found_files := map[string]bool{}

		// Check both img and files directories
		img_dir := '${export_path}/content/${primary_col_name}/img'
		files_dir := '${export_path}/content/${primary_col_name}/files'

		// Scan img directory
		if os.exists(img_dir) {
			img_files := os.ls(img_dir) or { []string{} }
			for img_file in img_files {
				found_files[img_file] = true
			}
		}

		// Scan files directory
		if os.exists(files_dir) {
			file_list := os.ls(files_dir) or { []string{} }
			for file in file_list {
				found_files[file] = true
			}
		}

		println('Files/Images found in export directory:')
		if found_files.len > 0 {
			for file_name, _ in found_files {
				println('  ✓ ${file_name}')
				if file_name in expected_files {
					verified_count++
				}
			}
		} else {
			println('  (none found)')
		}

		println('\n=== FILE VERIFICATION RESULTS ===\n')
		println('Expected files from links: ${file_count}')
		println('Files found in export: ${found_files.len}')
		println('Files verified (present in export): ${verified_count}')

		// Check for missing expected files
		for expected_file, source_col in expected_files {
			if expected_file !in found_files {
				missing_count++
				println('  ✗ Missing: ${expected_file} (from ${source_col})')
			}
		}

		if missing_count > 0 {
			println('\n❌ ${missing_count} expected files are MISSING from export!')
		} else if verified_count == file_count && file_count > 0 {
			println('\n✓ All expected files are present in export directory!')
		} else if file_count == 0 {
			println('\n⚠ No file links were found during validation (check if pages have file references)')
		}

		// Show directory structure
		println('\n=== EXPORT DIRECTORY STRUCTURE ===\n')
		if os.exists('${export_path}/content/${primary_col_name}') {
			println('${export_path}/content/${primary_col_name}/')

			content_files := os.ls('${export_path}/content/${primary_col_name}') or { []string{} }
			for item in content_files {
				full_path := '${export_path}/content/${primary_col_name}/${item}'
				if os.is_dir(full_path) {
					sub_items := os.ls(full_path) or { []string{} }
					println('  ${item}/ (${sub_items.len} items)')
					for sub_item in sub_items {
						println('    - ${sub_item}')
					}
				} else {
					println('  - ${item}')
				}
			}
		}
	}
}
