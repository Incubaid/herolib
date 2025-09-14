module heroprompt

import rand
import time
import os
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.develop.codewalker

// Selection API
@[params]
pub struct AddDirParams {
pub mut:
	path         string @[required]
	include_tree bool = true // true for base directories, false for selected directories
}

@[params]
pub struct AddFileParams {
pub mut:
	path string @[required]
}

// add a directory to the selection (no recursion stored; recursion is done on-demand)
pub fn (mut wsp Workspace) add_dir(args AddDirParams) !HeropromptChild {
	if args.path.len == 0 {
		return error('the directory path is required')
	}

	mut dir_path := pathlib.get(args.path)
	if !dir_path.exists() || !dir_path.is_dir() {
		return error('path is not an existing directory: ${args.path}')
	}

	abs_path := dir_path.realpath()
	name := dir_path.name()

	for child in wsp.children {
		if child.path.cat == .dir && child.path.path == abs_path {
			return error('the directory is already added to the workspace')
		}
	}

	mut ch := HeropromptChild{
		path:         pathlib.Path{
			path:  abs_path
			cat:   .dir
			exist: .yes
		}
		name:         name
		include_tree: args.include_tree
	}
	wsp.children << ch
	wsp.save()!
	return ch
}

// add a file to the selection
pub fn (mut wsp Workspace) add_file(args AddFileParams) !HeropromptChild {
	if args.path.len == 0 {
		return error('The file path is required')
	}

	mut file_path := pathlib.get(args.path)
	if !file_path.exists() || !file_path.is_file() {
		return error('Path is not an existing file: ${args.path}')
	}

	abs_path := file_path.realpath()
	name := file_path.name()

	for child in wsp.children {
		if child.path.cat == .file && child.name == name {
			return error('another file with the same name already exists: ${name}')
		}

		if child.path.cat == .dir && child.name == name {
			return error('${name}: is a directory, cannot add file with same name')
		}
	}

	content := file_path.read() or { '' }
	mut ch := HeropromptChild{
		path:    pathlib.Path{
			path:  abs_path
			cat:   .file
			exist: .yes
		}
		name:    name
		content: content
	}

	wsp.children << ch
	wsp.save()!
	return ch
}

// Removal API
@[params]
pub struct RemoveParams {
pub mut:
	path string
	name string
}

// Remove a directory from the selection (by absolute path or name)
pub fn (mut wsp Workspace) remove_dir(args RemoveParams) ! {
	if args.path.len == 0 && args.name.len == 0 {
		return error('either path or name is required to remove a directory')
	}
	mut idxs := []int{}
	for i, ch in wsp.children {
		if ch.path.cat != .dir {
			continue
		}
		if args.path.len > 0 && pathlib.get(args.path).realpath() == ch.path.path {
			idxs << i
			continue
		}
		if args.name.len > 0 && args.name == ch.name {
			idxs << i
		}
	}
	if idxs.len == 0 {
		return error('no matching directory found to remove')
	}
	// remove from end to start to keep indices valid
	idxs.sort(a > b)
	for i in idxs {
		wsp.children.delete(i)
	}
	wsp.save()!
}

// Remove a file from the selection (by absolute path or name)
pub fn (mut wsp Workspace) remove_file(args RemoveParams) ! {
	if args.path.len == 0 && args.name.len == 0 {
		return error('either path or name is required to remove a file')
	}
	mut idxs := []int{}
	for i, ch in wsp.children {
		if ch.path.cat != .file {
			continue
		}
		if args.path.len > 0 && pathlib.get(args.path).realpath() == ch.path.path {
			idxs << i
			continue
		}
		if args.name.len > 0 && args.name == ch.name {
			idxs << i
		}
	}
	if idxs.len == 0 {
		return error('no matching file found to remove')
	}
	idxs.sort(a > b)
	for i in idxs {
		wsp.children.delete(i)
	}
	wsp.save()!
}

// Delete this workspace from the store
pub fn (wsp &Workspace) delete_workspace() ! {
	delete(name: wsp.name)!
}

// Update this workspace (name and/or base_path)
@[params]
pub struct UpdateParams {
pub mut:
	name      string
	base_path string
}

pub fn (wsp &Workspace) update_workspace(args UpdateParams) !&Workspace {
	mut updated := Workspace{
		name:     if args.name.len > 0 { args.name } else { wsp.name }
		children: wsp.children
		created:  wsp.created
		updated:  time.now()
		is_saved: true
	}
	// if name changed, delete old key first
	if updated.name != wsp.name {
		delete(name: wsp.name)!
	}
	set(updated)!
	return get(name: updated.name)!
}

