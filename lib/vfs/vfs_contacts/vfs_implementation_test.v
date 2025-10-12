module vfs_contacts

import incubaid.herolib.circles.base
import incubaid.herolib.circles.mcc.db as core
import incubaid.herolib.circles.mcc.models as contacts
// import incubaid.herolib.circles.mcc.models

fn test_contacts_vfs() ! {
	// Create a session state
	mut session_state := base.new_session(name: 'test')!

	// Setup mock database
	mut contacts_db := core.new_contacts_db(session_state)!

	// 	Set instances
	contact1 := contacts.Contact{
		id:          1
		first_name:  'John'
		last_name:   'Doe'
		email:       'john.doe@example.com'
		group:       'personal'
		created_at:  1698777600
		modified_at: 1698777600
	}

	contact2 := contacts.Contact{
		id:          2
		first_name:  'Jane'
		last_name:   'Doe'
		email:       'jane.doe@example.com'
		group:       'personal'
		created_at:  1698777600
		modified_at: 1698777600
	}

	contact3 := contacts.Contact{
		id:          3
		first_name:  'Janane'
		last_name:   'Doe'
		email:       'Janane.doe@example.com'
		group:       'other'
		created_at:  1698777600
		modified_at: 1698777600
	}

	// Add emails to the database
	contacts_db.set(contact1) or { panic(err) }
	contacts_db.set(contact2) or { panic(err) }
	contacts_db.set(contact3) or { panic(err) }

	// Create VFS instance
	mut contacts_vfs := new(&contacts_db) or { panic(err) }

	// Test root directory
	root := contacts_vfs.root_get()!
	assert root.is_dir()

	// Test listing groups
	groups := contacts_vfs.dir_list('')!
	assert groups.len == 2

	contacts_entry1 := groups[0] as ContactsFSEntry
	contacts_entry2 := groups[1] as ContactsFSEntry

	assert contacts_entry1.metadata.name == 'personal'
	assert contacts_entry2.metadata.name == 'other'

	// Test listing group subdirs
	subdirs := contacts_vfs.dir_list('personal')!
	assert subdirs.len == 2

	contact_subdir1 := subdirs[0] as ContactsFSEntry
	contact_subdir2 := subdirs[1] as ContactsFSEntry

	assert contact_subdir1.metadata.name == 'by_name'
	assert contact_subdir2.metadata.name == 'by_email'

	// Test listing contacts by name
	contacts_by_name := contacts_vfs.dir_list('personal/by_name')!
	assert contacts_by_name.len == 2

	contacts_by_name1 := contacts_by_name[0] as ContactsFSEntry
	assert contacts_by_name1.metadata.name == 'john_doe.json'

	// Test listing contacts by email
	contacts_by_email := contacts_vfs.dir_list('personal/by_email')!
	assert contacts_by_email.len == 2

	contacts_by_email1 := contacts_by_email[0] as ContactsFSEntry
	assert contacts_by_email1.metadata.name == 'john_doeexample.com.json'

	// Test reading contact file
	contact_data := contacts_vfs.file_read('personal/by_name/john_doe.json')!
	assert contact_data.len > 0

	// Test existence checks
	assert contacts_vfs.exists('personal')
	assert contacts_vfs.exists('personal/by_name')
	assert contacts_vfs.exists('personal/by_name/john_doe.json')
	assert !contacts_vfs.exists('nonexistent')
}
