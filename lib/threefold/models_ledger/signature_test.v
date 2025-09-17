#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_signature_new() {
	mut mydb := setup_test_db()!
	mut sig_db := DBSignature{db: &mydb}

	mut signature := sig_db.new(
		name: 'Test Signature'
		description: 'A test signature for unit testing'
		signer_id: 1
		tx_id: 123
		signature: 'abcd1234567890efgh'
	)!

	assert signature.name == 'Test Signature'
	assert signature.description == 'A test signature for unit testing'
	assert signature.signer_id == 1
	assert signature.tx_id == 123
	assert signature.signature == 'abcd1234567890efgh'
	assert signature.timestamp > 0
	assert signature.id == 0
	assert signature.updated_at > 0
}

fn test_signature_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut sig_db := DBSignature{db: &mydb}

	mut original_sig := sig_db.new(
		name: 'Encoding Test Signature'
		description: 'Testing encoding and decoding'
		signer_id: 999
		tx_id: 888
		signature: 'hex_encoded_signature_123456789abcdef'
	)!

	// Test encoding
	mut encoder_obj := encoder.new()
	original_sig.dump(mut encoder_obj)!
	encoded_data := encoder_obj.bytes()

	// Test decoding
	mut decoder_obj := encoder.new_decoder(encoded_data)
	mut decoded_sig := Signature{}
	sig_db.load(mut decoded_sig, mut decoder_obj)!

	// Verify all fields match
	assert decoded_sig.signer_id == original_sig.signer_id
	assert decoded_sig.tx_id == original_sig.tx_id
	assert decoded_sig.signature == original_sig.signature
	assert decoded_sig.timestamp == original_sig.timestamp
}

fn test_signature_crud_operations() {
	mut mydb := setup_test_db()!
	mut sig_db := DBSignature{db: &mydb}

	// Create and save
	mut signature := sig_db.new(
		name: 'CRUD Test Signature'
		description: 'Testing CRUD operations'
		signer_id: 5
		tx_id: 15
		signature: 'crud_test_signature_hex'
	)!

	signature = sig_db.set(signature)!
	assert signature.id > 0
	sig_id := signature.id

	// Get
	retrieved := sig_db.get(sig_id)!
	assert retrieved.signer_id == 5
	assert retrieved.tx_id == 15
	assert retrieved.signature == 'crud_test_signature_hex'

	// Update
	signature.signature = 'updated_signature_hex'
	signature = sig_db.set(signature)!

	updated := sig_db.get(sig_id)!
	assert updated.signature == 'updated_signature_hex'

	// Exist
	exists := sig_db.exist(sig_id)!
	assert exists == true

	// Delete
	sig_db.delete(sig_id)!
	exists_after := sig_db.exist(sig_id)!
	assert exists_after == false
}

fn test_signature_list() {
	mut mydb := setup_test_db()!
	mut sig_db := DBSignature{db: &mydb}

	initial_list := sig_db.list()!
	initial_count := initial_list.len

	// Create multiple signatures
	mut sig1 := sig_db.new(
		name: 'Signature 1'
		description: 'First signature'
		signer_id: 1
		tx_id: 101
		signature: 'signature1_hex'
	)!

	mut sig2 := sig_db.new(
		name: 'Signature 2'
		description: 'Second signature'
		signer_id: 2
		tx_id: 102
		signature: 'signature2_hex'
	)!

	sig1 = sig_db.set(sig1)!
	sig2 = sig_db.set(sig2)!

	sig_list := sig_db.list()!
	assert sig_list.len == initial_count + 2

	mut found1 := false
	mut found2 := false
	for s in sig_list {
		if s.signer_id == 1 {
			found1 = true
			assert s.tx_id == 101
		}
		if s.signer_id == 2 {
			found2 = true
			assert s.tx_id == 102
		}
	}
	assert found1 && found2
}

fn test_signature_edge_cases() {
	mut mydb := setup_test_db()!
	mut sig_db := DBSignature{db: &mydb}

	// Test minimal signature
	mut minimal_sig := sig_db.new(
		name: ''
		description: ''
		signer_id: 0
		tx_id: 0
		signature: ''
	)!

	minimal_sig = sig_db.set(minimal_sig)!
	retrieved := sig_db.get(minimal_sig.id)!

	assert retrieved.name == ''
	assert retrieved.description == ''
	assert retrieved.signer_id == 0
	assert retrieved.tx_id == 0
	assert retrieved.signature == ''

	// Test very long signature
	long_signature := 'A'.repeat(10000)

	mut long_sig := sig_db.new(
		name: 'Long Signature'
		description: 'Testing with very long signature'
		signer_id: 999999
		tx_id: 888888
		signature: long_signature
	)!

	long_sig = sig_db.set(long_sig)!
	retrieved_long := sig_db.get(long_sig.id)!

	assert retrieved_long.signature == long_signature
	assert retrieved_long.signer_id == 999999
	assert retrieved_long.tx_id == 888888
}