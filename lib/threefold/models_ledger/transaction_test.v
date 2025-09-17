#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_transaction_new() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Create test transaction with signatures
	sig1 := TransactionSignature{
		signer_id: 1
		signature: 'sig1_abcd123'
		timestamp: 1234567890
	}

	sig2 := TransactionSignature{
		signer_id: 2
		signature: 'sig2_efgh456'
		timestamp: 1234567891
	}

	mut transaction := tx_db.new(
		name:        'Test Transaction'
		description: 'A test transaction for unit testing'
		txid:        12345
		source:      100
		destination: 200
		assetid:     1
		amount:      500.75
		timestamp:   1234567890
		status:      'pending'
		memo:        'Test transfer'
		tx_type:     .transfer
		signatures:  [sig1, sig2]
	)!

	// Verify the transaction was created with correct values
	assert transaction.name == 'Test Transaction'
	assert transaction.description == 'A test transaction for unit testing'
	assert transaction.txid == 12345
	assert transaction.source == 100
	assert transaction.destination == 200
	assert transaction.assetid == 1
	assert transaction.amount == 500.75
	assert transaction.timestamp == 1234567890
	assert transaction.status == 'pending'
	assert transaction.memo == 'Test transfer'
	assert transaction.tx_type == .transfer
	assert transaction.signatures.len == 2
	assert transaction.signatures[0].signer_id == 1
	assert transaction.signatures[1].signature == 'sig2_efgh456'
	assert transaction.id == 0 // Should be 0 before saving
	assert transaction.updated_at > 0 // Should have timestamp
}

fn test_transaction_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Create a complex transaction with multiple signatures
	sigs := [
		TransactionSignature{
			signer_id: 10
			signature: 'complex_sig_1_abcdef123456'
			timestamp: 1234567800
		},
		TransactionSignature{
			signer_id: 20
			signature: 'complex_sig_2_ghijkl789012'
			timestamp: 1234567801
		},
		TransactionSignature{
			signer_id: 30
			signature: 'complex_sig_3_mnopqr345678'
			timestamp: 1234567802
		},
	]

	mut original_tx := tx_db.new(
		name:        'Encoding Test Transaction'
		description: 'Testing encoding and decoding functionality'
		txid:        99999
		source:      999
		destination: 888
		assetid:     5
		amount:      12345.6789
		timestamp:   1234567890
		status:      'completed'
		memo:        'Complex transaction for encoding test with special chars: !@#$%^&*()'
		tx_type:     .clawback
		signatures:  sigs
	)!

	// Test encoding
	mut encoder_obj := encoder.encoder_new()
	original_tx.dump(mut encoder_obj)!
	encoded_data := encoder_obj.data

	// Test decoding
	mut decoder_obj := encoder.decoder_new(encoded_data)
	mut decoded_tx := Transaction{}
	tx_db.load(mut decoded_tx, mut decoder_obj)!

	// Verify all fields match after encoding/decoding
	assert decoded_tx.txid == original_tx.txid
	assert decoded_tx.source == original_tx.source
	assert decoded_tx.destination == original_tx.destination
	assert decoded_tx.assetid == original_tx.assetid
	assert decoded_tx.amount == original_tx.amount
	assert decoded_tx.timestamp == original_tx.timestamp
	assert decoded_tx.status == original_tx.status
	assert decoded_tx.memo == original_tx.memo
	assert decoded_tx.tx_type == original_tx.tx_type

	// Verify signatures array
	assert decoded_tx.signatures.len == original_tx.signatures.len
	for i, sig in original_tx.signatures {
		assert decoded_tx.signatures[i].signer_id == sig.signer_id
		assert decoded_tx.signatures[i].signature == sig.signature
		assert decoded_tx.signatures[i].timestamp == sig.timestamp
	}
}

