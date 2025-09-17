#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder


// Test Account model CRUD operations with focus on encoding/decoding
fn test_account_new() {
	mut mydb := setup_test_db()!
	mut account_db := DBAccount{db: &mydb}

	// Create test account with complex nested structures
	policy := AccountPolicyArg{
		policy_id: 1
		admins: [u32(1), 2, 3]
		min_signatures: 2
		limits: [
			AccountLimit{
				amount: 1000.0
				asset_id: 1
				period: .daily
			},
			AccountLimit{
				amount: 5000.0
				asset_id: 2
				period: .monthly
			}
		]
		whitelist_out: [u32(10), 20]
		whitelist_in: [u32(30), 40]
		lock_till: 1234567890
		admin_lock_type: .locked_till
		admin_lock_till: 1234567900
		admin_unlock: [u32(5), 6]
		admin_unlock_min_signature: 1
		clawback_accounts: [u32(7), 8]
		clawback_min_signatures: 2
		clawback_from: 1234567800
		clawback_to: 1234567950
	}

	asset := AccountAsset{
		assetid: 1
		balance: 1500.0
		metadata: {'currency': 'USD', 'type': 'stable'}
	}

	mut account := account_db.new(
		name: 'Test Account'
		description: 'A test account for unit testing'
		owner_id: 123
		location_id: 456
		accountpolicies: [policy]
		assets: [asset]
		assetid: 1
		last_activity: 1234567890
		administrators: [u32(1), 2, 3]
	)!

	// Verify the account was created with correct values
	assert account.name == 'Test Account'
	assert account.description == 'A test account for unit testing'
	assert account.owner_id == 123
	assert account.location_id == 456
	assert account.accountpolicies.len == 1
	assert account.accountpolicies[0].policy_id == 1
	assert account.accountpolicies[0].admins.len == 3
	assert account.accountpolicies[0].limits.len == 2
	assert account.assets.len == 1
	assert account.assets[0].assetid == 1
	assert account.assets[0].balance == 1500.0
	assert account.administrators.len == 3
}

fn test_account_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut account_db := DBAccount{db: &mydb}

	// Create a complex account with all field types
	policy := AccountPolicyArg{
		policy_id: 1
		admins: [u32(1), 2, 3]
		min_signatures: 2
		limits: [
			AccountLimit{
				amount: 1000.0
				asset_id: 1
				period: .daily
			}
		]
		whitelist_out: [u32(10)]
		whitelist_in: [u32(30)]
		lock_till: 1234567890
		admin_lock_type: .locked
		admin_lock_till: 1234567900
		admin_unlock: [u32(5)]
		admin_unlock_min_signature: 1
		clawback_accounts: [u32(7)]
		clawback_min_signatures: 1
		clawback_from: 1234567800
		clawback_to: 1234567950
	}

	asset := AccountAsset{
		assetid: 1
		balance: 1500.0
		metadata: {'currency': 'USD', 'type': 'stable', 'issuer': 'test'}
	}

	mut original_account := account_db.new(
		name: 'Encoding Test Account'
		description: 'Testing encoding and decoding'
		owner_id: 999
		location_id: 888
		accountpolicies: [policy]
		assets: [asset]
		assetid: 1
		last_activity: 1234567890
		administrators: [u32(1), 2, 3, 4, 5]
	)!

	// Test encoding
	mut encoder_obj := encoder.encoder_new()
	original_account.dump(mut encoder_obj)!
	encoded_data := encoder_obj.data

	// Test decoding
	mut decoder_obj := encoder.decoder_new(encoded_data)
	mut decoded_account := Account{}
	account_db.load(mut decoded_account, mut decoder_obj)!

	// Verify all fields match after encoding/decoding
	assert decoded_account.owner_id == original_account.owner_id
	assert decoded_account.location_id == original_account.location_id
	assert decoded_account.assetid == original_account.assetid
	assert decoded_account.last_activity == original_account.last_activity
	assert decoded_account.administrators.len == original_account.administrators.len
	assert decoded_account.administrators[0] == original_account.administrators[0]
	assert decoded_account.administrators[4] == original_account.administrators[4]

	// Verify account policies
	assert decoded_account.accountpolicies.len == original_account.accountpolicies.len
	decoded_policy := decoded_account.accountpolicies[0]
	original_policy := original_account.accountpolicies[0]
	assert decoded_policy.policy_id == original_policy.policy_id
	assert decoded_policy.admins.len == original_policy.admins.len
	assert decoded_policy.min_signatures == original_policy.min_signatures
	assert decoded_policy.limits.len == original_policy.limits.len
	assert decoded_policy.limits[0].amount == original_policy.limits[0].amount
	assert decoded_policy.limits[0].asset_id == original_policy.limits[0].asset_id
	assert decoded_policy.limits[0].period == original_policy.limits[0].period

	// Verify assets
	assert decoded_account.assets.len == original_account.assets.len
	decoded_asset := decoded_account.assets[0]
	original_asset := original_account.assets[0]
	assert decoded_asset.assetid == original_asset.assetid
	assert decoded_asset.balance == original_asset.balance
	assert decoded_asset.metadata.len == original_asset.metadata.len
	assert decoded_asset.metadata['currency'] == original_asset.metadata['currency']
	assert decoded_asset.metadata['type'] == original_asset.metadata['type']
}

