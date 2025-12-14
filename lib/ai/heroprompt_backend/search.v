//! Search Operations
//!
//! Search functionality within workspace files and context generation.
module heroprompt_backend

import incubaid.herolib.ai.filemap
import incubaid.herolib.core.pathlib

// SearchArgs specifies options for searching files.
@[params]
pub struct SearchArgs {
pub mut:
	workspace_id   string @[required]
	query          string @[required]
	case_sensitive bool
	max_results    int = 100
	context_lines  int = 2
}

// search searches for a query string within workspace files.
pub fn (self &HeropromptBackend) search(args SearchArgs) ![]SearchResult {
	ws := self.get_workspace(id: args.workspace_id)!
	mut results := []SearchResult{}

	query := if args.case_sensitive { args.query } else { args.query.to_lower() }

	for dir in ws.dirs {
		fm := filemap.filemap(path: dir.path, content_read: true) or { continue }

		for rel_path, content in fm.content {
			if results.len >= args.max_results {
				return results
			}

			results << search_in_content(
				content:        content
				query:          query
				file_path:      '${dir.path}/${rel_path}'
				case_sensitive: args.case_sensitive
				context_lines:  args.context_lines
				max_results:    args.max_results - results.len
			)
		}
	}

	return results
}

// SearchInContentArgs specifies options for content search.
@[params]
struct SearchInContentArgs {
	content        string
	query          string
	file_path      string
	case_sensitive bool
	context_lines  int
	max_results    int
}

// search_in_content searches for query in file content.
fn search_in_content(args SearchInContentArgs) []SearchResult {
	mut results := []SearchResult{}
	lines := args.content.split_into_lines()

	for i, line in lines {
		if results.len >= args.max_results {
			break
		}

		search_line := if args.case_sensitive { line } else { line.to_lower() }
		if search_line.contains(args.query) {
			start := if i >= args.context_lines { i - args.context_lines } else { 0 }
			end := if i + args.context_lines < lines.len { i + args.context_lines + 1 } else { lines.len }

			mut ctx := []string{}
			for j in start .. end {
				ctx << lines[j]
			}

			results << SearchResult{
				path:        args.file_path
				line_number: i + 1
				line:        line
				context:     ctx.join('\n')
			}
		}
	}

	return results
}

// GenerateContextArgs specifies options for context generation.
@[params]
pub struct GenerateContextArgs {
pub mut:
	workspace_id string   @[required]
	file_paths   []string @[required]
}

// generate_context creates a formatted context string from selected files.
pub fn (self &HeropromptBackend) generate_context(args GenerateContextArgs) !string {
	ws := self.get_workspace(id: args.workspace_id) or { return '' }
	mut output := []string{}

	for path in args.file_paths {
		content := get_file_content(path: path) or { continue }

		// Convert to relative path if possible
		mut rel_path := path
		for dir in ws.dirs {
			if path.starts_with(dir.path) {
				mut p := pathlib.get(path)
				rel_path = p.path_relative(dir.path) or { path }
				break
			}
		}

		output << '===FILE:${rel_path}==='
		output << content
	}

	if output.len > 0 {
		output << '===END==='
	}

	return output.join('\n')
}
