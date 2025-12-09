module heroprompt

import os

// build_selected_tree renders a minimal tree of the given file paths.
// - files: absolute or relative file paths
// - base_root: if provided and files are absolute, the tree is rendered relative to this root
// The output marks files with a trailing " *" like the existing map convention.
pub fn build_selected_tree(files []string, base_root string) string {
	mut rels := []string{}
	for p in files {
		mut rp := p
		if base_root.len > 0 && rp.starts_with(base_root) {
			rp = rp[base_root.len..]
			if rp.len > 0 && rp.starts_with('/') {
				rp = rp[1..]
			}
		}
		rels << rp
	}

	rels.sort()
	return tree_from_rel_paths(rels, '')
}

fn tree_from_rel_paths(paths []string, prefix string) string {
	mut out := ''
	// group into directories and files at the current level
	mut dir_children := map[string][]string{}
	mut files := []string{}
	for p in paths {
		parts := p.split('/')
		if parts.len <= 1 {
			if p.len > 0 {
				files << parts[0]
			}
		} else {
			key := parts[0]
			rest := parts[1..].join('/')
			mut arr := dir_children[key] or { []string{} }
			arr << rest
			dir_children[key] = arr
		}
	}
	mut dir_names := dir_children.keys()
	dir_names.sort()
	files.sort()
	// render directories first, then files
	for j, d in dir_names {
		is_last_dir := j == dir_names.len - 1
		connector := if is_last_dir && files.len == 0 { '└── ' } else { '├── ' }
		out += '${prefix}${connector}${d}\n'
		child_prefix := if is_last_dir && files.len == 0 {
			prefix + '    '
		} else {
			prefix + '│   '
		}
		out += tree_from_rel_paths(dir_children[d], child_prefix)
	}
	for i, f in files {
		file_connector := if i == files.len - 1 { '└── ' } else { '├── ' }
		out += '${prefix}${file_connector}${f} *\n'
	}
	return out
}

// resolve_path resolves a relative path against a base path.
// If rel_path is absolute, returns it as-is.
// If rel_path is empty, returns base_path.
pub fn resolve_path(base_path string, rel_path string) string {
	if rel_path.len == 0 {
		return base_path
	}
	if os.is_abs_path(rel_path) {
		return rel_path
	}
	return os.join_path(base_path, rel_path)
}

pub struct DirItem {
pub:
	name string
	typ  string
}

// build_file_tree_fs builds a file system tree for given root directories
pub fn build_file_tree_fs(roots []string, prefix string) string {
	// Create ignore matcher with default patterns
	ignore_matcher := gitignore_matcher_new()
	return build_file_tree_fs_with_ignore(roots, prefix, &ignore_matcher)
}

// build_file_tree_fs_with_ignore builds a file system tree with ignore pattern filtering
pub fn build_file_tree_fs_with_ignore(roots []string, prefix string, ignore_matcher &IgnoreMatcher) string {
	mut out := ''
	for i, root in roots {
		if !os.is_dir(root) {
			continue
		}
		connector := if i == roots.len - 1 { '└── ' } else { '├── ' }
		out += '${prefix}${connector}${os.base(root)}\n'
		child_prefix := if i == roots.len - 1 { prefix + '    ' } else { prefix + '│   ' }
		out += build_file_tree_fs_recursive_with_ignore(root, child_prefix, '', ignore_matcher)
	}
	return out
}

// build_file_tree_fs_recursive builds the contents of a directory without adding the directory name itself
fn build_file_tree_fs_recursive(root string, prefix string) string {
	// Create ignore matcher with default patterns for backward compatibility
	ignore_matcher := gitignore_matcher_new()
	return build_file_tree_fs_recursive_with_ignore(root, prefix, '', &ignore_matcher)
}

