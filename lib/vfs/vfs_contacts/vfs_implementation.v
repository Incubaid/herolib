module vfs_contacts

import json
import time
import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.models as contacts
import incubaid.herolib.core.texttools

// Basic operations
pub fn (mut myvfs ContactsVFS) root_get() !vfs.FSEntry {
	metadata := vfs.Metadata{
		id:          1
		name:        ''
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}

	return ContactsFSEntry{
		path:     ''
		metadata: metadata
	}
}

// File operations
pub fn (mut myvfs ContactsVFS) file_create(path string) !vfs.FSEntry {
	return error('Contacts VFS is read-only')
}

pub fn (mut myvfs ContactsVFS) file_read(path string) ![]u8 {
	if !myvfs.exists(path) {
		return error('File does not exist: ${path}')
	}

	entry := myvfs.get(path)!

	if !entry.is_file() {
		return error('Path is not a file: ${path}')
	}

	contacts_entry := entry as ContactsFSEntry
	if contact := contacts_entry.contact {
		return json.encode(contact).bytes()
	}

	return error('Failed to read file: ${path}')
}

pub fn (mut myvfs ContactsVFS) file_write(path string, data []u8) ! {
	return error('Contacts VFS is read-only')
}

pub fn (mut myvfs ContactsVFS) file_concatenate(path string, data []u8) ! {
	return error('Contacts VFS is read-only')
}

pub fn (mut myvfs ContactsVFS) file_delete(path string) ! {
	return error('Contacts VFS is read-only')
}

// Directory operations
pub fn (mut myvfs ContactsVFS) dir_create(path string) !vfs.FSEntry {
	return error('Contacts VFS is read-only')
}

pub fn (mut myvfs ContactsVFS) dir_list(path string) ![]vfs.FSEntry {
	if !myvfs.exists(path) {
		return error('Directory does not exist: ${path}')
	}

	// Get all contacts
	contacts_ := myvfs.contacts_db.getall() or { return error('Failed to get contacts: ${err}') }

	// If we're at the root, return all groups
	if path == '' {
		return myvfs.list_groups(contacts_)!
	}

	// Check if we're in a group path
	path_parts := path.split('/')
	if path_parts.len == 1 {
		// We're in a group, show the by_name and by_email directories
		return myvfs.list_group_subdirs(path)!
	} else if path_parts.len == 2 && path_parts[1] in ['by_name', 'by_email'] {
		// We're in a by_name or by_email directory, list the contacts
		return myvfs.list_contacts_by_type(path_parts[0], path_parts[1], contacts_)!
	}

	return []vfs.FSEntry{}
}

pub fn (mut myvfs ContactsVFS) dir_delete(path string) ! {
	return error('Contacts VFS is read-only')
}

// Symlink operations
pub fn (mut myvfs ContactsVFS) link_create(target_path string, link_path string) !vfs.FSEntry {
	return error('Contacts VFS does not support symlinks')
}

pub fn (mut myvfs ContactsVFS) link_read(path string) !string {
	return error('Contacts VFS does not support symlinks')
}

pub fn (mut myvfs ContactsVFS) link_delete(path string) ! {
	return error('Contacts VFS does not support symlinks')
}

// Common operations
pub fn (mut myvfs ContactsVFS) exists(path string) bool {
	// Root always exists
	if path == '' {
		return true
	}

	// Get all contacts
	contacts_ := myvfs.contacts_db.getall() or { return false }

	path_parts := path.split('/')

	// Check if the path is a group
	if path_parts.len == 1 {
		for contact in contacts_ {
			if contact.group == path_parts[0] {
				return true
			}
		}
	}

	// Check if the path is a group subdir (by_name or by_email)
	if path_parts.len == 2 && path_parts[1] in ['by_name', 'by_email'] {
		for contact in contacts_ {
			if contact.group == path_parts[0] {
				return true
			}
		}
	}

	// Check if the path is a contact file
	if path_parts.len == 3 && path_parts[1] in ['by_name', 'by_email'] {
		for contact in contacts_ {
			if contact.group != path_parts[0] {
				continue
			}

			if path_parts[1] == 'by_name' {
				filename := texttools.name_fix('${contact.first_name}_${contact.last_name}') +
					'.json'
				if filename == path_parts[2] {
					return true
				}
			} else if path_parts[1] == 'by_email' {
				filename := texttools.name_fix(contact.email) + '.json'
				if filename == path_parts[2] {
					return true
				}
			}
		}
	}

	return false
}

