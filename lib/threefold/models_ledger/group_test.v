#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_group_new() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Create test group with configuration
	config := GroupConfig{
		max_members: 100
		allow_guests: true
		auto_approve: false
		require_invite: true
	}

	mut group := group_db.new(
		name: 'Test Group'
		description: 'A test group for unit testing'
		group_name: 'developers'
		dnsrecords: [u32(1), 2, 3]
		administrators: [u32(10), 20]
		min_signatures: 2
		config: config
		status: .active
		visibility: .private
		created: 1234567890
		updated: 1234567891
	)!

	// Verify the group was created with correct values
	assert group.name == 'Test Group'
	assert group.description == 'A test group for unit testing'
	assert group.group_name == 'developers'
	assert group.dnsrecords.len == 3
	assert group.dnsrecords[0] == 1
	assert group.administrators.len == 2
	assert group.administrators[1] == 20
	assert group.min_signatures == 2
	assert group.config.max_members == 100
	assert group.config.allow_guests == true
	assert group.config.auto_approve == false
	assert group.config.require_invite == true
	assert group.status == .active
	assert group.visibility == .private
	assert group.created == 1234567890
	assert group.updated == 1234567891
	assert group.id == 0 // Should be 0 before saving
	assert group.updated_at > 0 // Should have timestamp
}

fn test_group_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Create a complex group
	config := GroupConfig{
		max_members: 500
		allow_guests: false
		auto_approve: true
		require_invite: false
	}

	mut original_group := group_db.new(
		name: 'Encoding Test Group'
		description: 'Testing encoding and decoding functionality'
		group_name: 'encoding_test_group'
		dnsrecords: [u32(100), 200, 300, 400, 500]
		administrators: [u32(1), 5, 10, 15, 20, 25]
		min_signatures: 3
		config: config
		status: .suspended
		visibility: .unlisted
		created: 1700000000
		updated: 1700000001
	)!

	// Test encoding
	mut encoder_obj := encoder.encoder_new()
	original_group.dump(mut encoder_obj)!
	encoded_data := encoder_obj.data

	// Test decoding
	mut decoder_obj := encoder.decoder_new(encoded_data)
	mut decoded_group := Group{}
	group_db.load(mut decoded_group, mut decoder_obj)!

	// Verify all fields match after encoding/decoding
	assert decoded_group.group_name == original_group.group_name
	assert decoded_group.min_signatures == original_group.min_signatures
	assert decoded_group.status == original_group.status
	assert decoded_group.visibility == original_group.visibility
	assert decoded_group.created == original_group.created
	assert decoded_group.updated == original_group.updated

	// Verify dnsrecords list
	assert decoded_group.dnsrecords.len == original_group.dnsrecords.len
	for i, record_id in original_group.dnsrecords {
		assert decoded_group.dnsrecords[i] == record_id
	}

	// Verify administrators list
	assert decoded_group.administrators.len == original_group.administrators.len
	for i, admin in original_group.administrators {
		assert decoded_group.administrators[i] == admin
	}

	// Verify config
	assert decoded_group.config.max_members == original_group.config.max_members
	assert decoded_group.config.allow_guests == original_group.config.allow_guests
	assert decoded_group.config.auto_approve == original_group.config.auto_approve
	assert decoded_group.config.require_invite == original_group.config.require_invite
}

fn test_group_set_and_get() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Create group
	config := GroupConfig{
		max_members: 50
		allow_guests: true
		auto_approve: true
		require_invite: false
	}

	mut group := group_db.new(
		name: 'DB Test Group'
		description: 'Testing database operations'
		group_name: 'db_test'
		dnsrecords: [u32(1)]
		administrators: [u32(5), 10]
		min_signatures: 1
		config: config
		status: .active
		visibility: .public
		created: 1234567890
		updated: 1234567890
	)!

	// Save the group
	group = group_db.set(group)!

	// Verify ID was assigned
	assert group.id > 0
	original_id := group.id

	// Retrieve the group
	retrieved_group := group_db.get(group.id)!

	// Verify all fields match through the database roundtrip
	assert retrieved_group.id == original_id
	assert retrieved_group.name == 'DB Test Group'
	assert retrieved_group.description == 'Testing database operations'
	assert retrieved_group.group_name == 'db_test'
	assert retrieved_group.status == .active
	assert retrieved_group.visibility == .public
	assert retrieved_group.min_signatures == 1
	assert retrieved_group.created == 1234567890
	assert retrieved_group.updated == 1234567890
	assert retrieved_group.dnsrecords.len == 1
	assert retrieved_group.dnsrecords[0] == 1
	assert retrieved_group.administrators.len == 2
	assert retrieved_group.administrators[0] == 5
	assert retrieved_group.administrators[1] == 10
	assert retrieved_group.config.max_members == 50
	assert retrieved_group.config.allow_guests == true
}

