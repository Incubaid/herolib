module models_ledger

import json

fn test_account_crud() ! {
	mut db := setup_test_db()!
	mut account_db := DBAccount{
		db: db
	}

	// Create test
	mut account_arg := AccountArg{
		name:            'Test Account'
		description:     'Description for test account'
		owner_id:        1
		location_id:     2
		accountpolicies: []AccountPolicyArg{}
		assets:          []AccountAsset{}
		assetid:         3
		administrators:  [u32(1), 2, 3]
	}

	mut account := account_db.new(account_arg)!
	account = account_db.set(account)!
	assert account.id > 0

	// Get test
	retrieved := account_db.get(account.id)!
	assert retrieved.name == 'Test Account'
	assert retrieved.description == 'Description for test account'
	assert retrieved.owner_id == 1
	assert retrieved.location_id == 2
	assert retrieved.assetid == 3
	assert retrieved.administrators == [u32(1), 2, 3]

	// Update test
	account.name = 'Updated Account'
	account.description = 'Updated description'
	account_db.set(account)!
	retrieved = account_db.get(account.id)!
	assert retrieved.name == 'Updated Account'
	assert retrieved.description == 'Updated description'

	// Delete test
	success := account_db.delete(account.id)!
	assert success == true
	assert account_db.exist(account.id)! == false
}

fn test_account_api_handler() ! {
	mut db := setup_test_db()!
	mut factory := new_models_factory(db)!

	// Test set method
	account_arg := AccountArg{
		name:           'API Test Account'
		description:    'API test description'
		owner_id:       10
		location_id:    20
		assetid:        30
		administrators: [u32(10), 20]
	}

	json_params := json.encode(account_arg)

	// Set
	response := account_handle(mut factory, 1, {}, UserRef{ id: 1 }, 'set', json_params)!
	id := response.result.int()
	assert id > 0

	// Exist
	response2 := account_handle(mut factory, 2, {}, UserRef{ id: 1 }, 'exist', id.str())!
	assert response2.result == 'true'

	// Get
	response3 := account_handle(mut factory, 3, {}, UserRef{ id: 1 }, 'get', id.str())!
	assert response3.result.contains('API Test Account')

	// List
	response4 := account_handle(mut factory, 4, {}, UserRef{ id: 1 }, 'list', '{}')!
	assert response4.result.contains('API Test Account')

	// Delete
	response5 := account_handle(mut factory, 5, {}, UserRef{ id: 1 }, 'delete', id.str())!
	assert response5.result == 'true'

	// Verify deletion
	response6 := account_handle(mut factory, 6, {}, UserRef{ id: 1 }, 'exist', id.str())!
	assert response6.result == 'false'
}
