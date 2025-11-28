module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.base
import json

@[params]
pub struct ExportArgs {
pub mut:
	destination string @[required]
	reset       bool = true
	include     bool = true
	redis       bool = true
}

// Export all collections
pub fn (mut a Atlas) export(args ExportArgs) ! {
	mut dest := pathlib.get_dir(path: args.destination, create: true)!

	if args.reset {
		dest.empty()!
	}

	// Validate links before export to populate page.links
	a.validate_links()!

	for _, mut col in a.collections {
		col.export(
			destination: dest
			reset:       args.reset
			include:     args.include
			redis:       args.redis
		)!
	}
}

@[params]
pub struct CollectionExportArgs {
pub mut:
	destination pathlib.Path @[required]
	reset       bool = true
	include     bool = true // process includes during export
	redis       bool = true
}

// Export a single collection
// Export a single collection with recursive link processing
pub fn (mut c Collection) export(args CollectionExportArgs) ! {
	// Create collection directory
	mut col_dir := pathlib.get_dir(
		path:   '${args.destination.path}/content/${c.name}'
		create: true
	)!
	mut dir_meta := pathlib.get_dir(
		path:   '${args.destination.path}/meta/'
		create: true
	)!

	if c.has_errors() {
		c.print_errors()
	}

	meta := json.encode_pretty(c)
	mut json_file := pathlib.get_file(
		path:   '${dir_meta.path}/${c.name}.json'
		create: true
	)!
	json_file.write(meta)!

	// Track all cross-collection pages and files that need to be exported
	// Use maps with collection:name as key to track globally across all resolutions
	mut cross_collection_pages := map[string]&Page{} // key: "collection:page_name"
	mut cross_collection_files := map[string]&File{} // key: "collection:file_name"
	mut processed_local_pages := map[string]bool{} // Track which local pages we've already processed
	mut processed_cross_pages := map[string]bool{} // Track which cross-collection pages we've processed for links

	// First pass: export all pages in this collection and recursively collect ALL cross-collection references
	for _, mut page in c.pages {
		// Get content with includes processed and links transformed for export
		content := page.content_with_fixed_links(
			include:          args.include
			cross_collection: true
			export_mode:      true
		)!

		mut dest_file := pathlib.get_file(path: '${col_dir.path}/${page.name}.md', create: true)!
		dest_file.write(content)!

		// Recursively collect cross-collection references from this page
		c.collect_cross_collection_references(mut page, mut cross_collection_pages, mut
			cross_collection_files, mut processed_cross_pages)!

		// println('------- ${c.name} ${page.key()}')
		// if page.key() == 'geoaware:solution' && c.name == 'mycelium_nodes_tiers' {
		// 	println(cross_collection_pages)
		// 	println(cross_collection_files)
		// 	// println(processed_cross_pages)
		// 	$dbg;
		// }

		// copy the pages to the right exported path
		for _, mut ref_page in cross_collection_pages {
			mut src_file := ref_page.path()!
			mut subdir_path := pathlib.get_dir(
				path:   '${col_dir.path}'
				create: true
			)!
			mut dest_path := '${subdir_path.path}/${ref_page.name}.md'
			src_file.copy(dest: dest_path)!
			// println(dest_path)
			// $dbg;
		}
		// copy the files to the right exported path
		for _, mut ref_file in cross_collection_files {
			mut src_file2 := ref_file.path()!

			// Determine subdirectory based on file type
			mut subdir := if ref_file.is_image() { 'img' } else { 'files' }

			// Ensure subdirectory exists
			mut subdir_path := pathlib.get_dir(
				path:   '${col_dir.path}/${subdir}'
				create: true
			)!

			mut dest_path := '${subdir_path.path}/${ref_file.name}'
			mut dest_file2 := pathlib.get_file(path: dest_path, create: true)!
			src_file2.copy(dest: dest_file2.path)!
		}

		processed_local_pages[page.name] = true

		// Redis operations...
		if args.redis {
			mut context := base.context()!
			mut redis := context.redis()!
			redis.hset('atlas:${c.name}', page.name, page.path)!
		}
	}

	// Copy all files/images from this collection to the export directory
	for _, mut file in c.files {
		mut src_file := file.path()!

		// Determine subdirectory based on file type
		mut subdir := if file.is_image() { 'img' } else { 'files' }

		// Ensure subdirectory exists
		mut subdir_path := pathlib.get_dir(
			path:   '${col_dir.path}/${subdir}'
			create: true
		)!

		mut dest_path := '${subdir_path.path}/${file.name}'
		mut dest_file := pathlib.get_file(path: dest_path, create: true)!
		src_file.copy(dest: dest_file.path)!
	}
}

// Helper function to recursively collect cross-collection references
// This processes a page's links and adds all non-local references to the collections
fn (mut c Collection) collect_cross_collection_references(mut page Page,
	mut all_cross_pages map[string]&Page,
	mut all_cross_files map[string]&File,
	mut processed_pages map[string]bool) ! {
	page_key := page.key()

	// If we've already processed this page, skip it (prevents infinite loops with cycles)
	if page_key in processed_pages {
		return
	}

	// Mark this page as processed BEFORE recursing (prevents infinite loops with circular references)
	processed_pages[page_key] = true

	// Process all links in the current page
	// Use cached links from validation (before transformation) to preserve collection info
	for mut link in page.links {
		if link.status != .found {
			continue
		}

		is_local := link.target_collection_name == c.name

		// Collect cross-collection page references and recursively process them
		if link.file_type == .page && !is_local {
			page_ref := '${link.target_collection_name}:${link.target_item_name}'

			// Only add if not already collected
			if page_ref !in all_cross_pages {
				mut target_page := link.target_page()!
				all_cross_pages[page_ref] = target_page

				// Recursively process the target page's links to find more cross-collection references
				// This ensures we collect ALL transitive cross-collection page and file references
				c.collect_cross_collection_references(mut target_page, mut all_cross_pages, mut
					all_cross_files, mut processed_pages)!
			}
		}

		// Collect cross-collection file/image references
		if (link.file_type == .file || link.file_type == .image) && !is_local {
			file_key := '${link.target_collection_name}:${link.target_item_name}'

			// Only add if not already collected
			if file_key !in all_cross_files {
				mut target_file := link.target_file()!
				all_cross_files[file_key] = target_file
			}
		}
	}
}