fn test_group_update() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Create and save a group
	config := GroupConfig{
		max_members: 25
		allow_guests: false
		auto_approve: false
		require_invite: true
	}

	mut group := group_db.new(
		name: 'Original Group'
		description: 'Original description'
		group_name: 'original'
		dnsrecords: []u32{}
		administrators: [u32(1)]
		min_signatures: 1
		config: config
		status: .active
		visibility: .private
		created: 1234567890
		updated: 1234567890
	)!

	group = group_db.set(group)!
	original_id := group.id
	original_created_at := group.created_at

	// Update the group
	new_config := GroupConfig{
		max_members: 200
		allow_guests: true
		auto_approve: true
		require_invite: false
	}

	group.name = 'Updated Group'
	group.description = 'Updated description'
	group.group_name = 'updated'
	group.dnsrecords = [u32(10), 20, 30]
	group.administrators = [u32(1), 2, 3, 4]
	group.min_signatures = 3
	group.config = new_config
	group.status = .inactive
	group.visibility = .public
	group.updated = 1234567999

	group = group_db.set(group)!

	// Verify ID remains the same
	assert group.id == original_id
	assert group.created_at == original_created_at

	// Retrieve and verify updates
	updated_group := group_db.get(group.id)!
	assert updated_group.name == 'Updated Group'
	assert updated_group.description == 'Updated description'
	assert updated_group.group_name == 'updated'
	assert updated_group.status == .inactive
	assert updated_group.visibility == .public
	assert updated_group.min_signatures == 3
	assert updated_group.updated == 1234567999
	assert updated_group.dnsrecords.len == 3
	assert updated_group.administrators.len == 4
	assert updated_group.config.max_members == 200
	assert updated_group.config.auto_approve == true
}

fn test_group_exist_and_delete() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Test non-existent group
	exists := group_db.exist(999)!
	assert exists == false

	// Create and save a group
	config := GroupConfig{
		max_members: 10
		allow_guests: false
		auto_approve: false
		require_invite: true
	}

	mut group := group_db.new(
		name: 'To Be Deleted'
		description: 'This group will be deleted'
		group_name: 'delete_me'
		dnsrecords: []u32{}
		administrators: []u32{}
		min_signatures: 0
		config: config
		status: .archived
		visibility: .private
		created: 1234567890
		updated: 1234567890
	)!

	group = group_db.set(group)!
	group_id := group.id

	// Test existing group
	exists_after_save := group_db.exist(group_id)!
	assert exists_after_save == true

	// Delete the group
	group_db.delete(group_id)!

	// Verify it no longer exists
	exists_after_delete := group_db.exist(group_id)!
	assert exists_after_delete == false

	// Verify get fails
	if _ := group_db.get(group_id) {
		panic('Should not be able to get deleted group')
	}
}

