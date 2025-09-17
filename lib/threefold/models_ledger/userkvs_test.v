#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_userkvs_new() {
	mut mydb := setup_test_db()!
	mut kvs_db := DBUserKVS{db: &mydb}

	mut userkvs := kvs_db.new(
		name: 'Test User KVS'
		description: 'A test user KVS for unit testing'
		user_id: 1
	)!

	assert userkvs.name == 'Test User KVS'
	assert userkvs.description == 'A test user KVS for unit testing'
	assert userkvs.user_id == 1
	assert userkvs.id == 0
	assert userkvs.updated_at > 0
}

fn test_userkvs_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut kvs_db := DBUserKVS{db: &mydb}

	mut original_kvs := kvs_db.new(
		name: 'Encoding Test KVS'
		description: 'Testing encoding and decoding'
		user_id: 999
	)!

	// Test encoding
	mut encoder_obj := encoder.new()
	original_kvs.dump(mut encoder_obj)!
	encoded_data := encoder_obj.bytes()

	// Test decoding
	mut decoder_obj := encoder.new_decoder(encoded_data)
	mut decoded_kvs := UserKVS{}
	kvs_db.load(mut decoded_kvs, mut decoder_obj)!

	// Verify all fields match
	assert decoded_kvs.user_id == original_kvs.user_id
}

fn test_userkvs_crud_operations() {
	mut mydb := setup_test_db()!
	mut kvs_db := DBUserKVS{db: &mydb}

	// Create and save
	mut userkvs := kvs_db.new(
		name: 'CRUD Test KVS'
		description: 'Testing CRUD operations'
		user_id: 5
	)!

	userkvs = kvs_db.set(userkvs)!
	assert userkvs.id > 0
	kvs_id := userkvs.id

	// Get
	retrieved := kvs_db.get(kvs_id)!
	assert retrieved.user_id == 5
	assert retrieved.name == 'CRUD Test KVS'

	// Update
	userkvs.name = 'Updated KVS'
	userkvs.description = 'Updated description'
	userkvs = kvs_db.set(userkvs)!

	updated := kvs_db.get(kvs_id)!
	assert updated.name == 'Updated KVS'
	assert updated.description == 'Updated description'

	// Exist
	exists := kvs_db.exist(kvs_id)!
	assert exists == true

	// Delete
	kvs_db.delete(kvs_id)!
	exists_after := kvs_db.exist(kvs_id)!
	assert exists_after == false
}

fn test_userkvs_list() {
	mut mydb := setup_test_db()!
	mut kvs_db := DBUserKVS{db: &mydb}

	initial_list := kvs_db.list()!
	initial_count := initial_list.len

	// Create multiple KVS
	mut kvs1 := kvs_db.new(
		name: 'KVS 1'
		description: 'First KVS'
		user_id: 1
	)!

	mut kvs2 := kvs_db.new(
		name: 'KVS 2'
		description: 'Second KVS'
		user_id: 2
	)!

	kvs1 = kvs_db.set(kvs1)!
	kvs2 = kvs_db.set(kvs2)!

	kvs_list := kvs_db.list()!
	assert kvs_list.len == initial_count + 2

	mut found1 := false
	mut found2 := false
	for kvs in kvs_list {
		if kvs.user_id == 1 {
			found1 = true
			assert kvs.name == 'KVS 1'
		}
		if kvs.user_id == 2 {
			found2 = true
			assert kvs.name == 'KVS 2'
		}
	}
	assert found1 && found2
}