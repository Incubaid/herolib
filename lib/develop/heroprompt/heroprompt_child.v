module heroprompt

import freeflowuniverse.herolib.core.pathlib
import os

pub struct HeropromptChild {
pub mut:
	content      string
	path         pathlib.Path
	name         string
	include_tree bool // when true and this child is a dir, include full subtree in maps/contents
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

// Read the file content
pub fn (chl HeropromptChild) read() !string {
	if chl.path.cat != .file {
		return error('cannot read content of a directory')
	}
	content := os.read_file(chl.path.path)!
	return content
}
