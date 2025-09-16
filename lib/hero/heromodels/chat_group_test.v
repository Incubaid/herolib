#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels { ChatType }
import freeflowuniverse.herolib.data.ourtime

// Test ChatGroup model CRUD operations
fn test_chat_group_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test creating a new chat group with all fields
	now := ourtime.now().unix()
	mut chat_group := mydb.chat_group.new(
		name:           'General Discussion'
		description:    'Main channel for general team discussions'
		chat_type:      .public_channel
		last_activity:  now
		is_archived:    false
		securitypolicy: 1
		tags:           ['general', 'team', 'discussion']
		comments:       []
	) or { panic('Failed to create chat group: ${err}') }

	// Verify the chat group was created with correct values
	assert chat_group.name == 'General Discussion'
	assert chat_group.description == 'Main channel for general team discussions'
	assert chat_group.chat_type == .public_channel
	assert chat_group.last_activity == now
	assert chat_group.is_archived == false
	assert chat_group.id == 0 // Should be 0 before saving
	assert chat_group.updated_at > 0 // Should have timestamp
}

fn test_chat_group_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a chat group
	now := ourtime.now().unix()
	mut chat_group := mydb.chat_group.new(
		name:           'Development Team'
		description:    'Private channel for development team coordination'
		chat_type:      .private_channel
		last_activity:  now - 3600 // 1 hour ago
		is_archived:    false
		securitypolicy: 2
		tags:           ['development', 'private', 'team']
		comments:       []
	) or { panic('Failed to create chat group: ${err}') }

	// Save the chat group
	chat_group = mydb.chat_group.set(chat_group) or { panic('Failed to save chat group: ${err}') }

	// Verify ID was assigned
	assert chat_group.id > 0
	original_id := chat_group.id

	// Retrieve the chat group
	retrieved_group := mydb.chat_group.get(chat_group.id) or {
		panic('Failed to get chat group: ${err}')
	}

	// Verify all fields match
	assert retrieved_group.id == original_id
	assert retrieved_group.name == 'Development Team'
	assert retrieved_group.description == 'Private channel for development team coordination'
	assert retrieved_group.chat_type == .private_channel
	assert retrieved_group.last_activity == now - 3600
	assert retrieved_group.is_archived == false
	assert retrieved_group.created_at > 0
	assert retrieved_group.updated_at > 0
}

fn test_chat_group_types() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test all chat types
	chat_types := [ChatType.public_channel, .private_channel, .direct_message, .group_message]
	now := ourtime.now().unix()

	for chat_type in chat_types {
		mut chat_group := mydb.chat_group.new(
			name:           'Chat ${chat_type}'
			description:    'Testing ${chat_type} type'
			chat_type:      ChatType(chat_type)
			last_activity:  now
			is_archived:    false
			securitypolicy: 1
			tags:           ['test']
			comments:       []
		) or { panic('Failed to create chat group with type ${chat_type}: ${err}') }

		chat_group = mydb.chat_group.set(chat_group) or {
			panic('Failed to save chat group with type ${chat_type}: ${err}')
		}

		retrieved_group := mydb.chat_group.get(chat_group.id) or {
			panic('Failed to get chat group with type ${chat_type}: ${err}')
		}
		assert retrieved_group.chat_type == ChatType(chat_type)
	}
}

fn test_chat_group_archive() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create an active chat group
	now := ourtime.now().unix()
	mut chat_group := mydb.chat_group.new(
		name:           'Old Project Channel'
		description:    'Channel for a completed project'
		chat_type:      .public_channel
		last_activity:  now - 86400 * 30 // 30 days ago
		is_archived:    false
		securitypolicy: 1
		tags:           ['project', 'completed']
		comments:       []
	) or { panic('Failed to create chat group: ${err}') }

	chat_group = mydb.chat_group.set(chat_group) or { panic('Failed to save chat group: ${err}') }

	// Verify it's not archived initially
	retrieved_group := mydb.chat_group.get(chat_group.id) or {
		panic('Failed to get chat group: ${err}')
	}
	assert retrieved_group.is_archived == false

	// Archive the chat group
	chat_group.is_archived = true
	chat_group = mydb.chat_group.set(chat_group) or { panic('Failed to update chat group: ${err}') }

	// Verify it's now archived
	archived_group := mydb.chat_group.get(chat_group.id) or {
		panic('Failed to get archived chat group: ${err}')
	}
	assert archived_group.is_archived == true
	assert archived_group.name == 'Old Project Channel'
}

fn test_chat_group_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a chat group
	now := ourtime.now().unix()
	mut chat_group := mydb.chat_group.new(
		name:           'Original Channel'
		description:    'Original description'
		chat_type:      .public_channel
		last_activity:  now - 86400
		is_archived:    false
		securitypolicy: 1
		tags:           ['original']
		comments:       []
	) or { panic('Failed to create chat group: ${err}') }

	chat_group = mydb.chat_group.set(chat_group) or { panic('Failed to save chat group: ${err}') }
	original_id := chat_group.id
	original_created_at := chat_group.created_at
	original_updated_at := chat_group.updated_at

	// Update the chat group
	chat_group.name = 'Updated Channel'
	chat_group.description = 'Updated description'
	chat_group.chat_type = .private_channel
	chat_group.last_activity = now
	chat_group.is_archived = true

	chat_group = mydb.chat_group.set(chat_group) or { panic('Failed to update chat group: ${err}') }

	// Verify ID remains the same and updated_at is set
	assert chat_group.id == original_id
	assert chat_group.created_at == original_created_at
	assert chat_group.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_group := mydb.chat_group.get(chat_group.id) or {
		panic('Failed to get updated chat group: ${err}')
	}
	assert updated_group.name == 'Updated Channel'
	assert updated_group.description == 'Updated description'
	assert updated_group.chat_type == .private_channel
	assert updated_group.last_activity == now
	assert updated_group.is_archived == true
}

