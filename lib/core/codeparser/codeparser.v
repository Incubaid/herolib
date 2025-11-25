module codeparser

import incubaid.herolib.core.code
import incubaid.herolib.core.pathlib

// ParseError represents an error that occurred while parsing a file
pub struct ParseError {
pub:
	file_path string
	error     string
}

// ParsedFile represents a successfully parsed V file
pub struct ParsedFile {
pub:
	path        string
	module_name string
	vfile       code.VFile
}

pub struct ModuleStats {
pub mut:
	file_count      int
	struct_count    int
	function_count  int
	interface_count int
	const_count     int
}

pub struct ParsedModule {
pub:
	name       string
	file_paths []string
	stats      ModuleStats
}

pub struct CodeParser {
pub mut:
	root_dir     string
	options      ParserOptions
	parsed_files map[string]ParsedFile
	modules      map[string][]string
	parse_errors []ParseError
}

// scan_directory recursively walks the directory and identifies all V files
// Files are stored but not parsed until parse() is called
fn (mut parser CodeParser) scan_directory() ! {
	mut root := pathlib.get_dir(path: parser.root_dir, create: false)!

	if !root.exists() {
		return error('root directory does not exist: ${parser.root_dir}')
	}

	// Use pathlib's recursive listing capability
	mut items := root.list(recursive: parser.options.recursive)!

	for item in items.paths {
		// Skip non-V files
		if !item.path.ends_with('.v') {
			continue
		}

		// Skip generated files (ending with _.v)
		if item.path.ends_with('_.v') {
			continue
		}

		// Check exclude patterns
		should_skip := parser.options.exclude_patterns.any(item.path.contains(it))
		if should_skip {
			continue
		}

		// Store file path for lazy parsing
		parsed_file := ParsedFile{
			path:        item.path
			module_name: ''
			vfile:       code.VFile{}
		}
		parser.parsed_files[item.path] = parsed_file
	}
}

// parse processes all V files that were scanned and parses them
pub fn (mut parser CodeParser) parse() ! {
	for file_path, _ in parser.parsed_files {
		if parser.parsed_files[file_path].vfile.mod == '' {
			// Only parse if not already parsed
			parser.parse_file(file_path)!
		}
	}
}

// parse_file parses a single V file and adds it to the index
pub fn (mut parser CodeParser) parse_file(file_path string) ! {
	mut file := pathlib.get_file(path: file_path) or {
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     'Failed to access file: ${err.msg()}'
		}
		return error('Failed to access file: ${err.msg()}')
	}

	content := file.read() or {
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     'Failed to read file: ${err.msg()}'
		}
		return error('Failed to read file: ${err.msg()}')
	}

	// Parse the V file
	vfile := code.parse_vfile(content) or {
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     'Parse error: ${err.msg()}'
		}
		return error('Parse error: ${err.msg()}')
	}

	parsed_file := ParsedFile{
		path:        file_path
		module_name: vfile.mod
		vfile:       vfile
	}

	parser.parsed_files[file_path] = parsed_file

	// Index by module
	if vfile.mod !in parser.modules {
		parser.modules[vfile.mod] = []string{}
	}
	if file_path !in parser.modules[vfile.mod] {
		parser.modules[vfile.mod] << file_path
	}
}

// has_errors returns true if any parsing errors occurred
pub fn (parser CodeParser) has_errors() bool {
	return parser.parse_errors.len > 0
}

// error_count returns the number of parsing errors
pub fn (parser CodeParser) error_count() int {
	return parser.parse_errors.len
}
