module codewalker

import incubaid.herolib.core.pathlib

// CodeWalker walks directories and parses file content
pub struct CodeWalker {
pub mut:
	ignorematcher IgnoreMatcher
}

@[params]
pub struct FileMapArgs {
pub mut:
	path         string
	content      string
	content_read bool = true // If false, file content not read from disk
}

// parse extracts FileMap from formatted content string
pub fn (mut cw CodeWalker) parse(content string) !FileMap {
	return cw.filemap_get_from_content(content)
}

// filemap_get creates FileMap from path or content string
pub fn (mut cw CodeWalker) filemap_get(args FileMapArgs) !FileMap {
	if args.path != '' {
		return cw.filemap_get_from_path(args.path, args.content_read)!
	} else if args.content != '' {
		return cw.filemap_get_from_content(args.content)!
	} else {
		return error('Either path or content must be provided')
	}
}

// filemap_get_from_path reads directory and creates FileMap, respecting ignore patterns
fn (mut cw CodeWalker) filemap_get_from_path(path string, content_read bool) !FileMap {
	mut dir := pathlib.get(path)
	if !dir.exists() || !dir.is_dir() {
		return error('Directory "${path}" does not exist')
	}

	mut files := dir.list(ignore_default: false)!
	mut fm := FileMap{
		source: path
	}

	// Collect ignore patterns from .gitignore and .heroignore with scoping
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

// parse_header robustly extracts block type and filename from header line
// Handles variable `=` count, spaces, and case-insensitivity
// Example: `  ===FILE: myfile.txt ===` → $(BlockKind.file, "myfile.txt")
fn parse_header(line string) !(BlockKind, string) {
	cleaned := line.trim_space()

	// Must have = and content
	if !cleaned.contains('=') {
		return BlockKind.end, ''
	}

	// Strip leading and trailing = (any count), preserving spaces between
	mut content := cleaned.trim_left('=').trim_space()
	content = content.trim_right('=').trim_space()

	if content.len == 0 {
		return BlockKind.end, ''
	}

	// Check for END marker
	if content.to_lower() == 'end' {
		return BlockKind.end, ''
	}

	// Parse FILE or FILECHANGE
	if content.contains(':') {
		kind_str := content.all_before(':').to_lower().trim_space()
		filename := content.all_after(':').trim_space()

		if filename.len < 1 {
			return error('Invalid filename: empty after colon')
		}

		match kind_str {
			'file' { return BlockKind.file, filename }
			'filechange' { return BlockKind.filechange, filename }
			else { return BlockKind.end, '' }
		}
	}

	return BlockKind.end, ''
}

// filemap_get_from_content parses FileMap from string with ===FILE:name=== format
fn (mut cw CodeWalker) filemap_get_from_content(content string) !FileMap {
	mut fm := FileMap{}

	mut current_kind := BlockKind.end
	mut filename := ''
	mut block := []string{}
	mut had_any_block := false
	mut linenr := 0

	for line in content.split_into_lines() {
		linenr += 1
		line_trimmed := line.trim_space()

		kind, name := parse_header(line_trimmed)!

		match kind {
			.end {
				if filename == '' {
					if had_any_block {
						fm.errors << FMError{
							message:  'Unexpected END marker without active block'
							linenr:   linenr
							category: 'parse'
						}
					} else {
						fm.errors << FMError{
							message:  'END found before any FILE block'
							linenr:   linenr
							category: 'parse'
						}
					}
				} else {
					// Store current block
					match current_kind {
						.file { fm.content[filename] = block.join_lines() }
						.filechange { fm.content_change[filename] = block.join_lines() }
						else {}
					}
					filename = ''
					block = []string{}
					current_kind = .end
				}
			}
			.file, .filechange {
				// Flush previous block if any
				if filename != '' {
					match current_kind {
						.file { fm.content[filename] = block.join_lines() }
						.filechange { fm.content_change[filename] = block.join_lines() }
						else {}
					}
				}
				filename = name
				current_kind = kind
				block = []string{}
				had_any_block = true
			}
		}

		// Accumulate non-header lines
		if kind == .end || kind == .file || kind == .filechange {
			continue
		}

		if filename == '' && line_trimmed.len > 0 {
			fm.errors << FMError{
				message:  "Content before first FILE block: '${line}'"
				linenr:   linenr
				category: 'parse'
			}
		} else if filename != '' {
			block << line
		}
	}

	// Flush final block if any
	if filename != '' {
		match current_kind {
			.file { fm.content[filename] = block.join_lines() }
			.filechange { fm.content_change[filename] = block.join_lines() }
			else {}
		}
	}

	return fm
}
