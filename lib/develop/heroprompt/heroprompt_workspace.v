module heroprompt

import os
import incubaid.herolib.ui.console
import incubaid.herolib.data.ourtime

@[params]
pub struct WorkspaceAddDirectoryParams {
pub mut:
	path        string @[required] // Path to directory directory
	name        string // Optional custom name (defaults to directory name)
	description string // Optional description
	scan        bool = true // Whether to scan the directory (default: true)
}

// add_directory adds a new directory to this workspace
pub fn (mut ws Workspace) add_directory(args WorkspaceAddDirectoryParams) !&Directory {
	console.print_header('Adding directory to workspace: ${ws.name}')

	// Create directory
	repo := new_directory(
		path:        args.path
		name:        args.name
		description: args.description
	)!

	// Check if directory already exists
	for _, existing_repo in ws.directories {
		if existing_repo.path == repo.path {
			return error('directory already added: ${repo.path}')
		}
	}

	// Add to workspace
	ws.directories[repo.id] = &repo
	ws.updated = ourtime.now()

	// Auto-save to Redis
	if mut parent := ws.parent {
		parent.save() or {
			console.print_stderr('Warning: Failed to auto-save after adding directory: ${err}')
		}
	}

	console.print_info('Directory added: ${repo.name}')
	return ws.directories[repo.id] or { return error('failed to retrieve added directory') }
}

@[params]
pub struct WorkspaceRemoveDirectoryParams {
pub mut:
	id   string // Directory ID
	path string // Directory path (alternative to ID)
	name string // Directory name (alternative to ID)
}

// remove_directory removes a directory from this workspace
pub fn (mut ws Workspace) remove_directory(args WorkspaceRemoveDirectoryParams) ! {
	mut found_id := ''

	// Find directory by ID, path, or name
	if args.id.len > 0 {
		if args.id in ws.directories {
			found_id = args.id
		}
	} else if args.path.len > 0 {
		// Normalize the path for comparison
		normalized_path := os.real_path(args.path)
		for id, repo in ws.directories {
			if repo.path == normalized_path {
				found_id = id
				break
			}
		}
	} else if args.name.len > 0 {
		for id, repo in ws.directories {
			if repo.name == args.name {
				found_id = id
				break
			}
		}
	}

	if found_id.len == 0 {
		return error('no matching directory found')
	}

	ws.directories.delete(found_id)
	ws.updated = ourtime.now()

	// Auto-save to Redis
	if mut parent := ws.parent {
		parent.save() or {
			console.print_stderr('Warning: Failed to auto-save after removing directory: ${err}')
		}
	}

	console.print_info('Directory removed from workspace')
}

// get_directory retrieves a directory by ID
pub fn (ws &Workspace) get_directory(id string) !&Directory {
	if id !in ws.directories {
		return error('directory not found: ${id}')
	}
	return ws.directories[id] or { return error('directory not found: ${id}') }
}

// list_directories returns all directories in this workspace
pub fn (ws &Workspace) list_directories() []&Directory {
	mut repos := []&Directory{}
	for _, repo in ws.directories {
		repos << repo
	}
	return repos
}

@[params]
pub struct WorkspaceAddFileParams {
pub mut:
	path string @[required] // Path to file
}

// add_file adds a standalone file to this workspace
pub fn (mut ws Workspace) add_file(args WorkspaceAddFileParams) !HeropromptFile {
	console.print_info('Adding file to workspace: ${args.path}')

	// Create file using the file factory
	file := new_file(path: args.path)!

	// Check if file already exists
	for existing_file in ws.files {
		if existing_file.path == file.path {
			return error('file already added: ${file.path}')
		}
	}

	// Add to workspace
	ws.files << file
	ws.updated = ourtime.now()

	// Auto-save to Redis
	if mut parent := ws.parent {
		parent.save() or {
			console.print_stderr('Warning: Failed to auto-save after adding file: ${err}')
		}
	}

	console.print_info('File added: ${file.name}')
	return file
}

@[params]
pub struct WorkspaceRemoveFileParams {
pub mut:
	id   string // File ID
	path string // File path (alternative to ID)
	name string // File name (alternative to ID)
}