fn test_account_set_and_get() {
	mut mydb := setup_test_db()!
	mut account_db := DBAccount{db: &mydb}

	// Create account
	policy := AccountPolicyArg{
		policy_id: 1
		admins: [u32(1)]
		min_signatures: 1
		limits: []AccountLimit{}
		whitelist_out: []u32{}
		whitelist_in: []u32{}
		lock_till: 0
		admin_lock_type: .free
		admin_lock_till: 0
		admin_unlock: []u32{}
		admin_unlock_min_signature: 0
		clawback_accounts: []u32{}
		clawback_min_signatures: 0
		clawback_from: 0
		clawback_to: 0
	}

	mut account := account_db.new(
		name: 'DB Test Account'
		description: 'Testing database operations'
		owner_id: 123
		location_id: 456
		accountpolicies: [policy]
		assets: []AccountAsset{}
		assetid: 1
		last_activity: 1234567890
		administrators: [u32(1), 2]
	)!

	// Save the account
	account = account_db.set(account)!

	// Verify ID was assigned
	assert account.id > 0
	original_id := account.id

	// Retrieve the account
	retrieved_account := account_db.get(account.id)!

	// Verify all fields match through the database roundtrip
	assert retrieved_account.id == original_id
	assert retrieved_account.name == 'DB Test Account'
	assert retrieved_account.description == 'Testing database operations'
	assert retrieved_account.owner_id == 123
	assert retrieved_account.location_id == 456
	assert retrieved_account.assetid == 1
	assert retrieved_account.last_activity == 1234567890
	assert retrieved_account.administrators.len == 2
	assert retrieved_account.administrators[0] == 1
	assert retrieved_account.administrators[1] == 2
	assert retrieved_account.accountpolicies.len == 1
	assert retrieved_account.accountpolicies[0].policy_id == 1
}

fn test_account_delete_and_exist() {
	mut mydb := setup_test_db()!
	mut account_db := DBAccount{db: &mydb}

	// Create and save account
	mut account := account_db.new(
		name: 'To Be Deleted'
		description: 'This account will be deleted'
		owner_id: 999
		location_id: 888
		accountpolicies: []AccountPolicyArg{}
		assets: []AccountAsset{}
		assetid: 1
		last_activity: 1234567890
		administrators: []u32{}
	)!

	account = account_db.set(account)!
	account_id := account.id

	// Verify it exists
	exists_before := account_db.exist(account_id)!
	assert exists_before == true

	// Delete the account
	account_db.delete(account_id)!

	// Verify it no longer exists
	exists_after := account_db.exist(account_id)!
	assert exists_after == false

	// Verify get fails
	if _ := account_db.get(account_id) {
		panic('Should not be able to get deleted account')
	}
}

fn test_account_list() {
	mut mydb := setup_test_db()!
	mut account_db := DBAccount{db: &mydb}

	// Initially should be empty
	initial_list := account_db.list()!
	initial_count := initial_list.len

	// Create multiple accounts
	mut account1 := account_db.new(
		name: 'Account 1'
		description: 'First account'
		owner_id: 1
		location_id: 1
		accountpolicies: []AccountPolicyArg{}
		assets: []AccountAsset{}
		assetid: 1
		last_activity: 1234567890
		administrators: []u32{}
	)!

	mut account2 := account_db.new(
		name: 'Account 2'
		description: 'Second account'
		owner_id: 2
		location_id: 2
		accountpolicies: []AccountPolicyArg{}
		assets: []AccountAsset{}
		assetid: 2
		last_activity: 1234567891
		administrators: [u32(1)]
	)!

	// Save both accounts
	account1 = account_db.set(account1)!
	account2 = account_db.set(account2)!

	// List accounts
	account_list := account_db.list()!

	// Should have 2 more accounts than initially
	assert account_list.len == initial_count + 2

	// Find our accounts in the list
	mut found_account1 := false
	mut found_account2 := false

	for acc in account_list {
		if acc.name == 'Account 1' {
			found_account1 = true
			assert acc.owner_id == 1
			assert acc.location_id == 1
		}
		if acc.name == 'Account 2' {
			found_account2 = true
			assert acc.owner_id == 2
			assert acc.administrators.len == 1
		}
	}

	assert found_account1 == true
	assert found_account2 == true
}