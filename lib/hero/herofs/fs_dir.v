module herofs

import time
import crypto.blake3
import json
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// FsDir represents a directory in a filesystem
@[heap]
pub struct FsDir {
	db.Base
pub mut:
	name      string
	fs_id     u32 // Associated filesystem
	parent_id u32 // Parent directory ID (0 for root)
}

// DirectoryContents represents the contents of a directory
pub struct DirectoryContents {
pub mut:
	directories []FsDir
	files       []FsFile
	symlinks    []FsSymlink
}

// ListContentsOptions defines options for listing directory contents
@[params]
pub struct ListContentsOptions {
pub mut:
	recursive        bool
	include_patterns []string // File/directory name patterns to include (e.g. *.py, doc*)
	exclude_patterns []string // File/directory name patterns to exclude
}

// we only keep the parents, not the children, as children can be found by doing a query on parent_id, we will need some smart hsets to make this fast enough and efficient

pub struct DBFsDir {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self FsDir) type_name() string {
	return 'fs_dir'
}

pub fn (self FsDir) dump(mut e encoder.Encoder) ! {
	e.add_string(self.name)
	e.add_u32(self.fs_id)
	e.add_u32(self.parent_id)
}

fn (mut self DBFsDir) load(mut o FsDir, mut e encoder.Decoder) ! {
	o.name = e.get_string()!
	o.fs_id = e.get_u32()!
	o.parent_id = e.get_u32()!
}

@[params]
pub struct FsDirArg {
pub mut:
	name        string @[required]
	description string
	fs_id       u32 @[required]
	parent_id   u32
	tags        []string
	comments    []db.CommentArg
}

// get new directory, not from the DB
pub fn (mut self DBFsDir) new(args FsDirArg) !FsDir {
	mut o := FsDir{
		name:      args.name
		fs_id:     args.fs_id
		parent_id: args.parent_id
	}

	// Set base fields
	o.description = args.description
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBFsDir) set(o FsDir) !u32 {
	id := self.db.set[FsDir](o)!

	// Store directory in filesystem's directory index
	path_key := '${o.fs_id}:${o.parent_id}:${o.name}'
	self.db.redis.hset('fsdir:paths', path_key, id.str())!

	// Store in filesystem's directory list using hset
	self.db.redis.hset('fsdir:fs:${o.fs_id}', id.str(), id.str())!

	// Store in parent's children list using hset
	if o.parent_id > 0 {
		self.db.redis.hset('fsdir:children:${o.parent_id}', id.str(), id.str())!
	}

	return id
}

pub fn (mut self DBFsDir) delete(id u32) ! {
	// Get the directory info before deleting
	dir := self.get(id)!

	// Check if directory has children using hkeys
	children := self.db.redis.hkeys('fsdir:children:${id}')!
	if children.len > 0 {
		return error('Cannot delete directory ${dir.name} (ID: ${id}) because it has ${children.len} children')
	}

	// Remove from path index
	path_key := '${dir.fs_id}:${dir.parent_id}:${dir.name}'
	self.db.redis.hdel('fsdir:paths', path_key)!

	// Remove from filesystem's directory list using hdel
	self.db.redis.hdel('fsdir:fs:${dir.fs_id}', id.str())!

	// Remove from parent's children list using hdel
	if dir.parent_id > 0 {
		self.db.redis.hdel('fsdir:children:${dir.parent_id}', id.str())!
	}

	// Delete the directory itself
	self.db.delete[FsDir](id)!
}

pub fn (mut self DBFsDir) exist(id u32) !bool {
	return self.db.exists[FsDir](id)!
}

