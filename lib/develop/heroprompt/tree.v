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
