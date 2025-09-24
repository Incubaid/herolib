module codewalker

import freeflowuniverse.herolib.core.pathlib

pub struct CodeWalker {
pub mut:
	ignorematcher IgnoreMatcher
	errors        []CWError
}

@[params]
pub struct FileMapArgs {
pub mut:
	path         string
	content      string
	content_read bool = true // if we start from path, and this is on false then we don't read the content
}

// Public factory to parse the filemap-text format directly
pub fn (mut cw CodeWalker) parse(content string) !FileMap {
	return cw.filemap_get_from_content(content)
}

pub fn (mut cw CodeWalker) filemap_get(args FileMapArgs) !FileMap {
	if args.path != '' {
		return cw.filemap_get_from_path(args.path, args.content_read)!
	} else if args.content != '' {
		return cw.filemap_get_from_content(args.content)!
	} else {
		return error('Either path or content must be provided to get FileMap')
	}
}

// get the filemap from a path
fn (mut cw CodeWalker) filemap_get_from_path(path string, content_read bool) !FileMap {
	mut dir := pathlib.get(path)
	if !dir.exists() || !dir.is_dir() {
		return error('Source directory "${path}" does not exist')
	}

	mut files := dir.list(ignore_default: false)!
	mut fm := FileMap{
		source: path
	}

	// collect ignore patterns from .gitignore and .heroignore files (recursively),
	// and scope them to the directory where they were found
	for mut p in files.paths {
		if p.is_file() {
			name := p.name()
			if name == '.gitignore' || name == '.heroignore' {
				content := p.read() or { '' }
				if content != '' {
					rel := p.path_relative(path) or { '' }
					base_rel := if rel.contains('/') { rel.all_before_last('/') } else { '' }
					cw.ignorematcher.add_content_with_base(base_rel, content)
				}
			}
		}
	}

	for mut file in files.paths {
		if file.is_file() {
			name := file.name()
			if name == '.gitignore' || name == '.heroignore' {
				continue
			}
			relpath := file.path_relative(path)!
			if cw.ignorematcher.is_ignored(relpath) {
				continue
			}
			if content_read {
				content := file.read()!
				fm.content[relpath] = content
			} else {
				fm.content[relpath] = ''
			}
		}
	}
	return fm
}

// Parse a header line and return (kind, filename)
// kind: 'FILE' | 'FILECHANGE' | 'LEGACY' | 'END'
fn (mut cw CodeWalker) parse_header(line string, linenr int) !(string, string) {
	if line == '===END===' {
		return 'END', ''
	}
	if line.starts_with('===FILE:') && line.ends_with('===') {
		name := line.trim_left('=').trim_right('=').all_after(':').trim_space()
		if name.len < 1 {
			cw.error('Invalid filename, < 1 chars.', linenr, 'filename_get', true)!
		}
		return 'FILE', name
	}
	if line.starts_with('===FILECHANGE:') && line.ends_with('===') {
		name := line.trim_left('=').trim_right('=').all_after(':').trim_space()
		if name.len < 1 {
			cw.error('Invalid filename, < 1 chars.', linenr, 'filename_get', true)!
		}
		return 'FILECHANGE', name
	}
	// Legacy header: ===filename===
	if line.starts_with('===') && line.ends_with('===') {
		name := line.trim('=').trim_space()
		if name == 'END' {
			return 'END', ''
		}
		if name.len < 1 {
			cw.error('Invalid filename, < 1 chars.', linenr, 'filename_get', true)!
		}
		return 'LEGACY', name
	}
	return '', ''
}

fn (mut cw CodeWalker) error(msg string, linenr int, category string, fail bool) ! {
	cw.errors << CWError{
		message:  msg
		linenr:   linenr
		category: category
	}
	if fail {
		return error(msg)
	}
}

// internal function to get the filename
fn (mut cw CodeWalker) parse_filename_get(line string, linenr int) !string {
	parts := line.split('===')
	if parts.len < 2 {
		cw.error('Invalid filename line: ${line}.', linenr, 'filename_get', true)!
	}
	mut name := parts[1].trim_space()
	if name.len < 2 {
		cw.error('Invalid filename, < 2 chars: ${name}.', linenr, 'filename_get', true)!
	}
	return name
}

enum ParseState {
	start
	in_block
}

// Parse filemap content string
fn (mut cw CodeWalker) filemap_get_from_content(content string) !FileMap {
	mut fm := FileMap{}

	mut current_kind := '' // 'FILE' | 'FILECHANGE' | 'LEGACY'
	mut filename := ''
	mut block := []string{}
	mut had_any_block := false

	mut linenr := 0

	for line in content.split_into_lines() {
		linenr += 1
		line2 := line.trim_space()

		kind, name := cw.parse_header(line2, linenr)!
		if kind == 'END' {
			if filename == '' {
				if had_any_block {
					cw.error("Filename 'END' is reserved.", linenr, 'parse', true)!
				} else {
					cw.error('END found at start, not good.', linenr, 'parse', true)!
				}
			} else {
				if current_kind == 'FILE' || current_kind == 'LEGACY' {
					fm.content[filename] = block.join_lines()
				} else if current_kind == 'FILECHANGE' {
					fm.content_change[filename] = block.join_lines()
				}
				filename = ''
				block = []string{}
				current_kind = ''
			}
			continue
		}

		if kind in ['FILE', 'FILECHANGE', 'LEGACY'] {
			// starting a new block header
			if filename != '' {
				if current_kind == 'FILE' || current_kind == 'LEGACY' {
					fm.content[filename] = block.join_lines()
				} else if current_kind == 'FILECHANGE' {
					fm.content_change[filename] = block.join_lines()
				}
			}
			filename = name
			current_kind = kind
			block = []string{}
			had_any_block = true
			continue
		}

		// Non-header line
		if filename == '' {
			if line2.len > 0 {
				cw.error("Unexpected content before first file block: '${line}'.", linenr,
					'parse', false)!
			}
		} else {
			block << line
		}
	}

	// EOF: flush current block if any
	if filename != '' {
		if current_kind == 'FILE' || current_kind == 'LEGACY' {
			fm.content[filename] = block.join_lines()
		} else if current_kind == 'FILECHANGE' {
			fm.content_change[filename] = block.join_lines()
		}
	}

	return fm
}
