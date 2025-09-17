#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_member_new() {
	mut mydb := setup_test_db()!
	mut member_db := DBMember{
		db: &mydb
	}

	mut member := member_db.new(
		name:        'Test Member'
		description: 'A test member for unit testing'
		group_id:    1
		user_id:     10
		role:        .admin
		status:      .active
	)!

	assert member.name == 'Test Member'
	assert member.description == 'A test member for unit testing'
	assert member.group_id == 1
	assert member.user_id == 10
	assert member.role == .admin
	assert member.status == .active
	assert member.join_date > 0
	assert member.last_activity > 0
	assert member.id == 0
	assert member.updated_at > 0
}

fn test_member_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut member_db := DBMember{
		db: &mydb
	}

	mut original_member := member_db.new(
		name:        'Encoding Test Member'
		description: 'Testing encoding and decoding'
		group_id:    999
		user_id:     888
		role:        .moderator
		status:      .suspended
	)!

	// Test encoding
	mut encoder_obj := encoder.encoder_new()
	original_member.dump(mut encoder_obj)!
	encoded_data := encoder_obj.data

	// Test decoding
	mut decoder_obj := encoder.decoder_new(encoded_data)
	mut decoded_member := Member{}
	member_db.load(mut decoded_member, mut decoder_obj)!

	// Verify all fields match
	assert decoded_member.group_id == original_member.group_id
	assert decoded_member.user_id == original_member.user_id
	assert decoded_member.role == original_member.role
	assert decoded_member.status == original_member.status
	assert decoded_member.join_date == original_member.join_date
	assert decoded_member.last_activity == original_member.last_activity
}

fn test_member_crud_operations() {
	mut mydb := setup_test_db()!
	mut member_db := DBMember{
		db: &mydb
	}

	// Create and save
	mut member := member_db.new(
		name:        'CRUD Test Member'
		description: 'Testing CRUD operations'
		group_id:    5
		user_id:     15
		role:        .member
		status:      .pending
	)!

	member = member_db.set(member)!
	assert member.id > 0
	member_id := member.id

	// Get
	retrieved := member_db.get(member_id)!
	assert retrieved.group_id == 5
	assert retrieved.user_id == 15
	assert retrieved.role == .member
	assert retrieved.status == .pending

	// Update
	member.role = .owner
	member.status = .active
	member = member_db.set(member)!

	updated := member_db.get(member_id)!
	assert updated.role == .owner
	assert updated.status == .active

	// Exist
	exists := member_db.exist(member_id)!
	assert exists == true

	// Delete
	member_db.delete(member_id)!
	exists_after := member_db.exist(member_id)!
	assert exists_after == false
}

fn test_member_list() {
	mut mydb := setup_test_db()!
	mut member_db := DBMember{
		db: &mydb
	}

	initial_list := member_db.list()!
	initial_count := initial_list.len

	// Create multiple members
	mut member1 := member_db.new(
		name:        'Member 1'
		description: 'First member'
		group_id:    1
		user_id:     1
		role:        .admin
		status:      .active
	)!

	mut member2 := member_db.new(
		name:        'Member 2'
		description: 'Second member'
		group_id:    2
		user_id:     2
		role:        .member
		status:      .pending
	)!

	member1 = member_db.set(member1)!
	member2 = member_db.set(member2)!

	member_list := member_db.list()!
	assert member_list.len == initial_count + 2

	mut found1 := false
	mut found2 := false
	for m in member_list {
		if m.name == 'Member 1' {
			found1 = true
			assert m.role == .admin
		}
		if m.name == 'Member 2' {
			found2 = true
			assert m.status == .pending
		}
	}
	assert found1 && found2
}

fn test_member_roles_and_statuses() {
	mut mydb := setup_test_db()!
	mut member_db := DBMember{
		db: &mydb
	}

	roles := [MemberRole.member, .moderator, .admin, .owner]
	statuses := [MemberStatus.pending, .active, .suspended, .archived]

	for i, role in roles {
		status := statuses[i % statuses.len]
		mut member := member_db.new(
			name:        'Role Test ${i}'
			description: 'Testing ${role} with ${status}'
			group_id:    u32(i + 1)
			user_id:     u32(i + 100)
			role:        role
			status:      status
		)!

		member = member_db.set(member)!
		retrieved := member_db.get(member.id)!
		assert retrieved.role == role
		assert retrieved.status == status
	}
}
