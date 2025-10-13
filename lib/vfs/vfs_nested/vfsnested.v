module vfs_nested

import incubaid.herolib.vfs
import time

// NestedVFS represents a VFS that can contain multiple nested VFS instances
pub struct NestedVFS {
mut:
	vfs_map map[string]vfs.VFSImplementation @[skip] // Map of path prefixes to VFS implementations
}

// new creates a new NestedVFS instance
pub fn new() &NestedVFS {
	return &NestedVFS{
		vfs_map: map[string]vfs.VFSImplementation{}
	}
}

// add_vfs adds a new VFS implementation at the specified path prefix
pub fn (mut self NestedVFS) add_vfs(prefix string, impl vfs.VFSImplementation) ! {
	if prefix in self.vfs_map {
		return error('VFS already exists at prefix: ${prefix}')
	}
	self.vfs_map[prefix] = impl
}

// find_vfs finds the appropriate VFS implementation for a given path
fn (self &NestedVFS) find_vfs(path string) !(vfs.VFSImplementation, string) {
	if path == '' || path == '/' {
		return self, '/'
	}

	// Sort prefixes by length (longest first) to match most specific path
	mut prefixes := self.vfs_map.keys()
	prefixes.sort(a.len > b.len)

	for prefix in prefixes {
		if path.starts_with(prefix) {
			relative_path := path[prefix.len..]
			return self.vfs_map[prefix], relative_path
		}
	}
	return error('No VFS found for path: ${path}')
}

// Implementation of VFSImplementation interface
pub fn (mut self NestedVFS) root_get() !vfs.FSEntry {
	// Return a special root entry that represents the nested VFS
	return &RootEntry{
		metadata: vfs.Metadata{
			id:          0
			name:        ''
			path:        '/'
			file_type:   .directory
			size:        0
			created_at:  0
			modified_at: 0
			accessed_at: 0
		}
	}
}

pub fn (mut self NestedVFS) delete(path string) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.delete(rel_path)
}

pub fn (mut self NestedVFS) link_delete(path string) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.link_delete(rel_path)
}

pub fn (mut self NestedVFS) file_create(path string) !vfs.FSEntry {
	mut impl, rel_path := self.find_vfs(path)!
	sub_entry := impl.file_create(rel_path)!

	// Find the prefix for this VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == impl {
			prefix = p
			break
		}
	}

	return self.nester_entry(sub_entry, prefix)
}

pub fn (mut self NestedVFS) file_read(path string) ![]u8 {
	// Special handling for macOS resource fork files (._*)
	if path.starts_with('/._') || path.contains('/._') {
		// Return empty data for resource fork files
		return []u8{}
	}

	mut impl, rel_path := self.find_vfs(path)!
	return impl.file_read(rel_path)
}

pub fn (mut self NestedVFS) file_write(path string, data []u8) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.file_write(rel_path, data)
}

pub fn (mut self NestedVFS) file_delete(path string) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.file_delete(rel_path)
}

pub fn (mut self NestedVFS) dir_create(path string) !vfs.FSEntry {
	mut impl, rel_path := self.find_vfs(path)!
	sub_entry := impl.dir_create(rel_path)!

	// Find the prefix for this VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == impl {
			prefix = p
			break
		}
	}

	return self.nester_entry(sub_entry, prefix)
}

pub fn (mut self NestedVFS) dir_list(path string) ![]vfs.FSEntry {
	// Special case for root directory
	if path == '' || path == '/' {
		mut entries := []vfs.FSEntry{}
		for prefix, mut impl in self.vfs_map {
			root := impl.root_get() or { continue }
			entries << &MountEntry{
				metadata: vfs.Metadata{
					id:          0
					name:        prefix
					path:        prefix
					file_type:   .directory
					size:        0
					created_at:  0
					modified_at: 0
					accessed_at: 0
				}
				impl:     impl
			}
		}
		return entries
	}

	mut impl, rel_path := self.find_vfs(path)!
	sub_entries := impl.dir_list(rel_path)!

	// Find the prefix for this VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == impl {
			prefix = p
			break
		}
	}

	// Convert all entries to nested entries
	mut entries := []vfs.FSEntry{}
	for sub_entry in sub_entries {
		entries << self.nester_entry(sub_entry, prefix)
	}

	return entries
}

