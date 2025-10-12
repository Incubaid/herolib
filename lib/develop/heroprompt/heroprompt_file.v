module heroprompt

import rand
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.data.ourtime

// HeropromptFile represents a standalone file added to a workspace
// (not part of a directory)
@[heap]
pub struct HeropromptFile {
pub mut:
	id          string = rand.uuid_v4() // Unique identifier
	name        string          // File name
	path        string          // Absolute path to file
	content     string          // File content (cached)
	created     ourtime.OurTime // When added to workspace
	updated     ourtime.OurTime // Last update time
	is_selected bool            // UI state: whether file checkbox is checked
}

// Create a new file instance
@[params]
pub struct NewFileParams {
pub mut:
	path string @[required] // Absolute path to file
}

pub fn new_file(args NewFileParams) !HeropromptFile {
	if args.path.len == 0 {
		return error('file path is required')
	}

	mut file_path := pathlib.get(args.path)
	if !file_path.exists() || !file_path.is_file() {
		return error('path is not an existing file: ${args.path}')
	}

	abs_path := file_path.realpath()
	file_name := file_path.name()

	// Read file content
	content := file_path.read() or { '' }

	return HeropromptFile{
		id:      rand.uuid_v4()
		name:    file_name
		path:    abs_path
		content: content
		created: ourtime.now()
		updated: ourtime.now()
	}
}

// Refresh file content from disk
pub fn (mut file HeropromptFile) refresh() ! {
	mut file_path := pathlib.get(file.path)
	if !file_path.exists() {
		return error('file no longer exists: ${file.path}')
	}
	file.content = file_path.read()!
	file.updated = ourtime.now()
}

// Check if file still exists
pub fn (file &HeropromptFile) exists() bool {
	mut file_path := pathlib.get(file.path)
	return file_path.exists() && file_path.is_file()
}

// Get file extension
pub fn (file &HeropromptFile) extension() string {
	return get_file_extension(file.name)
}

// Utility function to get file extension with special handling for common files
pub fn get_file_extension(filename string) string {
	// Handle special cases for common files without extensions
	special_files := {
		'dockerfile':   'dockerfile'
		'makefile':     'makefile'
		'license':      'license'
		'readme':       'readme'
		'changelog':    'changelog'
		'authors':      'authors'
		'contributors': 'contributors'
		'copying':      'copying'
		'install':      'install'
		'news':         'news'
		'todo':         'todo'
		'version':      'version'
		'manifest':     'manifest'
		'gemfile':      'gemfile'
		'rakefile':     'rakefile'
		'procfile':     'procfile'
		'vagrantfile':  'vagrantfile'
	}
	lower_filename := filename.to_lower()
	if lower_filename in special_files {
		return special_files[lower_filename]
	}
	if filename.starts_with('.') && !filename.starts_with('..') {
		if filename.contains('.') && filename.len > 1 {
			parts := filename[1..].split('.')
			if parts.len >= 2 {
				return parts[parts.len - 1]
			} else {
				return filename[1..]
			}
		} else {
			return filename[1..]
		}
	}
	parts := filename.split('.')
	if parts.len < 2 {
		return ''
	}
	return parts[parts.len - 1]
}
