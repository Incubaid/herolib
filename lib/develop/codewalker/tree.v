module codewalker

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

// list_directory lists the contents of a directory.
// - base_path: workspace base path
// - rel_path: relative path from base (or absolute path)
// Returns a list of DirItem with name and type (file/directory).
pub fn list_directory(base_path string, rel_path string) ![]DirItem {
	dir := resolve_path(base_path, rel_path)
	if dir.len == 0 {
		return error('base_path not set')
	}
	entries := os.ls(dir) or { return error('cannot list directory') }
	mut out := []DirItem{}
	for e in entries {
		full := os.join_path(dir, e)
		if os.is_dir(full) {
			out << DirItem{
				name: e
				typ:  'directory'
			}
		} else if os.is_file(full) {
			out << DirItem{
				name: e
				typ:  'file'
			}
		}
	}
	return out
}

// list_directory_filtered lists the contents of a directory with ignore filtering applied.
// - base_path: workspace base path
// - rel_path: relative path from base (or absolute path)
// - ignore_matcher: IgnoreMatcher to filter out ignored files/directories
// Returns a list of DirItem with name and type (file/directory), filtered by ignore patterns.
pub fn list_directory_filtered(base_path string, rel_path string, ignore_matcher &IgnoreMatcher) ![]DirItem {
	dir := resolve_path(base_path, rel_path)
	if dir.len == 0 {
		return error('base_path not set')
	}
	entries := os.ls(dir) or { return error('cannot list directory') }
	mut out := []DirItem{}
	for e in entries {
		full := os.join_path(dir, e)

		// Calculate relative path from base_path for ignore checking
		mut check_path := if rel_path.len > 0 {
			if rel_path.ends_with('/') { rel_path + e } else { rel_path + '/' + e }
		} else {
			e
		}

		// For directories, also check with trailing slash
		is_directory := os.is_dir(full)
		mut should_ignore := ignore_matcher.is_ignored(check_path)
		if is_directory && !should_ignore {
			// Also check directory pattern with trailing slash
			should_ignore = ignore_matcher.is_ignored(check_path + '/')
		}

		// Check if this entry should be ignored
		if should_ignore {
			continue
		}

		if is_directory {
			out << DirItem{
				name: e
				typ:  'directory'
			}
		} else if os.is_file(full) {
			out << DirItem{
				name: e
				typ:  'file'
			}
		}
	}
	return out
}

// list_files_recursive recursively lists all files in a directory
pub fn list_files_recursive(root string) []string {
	mut out := []string{}
	entries := os.ls(root) or { return out }
	for e in entries {
		fp := os.join_path(root, e)
		if os.is_dir(fp) {
			out << list_files_recursive(fp)
		} else if os.is_file(fp) {
			out << fp
		}
	}
	return out
}

// build_file_tree_fs builds a file system tree for given root directories
pub fn build_file_tree_fs(roots []string, prefix string) string {
	mut out := ''
	for i, root in roots {
		if !os.is_dir(root) {
			continue
		}
		connector := if i == roots.len - 1 { '└── ' } else { '├── ' }
		out += '${prefix}${connector}${os.base(root)}\n'
		child_prefix := if i == roots.len - 1 { prefix + '    ' } else { prefix + '│   ' }
		// list children under root
		entries := os.ls(root) or { []string{} }
		// sort: dirs first then files
		mut dirs := []string{}
		mut files := []string{}
		for e in entries {
			fp := os.join_path(root, e)
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
			out += '${child_prefix}${file_connector}${os.base(f)} *\n'
		}
		// subdirectories
		for j, d in dirs {
			sub_connector := if j == dirs.len - 1 { '└── ' } else { '├── ' }
			out += '${child_prefix}${sub_connector}${os.base(d)}\n'
			sub_prefix := if j == dirs.len - 1 {
				child_prefix + '    '
			} else {
				child_prefix + '│   '
			}
			out += build_file_tree_fs([d], sub_prefix)
		}
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
