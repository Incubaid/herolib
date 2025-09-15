#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels

// Test User model CRUD operations
fn test_user_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test creating a new user with all fields
	mut user := mydb.user.new(
		name:           'John Doe'
		description:    'Software developer and tech enthusiast'
		email:          'john.doe@example.com'
		public_key:     'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...'
		phone:          '+1-555-123-4567'
		address:        '123 Main St, Anytown, USA'
		avatar_url:     'https://example.com/avatar.jpg'
		bio:            'Passionate about technology and open source'
		timezone:       'America/New_York'
		status:         .active
		securitypolicy: 1
		tags:           1
		comments:       []u32{}
	) or { panic('Failed to create user: ${err}') }

	// Verify the user was created with correct values
	assert user.name == 'John Doe'
	assert user.description == 'Software developer and tech enthusiast'
	assert user.email == 'john.doe@example.com'
	assert user.public_key == 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...'
	assert user.phone == '+1-555-123-4567'
	assert user.address == '123 Main St, Anytown, USA'
	assert user.avatar_url == 'https://example.com/avatar.jpg'
	assert user.bio == 'Passionate about technology and open source'
	assert user.timezone == 'America/New_York'
	assert user.status == .active
	assert user.id == 0 // Should be 0 before saving
	assert user.updated_at > 0 // Should have timestamp
}

fn test_user_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a user
	mut user := mydb.user.new(
		name:           'Alice Smith'
		description:    'Product manager with 5 years experience'
		email:          'alice.smith@company.com'
		public_key:     'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...'
		phone:          '+44-20-7946-0958'
		address:        'London, UK'
		avatar_url:     'https://company.com/avatars/alice.png'
		bio:            'Leading product development teams'
		timezone:       'Europe/London'
		status:         .active
		securitypolicy: 2
		tags:           2
		comments:       []u32{}
	) or { panic('Failed to create user: ${err}') }

	// Save the user
	mydb.user.set(mut user) or { panic('Failed to save user: ${err}') }

	// Verify ID was assigned
	assert user.id > 0
	original_id := user.id

	// Retrieve the user
	retrieved_user := mydb.user.get(user.id) or { panic('Failed to get user: ${err}') }

	// Verify all fields match
	assert retrieved_user.id == original_id
	assert retrieved_user.name == 'Alice Smith'
	assert retrieved_user.description == 'Product manager with 5 years experience'
	assert retrieved_user.email == 'alice.smith@company.com'
	assert retrieved_user.public_key == 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...'
	assert retrieved_user.phone == '+44-20-7946-0958'
	assert retrieved_user.address == 'London, UK'
	assert retrieved_user.avatar_url == 'https://company.com/avatars/alice.png'
	assert retrieved_user.bio == 'Leading product development teams'
	assert retrieved_user.timezone == 'Europe/London'
	assert retrieved_user.status == .active
	assert retrieved_user.created_at > 0
	assert retrieved_user.updated_at > 0
}

fn test_user_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a user
	mut user := mydb.user.new(
		name:           'Bob Wilson'
		description:    'Junior developer'
		email:          'bob.wilson@startup.com'
		public_key:     'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ...'
		phone:          '+1-415-555-0123'
		address:        'San Francisco, CA'
		avatar_url:     'https://startup.com/bob.jpg'
		bio:            'Learning and growing in tech'
		timezone:       'America/Los_Angeles'
		status:         .pending
		securitypolicy: 1
		tags:           3
		comments:       []u32{}
	) or { panic('Failed to create user: ${err}') }

	mydb.user.set(mut user) or { panic('Failed to save user: ${err}') }
	original_id := user.id
	original_created_at := user.created_at
	original_updated_at := user.updated_at

	// Update the user
	user.name = 'Bob Wilson Jr.'
	user.description = 'Senior developer'
	user.email = 'bob.wilson.jr@bigtech.com'
	user.phone = '+1-415-555-9999'
	user.address = 'Palo Alto, CA'
	user.bio = 'Experienced full-stack developer'
	user.status = .active

	mydb.user.set(mut user) or { panic('Failed to update user: ${err}') }

	// Verify ID remains the same and updated_at is set
	assert user.id == original_id
	assert user.created_at == original_created_at
	assert user.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_user := mydb.user.get(user.id) or { panic('Failed to get updated user: ${err}') }
	assert updated_user.name == 'Bob Wilson Jr.'
	assert updated_user.description == 'Senior developer'
	assert updated_user.email == 'bob.wilson.jr@bigtech.com'
	assert updated_user.phone == '+1-415-555-9999'
	assert updated_user.address == 'Palo Alto, CA'
	assert updated_user.bio == 'Experienced full-stack developer'
	assert updated_user.status == .active
}

fn test_user_status_transitions() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test all user status values
	statuses := [heromodels.UserStatus.pending, .active, .inactive, .suspended]

	for status in statuses {
		mut user := mydb.user.new(
			name:           'Test User ${status}'
			description:    'Testing status ${status}'
			email:          'test.${status}@example.com'
			public_key:     ''
			phone:          ''
			address:        ''
			avatar_url:     ''
			bio:            ''
			timezone:       'UTC'
			status:         status
			securitypolicy: 1
			tags:           0
			comments:       []u32{}
		) or { panic('Failed to create user with status ${status}: ${err}') }

		mydb.user.set(mut user) or { panic('Failed to save user with status ${status}: ${err}') }

		retrieved_user := mydb.user.get(user.id) or {
			panic('Failed to get user with status ${status}: ${err}')
		}
		assert retrieved_user.status == status
	}
}