// @[params]
// pub struct UpdateParams {
// pub mut:
// 	name string
// 	base_path string
// 	// Update only the name and the base path for now
// }

// // Delete this workspace from the store
// pub fn (wsp &Workspace) update_workspace(args_ UpdateParams) ! {
// 	delete(name: wsp.name)!
// }

// List workspaces (wrapper over factory list)
pub fn list_workspaces() ![]&Workspace {
	return list(fromdb: false)!
}

pub fn list_workspaces_fromdb() ![]&Workspace {
	return list(fromdb: true)!
}

// List entries in a directory relative to this workspace base or absolute
@[params]
pub struct ListArgs {
pub mut:
	path string // if empty, will use workspace.base_path
}

pub struct ListItem {
pub:
	name string
	typ  string @[json: 'type']
}

pub fn (wsp &Workspace) list_dir(base_path string, rel_path string) ![]ListItem {
	// Create an ignore matcher with default patterns
	ignore_matcher := codewalker.gitignore_matcher_new()
	items := codewalker.list_directory_filtered(base_path, rel_path, &ignore_matcher)!
	mut out := []ListItem{}
	for item in items {
		out << ListItem{
			name: item.name
			typ:  item.typ
		}
	}
	return out
}

// Get the currently selected children (copy)
pub fn (wsp Workspace) selected_children() []HeropromptChild {
	return wsp.children.clone()
}

// build_file_content generates formatted content for all selected files (and all files under selected dirs)
fn (wsp Workspace) build_file_content() !string {
	mut content := ''
	// files selected directly
	for ch in wsp.children {
		if ch.path.cat == .file {
			if content.len > 0 {
				content += '\n\n'
			}
			content += '${ch.path.path}\n'
			ext := get_file_extension(ch.name)
			if ch.content.len == 0 {
				// read on demand using pathlib
				mut file_path := pathlib.get(ch.path.path)
				ch_content := file_path.read() or { '' }
				if ch_content.len == 0 {
					content += '(Empty file)\n'
				} else {
					content += '```' + ext + '\n' + ch_content + '\n```'
				}
			} else {
				content += '```' + ext + '\n' + ch.content + '\n```'
			}
		}
	}
	return content
}

// build_file_content_for_paths generates formatted content for specific selected paths
fn (wsp Workspace) build_file_content_for_paths(selected_paths []string) !string {
	mut content := ''

	for path in selected_paths {
		if !os.exists(path) {
			continue // Skip non-existent paths
		}

		if content.len > 0 {
			content += '\n\n'
		}

		if os.is_file(path) {
			// Add file content
			content += '${path}\n'
			file_content := os.read_file(path) or {
				content += '(Error reading file: ${err.msg()})\n'
				continue
			}
			ext := get_file_extension(os.base(path))
			if file_content.len == 0 {
				content += '(Empty file)\n'
			} else {
				content += '```' + ext + '\n' + file_content + '\n```'
			}
		} else if os.is_dir(path) {
			// Add directory content using codewalker
			mut cw := codewalker.new(codewalker.CodeWalkerArgs{})!
			mut fm := cw.filemap_get(path: path)!
			for filepath, filecontent in fm.content {
				if content.len > 0 {
					content += '\n\n'
				}
				content += '${path}/${filepath}\n'
				ext := get_file_extension(filepath)
				if filecontent.len == 0 {
					content += '(Empty file)\n'
				} else {
					content += '```' + ext + '\n' + filecontent + '\n```'
				}
			}
		}
	}

	return content
}

pub struct HeropromptTmpPrompt {
pub mut:
	user_instructions string
	file_map          string
	file_contents     string
}

fn (wsp Workspace) build_user_instructions(text string) string {
	return text
}

// build_file_map creates a unified tree showing the minimal path structure for all workspace items
pub fn (wsp Workspace) build_file_map() string {
	// Collect all paths from workspace children
	mut all_paths := []string{}
	for ch in wsp.children {
		all_paths << ch.path.path
	}

	if all_paths.len == 0 {
		return ''
	}

	// Expand directories to include all their contents
	expanded_paths := expand_directory_paths(all_paths)

	// Find common root path to make the tree relative
	common_root := find_common_root_path(expanded_paths)

	// Build unified tree using the selected tree function
	return codewalker.build_selected_tree(expanded_paths, common_root)
}

