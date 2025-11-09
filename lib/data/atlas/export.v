module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.base
import json

@[params]
pub struct ExportArgs {
pub mut:
	destination string @[requireds]
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

	// Track cross-collection pages and files that need to be copied for self-contained export
	mut cross_collection_pages := map[string]&Page{} // key: page.name, value: &Page
	mut cross_collection_files := map[string]&File{} // key: file.name, value: &File

	// First pass: export all pages in this collection and collect cross-collection references
	for _, mut page in c.pages {
		// Get content with includes processed and links transformed for export
		content := page.content_with_fixed_links(
			include:          args.include
			cross_collection: true
			export_mode:      true
		)!

		mut dest_file := pathlib.get_file(path: '${col_dir.path}/${page.name}.md', create: true)!
		dest_file.write(content)!

		// Collect cross-collection references for copying (pages and files/images)
		// IMPORTANT: Use cached links from validation (before transformation) to preserve collection info
		for mut link in page.links {
			if link.status != .found {
				continue
			}

			// Collect cross-collection page references
			is_local := link.target_collection_name == c.name
			if !link.is_file_link && !is_local {
				mut target_page := link.target_page() or { continue }
				// Use page name as key to avoid duplicates
				if target_page.name !in cross_collection_pages {
					cross_collection_pages[target_page.name] = target_page
				}
			}

			// Collect cross-collection file/image references
			if link.is_file_link && !is_local {
				mut target_file := link.target_file() or { continue }
				// Use file name as key to avoid duplicates
				file_key := target_file.file_name()
				if file_key !in cross_collection_files {
					cross_collection_files[file_key] = target_file
				}
			}
		}

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

		mut dest_path := '${subdir_path.path}/${file.file_name()}'
		mut dest_file := pathlib.get_file(path: dest_path, create: true)!
		src_file.copy(dest: dest_file.path)!
	}

	// Second pass: copy cross-collection referenced pages to make collection self-contained
	for _, mut ref_page in cross_collection_pages {
		// Get the referenced page content with includes processed
		ref_content := ref_page.content_with_fixed_links(
			include:          args.include
			cross_collection: true
			export_mode:      true
		)!

		// Write the referenced page to this collection's directory
		mut dest_file := pathlib.get_file(path: '${col_dir.path}/${ref_page.name}.md', create: true)!
		dest_file.write(ref_content)!
	}

	// Third pass: copy cross-collection referenced files/images to make collection self-contained
	for _, mut ref_file in cross_collection_files {
		mut src_file := ref_file.path()!

		// Determine subdirectory based on file type
		mut subdir := if ref_file.is_image() { 'img' } else { 'files' }

		// Ensure subdirectory exists
		mut subdir_path := pathlib.get_dir(
			path:   '${col_dir.path}/${subdir}'
			create: true
		)!

		mut dest_path := '${subdir_path.path}/${ref_file.file_name()}'
		mut dest_file := pathlib.get_file(path: dest_path, create: true)!
		src_file.copy(dest: dest_file.path)!
	}
}