pub fn (mut self NestedVFS) dir_delete(path string) ! {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.dir_delete(rel_path)
}

pub fn (mut self NestedVFS) exists(path string) bool {
	// QUESTION: should root be nestervfs's own?
	if path == '' || path == '/' {
		return true
	}

	// // Special handling for macOS resource fork files (._*)
	// if path.starts_with('/._') || path.contains('/._') {
	// 	return true // Pretend these files exist for WebDAV Class 2 compatibility
	// }

	mut impl, rel_path := self.find_vfs(path) or { return false }
	return impl.exists(rel_path)
}

pub fn (mut self NestedVFS) get(path string) !vfs.FSEntry {
	if path == '' || path == '/' {
		return self.root_get()
	}

	// // Special handling for macOS resource fork files (._*)
	// if path.starts_with('/._') || path.contains('/._') {
	// 	// Extract the filename from the path
	// 	filename := path.all_after_last('/')

	// 	// Create a dummy resource fork entry
	// 	return &ResourceForkEntry{
	// 		metadata: vfs.Metadata{
	// 			id:          0
	// 			name:        filename
	// 			file_type:   .file
	// 			size:        0
	// 			created_at:  time.now().unix()
	// 			modified_at: time.now().unix()
	// 			accessed_at: time.now().unix()
	// 		}
	// 		path: path
	// 	}
	// }

	mut impl, rel_path := self.find_vfs(path)!

	// now must convert entry of nested fvs to entry of nester
	sub_entry := impl.get(rel_path)!

	// Find the prefix for this VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == impl {
			prefix = p
			break
		}
	}

	return self.nester_entry(sub_entry, prefix)
}

// nester_entry converts an FSEntry from a sub VFS to an FSEntry for the nester VFS
// by prefixing the nested VFS's path onto the FSEntry's path
fn (self &NestedVFS) nester_entry(entry vfs.FSEntry, prefix string) vfs.FSEntry {
	return &NestedEntry{
		original: entry
		prefix:   prefix
	}
}

pub fn (mut self NestedVFS) rename(old_path string, new_path string) !vfs.FSEntry {
	mut old_impl, old_rel_path := self.find_vfs(old_path)!
	mut new_impl, new_rel_path := self.find_vfs(new_path)!

	if old_impl != new_impl {
		return error('Cannot rename across different VFS implementations')
	}

	renamed_file := old_impl.rename(old_rel_path, new_rel_path)!

	// Find the prefix for this VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == old_impl {
			prefix = p
			break
		}
	}

	return self.nester_entry(renamed_file, prefix)
}

pub fn (mut self NestedVFS) copy(src_path string, dst_path string) !vfs.FSEntry {
	mut src_impl, src_rel_path := self.find_vfs(src_path)!
	mut dst_impl, dst_rel_path := self.find_vfs(dst_path)!

	if src_impl == dst_impl {
		copied_file := src_impl.copy(src_rel_path, dst_rel_path)!

		// Find the prefix for this VFS implementation
		mut prefix := ''
		for p, v in self.vfs_map {
			if v == src_impl {
				prefix = p
				break
			}
		}

		return self.nester_entry(copied_file, prefix)
	}

	// Copy across different VFS implementations
	// TODO: Q: What if it's not file? What if it's a symlink or directory?
	data := src_impl.file_read(src_rel_path)!
	new_file := dst_impl.file_create(dst_rel_path)!
	dst_impl.file_write(dst_rel_path, data)!

	// Find the prefix for the destination VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == dst_impl {
			prefix = p
			break
		}
	}

	return self.nester_entry(new_file, prefix)
}

