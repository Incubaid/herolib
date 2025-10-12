module vfs_mail

import json
import time
import incubaid.herolib.vfs
import incubaid.herolib.circles.mcc.models as mail
import incubaid.herolib.core.texttools

// Basic operations
pub fn (mut myvfs MailVFS) root_get() !vfs.FSEntry {
	metadata := vfs.Metadata{
		id:          1
		name:        ''
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}

	return MailFSEntry{
		path:     ''
		metadata: metadata
	}
}

// File operations
pub fn (mut myvfs MailVFS) file_create(path string) !vfs.FSEntry {
	return error('Mail VFS is read-only')
}

pub fn (mut myvfs MailVFS) file_read(path string) ![]u8 {
	if !myvfs.exists(path) {
		return error('File does not exist: ${path}')
	}

	entry := myvfs.get(path)!

	if !entry.is_file() {
		return error('Path is not a file: ${path}')
	}

	mail_entry := entry as MailFSEntry
	if email := mail_entry.email {
		return json.encode(email).bytes()
	}

	return error('Failed to read file: ${path}')
}

pub fn (mut myvfs MailVFS) file_write(path string, data []u8) ! {
	return error('Mail VFS is read-only')
}

pub fn (mut myvfs MailVFS) file_concatenate(path string, data []u8) ! {
	return error('Mail VFS is read-only')
}

pub fn (mut myvfs MailVFS) file_delete(path string) ! {
	return error('Mail VFS is read-only')
}

// Directory operations
pub fn (mut myvfs MailVFS) dir_create(path string) !vfs.FSEntry {
	return error('Mail VFS is read-only')
}

pub fn (mut myvfs MailVFS) dir_list(path string) ![]vfs.FSEntry {
	if !myvfs.exists(path) {
		return error('Directory does not exist: ${path}')
	}

	// Get all emails
	emails := myvfs.mail_db.getall() or { return error('Failed to get emails: ${err}') }

	// If we're at the root, return all mailboxes
	if path == '' {
		return myvfs.list_mailboxes(emails)!
	}

	// Check if we're in a mailbox path
	path_parts := path.split('/')
	if path_parts.len == 1 {
		// We're in a mailbox, show the id and subject directories
		return myvfs.list_mailbox_subdirs(path)!
	} else if path_parts.len == 2 && path_parts[1] in ['id', 'subject'] {
		// We're in an id or subject directory, list the emails
		return myvfs.list_emails_by_type(path_parts[0], path_parts[1], emails)!
	}

	return []vfs.FSEntry{}
}

pub fn (mut myvfs MailVFS) dir_delete(path string) ! {
	return error('Mail VFS is read-only')
}

// Symlink operations
pub fn (mut myvfs MailVFS) link_create(target_path string, link_path string) !vfs.FSEntry {
	return error('Mail VFS does not support symlinks')
}

pub fn (mut myvfs MailVFS) link_read(path string) !string {
	return error('Mail VFS does not support symlinks')
}

pub fn (mut myvfs MailVFS) link_delete(path string) ! {
	return error('Mail VFS does not support symlinks')
}