fn test_group_list() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Initially should be empty
	initial_list := group_db.list()!
	initial_count := initial_list.len

	// Create multiple groups
	config1 := GroupConfig{
		max_members: 100
		allow_guests: true
		auto_approve: true
		require_invite: false
	}

	config2 := GroupConfig{
		max_members: 50
		allow_guests: false
		auto_approve: false
		require_invite: true
	}

	mut group1 := group_db.new(
		name: 'Group 1'
		description: 'First group'
		group_name: 'group1'
		dnsrecords: [u32(1)]
		administrators: [u32(1)]
		min_signatures: 1
		config: config1
		status: .active
		visibility: .public
		created: 1234567890
		updated: 1234567890
	)!

	mut group2 := group_db.new(
		name: 'Group 2'
		description: 'Second group'
		group_name: 'group2'
		dnsrecords: [u32(1), 2]
		administrators: [u32(1), 2]
		min_signatures: 2
		config: config2
		status: .inactive
		visibility: .private
		created: 1234567891
		updated: 1234567891
	)!

	// Save both groups
	group1 = group_db.set(group1)!
	group2 = group_db.set(group2)!

	// List groups
	group_list := group_db.list()!

	// Should have 2 more groups than initially
	assert group_list.len == initial_count + 2

	// Find our groups in the list
	mut found_group1 := false
	mut found_group2 := false

	for grp in group_list {
		if grp.group_name == 'group1' {
			found_group1 = true
			assert grp.status == .active
			assert grp.visibility == .public
			assert grp.config.max_members == 100
		}
		if grp.group_name == 'group2' {
			found_group2 = true
			assert grp.status == .inactive
			assert grp.visibility == .private
			assert grp.config.require_invite == true
		}
	}

	assert found_group1 == true
	assert found_group2 == true
}

fn test_group_status_and_visibility() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Test all status values
	statuses := [GroupStatus.active, .inactive, .suspended, .archived]
	visibilities := [Visibility.public, .private, .unlisted]

	for i, status in statuses {
		visibility := visibilities[i % visibilities.len]

		config := GroupConfig{
			max_members: u32(10 + i)
			allow_guests: i % 2 == 0
			auto_approve: i % 2 == 1
			require_invite: i % 3 == 0
		}

		mut group := group_db.new(
			name: 'Status Test Group ${i}'
			description: 'Testing ${status} and ${visibility}'
			group_name: 'status_test_${i}'
			dnsrecords: []u32{}
			administrators: []u32{}
			min_signatures: 0
			config: config
			status: status
			visibility: visibility
			created: u64(1234567890 + i)
			updated: u64(1234567890 + i)
		)!

		group = group_db.set(group)!
		retrieved_group := group_db.get(group.id)!

		assert retrieved_group.status == status
		assert retrieved_group.visibility == visibility
		assert retrieved_group.config.max_members == u32(10 + i)
	}
}

fn test_group_edge_cases() {
	mut mydb := setup_test_db()!
	mut group_db := DBGroup{db: &mydb}

	// Test minimal group
	minimal_config := GroupConfig{
		max_members: 0
		allow_guests: false
		auto_approve: false
		require_invite: false
	}

	mut minimal_group := group_db.new(
		name: ''
		description: ''
		group_name: ''
		dnsrecords: []u32{}
		administrators: []u32{}
		min_signatures: 0
		config: minimal_config
		status: .active
		visibility: .public
		created: 0
		updated: 0
	)!

	minimal_group = group_db.set(minimal_group)!
	retrieved_minimal := group_db.get(minimal_group.id)!

	assert retrieved_minimal.name == ''
	assert retrieved_minimal.description == ''
	assert retrieved_minimal.group_name == ''
	assert retrieved_minimal.dnsrecords.len == 0
	assert retrieved_minimal.administrators.len == 0
	assert retrieved_minimal.config.max_members == 0

	// Test group with large arrays
	large_dns_records := []u32{len: 1000, init: u32(index + 1)}
	large_administrators := []u32{len: 100, init: u32(index + 1000)}

	large_config := GroupConfig{
		max_members: 99999
		allow_guests: true
		auto_approve: true
		require_invite: true
	}

	mut large_group := group_db.new(
		name: 'Large Group'
		description: 'Group with large arrays'
		group_name: 'large_group'
		dnsrecords: large_dns_records
		administrators: large_administrators
		min_signatures: 50
		config: large_config
		status: .active
		visibility: .public
		created: 1234567890
		updated: 1234567890
	)!

	large_group = group_db.set(large_group)!
	retrieved_large := group_db.get(large_group.id)!

	assert retrieved_large.dnsrecords.len == 1000
	assert retrieved_large.administrators.len == 100
	assert retrieved_large.dnsrecords[0] == 1
	assert retrieved_large.dnsrecords[999] == 1000
	assert retrieved_large.administrators[0] == 1000
	assert retrieved_large.administrators[99] == 1099
	assert retrieved_large.config.max_members == 99999
}