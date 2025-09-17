#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_user_new() {
	mut mydb := setup_test_db()!
	mut user_db := DBUser{db: &mydb}

	// Create test user with encrypted data
	secret_profile := SecretBox{
		data: [u8(1), 2, 3, 4, 5]
		nonce: [u8(10), 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]
	}

	secret_kyc := SecretBox{
		data: [u8(100), 101, 102, 103]
		nonce: [u8(200), 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211]
	}

	mut user := user_db.new(
		name: 'Test User'
		description: 'A test user for unit testing'
		username: 'testuser123'
		pubkey: 'ed25519_ABCD...XYZ'
		email: ['test@example.com', 'test2@example.com']
		status: .active
		userprofile: [secret_profile]
		kyc: [secret_kyc]
	)!

	// Verify the user was created with correct values
	assert user.name == 'Test User'
	assert user.description == 'A test user for unit testing'
	assert user.username == 'testuser123'
	assert user.pubkey == 'ed25519_ABCD...XYZ'
	assert user.email.len == 2
	assert user.email[0] == 'test@example.com'
	assert user.email[1] == 'test2@example.com'
	assert user.status == .active
	assert user.userprofile.len == 1
	assert user.kyc.len == 1
	assert user.id == 0 // Should be 0 before saving
	assert user.updated_at > 0 // Should have timestamp
}

fn test_user_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut user_db := DBUser{db: &mydb}

	// Create a complex user with multiple encrypted boxes
	profile1 := SecretBox{
		data: [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, 10]
		nonce: [u8(10), 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]
	}

	profile2 := SecretBox{
		data: [u8(50), 51, 52, 53, 54]
		nonce: [u8(60), 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71]
	}

	kyc1 := SecretBox{
		data: [u8(100), 101, 102, 103, 104, 105, 106]
		nonce: [u8(200), 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211]
	}

	mut original_user := user_db.new(
		name: 'Encoding Test User'
		description: 'Testing encoding and decoding functionality'
		username: 'encodeuser'
		pubkey: 'ed25519_ENCODE...TEST'
		email: ['encode@test.com', 'encode2@test.com', 'encode3@test.com']
		status: .suspended
		userprofile: [profile1, profile2]
		kyc: [kyc1]
	)!

	// Test encoding
	mut encoder_obj := encoder.encoder_new()
	original_user.dump(mut encoder_obj)!
	encoded_data := encoder_obj.data

	// Test decoding
	mut decoder_obj := encoder.decoder_new(encoded_data)
	mut decoded_user := User{}
	user_db.load(mut decoded_user, mut decoder_obj)!

	// Verify all fields match after encoding/decoding
	assert decoded_user.username == original_user.username
	assert decoded_user.pubkey == original_user.pubkey
	assert decoded_user.status == original_user.status

	// Verify email list
	assert decoded_user.email.len == original_user.email.len
	for i, email in original_user.email {
		assert decoded_user.email[i] == email
	}

	// Verify userprofile SecretBox arrays
	assert decoded_user.userprofile.len == original_user.userprofile.len
	for i, profile in original_user.userprofile {
		assert decoded_user.userprofile[i].data.len == profile.data.len
		assert decoded_user.userprofile[i].nonce.len == profile.nonce.len
		for j, byte_val in profile.data {
			assert decoded_user.userprofile[i].data[j] == byte_val
		}
		for j, nonce_val in profile.nonce {
			assert decoded_user.userprofile[i].nonce[j] == nonce_val
		}
	}

	// Verify kyc SecretBox arrays
	assert decoded_user.kyc.len == original_user.kyc.len
	for i, kyc_box in original_user.kyc {
		assert decoded_user.kyc[i].data.len == kyc_box.data.len
		assert decoded_user.kyc[i].nonce.len == kyc_box.nonce.len
		for j, byte_val in kyc_box.data {
			assert decoded_user.kyc[i].data[j] == byte_val
		}
		for j, nonce_val in kyc_box.nonce {
			assert decoded_user.kyc[i].nonce[j] == nonce_val
		}
	}
}

fn test_user_set_and_get() {
	mut mydb := setup_test_db()!
	mut user_db := DBUser{db: &mydb}

	// Create user
	mut user := user_db.new(
		name: 'DB Test User'
		description: 'Testing database operations'
		username: 'dbuser'
		pubkey: 'ed25519_DB...TEST'
		email: ['db@test.com']
		status: .active
		userprofile: []SecretBox{}
		kyc: []SecretBox{}
	)!

	// Save the user
	user = user_db.set(user)!

	// Verify ID was assigned
	assert user.id > 0
	original_id := user.id

	// Retrieve the user
	retrieved_user := user_db.get(user.id)!

	// Verify all fields match through the database roundtrip
	assert retrieved_user.id == original_id
	assert retrieved_user.name == 'DB Test User'
	assert retrieved_user.description == 'Testing database operations'
	assert retrieved_user.username == 'dbuser'
	assert retrieved_user.pubkey == 'ed25519_DB...TEST'
	assert retrieved_user.email.len == 1
	assert retrieved_user.email[0] == 'db@test.com'
	assert retrieved_user.status == .active
	assert retrieved_user.userprofile.len == 0
	assert retrieved_user.kyc.len == 0
}

