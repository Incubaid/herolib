module codeparser

import incubaid.herolib.core.code
import incubaid.herolib.core.pathlib
// import incubaid.herolib.ui.console
// import os

@[params]
pub struct ParserOptions {
pub:
	path             string @[required]
	recursive        bool = true
	exclude_patterns []string
	include_patterns []string = ['*.v']
}

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

// new creates a CodeParser and scans the given root directory
@[params]
pub fn new(args ParserOptions) !CodeParser {
	mut parser := CodeParser{
		root_dir:     args.path
		options:      args
		parsed_files: map[string]ParsedFile{}
		modules:      map[string][]string{}
	}
	parser.scan_directory()!
	return parser
}

// Accessor properties for backward compatibility
pub fn (parser CodeParser) files() map[string]code.VFile {
	mut result := map[string]code.VFile{}
	for _, parsed_file in parser.parsed_files {
		result[parsed_file.path] = parsed_file.vfile
	}
	return result
}

pub fn (parser CodeParser) errors() []ParseError {
	return parser.parse_errors
}

// parse_file parses a single V file and adds it to the index (public wrapper)
pub fn (mut parser CodeParser) parse_file(file_path string) {
	mut file := pathlib.get_file(path: file_path) or {
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     err.msg()
		}
		return
	}

	content := file.read() or {
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     err.msg()
		}
		return
	}

	// Parse the V file
	vfile := code.parse_vfile(content) or {
		parser.parse_errors << ParseError{
			file_path: file_path
			error:     err.msg()
		}
		return
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
	parser.modules[vfile.mod] << file_path
}

// parse processes all V files that were scanned
pub fn (mut parser CodeParser) parse() ! {
	for file_path, _ in parser.parsed_files {
		parser.parse_file(file_path)
	}
}

// get_module_stats calculates statistics for a module
pub fn (parser CodeParser) get_module_stats(module string) ModuleStats {
	// TODO: Fix this function
	return ModuleStats{}
}

// error adds a new parsing error to the list
fn (mut parser CodeParser) error(file_path string, msg string) {
	parser.parse_errors << ParseError{
		file_path: file_path
		error:     msg
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