pub fn (mut self DBFsDir) get(id u32) !FsDir {
	mut o, data := self.db.get_data[FsDir](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBFsDir) list() ![]FsDir {
	return self.db.list[FsDir]()!.map(self.get(it)!)
}

// Get directory by path components
pub fn (mut self DBFsDir) get_by_path(fs_id u32, parent_id u32, name string) !FsDir {
	path_key := '${fs_id}:${parent_id}:${name}'
	id_str := self.db.redis.hget('fsdir:paths', path_key)!
	if id_str == '' {
		return error('Directory "${name}" not found in filesystem ${fs_id} under parent ${parent_id}')
	}
	return self.get(id_str.u32())!
}

// Get all directories in a filesystem
pub fn (mut self DBFsDir) list_by_filesystem(fs_id u32) ![]FsDir {
	dir_ids := self.db.redis.hkeys('fsdir:fs:${fs_id}')!
	mut dirs := []FsDir{}
	for id_str in dir_ids {
		dirs << self.get(id_str.u32())!
	}
	return dirs
}

// Get directory by absolute path
pub fn (mut self DBFsDir) get_by_absolute_path(fs_id u32, path string) !FsDir {
	// Normalize path (remove trailing slashes, handle empty path)
	normalized_path := if path == '' || path == '/' { '/' } else { path.trim_right('/') }
	
	if normalized_path == '/' {
		// Special case for root directory
		dirs := self.list_by_filesystem(fs_id)!
		for dir in dirs {
			if dir.parent_id == 0 {
				return dir
			}
		}
		return error('Root directory not found for filesystem ${fs_id}')
	}
	
	// Split path into components
	components := normalized_path.trim_left('/').split('/')
	
	// Start from the root directory
	mut current_dir_id := u32(0)
	mut dirs := self.list_by_filesystem(fs_id)!
	
	// Find root directory
	for dir in dirs {
		if dir.parent_id == 0 {
			current_dir_id = dir.id
			break
		}
	}
	
	if current_dir_id == 0 {
		return error('Root directory not found for filesystem ${fs_id}')
	}
	
	// Navigate through path components
	for component in components {
		mut found := false
		for dir in dirs {
			if dir.parent_id == current_dir_id && dir.name == component {
				current_dir_id = dir.id
				found = true
				break
			}
		}
		
		if !found {
			return error('Directory "${component}" not found in path "${normalized_path}"')
		}
		
		// Update dirs for next iteration
		dirs = self.list_children(current_dir_id)!
	}
	
	return self.get(current_dir_id)!
}

// Create a directory by absolute path, creating parent directories as needed
pub fn (mut self DBFsDir) create_path(fs_id u32, path string) !u32 {
	// Normalize path
	normalized_path := if path == '' || path == '/' { '/' } else { path.trim_right('/') }
	
	if normalized_path == '/' {
		// Special case for root directory
		dirs := self.list_by_filesystem(fs_id)!
		for dir in dirs {
			if dir.parent_id == 0 {
				return dir.id
			}
		}
		
		// Create root directory if it doesn't exist
		mut root_dir := self.new(
			name: 'root'
			fs_id: fs_id
			parent_id: 0
			description: 'Root directory'
		)!
		return self.set(root_dir)!
	}
	
	// Split path into components
	components := normalized_path.trim_left('/').split('/')
	
	// Start from the root directory
	mut current_dir_id := u32(0)
	mut dirs := self.list_by_filesystem(fs_id)!
	
	// Find or create root directory
	for dir in dirs {
		if dir.parent_id == 0 {
			current_dir_id = dir.id
			break
		}
	}
	
	if current_dir_id == 0 {
		// Create root directory
		mut root_dir := self.new(
			name: 'root'
			fs_id: fs_id
			parent_id: 0
			description: 'Root directory'
		)!
		current_dir_id = self.set(root_dir)!
	}
	
	// Navigate/create through path components
	for component in components {
		mut found := false
		for dir in dirs {
			if dir.parent_id == current_dir_id && dir.name == component {
				current_dir_id = dir.id
				found = true
				break
			}
		}
		
		if !found {
			// Create this directory component
			mut new_dir := self.new(
				name: component
				fs_id: fs_id
				parent_id: current_dir_id
				description: 'Directory created as part of path ${normalized_path}'
			)!
			current_dir_id = self.set(new_dir)!
		}
		
		// Update directory list for next iteration
		dirs = self.list_children(current_dir_id)!
	}
	
	return current_dir_id
}

// Delete a directory by absolute path
pub fn (mut self DBFsDir) delete_by_path(fs_id u32, path string) ! {
	dir := self.get_by_absolute_path(fs_id, path)!
	self.delete(dir.id)!
}

// Move a directory using source and destination paths
pub fn (mut self DBFsDir) move_by_path(fs_id u32, source_path string, dest_path string) !u32 {
	// Get the source directory
	source_dir := self.get_by_absolute_path(fs_id, source_path)!
	
	// For the destination, we need the parent directory
	dest_dir_path := dest_path.all_before_last('/')
	dest_dir_name := dest_path.all_after_last('/')
	
	dest_parent_dir := if dest_dir_path == '' || dest_dir_path == '/' {
		// Moving to the root
		self.get_by_absolute_path(fs_id, '/')!
	} else {
		self.get_by_absolute_path(fs_id, dest_dir_path)!
	}
	
	// First rename if the destination name is different
	if source_dir.name != dest_dir_name {
		self.rename(source_dir.id, dest_dir_name)!
	}
	
	// Then move to the new parent
	return self.move(source_dir.id, dest_parent_dir.id)!
}

// Get children of a directory
pub fn (mut self DBFsDir) list_children(dir_id u32) ![]FsDir {
	child_ids := self.db.redis.hkeys('fsdir:children:${dir_id}')!
	mut dirs := []FsDir{}
	for id_str in child_ids {
		dirs << self.get(id_str.u32())!
	}
	return dirs
}

// Check if a directory has children
pub fn (mut self DBFsDir) has_children(dir_id u32) !bool {
	keys := self.db.redis.hkeys('fsdir:children:${dir_id}')!
	return keys.len > 0
}

// Rename a directory
pub fn (mut self DBFsDir) rename(id u32, new_name string) !u32 {
	mut dir := self.get(id)!

	// Remove old path index
	old_path_key := '${dir.fs_id}:${dir.parent_id}:${dir.name}'
	self.db.redis.hdel('fsdir:paths', old_path_key)!

	// Update name
	dir.name = new_name

	// Save with new name
	return self.set(dir)!
}

// Move a directory to a new parent
pub fn (mut self DBFsDir) move(id u32, new_parent_id u32) !u32 {
	mut dir := self.get(id)!

	// Check that new parent exists and is in the same filesystem
	if new_parent_id > 0 {
		parent := self.get(new_parent_id)!
		if parent.fs_id != dir.fs_id {
			return error('Cannot move directory across filesystems')
		}
	}

	// Remove old path index
	old_path_key := '${dir.fs_id}:${dir.parent_id}:${dir.name}'
	self.db.redis.hdel('fsdir:paths', old_path_key)!

	// Remove from old parent's children list
	if dir.parent_id > 0 {
		self.db.redis.hdel('fsdir:children:${dir.parent_id}', id.str())!
	}

	// Update parent
	dir.parent_id = new_parent_id

	// Save with new parent
	return self.set(dir)!
}

// List contents of a directory with filtering capabilities
pub fn (mut self DBFsDir) list_contents(mut fs_factory FsFactory, dir_id u32, opts ListContentsOptions) !DirectoryContents {
	mut result := DirectoryContents{}
	
	// Helper function to check if name matches include/exclude patterns
	
	// Check if item should be included based on patterns
	should_include_local := fn (name string, include_patterns []string, exclude_patterns []string) bool {
		// Helper function to check if name matches include/exclude patterns
		matches_pattern_fn := fn (name_inner string, patterns []string) bool {
			if patterns.len == 0 {
				return true // No patterns means include everything
			}
			
			for pattern in patterns {
				if pattern.contains('*') {
					prefix := pattern.all_before('*')
					suffix := pattern.all_after('*')
					
					if prefix == '' && suffix == '' {
						return true // Pattern is just "*"
					} else if prefix == '' {
						if name_inner.ends_with(suffix) {
							return true
						}
					} else if suffix == '' {
						if name_inner.starts_with(prefix) {
							return true
						}
					} else {
						if name_inner.starts_with(prefix) && name_inner.ends_with(suffix) {
							return true
						}
					}
				} else if name_inner == pattern {
					return true // Exact match
				}
			}
			
			return false
		}
		
		// First apply include patterns (if empty, include everything)
		if !matches_pattern_fn(name, include_patterns) && include_patterns.len > 0 {
			return false
		}
		
		// Then apply exclude patterns
		if matches_pattern_fn(name, exclude_patterns) && exclude_patterns.len > 0 {
			return false
		}
		
		return true
	}
	
	// Get directories, files, and symlinks in the current directory
	dirs := self.list_children(dir_id)!
	for dir in dirs {
		if should_include_local(dir.name, opts.include_patterns, opts.exclude_patterns) {
			result.directories << dir
		}
		
		// If recursive, process subdirectories
		if opts.recursive {
			sub_contents := self.list_contents(mut fs_factory, dir.id, opts)!
			result.directories << sub_contents.directories
			result.files << sub_contents.files
			result.symlinks << sub_contents.symlinks
		}
	}
	
	// Get files in the directory
	files := fs_factory.fs_file.list_by_directory(dir_id)!
	for file in files {
		if should_include_local(file.name, opts.include_patterns, opts.exclude_patterns) {
			result.files << file
		}
	}
	
	// Get symlinks in the directory
	symlinks := fs_factory.fs_symlink.list_by_parent(dir_id)!
	for symlink in symlinks {
		if should_include_local(symlink.name, opts.include_patterns, opts.exclude_patterns) {
			result.symlinks << symlink
		}
	}
	
	return result
}
