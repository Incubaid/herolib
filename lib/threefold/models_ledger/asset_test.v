#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_asset_new() {
	mut mydb := setup_test_db()!
	mut asset_db := DBAsset{db: &mydb}

	// Test creating a new asset with all fields
	mut asset := asset_db.new(
		name: 'Test Token'
		description: 'A test token for unit testing'
		address: 'GBTC...XYZ123'
		asset_type: 'token'
		issuer: 1
		supply: 1000000.0
		decimals: 8
		is_frozen: false
		metadata: {'symbol': 'TEST', 'website': 'https://test.com'}
		administrators: [u32(1), 2, 3]
		min_signatures: 2
	)!

	// Verify the asset was created with correct values
	assert asset.name == 'Test Token'
	assert asset.description == 'A test token for unit testing'
	assert asset.address == 'GBTC...XYZ123'
	assert asset.asset_type == 'token'
	assert asset.issuer == 1
	assert asset.supply == 1000000.0
	assert asset.decimals == 8
	assert asset.is_frozen == false
	assert asset.metadata.len == 2
	assert asset.metadata['symbol'] == 'TEST'
	assert asset.metadata['website'] == 'https://test.com'
	assert asset.administrators.len == 3
	assert asset.min_signatures == 2
	assert asset.id == 0 // Should be 0 before saving
	assert asset.updated_at > 0 // Should have timestamp
}

fn test_asset_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut asset_db := DBAsset{db: &mydb}

	// Create a complex asset with all field types
	mut original_asset := asset_db.new(
		name: 'Encoding Test Asset'
		description: 'Testing encoding and decoding functionality'
		address: 'GABCD...XYZ789'
		asset_type: 'nft'
		issuer: 999
		supply: 5000000.0
		decimals: 6
		is_frozen: true
		metadata: {
			'symbol': 'ETA'
			'website': 'https://example.com'
			'description': 'Extended test asset'
			'category': 'utility'
			'version': '1.0'
		}
		administrators: [u32(10), 20, 30, 40]
		min_signatures: 3
	)!

	// Test encoding
	mut encoder_obj := encoder.encoder_new()
	original_asset.dump(mut encoder_obj)!
	encoded_data := encoder_obj.data

	// Test decoding
	mut decoder_obj := encoder.decoder_new(encoded_data)
	mut decoded_asset := Asset{}
	asset_db.load(mut decoded_asset, mut decoder_obj)!

	// Verify all fields match after encoding/decoding
	assert decoded_asset.address == original_asset.address
	assert decoded_asset.asset_type == original_asset.asset_type
	assert decoded_asset.issuer == original_asset.issuer
	assert decoded_asset.supply == original_asset.supply
	assert decoded_asset.decimals == original_asset.decimals
	assert decoded_asset.is_frozen == original_asset.is_frozen
	assert decoded_asset.min_signatures == original_asset.min_signatures

	// Verify metadata map
	assert decoded_asset.metadata.len == original_asset.metadata.len
	for key, value in original_asset.metadata {
		assert decoded_asset.metadata[key] == value
	}

	// Verify administrators list
	assert decoded_asset.administrators.len == original_asset.administrators.len
	for i, admin in original_asset.administrators {
		assert decoded_asset.administrators[i] == admin
	}
}

fn test_asset_set_and_get() {
	mut mydb := setup_test_db()!
	mut asset_db := DBAsset{db: &mydb}

	// Create asset
	mut asset := asset_db.new(
		name: 'DB Test Asset'
		description: 'Testing database operations'
		address: 'GTEST...DB123'
		asset_type: 'token'
		issuer: 42
		supply: 100000.0
		decimals: 2
		is_frozen: false
		metadata: {'currency': 'EUR', 'region': 'EU'}
		administrators: [u32(5), 10]
		min_signatures: 1
	)!

	// Save the asset
	asset = asset_db.set(asset)!

	// Verify ID was assigned
	assert asset.id > 0
	original_id := asset.id

	// Retrieve the asset
	retrieved_asset := asset_db.get(asset.id)!

	// Verify all fields match through the database roundtrip
	assert retrieved_asset.id == original_id
	assert retrieved_asset.name == 'DB Test Asset'
	assert retrieved_asset.description == 'Testing database operations'
	assert retrieved_asset.address == 'GTEST...DB123'
	assert retrieved_asset.asset_type == 'token'
	assert retrieved_asset.issuer == 42
	assert retrieved_asset.supply == 100000.0
	assert retrieved_asset.decimals == 2
	assert retrieved_asset.is_frozen == false
	assert retrieved_asset.metadata.len == 2
	assert retrieved_asset.metadata['currency'] == 'EUR'
	assert retrieved_asset.metadata['region'] == 'EU'
	assert retrieved_asset.administrators.len == 2
	assert retrieved_asset.administrators[0] == 5
	assert retrieved_asset.administrators[1] == 10
	assert retrieved_asset.min_signatures == 1
}

