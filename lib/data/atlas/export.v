module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.base
import os

@[params]
pub struct ExportArgs {
pub mut:
	destination string
	reset       bool = true
	redis       bool = true
}

// Export all collections
pub fn (mut a Atlas) export(args ExportArgs) ! {
	mut dest := pathlib.get_dir(path: args.destination, create: true)!

	if args.reset {
		dest.empty()!
	}

	for _, mut col in a.collections {
		col.export(
			destination: dest
			reset:       args.reset
			redis:       args.redis
		)!
	}
}

@[params]
pub struct CollectionExportArgs {
pub mut:
	destination pathlib.Path @[required]
	reset       bool = true
	redis       bool = true
}

// Export a single collection
pub fn (mut c Collection) export(args CollectionExportArgs) ! {
	// Create collection directory
	col_dir := pathlib.get_dir(
		path:   '${args.destination.path}/${c.name}'
		create: true
	)!

	// Write .collection file
	mut cfile := pathlib.get_file(
		path:   '${col_dir.path}/.collection'
		create: true
	)!
	cfile.write("name:${c.name} src:'${c.path.path}'")!

	// Export pages
	export_pages(c.name, c.pages.values(), col_dir, args.redis)!

	// Export images
	export_files(c.name, c.images.values(), col_dir, 'img', args.redis)!

	// Export files
	export_files(c.name, c.files.values(), col_dir, 'files', args.redis)!

	// Store collection metadata in Redis if enabled
	if args.redis {
		mut context := base.context()!
		mut redis := context.redis()!
		redis.hset('atlas:path', c.name, col_dir.path)!
	}
}

// Export pages to destination
fn export_pages(col_name string, pages []&Page, dest pathlib.Path, redis bool) ! {
	mut context := base.context()!
	mut redis_client := context.redis()!

	for mut page in pages {
		// Simple copy of markdown content
		content := page.read_content()!

		mut dest_file := pathlib.get_file(
			path:   '${dest.path}/${page.name}.md'
			create: true
		)!
		dest_file.write(content)!

		if redis {
			redis_client.hset('atlas:${col_name}', page.name, '${page.name}.md')!
		}
	}
}

// Export files/images to destination
fn export_files(col_name string, files []&File, dest pathlib.Path, subdir string, redis bool) ! {
	if files.len == 0 {
		return
	}

	mut context := base.context()!
	mut redis_client := context.redis()!

	// Create subdirectory
	files_dir := pathlib.get_dir(
		path:   '${dest.path}/${subdir}'
		create: true
	)!

	for mut file in files {
		dest_path := '${files_dir.path}/${file.file_name()}'

		// Copy file
		file.path.copy(dest: dest_path)!

		if redis {
			redis_client.hset('atlas:${col_name}', file.file_name(), '${subdir}/${file.file_name()}')!
		}
	}
}