pub fn (mut myvfs ContactsVFS) get(path string) !vfs.FSEntry {
	// Root always exists
	if path == '' {
		return myvfs.root_get()!
	}

	// Get all contacts
	contacts_ := myvfs.contacts_db.getall() or { return error('Failed to get contacts: ${err}') }

	path_parts := path.split('/')

	// Check if the path is a group
	if path_parts.len == 1 {
		for contact in contacts_ {
			if contact.group == path_parts[0] {
				metadata := vfs.Metadata{
					id:          u32(path_parts[0].bytes().bytestr().hash())
					name:        path_parts[0]
					file_type:   .directory
					created_at:  time.now().unix()
					modified_at: time.now().unix()
					accessed_at: time.now().unix()
				}

				return ContactsFSEntry{
					path:     path
					metadata: metadata
				}
			}
		}
	}

	// Check if the path is a group subdir (by_name or by_email)
	if path_parts.len == 2 && path_parts[1] in ['by_name', 'by_email'] {
		metadata := vfs.Metadata{
			id:          u32(path.bytes().bytestr().hash())
			name:        path_parts[1]
			file_type:   .directory
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
		}

		return ContactsFSEntry{
			path:     path
			metadata: metadata
		}
	}

	// Check if the path is a contact file
	if path_parts.len == 3 && path_parts[1] in ['by_name', 'by_email'] {
		for contact in contacts_ {
			if contact.group != path_parts[0] {
				continue
			}

			if path_parts[1] == 'by_name' {
				filename := texttools.name_fix('${contact.first_name}_${contact.last_name}') +
					'.json'
				if filename == path_parts[2] {
					metadata := vfs.Metadata{
						id:          u32(contact.id)
						name:        filename
						file_type:   .file
						size:        u64(json.encode(contact).len)
						created_at:  contact.created_at
						modified_at: contact.modified_at
						accessed_at: time.now().unix()
					}

					return ContactsFSEntry{
						path:     path
						metadata: metadata
						contact:  contact
					}
				}
			} else if path_parts[1] == 'by_email' {
				filename := texttools.name_fix(contact.email) + '.json'
				if filename == path_parts[2] {
					metadata := vfs.Metadata{
						id:          u32(contact.id)
						name:        filename
						file_type:   .file
						size:        u64(json.encode(contact).len)
						created_at:  contact.created_at
						modified_at: contact.modified_at
						accessed_at: time.now().unix()
					}

					return ContactsFSEntry{
						path:     path
						metadata: metadata
						contact:  contact
					}
				}
			}
		}
	}

	return error('Path not found: ${path}')
}

pub fn (mut myvfs ContactsVFS) rename(old_path string, new_path string) !vfs.FSEntry {
	return error('Contacts VFS is read-only')
}

pub fn (mut myvfs ContactsVFS) copy(src_path string, dst_path string) !vfs.FSEntry {
	return error('Contacts VFS is read-only')
}

pub fn (mut myvfs ContactsVFS) move(src_path string, dst_path string) !vfs.FSEntry {
	return error('Contacts VFS is read-only')
}

pub fn (mut myvfs ContactsVFS) delete(path string) ! {
	return error('Contacts VFS is read-only')
}

// FSEntry Operations
pub fn (mut myvfs ContactsVFS) get_path(entry &vfs.FSEntry) !string {
	contacts_entry := entry as ContactsFSEntry
	return contacts_entry.path
}

pub fn (mut myvfs ContactsVFS) print() ! {
	println('Contacts VFS')
}

// Cleanup operation
pub fn (mut myvfs ContactsVFS) destroy() ! {
	// Nothing to clean up
}

// Helper functions
fn (mut myvfs ContactsVFS) list_groups(contacts_ []contacts.Contact) ![]vfs.FSEntry {
	mut groups := map[string]bool{}

	// Collect unique group names
	for contact in contacts_ {
		groups[contact.group] = true
	}

	// Create FSEntry for each group
	mut result := []vfs.FSEntry{cap: groups.len}
	for group, _ in groups {
		metadata := vfs.Metadata{
			id:          u32(group.bytes().bytestr().hash())
			name:        group
			file_type:   .directory
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
		}

		result << ContactsFSEntry{
			path:     group
			metadata: metadata
		}
	}

	return result
}

fn (mut myvfs ContactsVFS) list_group_subdirs(group string) ![]vfs.FSEntry {
	mut result := []vfs.FSEntry{cap: 2}

	// Create by_name directory
	by_name_metadata := vfs.Metadata{
		id:          u32('${group}/by_name'.bytes().bytestr().hash())
		name:        'by_name'
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}

	result << ContactsFSEntry{
		path:     '${group}/by_name'
		metadata: by_name_metadata
	}

	// Create by_email directory
	by_email_metadata := vfs.Metadata{
		id:          u32('${group}/by_email'.bytes().bytestr().hash())
		name:        'by_email'
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}

	result << ContactsFSEntry{
		path:     '${group}/by_email'
		metadata: by_email_metadata
	}

	return result
}

fn (mut myvfs ContactsVFS) list_contacts_by_type(group string, list_type string, contacts_ []contacts.Contact) ![]vfs.FSEntry {
	mut result := []vfs.FSEntry{}

	for contact in contacts_ {
		if contact.group != group {
			continue
		}

		if list_type == 'by_name' {
			filename := texttools.name_fix('${contact.first_name}_${contact.last_name}') + '.json'
			metadata := vfs.Metadata{
				id:          u32(contact.id)
				name:        filename
				file_type:   .file
				size:        u64(json.encode(contact).len)
				created_at:  contact.created_at
				modified_at: contact.modified_at
				accessed_at: time.now().unix()
			}

			result << ContactsFSEntry{
				path:     '${group}/by_name/${filename}'
				metadata: metadata
				contact:  contact
			}
		} else if list_type == 'by_email' {
			filename := texttools.name_fix(contact.email) + '.json'
			metadata := vfs.Metadata{
				id:          u32(contact.id)
				name:        filename
				file_type:   .file
				size:        u64(json.encode(contact).len)
				created_at:  contact.created_at
				modified_at: contact.modified_at
				accessed_at: time.now().unix()
			}

			result << ContactsFSEntry{
				path:     '${group}/by_email/${filename}'
				metadata: metadata
				contact:  contact
			}
		}
	}

	return result
}
