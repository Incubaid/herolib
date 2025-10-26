module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.base
import json

@[params]
pub struct ExportArgs {
pub mut:
	destination      string @[required]
	destination_meta string // NEW: where to save collection metadata
	reset            bool = true
	include          bool = true
	redis            bool = true
}

// Export all collections
pub fn (mut a Atlas) export(args ExportArgs) ! {
	mut dest := pathlib.get_dir(path: args.destination, create: true)!

	if args.reset {
		dest.empty()!
	}

	// Validate links before export
	// a.validate_links()!

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
	mut col_dir_meta := pathlib.get_dir(
		path:   '${args.destination.path}/meta/${c.name}'
		create: true
	)!

	if args.reset {
		col_dir.empty()!
		col_dir_meta.empty()!
	}

	

	if c.has_errors() {
		c.print_errors()
	}

	for _, mut page in c.pages {
		content := page.content(include: args.include)!

		// NEW: Process cross-collection links
		processed_content := page.process_cross_collection_links(mut col_dir)!

		mut dest_file := pathlib.get_file(path: '${col_dir.path}/${page.name}.md', create: true)!
		dest_file.write(processed_content)!

		// Redis operations...
		if args.redis {
			mut context := base.context()!
			mut redis := context.redis()!
			redis.hset('atlas:${c.name}', page.name, page.path)!
		}

		meta := json.encode_pretty(page)
		mut json_file := pathlib.get_file(
			path:   '${col_dir_meta.path}/${page.name}.json'
			create: true
		)!
		json_file.write(meta)!
	}

	// Export files
	if c.files.len > 0 {
		files_dir := pathlib.get_dir(
			path:   '${col_dir.path}/files'
			create: true
		)!

		for _, mut file in c.files {
			dest_path := '${files_dir.path}/${file.file_name()}'
			mut p2 := file.path()!
			p2.copy(dest: col_dir.path)!

			if args.redis {
				mut context := base.context()!
				mut redis := context.redis()!
				redis.hset('atlas:${c.name}', file.file_name(), file.path()!.path)!
			}
		}
	}
}
