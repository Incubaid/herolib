module codeparser

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.code
import log

// new creates a CodeParser from a root directory
// It walks the directory tree, parses all .v files, and indexes them
//
// Args:
//   root_dir string - directory to scan (absolute or relative)
// Returns:
//   CodeParser - indexed codebase
//   error - if directory doesn't exist or other I/O errors
pub fn new(root_dir string) !CodeParser {
	mut parser := CodeParser{
		root_path: root_dir
	}

	parser.scan_directory()!
	return parser
}

// scan_directory recursively walks the directory and parses all V files
fn (mut parser CodeParser) scan_directory() ! {
	mut root := pathlib.get_dir(path: parser.root_dir, create: false)!

	if !root.exists() {
		return error('root directory does not exist: ${parser.root_dir}')
	}

	parser.walk_dir(mut root)!
}

// walk_dir recursively traverses directories and collects V files
fn (mut parser CodeParser) walk_dir(mut dir pathlib.Path) ! {
	// Get all items in directory
	mut items := dir.list()!

	for item in items {
		if item.is_file() && item.path.ends_with('.v') {
			// Skip generated files
			if item.path.ends_with('_.v') {
				continue
			}

			parser.parse_file(item.path)
		} else if item.is_dir() {
			// Recursively walk subdirectories
			mut subdir := pathlib.get_dir(path: item.path, create: false) or { continue }
			parser.walk_dir(mut subdir) or { continue }
		}
	}
}

// parse_file parses a single V file and adds it to the index
fn (mut parser CodeParser) parse_file(file_path string) {
	mut file := pathlib.get_file(path: file_path) or {
		err_msg := 'failed to read file: ${err}'
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     err_msg
		}
		return
	}

	content := file.read() or {
		err_msg := 'failed to read content: ${err}'
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     err_msg
		}
		return
	}

	// Parse the V file
	vfile := code.parse_vfile(content) or {
		err_msg := 'parse error: ${err}'
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     err_msg
		}
		return
	}

	parsed_file := ParsedFile{
		path:        file_path
		module_name: vfile.mod
		vfile:       vfile
		parse_error: ''
	}

	parser.parsed_files[file_path] = parsed_file

	// Index by module
	if vfile.mod !in parser.modules {
		parser.modules[vfile.mod] = []string{}
	}
	parser.modules[vfile.mod] << file_path
}

// has_errors returns true if any parsing errors occurred
pub fn (parser CodeParser) has_errors() bool {
	return parser.parse_errors.len > 0
}

// error_count returns the number of parsing errors
pub fn (parser CodeParser) error_count() int {
	return parser.parse_errors.len
}

// print_errors prints all parsing errors to stdout
pub fn (parser CodeParser) print_errors() {
	if parser.parse_errors.len == 0 {
		println('No parsing errors')
		return
	}

	println('Parsing Errors (${parser.parse_errors.len}):')
	for err in parser.parse_errors {
		println('  ${err.file_path}: ${err.error}')
	}
}
