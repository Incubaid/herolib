#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db

// Test that all models can be created and their basic functionality works
fn test_all_models_integration() {
	mut mydb := setup_test_db()!

	// Initialize all model DBs
	mut account_db := DBAccount{db: &mydb}
	mut asset_db := DBAsset{db: &mydb}
	mut user_db := DBUser{db: &mydb}
	mut transaction_db := DBTransaction{db: &mydb}
	mut dnszone_db := DBDNSZone{db: &mydb}
	mut group_db := DBGroup{db: &mydb}
	mut member_db := DBMember{db: &mydb}
	mut notary_db := DBNotary{db: &mydb}
	mut signature_db := DBSignature{db: &mydb}
	mut userkvs_db := DBUserKVS{db: &mydb}
	mut userkvsitem_db := DBUserKVSItem{db: &mydb}

	// Create one instance of each model to ensure they all work
	mut user := user_db.new(
		name: 'Integration Test User'
		description: 'User for integration testing'
		username: 'integrationuser'
		pubkey: 'ed25519_INTEGRATION_TEST'
		email: ['integration@test.com']
		status: .active
		userprofile: []SecretBox{}
		kyc: []SecretBox{}
	)!
	user = user_db.set(user)!

	mut asset := asset_db.new(
		name: 'Integration Test Asset'
		description: 'Asset for integration testing'
		address: 'GINTEGRATION...TEST'
		asset_type: 'token'
		issuer: user.id
		supply: 1000000.0
		decimals: 8
		is_frozen: false
		metadata: {'test': 'integration'}
		administrators: [user.id]
		min_signatures: 1
	)!
	asset = asset_db.set(asset)!

	mut account := account_db.new(
		name: 'Integration Test Account'
		description: 'Account for integration testing'
		owner_id: user.id
		location_id: 0
		accountpolicies: []AccountPolicyArg{}
		assets: []AccountAsset{}
		assetid: asset.id
		last_activity: 1234567890
		administrators: [user.id]
	)!
	account = account_db.set(account)!

	mut transaction := transaction_db.new(
		name: 'Integration Test Transaction'
		description: 'Transaction for integration testing'
		txid: 12345
		source: account.id
		destination: account.id
		assetid: asset.id
		amount: 100.0
		timestamp: 1234567890
		status: 'pending'
		memo: 'Integration test'
		tx_type: .transfer
		signatures: []TransactionSignature{}
	)!
	transaction = transaction_db.set(transaction)!

	mut dnszone := dnszone_db.new(
		name: 'Integration Test DNS Zone'
		description: 'DNS zone for integration testing'
		domain: 'integration.test'
		dnsrecords: []DNSRecord{}
		administrators: [user.id]
		status: .active
		min_signatures: 1
		metadata: {'test': 'integration'}
		soarecord: []SOARecord{}
	)!
	dnszone = dnszone_db.set(dnszone)!

	mut group := group_db.new(
		name: 'Integration Test Group'
		description: 'Group for integration testing'
		group_name: 'integration_group'
		dnsrecords: [dnszone.id]
		administrators: [user.id]
		min_signatures: 1
		config: GroupConfig{
			max_members: 100
			allow_guests: true
			auto_approve: true
			require_invite: false
		}
		status: .active
		visibility: .public
		created: 1234567890
		updated: 1234567890
	)!
	group = group_db.set(group)!

	mut member := member_db.new(
		name: 'Integration Test Member'
		description: 'Member for integration testing'
		group_id: group.id
		user_id: user.id
		role: .admin
		status: .active
	)!
	member = member_db.set(member)!

	mut notary := notary_db.new(
		name: 'Integration Test Notary'
		description: 'Notary for integration testing'
		notary_id: 1
		pubkey: 'ed25519_NOTARY_INTEGRATION'
		address: 'TFT_INTEGRATION_NOTARY'
		is_active: true
	)!
	notary = notary_db.set(notary)!

	mut signature := signature_db.new(
		name: 'Integration Test Signature'
		description: 'Signature for integration testing'
		signer_id: user.id
		tx_id: transaction.id
		signature: 'integration_signature_hex'
	)!
	signature = signature_db.set(signature)!

	mut userkvs := userkvs_db.new(
		name: 'Integration Test KVS'
		description: 'KVS for integration testing'
		user_id: user.id
	)!
	userkvs = userkvs_db.set(userkvs)!

	mut userkvsitem := userkvsitem_db.new(
		name: 'Integration Test KVS Item'
		description: 'KVS item for integration testing'
		kvs_id: userkvs.id
		key: 'integration_key'
		value: 'integration_value'
	)!
	userkvsitem = userkvsitem_db.set(userkvsitem)!

	// Verify all objects were created successfully
	assert user.id > 0
	assert asset.id > 0
	assert account.id > 0
	assert transaction.id > 0
	assert dnszone.id > 0
	assert group.id > 0
	assert member.id > 0
	assert notary.id > 0
	assert signature.id > 0
	assert userkvs.id > 0
	assert userkvsitem.id > 0

	// Verify relationships
	assert account.owner_id == user.id
	assert transaction.source == account.id
	assert transaction.assetid == asset.id
	assert member.group_id == group.id
	assert member.user_id == user.id
	assert signature.signer_id == user.id
	assert signature.tx_id == transaction.id
	assert userkvs.user_id == user.id
	assert userkvsitem.kvs_id == userkvs.id

	println('✅ All models integration test passed!')
}

fn test_encoding_decoding_performance() {
	mut mydb := setup_test_db()!

	// Test encoding/decoding performance with a complex object
	mut user_db := DBUser{db: &mydb}
	
	// Create a user with large encrypted data
	large_data := []u8{len: 10000, init: u8(index % 256)}
	large_nonce := []u8{len: 12, init: u8(index + 100)}
	
	large_secrets := []SecretBox{len: 10, init: SecretBox{
		data: large_data
		nonce: large_nonce
	}}

	mut user := user_db.new(
		name: 'Performance Test User'
		description: 'User for performance testing'
		username: 'perfuser'
		pubkey: 'ed25519_PERFORMANCE_TEST'
		email: ['perf@test.com', 'perf2@test.com', 'perf3@test.com']
		status: .active
		userprofile: large_secrets
		kyc: large_secrets
	)!

	// Save and retrieve to test full encoding/decoding cycle
	user = user_db.set(user)!
	retrieved_user := user_db.get(user.id)!

	// Verify the large data was preserved
	assert retrieved_user.userprofile.len == 10
	assert retrieved_user.kyc.len == 10
	assert retrieved_user.userprofile[0].data.len == 10000
	assert retrieved_user.userprofile[0].data[0] == 0
	assert retrieved_user.userprofile[0].data[9999] == 15 // 9999 % 256

	println('✅ Encoding/decoding performance test passed!')
}