// Common operations
pub fn (mut myvfs MailVFS) exists(path string) bool {
	// Root always exists
	if path == '' {
		return true
	}

	// Get all emails
	emails := myvfs.mail_db.getall() or { return false }

	// Debug print
	if path.contains('subject') {
		println('Checking exists for path: ${path}')
	}

	path_parts := path.split('/')

	// Check if the path is a mailbox
	if path_parts.len == 1 {
		for email in emails {
			mailbox_parts := email.mailbox.split('/')
			if mailbox_parts.len > 0 && mailbox_parts[0] == path_parts[0] {
				return true
			}
		}
	}

	// Check if the path is a mailbox subdir (id or subject)
	if path_parts.len == 2 && path_parts[1] in ['id', 'subject'] {
		for email in emails {
			mailbox_parts := email.mailbox.split('/')
			if mailbox_parts.len > 0 && mailbox_parts[0] == path_parts[0] {
				return true
			}
		}
	}

	// Check if the path is an email file
	if path_parts.len == 3 && path_parts[1] in ['id', 'subject'] {
		for email in emails {
			if email.mailbox.split('/')[0] != path_parts[0] {
				continue
			}

			if path_parts[1] == 'id' && '${email.id}.json' == path_parts[2] {
				return true
			} else if path_parts[1] == 'subject' {
				if envelope := email.envelope {
					subject_filename := texttools.name_fix(envelope.subject) + '.json'
					if path.contains('subject') {
						println('Comparing: "${path_parts[2]}" with "${subject_filename}"')
						println('Original subject: "${envelope.subject}"')
						println('After name_fix: "${texttools.name_fix(envelope.subject)}"')
					}
					if subject_filename == path_parts[2] {
						return true
					}
				}
			}
		}
	}

	return false
}

pub fn (mut myvfs MailVFS) get(path string) !vfs.FSEntry {
	// Root always exists
	if path == '' {
		return myvfs.root_get()!
	}

	// Debug print
	println('Getting path: ${path}')

	// Get all emails
	emails := myvfs.mail_db.getall() or { return error('Failed to get emails: ${err}') }

	// Debug: Print all emails
	println('All emails in DB:')
	for email in emails {
		if envelope := email.envelope {
			println('Email ID: ${email.id}, Subject: "${envelope.subject}", Mailbox: ${email.mailbox}')
		}
	}

	path_parts := path.split('/')

	// Check if the path is a mailbox
	if path_parts.len == 1 {
		for email in emails {
			mailbox_parts := email.mailbox.split('/')
			if mailbox_parts.len > 0 && mailbox_parts[0] == path_parts[0] {
				metadata := vfs.Metadata{
					id:          u32(path_parts[0].bytes().bytestr().hash())
					name:        path_parts[0]
					file_type:   .directory
					created_at:  time.now().unix()
					modified_at: time.now().unix()
					accessed_at: time.now().unix()
				}

				return MailFSEntry{
					path:     path
					metadata: metadata
				}
			}
		}
	}

	// Check if the path is a mailbox subdir (id or subject)
	if path_parts.len == 2 && path_parts[1] in ['id', 'subject'] {
		metadata := vfs.Metadata{
			id:          u32(path.bytes().bytestr().hash())
			name:        path_parts[1]
			file_type:   .directory
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
		}

		return MailFSEntry{
			path:     path
			metadata: metadata
		}
	}

	// Check if the path is an email file
	if path_parts.len == 3 && path_parts[1] in ['id', 'subject'] {
		for email in emails {
			if email.mailbox.split('/')[0] != path_parts[0] {
				continue
			}

			if path_parts[1] == 'id' && '${email.id}.json' == path_parts[2] {
				metadata := vfs.Metadata{
					id:          email.id
					name:        '${email.id}.json'
					file_type:   .file
					size:        u64(json.encode(email).len)
					created_at:  email.internal_date
					modified_at: email.internal_date
					accessed_at: time.now().unix()
				}

				return MailFSEntry{
					path:     path
					metadata: metadata
					email:    email
				}
			} else if path_parts[1] == 'subject' {
				if envelope := email.envelope {
					subject_filename := texttools.name_fix(envelope.subject) + '.json'
					if subject_filename == path_parts[2] {
						metadata := vfs.Metadata{
							id:          email.id
							name:        subject_filename
							file_type:   .file
							size:        u64(json.encode(email).len)
							created_at:  email.internal_date
							modified_at: email.internal_date
							accessed_at: time.now().unix()
						}

						return MailFSEntry{
							path:     path
							metadata: metadata
							email:    email
						}
					}
				}
			}
		}
	}

	return error('Path not found: ${path}')
}

