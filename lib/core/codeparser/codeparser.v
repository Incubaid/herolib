module codeparser

import incubaid.herolib.core.code
import incubaid.herolib.ui.console
import os

@[params]
pub struct ParseOptions {
pub:
	recursive        bool = true
	exclude_patterns []string
	include_patterns []string = ['*.v']
}

pub struct CodeParser {
pub:
	root_path string
	options   ParseOptions
pub mut:
	files   map[string]code.VFile
	modules []code.Module
	errors  []string
}

pub fn new(path string, opts ParseOptions) !CodeParser {
	mut parser := CodeParser{
		root_path: path
		options:   opts
	}
	return parser
}

pub fn (mut parser CodeParser) parse() ! {
	parser.files.clear()
	parser.errors.clear()

	v_files := parser.collect_files()!

	for file_path in v_files {
		console.print_debug('Parsing: ${file_path}')

		content := os.read_file(file_path) or {
			parser.errors << 'Failed to read ${file_path}: ${err}'
			continue
		}

		vfile := code.parse_vfile(content) or {
			parser.errors << 'Failed to parse ${file_path}: ${err}'
			continue
		}

		parser.files[file_path] = vfile
	}
}

pub fn (parser CodeParser) collect_files() ![]string {
	mut files := []string{}

	if parser.options.recursive {
		files = parser.collect_files_recursive(parser.root_path)!
	} else {
		files = code.list_v_files(parser.root_path)!
	}

	return files
}

fn (parser CodeParser) collect_files_recursive(dir string) ![]string {
	mut all_files := []string{}

	items := os.ls(dir)!
	for item in items {
		path := os.join_path(dir, item)

		if parser.should_skip(path) {
			continue
		}

		if os.is_dir(path) {
			sub_files := parser.collect_files_recursive(path)!
			all_files << sub_files
		} else if item.ends_with('.v') && !item.ends_with('_.v') {
			all_files << path
		}
	}

	return all_files
}

fn (parser CodeParser) should_skip(path string) bool {
	basename := os.base(path)

	// Skip common directories
	if basename in ['.git', 'node_modules', '.vscode', '__pycache__', '.github'] {
		return true
	}

	for pattern in parser.options.exclude_patterns {
		if basename.contains(pattern) {
			return true
		}
	}

	return false
}

pub fn (parser CodeParser) summarize() CodeSummary {
	mut summary := CodeSummary{}

	for _, vfile in parser.files {
		summary.total_files++
		summary.total_imports += vfile.imports.len
		summary.total_structs += vfile.structs().len
		summary.total_functions += vfile.functions().len
		summary.total_consts += vfile.consts.len
	}

	summary.total_errors = parser.errors.len

	return summary
}

pub struct CodeSummary {
pub mut:
	total_files     int
	total_imports   int
	total_structs   int
	total_functions int
	total_consts    int
	total_errors    int
}

pub fn (summary CodeSummary) print() {
	console.print_header('Code Summary')
	console.print_item('Files parsed: ${summary.total_files}')
	console.print_item('Imports: ${summary.total_imports}')
	console.print_item('Structs: ${summary.total_structs}')
	console.print_item('Functions: ${summary.total_functions}')
	console.print_item('Constants: ${summary.total_consts}')
	console.print_item('Errors: ${summary.total_errors}')
}

pub fn (parser CodeParser) print_errors() {
	if parser.errors.len > 0 {
		console.print_header('Parsing Errors')
		for err in parser.errors {
			console.print_stderr(err)
		}
	}
}