// find_common_root_path finds the common root directory for a list of paths
fn find_common_root_path(paths []string) string {
	if paths.len == 0 {
		return ''
	}
	if paths.len == 1 {
		// For single path, use its parent directory as root
		return os.dir(paths[0])
	}

	// Split all paths into components
	mut path_components := [][]string{}
	for path in paths {
		// Normalize path and split into components
		normalized := os.real_path(path)
		components := normalized.split(os.path_separator).filter(it.len > 0)
		path_components << components
	}

	// Find common prefix
	mut common_components := []string{}
	if path_components.len > 0 {
		// Find minimum length manually
		mut min_len := path_components[0].len
		for components in path_components {
			if components.len < min_len {
				min_len = components.len
			}
		}

		for i in 0 .. min_len {
			component := path_components[0][i]
			mut all_match := true
			for j in 1 .. path_components.len {
				if path_components[j][i] != component {
					all_match = false
					break
				}
			}
			if all_match {
				common_components << component
			} else {
				break
			}
		}
	}

	// Build common root path
	if common_components.len == 0 {
		return os.path_separator
	}

	return os.path_separator + common_components.join(os.path_separator)
}

// expand_directory_paths expands directory paths to include all files and subdirectories
fn expand_directory_paths(paths []string) []string {
	mut expanded := []string{}

	for path in paths {
		if !os.exists(path) {
			continue
		}

		if os.is_file(path) {
			// Add files directly
			expanded << path
		} else if os.is_dir(path) {
			// Expand directories using codewalker to get all files
			mut cw := codewalker.new(codewalker.CodeWalkerArgs{}) or { continue }
			mut fm := cw.filemap_get(path: path) or { continue }

			// Add the directory itself
			expanded << path

			// Add all files in the directory
			for filepath, _ in fm.content {
				full_path := os.join_path(path, filepath)
				expanded << full_path
			}
		}
	}

	return expanded
}

pub struct WorkspacePrompt {
pub mut:
	text string
}

pub fn (wsp Workspace) prompt(args WorkspacePrompt) string {
	user_instructions := wsp.build_user_instructions(args.text)
	file_map := wsp.build_file_map()
	file_contents := wsp.build_file_content() or { '(Error building file contents)' }
	prompt := HeropromptTmpPrompt{
		user_instructions: user_instructions
		file_map:          file_map
		file_contents:     file_contents
	}
	reprompt := $tmpl('./templates/prompt.template')
	return reprompt
}

@[params]
pub struct WorkspacePromptWithSelection {
pub mut:
	text           string
	selected_paths []string
}

// Generate prompt with specific selected paths instead of using workspace children
pub fn (wsp Workspace) prompt_with_selection(args WorkspacePromptWithSelection) !string {
	user_instructions := wsp.build_user_instructions(args.text)

	// Build file map for selected paths (unified tree)
	file_map := if args.selected_paths.len > 0 {
		// Expand directories to include all their contents
		expanded_paths := expand_directory_paths(args.selected_paths)
		common_root := find_common_root_path(expanded_paths)
		codewalker.build_selected_tree(expanded_paths, common_root)
	} else {
		// Fallback to workspace file map if no selections
		wsp.build_file_map()
	}

	// Build file content only for selected paths
	file_contents := wsp.build_file_content_for_paths(args.selected_paths) or {
		return error('failed to build file content: ${err.msg()}')
	}

	prompt := HeropromptTmpPrompt{
		user_instructions: user_instructions
		file_map:          file_map
		file_contents:     file_contents
	}
	reprompt := $tmpl('./templates/prompt.template')
	return reprompt
}

// Save the workspace
fn (mut wsp Workspace) save() !&Workspace {
	wsp.updated = time.now()
	wsp.is_saved = true
	set(wsp)!
	return get(name: wsp.name)!
}

// Generate a random name for the workspace
pub fn generate_random_workspace_name() string {
	adjectives := [
		'brave',
		'bright',
		'clever',
		'swift',
		'noble',
		'mighty',
		'fearless',
		'bold',
		'wise',
		'epic',
		'valiant',
		'fierce',
		'legendary',
		'heroic',
		'dynamic',
	]
	nouns := [
		'forge',
		'script',
		'ocean',
		'phoenix',
		'atlas',
		'quest',
		'shield',
		'dragon',
		'code',
		'summit',
		'path',
		'realm',
		'spark',
		'anvil',
		'saga',
	]

	// Seed randomness with time
	rand.seed([u32(time.now().unix()), u32(time.now().nanosecond)])

	adj := adjectives[rand.intn(adjectives.len) or { 0 }]
	noun := nouns[rand.intn(nouns.len) or { 0 }]
	number := rand.intn(100) or { 0 } // 0–99

	return '${adj}_${noun}_${number}'
}
