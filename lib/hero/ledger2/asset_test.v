module ledger

import json

fn test_asset_crud() ! {
	mut db := setup_test_db()!
	mut asset_db := DBAsset{
		db: db
	}

	// Create test
	mut asset_arg := AssetArg{
		name:           'TFT Token'
		description:    'ThreeFold Token'
		address:        'TFT123456789'
		asset_type:     'token'
		issuer:         1
		supply:         1000000.0
		decimals:       8
		is_frozen:      false
		metadata:       {
			'symbol':     'TFT'
			'blockchain': 'Stellar'
		}
		administrators: [u32(1), 2]
		min_signatures: 1
	}

	mut asset := asset_db.new(asset_arg)!
	asset = asset_db.set(asset)!
	assert asset.id > 0

	// Get test
	retrieved := asset_db.get(asset.id)!
	assert retrieved.name == 'TFT Token'
	assert retrieved.description == 'ThreeFold Token'
	assert retrieved.address == 'TFT123456789'
	assert retrieved.asset_type == 'token'
	assert retrieved.issuer == 1
	assert retrieved.supply == 1000000.0
	assert retrieved.decimals == 8
	assert retrieved.is_frozen == false
	assert retrieved.metadata == {
		'symbol':     'TFT'
		'blockchain': 'Stellar'
	}
	assert retrieved.administrators == [u32(1), 2]
	assert retrieved.min_signatures == 1

	// Update test
	asset.name = 'Updated TFT Token'
	asset.supply = 2000000.0
	asset.is_frozen = true
	asset_db.set(asset)!
	retrieved = asset_db.get(asset.id)!
	assert retrieved.name == 'Updated TFT Token'
	assert retrieved.supply == 2000000.0
	assert retrieved.is_frozen == true

	// Delete test
	success := asset_db.delete(asset.id)!
	assert success == true
	assert asset_db.exist(asset.id)! == false
}

fn test_asset_list_filtering() ! {
	mut db := setup_test_db()!
	mut asset_db := DBAsset{
		db: db
	}

	// Create multiple test assets
	for i in 0 .. 5 {
		mut asset_arg := AssetArg{
			name:        'Token ${i}'
			description: 'Description ${i}'
			address:     'ADDR${i}'
			asset_type:  if i < 3 { 'token' } else { 'nft' }
			issuer:      if i % 2 == 0 { u32(1) } else { u32(2) }
			supply:      1000.0 * u64(i + 1)
			decimals:    8
			is_frozen:   i >= 3
		}

		mut asset := asset_db.new(asset_arg)!
		asset_db.set(asset)!
	}

	// Test filter by text
	filtered := asset_db.list(AssetListArg{ filter: 'Token 1' })!
	assert filtered.len == 1
	assert filtered[0].name == 'Token 1'

	// Test filter by asset_type
	tokens := asset_db.list(AssetListArg{ asset_type: 'token' })!
	assert tokens.len == 3

	// Test filter by frozen status
	frozen := asset_db.list(AssetListArg{ is_frozen: true, filter_frozen: true })!
	assert frozen.len == 2

	// Test filter by issuer
	issuer1 := asset_db.list(AssetListArg{ issuer: 1, filter_issuer: true })!
	assert issuer1.len == 3

	// Test pagination
	page1 := asset_db.list(AssetListArg{ limit: 2, offset: 0 })!
	assert page1.len == 2
	page2 := asset_db.list(AssetListArg{ limit: 2, offset: 2 })!
	assert page2.len == 2
	page3 := asset_db.list(AssetListArg{ limit: 2, offset: 4 })!
	assert page3.len == 1
}

fn test_asset_api_handler() ! {
	mut db := setup_test_db()!
	mut factory := new_models_factory(db)!

	// Test set method
	asset_arg := AssetArg{
		name:        'API Test Asset'
		description: 'API test description'
		address:     'TEST123'
		asset_type:  'token'
		issuer:      1
		supply:      1000.0
		decimals:    8
	}

	json_params := json.encode(asset_arg)

	// Set
	response := asset_handle(mut factory, 1, {}, UserRef{ id: 1 }, 'set', json_params)!
	id := response.result.int()
	assert id > 0

	// Exist
	response2 := asset_handle(mut factory, 2, {}, UserRef{ id: 1 }, 'exist', id.str())!
	assert response2.result == 'true'

	// Get
	response3 := asset_handle(mut factory, 3, {}, UserRef{ id: 1 }, 'get', id.str())!
	assert response3.result.contains('API Test Asset')

	// List
	response4 := asset_handle(mut factory, 4, {}, UserRef{ id: 1 }, 'list', '{}')!
	assert response4.result.contains('API Test Asset')

	// List with filters
	filter_params := json.encode(AssetListArg{ asset_type: 'token' })
	response5 := asset_handle(mut factory, 5, {}, UserRef{ id: 1 }, 'list', filter_params)!
	assert response5.result.contains('API Test Asset')

	// Delete
	response6 := asset_handle(mut factory, 6, {}, UserRef{ id: 1 }, 'delete', id.str())!
	assert response6.result == 'true'

	// Verify deletion
	response7 := asset_handle(mut factory, 7, {}, UserRef{ id: 1 }, 'exist', id.str())!
	assert response7.result == 'false'
}
