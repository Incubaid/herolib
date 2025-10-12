module vfs_mail

import incubaid.herolib.vfs
// import incubaid.herolib.circles.mcc.models
import incubaid.herolib.circles.mcc.models as mail
import incubaid.herolib.circles.mcc.db as core
import incubaid.herolib.circles.base
import json
import time

fn test_mail_vfs() {
	// Create a session state
	mut session_state := base.new_session(name: 'test')!

	// Create a mail database
	mut mail_db := core.new_maildb(session_state)!

	// Create some test emails
	mut email1 := mail.Email{
		id:            1
		uid:           101
		seq_num:       1
		mailbox:       'Draft/important'
		message:       'This is a test email 1'
		internal_date: time.now().unix()
		envelope:      mail.Envelope{
			subject: 'Test Email 1'
			from:    ['sender1@example.com']
			to:      ['recipient1@example.com']
			date:    time.now().unix()
		}
	}

	mut email2 := mail.Email{
		id:            2
		uid:           102
		seq_num:       2
		mailbox:       'Draft/normal'
		message:       'This is a test email 2'
		internal_date: time.now().unix()
		envelope:      mail.Envelope{
			subject: 'Test Email 2'
			from:    ['sender2@example.com']
			to:      ['recipient2@example.com']
			date:    time.now().unix()
		}
	}

	mut email3 := mail.Email{
		id:            3
		uid:           103
		seq_num:       3
		mailbox:       'Inbox'
		message:       'This is a test email 3'
		internal_date: time.now().unix()
		envelope:      mail.Envelope{
			subject: 'Test Email 3'
			from:    ['sender3@example.com']
			to:      ['recipient3@example.com']
			date:    time.now().unix()
		}
	}

	// Add emails to the database
	mail_db.set(email1) or { panic(err) }
	mail_db.set(email2) or { panic(err) }
	mail_db.set(email3) or { panic(err) }

	// Create a mail VFS
	mut mail_vfs := new(&mail_db) or { panic(err) }

	// Test root directory
	root := mail_vfs.root_get() or { panic(err) }
	assert root.is_dir()

	// Test listing mailboxes
	mailboxes := mail_vfs.dir_list('') or { panic(err) }
	assert mailboxes.len == 2 // Draft and Inbox

	// Find the Draft mailbox
	mut draft_found := false
	mut inbox_found := false
	for entry in mailboxes {
		if entry.get_metadata().name == 'Draft' {
			draft_found = true
		}
		if entry.get_metadata().name == 'Inbox' {
			inbox_found = true
		}
	}
	assert draft_found
	assert inbox_found

	// Test listing mailbox subdirectories
	draft_subdirs := mail_vfs.dir_list('Draft') or { panic(err) }
	assert draft_subdirs.len == 2 // id and subject

	// Test listing emails by ID
	draft_emails_by_id := mail_vfs.dir_list('Draft/id') or { panic(err) }
	assert draft_emails_by_id.len == 2 // email1 and email2

	// Test listing emails by subject
	draft_emails_by_subject := mail_vfs.dir_list('Draft/subject') or { panic(err) }
	assert draft_emails_by_subject.len == 2 // email1 and email2

	// Test getting an email by ID
	email1_by_id := mail_vfs.get('Draft/id/1.json') or { panic(err) }
	assert email1_by_id.is_file()

	// Test reading an email by ID
	email1_content := mail_vfs.file_read('Draft/id/1.json') or { panic(err) }
	email1_json := json.decode(mail.Email, email1_content.bytestr()) or { panic(err) }
	assert email1_json.id == 1
	assert email1_json.mailbox == 'Draft/important'

	// // Test getting an email by subject
	// email1_by_subject := mail_vfs.get('Draft/subject/Test Email 1.json') or { panic(err) }
	// assert email1_by_subject.is_file()

	// // Test reading an email by subject
	// email1_content_by_subject := mail_vfs.file_read('Draft/subject/Test Email 1.json') or { panic(err) }
	// email1_json_by_subject := json.decode(mail.Email, email1_content_by_subject.bytestr()) or { panic(err) }
	// assert email1_json_by_subject.id == 1
	// assert email1_json_by_subject.mailbox == 'Draft/important'

	// Test exists function
	assert mail_vfs.exists('Draft')
	assert mail_vfs.exists('Draft/id')
	assert mail_vfs.exists('Draft/id/1.json')
	// assert mail_vfs.exists('Draft/subject/Test Email 1.json')
	assert !mail_vfs.exists('NonExistentMailbox')

	println('All mail VFS tests passed!')
}
