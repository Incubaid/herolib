module collection

import incubaid.herolib.core.pathlib { Path }
import incubaid.herolib.core.base
import incubaid.herolib.ui.console

pub enum CollectionErrorCat {
	unknown
	image_double
	file_double
	file_not_found
	image_not_found
	page_double
	page_not_found
	sidebar
	circular_import
	def
	summary
	include
}

pub struct CollectionError {
	Error
pub mut:
	path Path
	msg  string
	cat  CollectionErrorCat
}

pub fn (e CollectionError) msg() string {
	return 'collection error:\n\tPath: ${e.path.path}\n\tError message: ${e.msg}\n\tCategory: ${e.cat}'
}

pub fn (mut collection Collection) error(args CollectionError) ! {
	if collection.fail_on_error {
		return args
	}

	collection.errors << args
	console.print_stderr(args.msg)
}

pub struct ObjNotFound {
	Error
pub:
	name       string
	collection string
	info       string
}

pub fn (err ObjNotFound) msg() string {
	return 'Could not find object with name ${err.name} in collection ${err.collection}: ${err.info}'
}

// write errors.md in the collection, this allows us to see what the errors are
pub fn (collection Collection) errors_report(col_name string, dest_ string) ! {
	// console.print_debug("====== errors report: ${dest_} : ${collection.errors.len}\n${collection.errors}")
	mut context := base.context()!
	mut redis := context.redis()!
	mut dest := pathlib.get_file(path: dest_, create: true)!
	if collection.errors.len == 0 {
		dest.delete()!
		return
	}
	c := $tmpl('template/errors.md')
	dest.write(c)!
	redis.hset('doctree:${col_name}', 'errors', 'errors.md')!
}