fn test_transaction_set_and_get() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Create transaction
	sig := TransactionSignature{
		signer_id: 5
		signature: 'db_test_sig_123'
		timestamp: 1234567890
	}

	mut transaction := tx_db.new(
		name:        'DB Test Transaction'
		description: 'Testing database operations'
		txid:        555
		source:      111
		destination: 222
		assetid:     3
		amount:      100.50
		timestamp:   1234567890
		status:      'confirmed'
		memo:        'Database test transfer'
		tx_type:     .transfer
		signatures:  [sig]
	)!

	// Save the transaction
	transaction = tx_db.set(transaction)!

	// Verify ID was assigned
	assert transaction.id > 0
	original_id := transaction.id

	// Retrieve the transaction
	retrieved_tx := tx_db.get(transaction.id)!

	// Verify all fields match through the database roundtrip
	assert retrieved_tx.id == original_id
	assert retrieved_tx.name == 'DB Test Transaction'
	assert retrieved_tx.description == 'Testing database operations'
	assert retrieved_tx.txid == 555
	assert retrieved_tx.source == 111
	assert retrieved_tx.destination == 222
	assert retrieved_tx.assetid == 3
	assert retrieved_tx.amount == 100.50
	assert retrieved_tx.timestamp == 1234567890
	assert retrieved_tx.status == 'confirmed'
	assert retrieved_tx.memo == 'Database test transfer'
	assert retrieved_tx.tx_type == .transfer
	assert retrieved_tx.signatures.len == 1
	assert retrieved_tx.signatures[0].signer_id == 5
	assert retrieved_tx.signatures[0].signature == 'db_test_sig_123'
}

fn test_transaction_update() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Create and save a transaction
	mut transaction := tx_db.new(
		name:        'Original Transaction'
		description: 'Original description'
		txid:        777
		source:      100
		destination: 200
		assetid:     1
		amount:      50.0
		timestamp:   1234567890
		status:      'pending'
		memo:        'Original memo'
		tx_type:     .transfer
		signatures:  []TransactionSignature{}
	)!

	transaction = tx_db.set(transaction)!
	original_id := transaction.id
	original_created_at := transaction.created_at

	// Update the transaction
	new_sig := TransactionSignature{
		signer_id: 999
		signature: 'updated_signature_xyz'
		timestamp: 1234567999
	}

	transaction.name = 'Updated Transaction'
	transaction.description = 'Updated description'
	transaction.status = 'completed'
	transaction.memo = 'Updated memo'
	transaction.tx_type = .issue
	transaction.signatures = [new_sig]

	transaction = tx_db.set(transaction)!

	// Verify ID remains the same
	assert transaction.id == original_id
	assert transaction.created_at == original_created_at

	// Retrieve and verify updates
	updated_tx := tx_db.get(transaction.id)!
	assert updated_tx.name == 'Updated Transaction'
	assert updated_tx.description == 'Updated description'
	assert updated_tx.status == 'completed'
	assert updated_tx.memo == 'Updated memo'
	assert updated_tx.tx_type == .issue
	assert updated_tx.signatures.len == 1
	assert updated_tx.signatures[0].signer_id == 999
}

fn test_transaction_exist_and_delete() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Test non-existent transaction
	exists := tx_db.exist(999)!
	assert exists == false

	// Create and save a transaction
	mut transaction := tx_db.new(
		name:        'To Be Deleted'
		description: 'This transaction will be deleted'
		txid:        666
		source:      100
		destination: 200
		assetid:     1
		amount:      1.0
		timestamp:   1234567890
		status:      'failed'
		memo:        'Delete me'
		tx_type:     .burn
		signatures:  []TransactionSignature{}
	)!

	transaction = tx_db.set(transaction)!
	tx_id := transaction.id

	// Test existing transaction
	exists_after_save := tx_db.exist(tx_id)!
	assert exists_after_save == true

	// Delete the transaction
	tx_db.delete(tx_id)!

	// Verify it no longer exists
	exists_after_delete := tx_db.exist(tx_id)!
	assert exists_after_delete == false

	// Verify get fails
	if _ := tx_db.get(tx_id) {
		panic('Should not be able to get deleted transaction')
	}
}