pub fn (mut self NestedVFS) move(src_path string, dst_path string) !vfs.FSEntry {
	mut src_impl, src_rel_path := self.find_vfs(src_path)!
	_, dst_rel_path := self.find_vfs(dst_path)!
	moved_file := src_impl.move(src_rel_path, dst_rel_path)!

	// Find the prefix for this VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == src_impl {
			prefix = p
			break
		}
	}

	return self.nester_entry(moved_file, prefix)
}

pub fn (mut self NestedVFS) link_create(target_path string, link_path string) !vfs.FSEntry {
	mut impl, rel_path := self.find_vfs(link_path)!
	link_entry := impl.link_create(target_path, rel_path)!

	// Find the prefix for this VFS implementation
	mut prefix := ''
	for p, v in self.vfs_map {
		if v == impl {
			prefix = p
			break
		}
	}

	return self.nester_entry(link_entry, prefix)
}

pub fn (mut self NestedVFS) link_read(path string) !string {
	mut impl, rel_path := self.find_vfs(path)!
	return impl.link_read(rel_path)
}

pub fn (mut self NestedVFS) destroy() ! {
	for _, mut impl in self.vfs_map {
		impl.destroy()!
	}
}

// Special entry types for the nested VFS
struct RootEntry {
	metadata vfs.Metadata
}

fn (e &RootEntry) get_metadata() vfs.Metadata {
	return e.metadata
}

fn (e &RootEntry) get_path() string {
	return '/'
}

// is_dir returns true if the entry is a directory
pub fn (self &RootEntry) is_dir() bool {
	return self.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (self &RootEntry) is_file() bool {
	return self.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (self &RootEntry) is_symlink() bool {
	return self.metadata.file_type == .symlink
}

pub struct MountEntry {
pub mut:
	metadata vfs.Metadata
	impl     vfs.VFSImplementation
}

fn (e &MountEntry) get_metadata() vfs.Metadata {
	return e.metadata
}

fn (e &MountEntry) get_path() string {
	return '/${e.metadata.name.trim_left('/')}'
}

// is_dir returns true if the entry is a directory
pub fn (self &MountEntry) is_dir() bool {
	return self.metadata.file_type == .directory
}

// is_file returns true if the entry is a file
pub fn (self &MountEntry) is_file() bool {
	return self.metadata.file_type == .file
}

// is_symlink returns true if the entry is a symlink
pub fn (self &MountEntry) is_symlink() bool {
	return self.metadata.file_type == .symlink
}

// NestedEntry wraps an FSEntry from a sub VFS and prefixes its path
pub struct NestedEntry {
pub mut:
	original vfs.FSEntry
	prefix   string
}

fn (e &NestedEntry) get_metadata() vfs.Metadata {
	return e.original.get_metadata()
}

fn (e &NestedEntry) get_path() string {
	original_path := e.original.get_path()
	if original_path == '/' {
		return e.prefix
	}
	return e.prefix + '/${original_path.trim_string_left('/')}'
}

// is_dir returns true if the entry is a directory
pub fn (self &NestedEntry) is_dir() bool {
	return self.original.is_dir()
}

// is_file returns true if the entry is a file
pub fn (self &NestedEntry) is_file() bool {
	return self.original.is_file()
}

// is_symlink returns true if the entry is a symlink
pub fn (self &NestedEntry) is_symlink() bool {
	return self.original.is_symlink()
}

// // ResourceForkEntry represents a macOS resource fork file (._*)
// pub struct ResourceForkEntry {
// pub mut:
// 	metadata vfs.Metadata
// 	path     string
// }

// fn (e &ResourceForkEntry) get_metadata() vfs.Metadata {
// 	return e.metadata
// }

// fn (e &ResourceForkEntry) get_path() string {
// 	return e.path
// }

// // is_dir returns true if the entry is a directory
// pub fn (self &ResourceForkEntry) is_dir() bool {
// 	return false
// }

// // is_file returns true if the entry is a file
// pub fn (self &ResourceForkEntry) is_file() bool {
// 	return true
// }

// // is_symlink returns true if the entry is a symlink
// pub fn (self &ResourceForkEntry) is_symlink() bool {
// 	return false
// }
