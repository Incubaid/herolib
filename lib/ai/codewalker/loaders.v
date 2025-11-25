module codewalker

import incubaid.herolib.core.pathlib

// filemap_get_from_path reads directory and creates FileMap, respecting ignore patterns
fn filemap_get_from_path(path string, content_read bool) !FileMap {
	mut dir := pathlib.get(path)
	if !dir.exists() || !dir.is_dir() {
		return error('Directory "${path}" does not exist')
	}

	mut fm := FileMap{
		source: path
	}

	ignore_patterns := find_ignore_patterns(path)!

	// List all files using pathlib with both default and custom ignore patterns
	mut file_list := dir.list(
		recursive:     true
		filter_ignore: ignore_patterns
	)!

	for mut file in file_list.paths {
		if file.is_file() {
			relpath := file.path_relative(path)!
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

// filemap_get_from_content parses FileMap from string with ===FILE:name=== format
fn filemap_get_from_content(content string) !FileMap {
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