pub fn (mut myvfs MailVFS) rename(old_path string, new_path string) !vfs.FSEntry {
	return error('Mail VFS is read-only')
}

pub fn (mut myvfs MailVFS) copy(src_path string, dst_path string) !vfs.FSEntry {
	return error('Mail VFS is read-only')
}

pub fn (mut myvfs MailVFS) move(src_path string, dst_path string) !vfs.FSEntry {
	return error('Mail VFS is read-only')
}

pub fn (mut myvfs MailVFS) delete(path string) ! {
	return error('Mail VFS is read-only')
}

// FSEntry Operations
pub fn (mut myvfs MailVFS) get_path(entry &vfs.FSEntry) !string {
	mail_entry := entry as MailFSEntry
	return mail_entry.path
}

pub fn (mut myvfs MailVFS) print() ! {
	println('Mail VFS')
}

// Cleanup operation
pub fn (mut myvfs MailVFS) destroy() ! {
	// Nothing to clean up
}

// Helper functions
fn (mut myvfs MailVFS) list_mailboxes(emails []mail.Email) ![]vfs.FSEntry {
	mut mailboxes := map[string]bool{}

	// Collect unique top-level mailbox names
	for email in emails {
		mailbox_parts := email.mailbox.split('/')
		if mailbox_parts.len > 0 {
			mailboxes[mailbox_parts[0]] = true
		}
	}

	// Create FSEntry for each mailbox
	mut result := []vfs.FSEntry{cap: mailboxes.len}
	for mailbox, _ in mailboxes {
		metadata := vfs.Metadata{
			id:          u32(mailbox.bytes().bytestr().hash())
			name:        mailbox
			file_type:   .directory
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
		}

		result << MailFSEntry{
			path:     mailbox
			metadata: metadata
		}
	}

	return result
}

fn (mut myvfs MailVFS) list_mailbox_subdirs(mailbox string) ![]vfs.FSEntry {
	mut result := []vfs.FSEntry{cap: 2}

	// Create id directory
	id_metadata := vfs.Metadata{
		id:          u32('${mailbox}/id'.bytes().bytestr().hash())
		name:        'id'
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}

	result << MailFSEntry{
		path:     '${mailbox}/id'
		metadata: id_metadata
	}

	// Create subject directory
	subject_metadata := vfs.Metadata{
		id:          u32('${mailbox}/subject'.bytes().bytestr().hash())
		name:        'subject'
		file_type:   .directory
		created_at:  time.now().unix()
		modified_at: time.now().unix()
		accessed_at: time.now().unix()
	}

	result << MailFSEntry{
		path:     '${mailbox}/subject'
		metadata: subject_metadata
	}

	return result
}

fn (mut myvfs MailVFS) list_emails_by_type(mailbox string, list_type string, emails []mail.Email) ![]vfs.FSEntry {
	mut result := []vfs.FSEntry{}

	for email in emails {
		if email.mailbox.split('/')[0] != mailbox {
			continue
		}

		if list_type == 'id' {
			filename := '${email.id}.json'
			metadata := vfs.Metadata{
				id:          email.id
				name:        filename
				file_type:   .file
				size:        u64(json.encode(email).len)
				created_at:  email.internal_date
				modified_at: email.internal_date
				accessed_at: time.now().unix()
			}

			result << MailFSEntry{
				path:     '${mailbox}/id/${filename}'
				metadata: metadata
				email:    email
			}
		} else if list_type == 'subject' {
			if envelope := email.envelope {
				filename := texttools.name_fix(envelope.subject) + '.json'
				metadata := vfs.Metadata{
					id:          email.id
					name:        filename
					file_type:   .file
					size:        u64(json.encode(email).len)
					created_at:  email.internal_date
					modified_at: email.internal_date
					accessed_at: time.now().unix()
				}

				result << MailFSEntry{
					path:     '${mailbox}/subject/${filename}'
					metadata: metadata
					email:    email
				}
			}
		}
	}

	return result
}