fn test_chat_group_exist() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test non-existent chat group
	exists := mydb.chat_group.exist(999) or { panic('Failed to check existence: ${err}') }
	assert exists == false

	// Create and save a chat group
	mut chat_group := mydb.chat_group.new(
		name:           'Existence Test'
		description:    'Testing existence'
		chat_type:      .direct_message
		last_activity:  ourtime.now().unix()
		is_archived:    false
		securitypolicy: 1
		tags:           ['test']
		comments:       []
	) or { panic('Failed to create chat group: ${err}') }

	chat_group = mydb.chat_group.set(chat_group) or { panic('Failed to save chat group: ${err}') }

	// Test existing chat group
	exists_after_save := mydb.chat_group.exist(chat_group.id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after_save == true
}

fn test_chat_group_delete() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a chat group
	mut chat_group := mydb.chat_group.new(
		name:           'To Be Deleted'
		description:    'This chat group will be deleted'
		chat_type:      .group_message
		last_activity:  ourtime.now().unix()
		is_archived:    true
		securitypolicy: 1
		tags:           []
		comments:       []
	) or { panic('Failed to create chat group: ${err}') }

	chat_group = mydb.chat_group.set(chat_group) or { panic('Failed to save chat group: ${err}') }
	group_id := chat_group.id

	// Verify it exists
	exists_before := mydb.chat_group.exist(group_id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_before == true

	// Delete the chat group
	mydb.chat_group.delete(group_id) or { panic('Failed to delete chat group: ${err}') }

	// Verify it no longer exists
	exists_after := mydb.chat_group.exist(group_id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after == false

	// Verify get fails
	if _ := mydb.chat_group.get(group_id) {
		panic('Should not be able to get deleted chat group')
	}
}

fn test_chat_group_list() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Clear any existing chat groups by creating a fresh DB
	mydb = heromodels.new() or { panic('Failed to create fresh DB: ${err}') }

	// Initially should be empty
	initial_list := mydb.chat_group.list() or { panic('Failed to list chat groups: ${err}') }
	initial_count := initial_list.len

	// Create multiple chat groups
	now := ourtime.now().unix()
	mut group1 := mydb.chat_group.new(
		name:           'Public Channel'
		description:    'Public discussion channel'
		chat_type:      .public_channel
		last_activity:  now
		is_archived:    false
		securitypolicy: 1
		tags:           ['public', 'discussion']
		comments:       []
	) or { panic('Failed to create group1: ${err}') }

	mut group2 := mydb.chat_group.new(
		name:           'Private Team Chat'
		description:    'Private team coordination'
		chat_type:      .private_channel
		last_activity:  now - 3600
		is_archived:    false
		securitypolicy: 2
		tags:           ['private', 'team']
		comments:       []
	) or { panic('Failed to create group2: ${err}') }

	// Save both chat groups
	group1 = mydb.chat_group.set(group1) or { panic('Failed to save group1: ${err}') }
	group2 = mydb.chat_group.set(group2) or { panic('Failed to save group2: ${err}') }

	// List chat groups
	group_list := mydb.chat_group.list() or { panic('Failed to list chat groups: ${err}') }

	// Should have 2 more chat groups than initially
	assert group_list.len == initial_count + 2

	// Find our chat groups in the list
	mut found_group1 := false
	mut found_group2 := false

	for grp in group_list {
		if grp.name == 'Public Channel' {
			found_group1 = true
			assert grp.chat_type == .public_channel
			assert grp.is_archived == false
		}
		if grp.name == 'Private Team Chat' {
			found_group2 = true
			assert grp.chat_type == .private_channel
			assert grp.is_archived == false
		}
	}

	assert found_group1 == true
	assert found_group2 == true
}

fn test_chat_group_edge_cases() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test chat group with empty fields
	mut empty_group := mydb.chat_group.new(
		name:           ''
		description:    ''
		chat_type:      .direct_message
		last_activity:  0
		is_archived:    false
		securitypolicy: 0
		tags:           []
		comments:       []
	) or { panic('Failed to create empty chat group: ${err}') }

	empty_group = mydb.chat_group.set(empty_group) or { panic('Failed to save empty chat group: ${err}') }

	retrieved_empty := mydb.chat_group.get(empty_group.id) or {
		panic('Failed to get empty chat group: ${err}')
	}
	assert retrieved_empty.name == ''
	assert retrieved_empty.description == ''
	assert retrieved_empty.last_activity == 0
	assert retrieved_empty.is_archived == false

	// Test archived direct message
	now := ourtime.now().unix()
	mut dm_group := mydb.chat_group.new(
		name:           'DM: Alice & Bob'
		description:    'Direct message between Alice and Bob'
		chat_type:      .direct_message
		last_activity:  now - 86400 * 7 // 1 week ago
		is_archived:    true
		securitypolicy: 1
		tags:           ['dm', 'archived']
		comments:       []
	) or { panic('Failed to create DM group: ${err}') }

	dm_group = mydb.chat_group.set(dm_group) or { panic('Failed to save DM group: ${err}') }

	retrieved_dm := mydb.chat_group.get(dm_group.id) or { panic('Failed to get DM group: ${err}') }
	assert retrieved_dm.chat_type == .direct_message
	assert retrieved_dm.is_archived == true
	assert retrieved_dm.last_activity == now - 86400 * 7
}