fn test_transaction_list() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Initially should be empty
	initial_list := tx_db.list()!
	initial_count := initial_list.len

	// Create multiple transactions
	mut tx1 := tx_db.new(
		name:        'Transaction 1'
		description: 'First transaction'
		txid:        1001
		source:      1
		destination: 2
		assetid:     1
		amount:      100.0
		timestamp:   1234567890
		status:      'completed'
		memo:        'First'
		tx_type:     .transfer
		signatures:  []TransactionSignature{}
	)!

	mut tx2 := tx_db.new(
		name:        'Transaction 2'
		description: 'Second transaction'
		txid:        1002
		source:      2
		destination: 3
		assetid:     2
		amount:      200.0
		timestamp:   1234567891
		status:      'pending'
		memo:        'Second'
		tx_type:     .freeze
		signatures:  []TransactionSignature{}
	)!

	// Save both transactions
	tx1 = tx_db.set(tx1)!
	tx2 = tx_db.set(tx2)!

	// List transactions
	tx_list := tx_db.list()!

	// Should have 2 more transactions than initially
	assert tx_list.len == initial_count + 2

	// Find our transactions in the list
	mut found_tx1 := false
	mut found_tx2 := false

	for tx in tx_list {
		if tx.txid == 1001 {
			found_tx1 = true
			assert tx.status == 'completed'
			assert tx.tx_type == .transfer
		}
		if tx.txid == 1002 {
			found_tx2 = true
			assert tx.status == 'pending'
			assert tx.tx_type == .freeze
		}
	}

	assert found_tx1 == true
	assert found_tx2 == true
}

fn test_transaction_types() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Test all transaction types
	tx_types := [TransactionType.transfer, .clawback, .freeze, .unfreeze, .issue, .burn]

	for i, tx_type in tx_types {
		mut tx := tx_db.new(
			name:        'Transaction Type Test ${i}'
			description: 'Testing ${tx_type}'
			txid:        u32(2000 + i)
			source:      100
			destination: 200
			assetid:     1
			amount:      f64(i + 1) * 10.0
			timestamp:   1234567890
			status:      'completed'
			memo:        'Type test for ${tx_type}'
			tx_type:     tx_type
			signatures:  []TransactionSignature{}
		)!

		tx = tx_db.set(tx)!
		retrieved_tx := tx_db.get(tx.id)!
		assert retrieved_tx.tx_type == tx_type
	}
}

fn test_transaction_edge_cases() {
	mut mydb := setup_test_db()!
	mut tx_db := DBTransaction{
		db: &mydb
	}

	// Test minimal transaction
	mut minimal_tx := tx_db.new(
		name:        ''
		description: ''
		txid:        0
		source:      0
		destination: 0
		assetid:     0
		amount:      0.0
		timestamp:   0
		status:      ''
		memo:        ''
		tx_type:     .transfer
		signatures:  []TransactionSignature{}
	)!

	minimal_tx = tx_db.set(minimal_tx)!
	retrieved_minimal := tx_db.get(minimal_tx.id)!

	assert retrieved_minimal.name == ''
	assert retrieved_minimal.description == ''
	assert retrieved_minimal.txid == 0
	assert retrieved_minimal.amount == 0.0
	assert retrieved_minimal.status == ''
	assert retrieved_minimal.memo == ''
	assert retrieved_minimal.signatures.len == 0

	// Test transaction with many signatures
	many_sigs := []TransactionSignature{len: 100, init: TransactionSignature{
		signer_id: u32(index + 1)
		signature: 'sig_${index}_abcd123'
		timestamp: u64(1234567890 + index)
	}}

	mut large_tx := tx_db.new(
		name:        'Large Signature Transaction'
		description: 'Transaction with many signatures'
		txid:        9999
		source:      100
		destination: 200
		assetid:     1
		amount:      1000.0
		timestamp:   1234567890
		status:      'multisig'
		memo:        'Many signatures test'
		tx_type:     .transfer
		signatures:  many_sigs
	)!

	large_tx = tx_db.set(large_tx)!
	retrieved_large := tx_db.get(large_tx.id)!

	assert retrieved_large.signatures.len == 100
	assert retrieved_large.signatures[0].signer_id == 1
	assert retrieved_large.signatures[99].signer_id == 100
	assert retrieved_large.signatures[50].signature == 'sig_50_abcd123'
}