// remove_file removes a file from this workspace
pub fn (mut ws Workspace) remove_file(args WorkspaceRemoveFileParams) ! {
	mut found_idx := -1

	// Find file by ID, path, or name
	for idx, file in ws.files {
		if (args.id.len > 0 && file.id == args.id)
			|| (args.path.len > 0 && file.path == args.path)
			|| (args.name.len > 0 && file.name == args.name) {
			found_idx = idx
			break
		}
	}

	if found_idx == -1 {
		return error('no matching file found')
	}

	ws.files.delete(found_idx)
	ws.updated = ourtime.now()

	// Auto-save to Redis
	if mut parent := ws.parent {
		parent.save() or {
			console.print_stderr('Warning: Failed to auto-save after removing file: ${err}')
		}
	}

	console.print_info('File removed from workspace')
}

// get_file retrieves a file by ID
pub fn (ws &Workspace) get_file(id string) !HeropromptFile {
	for file in ws.files {
		if file.id == id {
			return file
		}
	}
	return error('file not found: ${id}')
}

// list_files returns all standalone files in this workspace
pub fn (ws &Workspace) list_files() []HeropromptFile {
	return ws.files
}

// item_count returns total items
pub fn (ws &Workspace) item_count() int {
	return ws.directories.len + ws.files.len
}

// str returns a string representation of the workspace
pub fn (ws &Workspace) str() string {
	return 'Workspace{name: "${ws.name}", directories: ${ws.directories.len}, files: ${ws.files.len}, is_active: ${ws.is_active}}'
}

// File Selection Methods

// select_file marks a file as selected for prompt generation
// The file path should be absolute or will be resolved relative to workspace
pub fn (mut ws Workspace) select_file(path string) ! {
	// Normalize path
	file_path := os.real_path(path)

	// Try to find and select in standalone files
	for mut file in ws.files {
		if os.real_path(file.path) == file_path {
			file.is_selected = true
			ws.updated = ourtime.now()
			if mut parent := ws.parent {
				parent.save() or {
					console.print_stderr('Warning: Failed to auto-save after selecting file: ${err}')
				}
			}
			return
		}
	}

	// File not found in workspace
	return error('file not found in workspace: ${path}')
}

// deselect_file marks a file as not selected
pub fn (mut ws Workspace) deselect_file(path string) ! {
	// Normalize path
	file_path := os.real_path(path)

	// Try to find and deselect in standalone files
	for mut file in ws.files {
		if os.real_path(file.path) == file_path {
			file.is_selected = false
			ws.updated = ourtime.now()
			if mut parent := ws.parent {
				parent.save() or {
					console.print_stderr('Warning: Failed to auto-save after deselecting file: ${err}')
				}
			}
			return
		}
	}

	// File not found in workspace
	return error('file not found in workspace: ${path}')
}

// select_all_files marks all files in the workspace as selected
pub fn (mut ws Workspace) select_all_files() ! {
	// Select all standalone files
	for mut file in ws.files {
		file.is_selected = true
	}

	ws.updated = ourtime.now()
	if mut parent := ws.parent {
		parent.save() or {
			console.print_stderr('Warning: Failed to auto-save after selecting all files: ${err}')
		}
	}
}

// deselect_all_files marks all files in the workspace as not selected
pub fn (mut ws Workspace) deselect_all_files() ! {
	// Deselect all standalone files
	for mut file in ws.files {
		file.is_selected = false
	}

	ws.updated = ourtime.now()
	if mut parent := ws.parent {
		parent.save() or {
			console.print_stderr('Warning: Failed to auto-save after deselecting all files: ${err}')
		}
	}
}

// get_selected_files returns all files that are currently selected
pub fn (ws &Workspace) get_selected_files() ![]string {
	mut selected := []string{}

	// Collect selected standalone files
	for file in ws.files {
		if file.is_selected {
			selected << file.path
		}
	}

	// Collect selected files from directories
	for _, dir in ws.directories {
		// Add files from directory's selected_files map
		for file_path, is_selected in dir.selected_files {
			if is_selected {
				selected << file_path
			}
		}
	}

	return selected
}