fn test_asset_update() {
	mut mydb := setup_test_db()!
	mut asset_db := DBAsset{db: &mydb}

	// Create and save an asset
	mut asset := asset_db.new(
		name: 'Original Asset'
		description: 'Original description'
		address: 'GORIG...123'
		asset_type: 'token'
		issuer: 1
		supply: 1000.0
		decimals: 8
		is_frozen: false
		metadata: {'version': '1.0'}
		administrators: [u32(1)]
		min_signatures: 1
	)!

	asset = asset_db.set(asset)!
	original_id := asset.id
	original_created_at := asset.created_at

	// Update the asset
	asset.name = 'Updated Asset'
	asset.description = 'Updated description'
	asset.supply = 2000.0
	asset.is_frozen = true
	asset.metadata = {'version': '2.0', 'status': 'updated'}
	asset.administrators = [u32(1), 2, 3]
	asset.min_signatures = 2

	asset = asset_db.set(asset)!

	// Verify ID remains the same
	assert asset.id == original_id
	assert asset.created_at == original_created_at

	// Retrieve and verify updates
	updated_asset := asset_db.get(asset.id)!
	assert updated_asset.name == 'Updated Asset'
	assert updated_asset.description == 'Updated description'
	assert updated_asset.supply == 2000.0
	assert updated_asset.is_frozen == true
	assert updated_asset.metadata.len == 2
	assert updated_asset.metadata['version'] == '2.0'
	assert updated_asset.metadata['status'] == 'updated'
	assert updated_asset.administrators.len == 3
	assert updated_asset.min_signatures == 2
}

fn test_asset_exist_and_delete() {
	mut mydb := setup_test_db()!
	mut asset_db := DBAsset{db: &mydb}

	// Test non-existent asset
	exists := asset_db.exist(999)!
	assert exists == false

	// Create and save an asset
	mut asset := asset_db.new(
		name: 'To Be Deleted'
		description: 'This asset will be deleted'
		address: 'GDEL...123'
		asset_type: 'token'
		issuer: 1
		supply: 1.0
		decimals: 0
		is_frozen: false
		metadata: map[string]string{}
		administrators: []u32{}
		min_signatures: 0
	)!

	asset = asset_db.set(asset)!
	asset_id := asset.id

	// Test existing asset
	exists_after_save := asset_db.exist(asset_id)!
	assert exists_after_save == true

	// Delete the asset
	asset_db.delete(asset_id)!

	// Verify it no longer exists
	exists_after_delete := asset_db.exist(asset_id)!
	assert exists_after_delete == false

	// Verify get fails
	if _ := asset_db.get(asset_id) {
		panic('Should not be able to get deleted asset')
	}
}

fn test_asset_list() {
	mut mydb := setup_test_db()!
	mut asset_db := DBAsset{db: &mydb}

	// Initially should be empty
	initial_list := asset_db.list()!
	initial_count := initial_list.len

	// Create multiple assets
	mut asset1 := asset_db.new(
		name: 'Asset 1'
		description: 'First asset'
		address: 'GFIRST...123'
		asset_type: 'token'
		issuer: 1
		supply: 1000.0
		decimals: 8
		is_frozen: false
		metadata: {'type': 'utility'}
		administrators: [u32(1)]
		min_signatures: 1
	)!

	mut asset2 := asset_db.new(
		name: 'Asset 2'
		description: 'Second asset'
		address: 'GSECOND...456'
		asset_type: 'nft'
		issuer: 2
		supply: 100.0
		decimals: 0
		is_frozen: true
		metadata: {'type': 'collectible', 'rarity': 'rare'}
		administrators: [u32(1), 2]
		min_signatures: 2
	)!

	// Save both assets
	asset1 = asset_db.set(asset1)!
	asset2 = asset_db.set(asset2)!

	// List assets
	asset_list := asset_db.list()!

	// Should have 2 more assets than initially
	assert asset_list.len == initial_count + 2

	// Find our assets in the list
	mut found_asset1 := false
	mut found_asset2 := false

	for ass in asset_list {
		if ass.name == 'Asset 1' {
			found_asset1 = true
			assert ass.asset_type == 'token'
			assert ass.is_frozen == false
			assert ass.metadata['type'] == 'utility'
		}
		if ass.name == 'Asset 2' {
			found_asset2 = true
			assert ass.asset_type == 'nft'
			assert ass.is_frozen == true
			assert ass.metadata['rarity'] == 'rare'
		}
	}

	assert found_asset1 == true
	assert found_asset2 == true
}

fn test_asset_edge_cases() {
	mut mydb := setup_test_db()!
	mut asset_db := DBAsset{db: &mydb}

	// Test empty/minimal asset
	mut minimal_asset := asset_db.new(
		name: ''
		description: ''
		address: ''
		asset_type: ''
		issuer: 0
		supply: 0.0
		decimals: 0
		is_frozen: false
		metadata: map[string]string{}
		administrators: []u32{}
		min_signatures: 0
	)!

	minimal_asset = asset_db.set(minimal_asset)!
	retrieved_minimal := asset_db.get(minimal_asset.id)!

	assert retrieved_minimal.name == ''
	assert retrieved_minimal.description == ''
	assert retrieved_minimal.address == ''
	assert retrieved_minimal.asset_type == ''
	assert retrieved_minimal.issuer == 0
	assert retrieved_minimal.supply == 0.0
	assert retrieved_minimal.metadata.len == 0
	assert retrieved_minimal.administrators.len == 0

	// Test asset with large metadata map
	large_metadata := map[string]string{}
	for i in 0 .. 100 {
		large_metadata['key_${i}'] = 'value_${i}'
	}

	mut large_asset := asset_db.new(
		name: 'Large Metadata Asset'
		description: 'Asset with large metadata'
		address: 'GLARGE...123'
		asset_type: 'token'
		issuer: 1
		supply: 1000.0
		decimals: 8
		is_frozen: false
		metadata: large_metadata
		administrators: []u32{}
		min_signatures: 0
	)!

	large_asset = asset_db.set(large_asset)!
	retrieved_large := asset_db.get(large_asset.id)!

	assert retrieved_large.metadata.len == 100
	assert retrieved_large.metadata['key_0'] == 'value_0'
	assert retrieved_large.metadata['key_99'] == 'value_99'
}