fn test_user_update() {
	mut mydb := setup_test_db()!
	mut user_db := DBUser{db: &mydb}

	// Create and save a user
	mut user := user_db.new(
		name: 'Original User'
		description: 'Original description'
		username: 'original'
		pubkey: 'ed25519_ORIG...123'
		email: ['orig@test.com']
		status: .active
		userprofile: []SecretBox{}
		kyc: []SecretBox{}
	)!

	user = user_db.set(user)!
	original_id := user.id
	original_created_at := user.created_at

	// Update the user
	new_profile := SecretBox{
		data: [u8(99), 98, 97]
		nonce: [u8(10), 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21]
	}

	user.name = 'Updated User'
	user.description = 'Updated description'
	user.email = ['updated@test.com', 'updated2@test.com']
	user.status = .inactive
	user.userprofile = [new_profile]

	user = user_db.set(user)!

	// Verify ID remains the same
	assert user.id == original_id
	assert user.created_at == original_created_at

	// Retrieve and verify updates
	updated_user := user_db.get(user.id)!
	assert updated_user.name == 'Updated User'
	assert updated_user.description == 'Updated description'
	assert updated_user.email.len == 2
	assert updated_user.email[0] == 'updated@test.com'
	assert updated_user.email[1] == 'updated2@test.com'
	assert updated_user.status == .inactive
	assert updated_user.userprofile.len == 1
	assert updated_user.userprofile[0].data.len == 3
}

fn test_user_exist_and_delete() {
	mut mydb := setup_test_db()!
	mut user_db := DBUser{db: &mydb}

	// Test non-existent user
	exists := user_db.exist(999)!
	assert exists == false

	// Create and save a user
	mut user := user_db.new(
		name: 'To Be Deleted'
		description: 'This user will be deleted'
		username: 'deleteme'
		pubkey: 'ed25519_DEL...123'
		email: ['delete@test.com']
		status: .archived
		userprofile: []SecretBox{}
		kyc: []SecretBox{}
	)!

	user = user_db.set(user)!
	user_id := user.id

	// Test existing user
	exists_after_save := user_db.exist(user_id)!
	assert exists_after_save == true

	// Delete the user
	user_db.delete(user_id)!

	// Verify it no longer exists
	exists_after_delete := user_db.exist(user_id)!
	assert exists_after_delete == false

	// Verify get fails
	if _ := user_db.get(user_id) {
		panic('Should not be able to get deleted user')
	}
}

fn test_user_list() {
	mut mydb := setup_test_db()!
	mut user_db := DBUser{db: &mydb}

	// Initially should be empty
	initial_list := user_db.list()!
	initial_count := initial_list.len

	// Create multiple users
	mut user1 := user_db.new(
		name: 'User 1'
		description: 'First user'
		username: 'user1'
		pubkey: 'ed25519_USER1...123'
		email: ['user1@test.com']
		status: .active
		userprofile: []SecretBox{}
		kyc: []SecretBox{}
	)!

	mut user2 := user_db.new(
		name: 'User 2'
		description: 'Second user'
		username: 'user2'
		pubkey: 'ed25519_USER2...456'
		email: ['user2@test.com', 'user2alt@test.com']
		status: .suspended
		userprofile: []SecretBox{}
		kyc: []SecretBox{}
	)!

	// Save both users
	user1 = user_db.set(user1)!
	user2 = user_db.set(user2)!

	// List users
	user_list := user_db.list()!

	// Should have 2 more users than initially
	assert user_list.len == initial_count + 2

	// Find our users in the list
	mut found_user1 := false
	mut found_user2 := false

	for u in user_list {
		if u.username == 'user1' {
			found_user1 = true
			assert u.status == .active
			assert u.email.len == 1
		}
		if u.username == 'user2' {
			found_user2 = true
			assert u.status == .suspended
			assert u.email.len == 2
		}
	}

	assert found_user1 == true
	assert found_user2 == true
}

fn test_user_edge_cases() {
	mut mydb := setup_test_db()!
	mut user_db := DBUser{db: &mydb}

	// Test empty/minimal user
	mut minimal_user := user_db.new(
		name: ''
		description: ''
		username: ''
		pubkey: ''
		email: []string{}
		status: .active
		userprofile: []SecretBox{}
		kyc: []SecretBox{}
	)!

	minimal_user = user_db.set(minimal_user)!
	retrieved_minimal := user_db.get(minimal_user.id)!

	assert retrieved_minimal.name == ''
	assert retrieved_minimal.description == ''
	assert retrieved_minimal.username == ''
	assert retrieved_minimal.pubkey == ''
	assert retrieved_minimal.email.len == 0
	assert retrieved_minimal.userprofile.len == 0
	assert retrieved_minimal.kyc.len == 0

	// Test user with large data arrays
	large_data := []u8{len: 1000, init: u8(index % 256)}
	large_nonce := []u8{len: 12, init: u8(index + 100)}

	large_secret := SecretBox{
		data: large_data
		nonce: large_nonce
	}

	mut large_user := user_db.new(
		name: 'Large Data User'
		description: 'User with large encrypted data'
		username: 'largeuser'
		pubkey: 'ed25519_LARGE...123'
		email: ['large@test.com']
		status: .active
		userprofile: [large_secret, large_secret] // Duplicate for testing
		kyc: [large_secret]
	)!

	large_user = user_db.set(large_user)!
	retrieved_large := user_db.get(large_user.id)!

	assert retrieved_large.userprofile.len == 2
	assert retrieved_large.kyc.len == 1
	assert retrieved_large.userprofile[0].data.len == 1000
	assert retrieved_large.userprofile[0].nonce.len == 12
	assert retrieved_large.userprofile[0].data[0] == 0
	assert retrieved_large.userprofile[0].data[999] == 231 // 999 % 256
}