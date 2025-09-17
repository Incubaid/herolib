#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_notary_new() {
	mut mydb := setup_test_db()!
	mut notary_db := DBNotary{db: &mydb}

	mut notary := notary_db.new(
		name: 'Test Notary'
		description: 'A test notary for unit testing'
		notary_id: 1
		pubkey: 'ed25519_ABCD1234567890EFGH'
		address: 'TFT_ADDRESS_XYZ123'
		is_active: true
	)!

	assert notary.name == 'Test Notary'
	assert notary.description == 'A test notary for unit testing'
	assert notary.notary_id == 1
	assert notary.pubkey == 'ed25519_ABCD1234567890EFGH'
	assert notary.address == 'TFT_ADDRESS_XYZ123'
	assert notary.is_active == true
	assert notary.id == 0
	assert notary.updated_at > 0
}

fn test_notary_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut notary_db := DBNotary{db: &mydb}

	mut original_notary := notary_db.new(
		name: 'Encoding Test Notary'
		description: 'Testing encoding and decoding'
		notary_id: 999
		pubkey: 'ed25519_ENCODING_TEST_PUBKEY_123456789'
		address: 'TFT_ENCODING_ADDRESS_ABCDEF'
		is_active: false
	)!

	// Test encoding
	mut encoder_obj := encoder.new()
	original_notary.dump(mut encoder_obj)!
	encoded_data := encoder_obj.bytes()

	// Test decoding
	mut decoder_obj := encoder.new_decoder(encoded_data)
	mut decoded_notary := Notary{}
	notary_db.load(mut decoded_notary, mut decoder_obj)!

	// Verify all fields match
	assert decoded_notary.notary_id == original_notary.notary_id
	assert decoded_notary.pubkey == original_notary.pubkey
	assert decoded_notary.address == original_notary.address
	assert decoded_notary.is_active == original_notary.is_active
}

fn test_notary_crud_operations() {
	mut mydb := setup_test_db()!
	mut notary_db := DBNotary{db: &mydb}

	// Create and save
	mut notary := notary_db.new(
		name: 'CRUD Test Notary'
		description: 'Testing CRUD operations'
		notary_id: 5
		pubkey: 'ed25519_CRUD_TEST_PUBKEY'
		address: 'TFT_CRUD_ADDRESS'
		is_active: true
	)!

	notary = notary_db.set(notary)!
	assert notary.id > 0
	notary_id := notary.id

	// Get
	retrieved := notary_db.get(notary_id)!
	assert retrieved.notary_id == 5
	assert retrieved.pubkey == 'ed25519_CRUD_TEST_PUBKEY'
	assert retrieved.address == 'TFT_CRUD_ADDRESS'
	assert retrieved.is_active == true

	// Update
	notary.is_active = false
	notary.address = 'TFT_UPDATED_ADDRESS'
	notary = notary_db.set(notary)!

	updated := notary_db.get(notary_id)!
	assert updated.is_active == false
	assert updated.address == 'TFT_UPDATED_ADDRESS'

	// Exist
	exists := notary_db.exist(notary_id)!
	assert exists == true

	// Delete
	notary_db.delete(notary_id)!
	exists_after := notary_db.exist(notary_id)!
	assert exists_after == false
}

fn test_notary_list() {
	mut mydb := setup_test_db()!
	mut notary_db := DBNotary{db: &mydb}

	initial_list := notary_db.list()!
	initial_count := initial_list.len

	// Create multiple notaries
	mut notary1 := notary_db.new(
		name: 'Notary 1'
		description: 'First notary'
		notary_id: 1
		pubkey: 'ed25519_NOTARY1_PUBKEY'
		address: 'TFT_NOTARY1_ADDRESS'
		is_active: true
	)!

	mut notary2 := notary_db.new(
		name: 'Notary 2'
		description: 'Second notary'
		notary_id: 2
		pubkey: 'ed25519_NOTARY2_PUBKEY'
		address: 'TFT_NOTARY2_ADDRESS'
		is_active: false
	)!

	notary1 = notary_db.set(notary1)!
	notary2 = notary_db.set(notary2)!

	notary_list := notary_db.list()!
	assert notary_list.len == initial_count + 2

	mut found1 := false
	mut found2 := false
	for n in notary_list {
		if n.notary_id == 1 {
			found1 = true
			assert n.is_active == true
		}
		if n.notary_id == 2 {
			found2 = true
			assert n.is_active == false
		}
	}
	assert found1 && found2
}

fn test_notary_edge_cases() {
	mut mydb := setup_test_db()!
	mut notary_db := DBNotary{db: &mydb}

	// Test empty strings
	mut minimal_notary := notary_db.new(
		name: ''
		description: ''
		notary_id: 0
		pubkey: ''
		address: ''
		is_active: false
	)!

	minimal_notary = notary_db.set(minimal_notary)!
	retrieved := notary_db.get(minimal_notary.id)!

	assert retrieved.name == ''
	assert retrieved.description == ''
	assert retrieved.notary_id == 0
	assert retrieved.pubkey == ''
	assert retrieved.address == ''
	assert retrieved.is_active == false

	// Test long strings
	long_pubkey := 'ed25519_' + 'A'.repeat(1000)
	long_address := 'TFT_' + 'B'.repeat(1000)

	mut long_notary := notary_db.new(
		name: 'Long String Notary'
		description: 'Testing with very long strings'
		notary_id: 999999
		pubkey: long_pubkey
		address: long_address
		is_active: true
	)!

	long_notary = notary_db.set(long_notary)!
	retrieved_long := notary_db.get(long_notary.id)!

	assert retrieved_long.pubkey == long_pubkey
	assert retrieved_long.address == long_address
	assert retrieved_long.notary_id == 999999
}