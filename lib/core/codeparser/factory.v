module codeparser

import incubaid.herolib.core.pathlib
import incubaid.herolib.core.code

// scan_directory recursively walks the directory and parses all V files using pathlib
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

		// Skip generated files
		if item.path.ends_with('_.v') {
			continue
		}

		// Check exclude patterns
		should_skip := parser.options.exclude_patterns.any(item.path.contains(it))
		if should_skip {
			continue
		}

		// Store file path for later parsing
		parsed_file := ParsedFile{
			path:        item.path
			module_name: ''
			vfile:       code.VFile{}
		}
		parser.parsed_files[item.path] = parsed_file
	}
}