// build_file_tree_fs_recursive_with_ignore builds the contents of a directory with ignore pattern filtering
fn build_file_tree_fs_recursive_with_ignore(root string, prefix string, base_rel_path string, ignore_matcher &IgnoreMatcher) string {
	mut out := ''
	// list children under root
	entries := os.ls(root) or { []string{} }
	// sort: dirs first then files
	mut dirs := []string{}
	mut files := []string{}

	for e in entries {
		fp := os.join_path(root, e)

		// Calculate relative path for ignore checking
		rel_path := if base_rel_path.len > 0 {
			if base_rel_path.ends_with('/') { base_rel_path + e } else { base_rel_path + '/' + e }
		} else {
			e
		}

		// Check if this entry should be ignored
		mut should_ignore := ignore_matcher.is_ignored(rel_path)
		if os.is_dir(fp) && !should_ignore {
			// Also check directory pattern with trailing slash
			should_ignore = ignore_matcher.is_ignored(rel_path + '/')
		}

		if should_ignore {
			continue
		}

		if os.is_dir(fp) {
			dirs << fp
		} else if os.is_file(fp) {
			files << fp
		}
	}

	dirs.sort()
	files.sort()

	// files
	for j, f in files {
		file_connector := if j == files.len - 1 && dirs.len == 0 {
			'└── '
		} else {
			'├── '
		}
		out += '${prefix}${file_connector}${os.base(f)} *\n'
	}

	// subdirectories
	for j, d in dirs {
		sub_connector := if j == dirs.len - 1 { '└── ' } else { '├── ' }
		out += '${prefix}${sub_connector}${os.base(d)}\n'
		sub_prefix := if j == dirs.len - 1 {
			prefix + '    '
		} else {
			prefix + '│   '
		}

		// Calculate new relative path for subdirectory
		dir_name := os.base(d)
		new_rel_path := if base_rel_path.len > 0 {
			if base_rel_path.ends_with('/') {
				base_rel_path + dir_name
			} else {
				base_rel_path + '/' + dir_name
			}
		} else {
			dir_name
		}

		out += build_file_tree_fs_recursive_with_ignore(d, sub_prefix, new_rel_path, ignore_matcher)
	}
	return out
}

// build_file_tree_selected builds a minimal tree that contains only the selected files.
// The tree is rendered relative to base_root when provided.
pub fn build_file_tree_selected(files []string, base_root string) string {
	mut rels := []string{}
	for fo in files {
		mut rp := fo
		if base_root.len > 0 && rp.starts_with(base_root) {
			// make path relative to the base root
			rp = rp[base_root.len..]
			if rp.len > 0 && rp.starts_with('/') {
				rp = rp[1..]
			}
		}
		rels << rp
	}
	rels.sort()
	return tree_from_rel_paths(rels, '')
}

// SearchResult represents a search result item
pub struct SearchResult {
pub:
	name      string // filename
	path      string // relative path from base
	full_path string // absolute path
	typ       string // 'file' or 'directory'
}

// search_files searches for files and directories matching a query string
// - base_path: the root directory to search from
// - query: the search query (case-insensitive substring match)
// - ignore_matcher: optional ignore matcher to filter results (can be null)
// Returns a list of SearchResult items
pub fn search_files(base_path string, query string, ignore_matcher &IgnoreMatcher) ![]SearchResult {
	if query.len == 0 {
		return []SearchResult{}
	}

	query_lower := query.to_lower()
	mut results := []SearchResult{}

	search_directory_recursive(base_path, base_path, query_lower, ignore_matcher, mut
		results)!

	return results
}

// search_directory_recursive recursively searches directories for matching files
fn search_directory_recursive(dir_path string, base_path string, query_lower string, ignore_matcher &IgnoreMatcher, mut results []SearchResult) ! {
	entries := os.ls(dir_path) or { return }

	for entry in entries {
		full_path := os.join_path(dir_path, entry)

		// Calculate relative path from base_path
		mut rel_path := full_path
		if full_path.starts_with(base_path) {
			rel_path = full_path[base_path.len..]
			if rel_path.starts_with('/') {
				rel_path = rel_path[1..]
			}
		}

		// Check if this entry should be ignored
		if unsafe { ignore_matcher != 0 } {
			if ignore_matcher.is_ignored(rel_path) {
				continue
			}
		}

		// Check if filename or path matches search query
		if entry.to_lower().contains(query_lower) || rel_path.to_lower().contains(query_lower) {
			results << SearchResult{
				name:      entry
				path:      rel_path
				full_path: full_path
				typ:       if os.is_dir(full_path) { 'directory' } else { 'file' }
			}
		}

		// Recursively search subdirectories
		if os.is_dir(full_path) {
			search_directory_recursive(full_path, base_path, query_lower, ignore_matcher, mut
				results)!
		}
	}
}