fn test_user_exist() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test non-existent user
	exists := mydb.user.exist(999) or { panic('Failed to check existence: ${err}') }
	assert exists == false

	// Create and save a user
	mut user := mydb.user.new(
		name:           'Existence Test'
		description:    'Testing existence'
		email:          'exist@test.com'
		public_key:     ''
		phone:          ''
		address:        ''
		avatar_url:     ''
		bio:            ''
		timezone:       'UTC'
		status:         .active
		securitypolicy: 1
		tags:           4
		comments:       []u32{}
	) or { panic('Failed to create user: ${err}') }

	mydb.user.set(mut user) or { panic('Failed to save user: ${err}') }

	// Test existing user
	exists_after_save := mydb.user.exist(user.id) or { panic('Failed to check existence: ${err}') }
	assert exists_after_save == true
}

fn test_user_delete() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a user
	mut user := mydb.user.new(
		name:           'To Be Deleted'
		description:    'This user will be deleted'
		email:          'delete@me.com'
		public_key:     ''
		phone:          ''
		address:        ''
		avatar_url:     ''
		bio:            ''
		timezone:       'UTC'
		status:         .inactive
		securitypolicy: 1
		tags:           0
		comments:       []u32{}
	) or { panic('Failed to create user: ${err}') }

	mydb.user.set(mut user) or { panic('Failed to save user: ${err}') }
	user_id := user.id

	// Verify it exists
	exists_before := mydb.user.exist(user_id) or { panic('Failed to check existence: ${err}') }
	assert exists_before == true

	// Delete the user
	mydb.user.delete(user_id) or { panic('Failed to delete user: ${err}') }

	// Verify it no longer exists
	exists_after := mydb.user.exist(user_id) or { panic('Failed to check existence: ${err}') }
	assert exists_after == false

	// Verify get fails
	if _ := mydb.user.get(user_id) {
		panic('Should not be able to get deleted user')
	}
}

fn test_user_list() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Clear any existing users by creating a fresh DB
	mydb = heromodels.new() or { panic('Failed to create fresh DB: ${err}') }

	// Initially should be empty
	initial_list := mydb.user.list() or { panic('Failed to list users: ${err}') }
	initial_count := initial_list.len

	// Create multiple users
	mut user1 := mydb.user.new(
		name:           'User One'
		description:    'First test user'
		email:          'user1@test.com'
		public_key:     'key1'
		phone:          '+1-111-111-1111'
		address:        'Address 1'
		avatar_url:     'avatar1.jpg'
		bio:            'Bio 1'
		timezone:       'UTC'
		status:         .active
		securitypolicy: 1
		tags:           5
		comments:       []u32{}
	) or { panic('Failed to create user1: ${err}') }

	mut user2 := mydb.user.new(
		name:           'User Two'
		description:    'Second test user'
		email:          'user2@test.com'
		public_key:     'key2'
		phone:          '+1-222-222-2222'
		address:        'Address 2'
		avatar_url:     'avatar2.jpg'
		bio:            'Bio 2'
		timezone:       'America/New_York'
		status:         .pending
		securitypolicy: 2
		tags:           6
		comments:       []u32{}
	) or { panic('Failed to create user2: ${err}') }

	// Save both users
	mydb.user.set(mut user1) or { panic('Failed to save user1: ${err}') }
	mydb.user.set(mut user2) or { panic('Failed to save user2: ${err}') }

	// List users
	user_list := mydb.user.list() or { panic('Failed to list users: ${err}') }

	// Should have 2 more users than initially
	assert user_list.len == initial_count + 2

	// Find our users in the list
	mut found_user1 := false
	mut found_user2 := false

	for usr in user_list {
		if usr.name == 'User One' {
			found_user1 = true
			assert usr.email == 'user1@test.com'
			assert usr.status == .active
		}
		if usr.name == 'User Two' {
			found_user2 = true
			assert usr.email == 'user2@test.com'
			assert usr.status == .pending
		}
	}

	assert found_user1 == true
	assert found_user2 == true
}

fn test_user_edge_cases() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test user with empty fields
	mut empty_user := mydb.user.new(
		name:           ''
		description:    ''
		email:          ''
		public_key:     ''
		phone:          ''
		address:        ''
		avatar_url:     ''
		bio:            ''
		timezone:       ''
		status:         .inactive
		securitypolicy: 0
		tags:           0
		comments:       []u32{}
	) or { panic('Failed to create empty user: ${err}') }

	mydb.user.set(mut empty_user) or { panic('Failed to save empty user: ${err}') }

	retrieved_empty := mydb.user.get(empty_user.id) or { panic('Failed to get empty user: ${err}') }
	assert retrieved_empty.name == ''
	assert retrieved_empty.email == ''
	assert retrieved_empty.phone == ''
	assert retrieved_empty.status == .inactive

	// Test user with very long fields
	long_text := 'Very long text. '.repeat(100)
	mut long_user := mydb.user.new(
		name:           long_text
		description:    long_text
		email:          'very.long.email.address.that.might.be.too.long@example.com'
		public_key:     long_text
		phone:          '+1-555-' + '1234567890'.repeat(10)
		address:        long_text
		avatar_url:     'https://example.com/' + 'path/'.repeat(50) + 'avatar.jpg'
		bio:            long_text
		timezone:       'America/New_York'
		status:         .active
		securitypolicy: 999
		tags:           7
		comments:       []u32{}
	) or { panic('Failed to create long user: ${err}') }

	mydb.user.set(mut long_user) or { panic('Failed to save long user: ${err}') }

	retrieved_long := mydb.user.get(long_user.id) or { panic('Failed to get long user: ${err}') }
	assert retrieved_long.name == long_text
	assert retrieved_long.description == long_text
	assert retrieved_long.status == .active
}
