module collection

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.base
import incubaid.herolib.core.texttools.regext
import os
import incubaid.herolib.data.doctree.pointer
import incubaid.herolib.data.doctree.collection.data

@[params]
pub struct CollectionExportArgs {
pub mut:
	destination    pathlib.Path @[required]
	file_paths     map[string]string
	reset          bool = true
	keep_structure bool // wether the structure of the src collection will be preserved or not
	exclude_errors bool // wether error reporting should be exported as well
	replacer       ?regext.ReplaceInstructions
	redis          bool = true
}

pub fn (mut c Collection) export(args CollectionExportArgs) ! {
	dir_src := pathlib.get_dir(path: args.destination.path + '/' + c.name, create: true)!

	mut cfile := pathlib.get_file(path: dir_src.path + '/.collection', create: true)! // will auto save it
	cfile.write("name:${c.name} src:'${c.path.path}'")!

	mut context := base.context()!
	mut redis := context.redis()!
	redis.hset('doctree:path', '${c.name}', dir_src.path)!

	c.errors << export_pages(c.name, c.path.path, c.pages.values(),
		dir_src:        dir_src
		file_paths:     args.file_paths
		keep_structure: args.keep_structure
		replacer:       args.replacer
		redis:          args.redis
	)!

	c.export_files(c.name, dir_src, args.reset)!
	c.export_images(c.name, dir_src, args.reset)!
	c.export_linked_pages(c.name, dir_src)!

	if !args.exclude_errors {
		c.errors_report(c.name, '${dir_src.path}/errors.md')!
	}
}

@[params]
pub struct ExportPagesArgs {
pub mut:
	dir_src        pathlib.Path
	file_paths     map[string]string
	keep_structure bool // wether the structure of the src collection will be preserved or not
	replacer       ?regext.ReplaceInstructions
	redis          bool = true
}

// creates page file, processes page links, then writes page
fn export_pages(col_name string, col_path string, pages []&data.Page, args ExportPagesArgs) ![]CollectionError {
	mut errors := []CollectionError{}

	mut context := base.context()!
	mut redis := context.redis()!

	for page in pages {
		dest := if args.keep_structure {
			relpath := page.path.path.trim_string_left(col_path)
			'${args.dir_src.path}/${relpath}'
		} else {
			'${args.dir_src.path}/${page.name}.md'
		}

		not_found := page.process_links(args.file_paths)!

		for pointer_str in not_found {
			ptr := pointer.pointer_new(text: pointer_str)!
			cat := match ptr.cat {
				.page {
					CollectionErrorCat.page_not_found
				}
				.image {
					CollectionErrorCat.image_not_found
				}
				else {
					CollectionErrorCat.file_not_found
				}
			}
			errors << CollectionError{
				path: page.path
				msg:  '${ptr.cat} ${ptr.str()} not found'
				cat:  cat
			}
		}

		mut dest_path := pathlib.get_file(path: dest, create: true)!
		mut markdown := page.get_markdown()!
		if mut replacer := args.replacer {
			markdown = replacer.replace(text: markdown)!
		}
		dest_path.write(markdown)!
		redis.hset('doctree:${col_name}', page.name, '${page.name}.md')!
	}
	return errors
}

fn (c Collection) export_files(col_name string, dir_src pathlib.Path, reset bool) ! {
	mut context := base.context()!
	mut redis := context.redis()!
	for _, file in c.files {
		mut d := '${dir_src.path}/img/${file.name}.${file.ext}'
		if reset || !os.exists(d) {
			file.copy(d)!
		}
		redis.hset('doctree:${col_name}', '${file.name}.${file.ext}', 'img/${file.name}.${file.ext}')!
	}
}

fn (c Collection) export_images(col_name string, dir_src pathlib.Path, reset bool) ! {
	mut context := base.context()!
	mut redis := context.redis()!
	for _, file in c.images {
		mut d := '${dir_src.path}/img/${file.name}.${file.ext}'
		redis.hset('doctree:${col_name}', '${file.name}.${file.ext}', 'img/${file.name}.${file.ext}')!
		if reset || !os.exists(d) {
			file.copy(d)!
		}
	}
}

fn (c Collection) export_linked_pages(col_name string, dir_src pathlib.Path) ! {
	mut context := base.context()!
	mut redis := context.redis()!
	collection_linked_pages := c.get_collection_linked_pages()!
	mut linked_pages_file := pathlib.get_file(path: dir_src.path + '/.linkedpages', create: true)!
	redis.hset('doctree:${col_name}', 'linkedpages', '${linked_pages_file.name()}.md')!
	linked_pages_file.write(collection_linked_pages.join_lines())!
}

fn (c Collection) get_collection_linked_pages() ![]string {
	mut linked_pages_set := map[string]bool{}
	for _, page in c.pages {
		for linked_page in page.get_linked_pages()! {
			linked_pages_set[linked_page] = true
		}
	}

	return linked_pages_set.keys()
}
