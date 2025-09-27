module herofs

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.hero.user
import json
import freeflowuniverse.herolib.hero.herofs { FsBlob }

fn test_fs_blob_new() ! {
	// TODO: do it for each test and call it like this
	mut factory := new_test()!
	mut db_fs_blob := factory.fs_blob

	mut args := FsBlobArg{
		data: 'Hello World!'.bytes()
	}

	blob := db_fs_blob.new(args)!

	assert blob.data == 'Hello World!'.bytes()
	assert blob.size_bytes == 12
	assert blob.hash == 'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b27796d9ad9587'
	assert blob.updated_at > 0

	println('✓ FsBlob new test passed!')
}

fn test_fs_blob_crud_operations() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'CRUD Test Data'.bytes()
	}

	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!
	original_id := blob.id

	retrieved_blob := db_fs_blob.get(original_id)!
	assert retrieved_blob.data == 'CRUD Test Data'.bytes()
	assert retrieved_blob.id == original_id

	exists := db_fs_blob.exist(original_id)!
	assert exists == true

	mut updated_args := FsBlobArg{
		data: 'Updated CRUD Test Data'.bytes()
	}
	mut updated_blob := db_fs_blob.new(updated_args)!
	updated_blob.id = original_id
	updated_blob = db_fs_blob.set(updated_blob)!

	final_blob := db_fs_blob.get(original_id)!
	assert final_blob.data == 'Updated CRUD Test Data'.bytes()

	mut expected_blob_for_hash := FsBlob{
		data:       'Updated CRUD Test Data'.bytes()
		size_bytes: 'Updated CRUD Test Data'.len
	}
	expected_blob_for_hash.calculate_hash()
	assert final_blob.hash == expected_blob_for_hash.hash

	db_fs_blob.delete(original_id)!
	exists_after_delete := db_fs_blob.exist(original_id)!
	assert exists_after_delete == false

	println('✓ FsBlob CRUD operations test passed!')
}

fn test_fs_blob_encoding_decoding() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Encoding Decoding Test'.bytes()
	}

	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!
	blob_id := blob.id

	retrieved_blob := db_fs_blob.get(blob_id)!

	assert retrieved_blob.data == 'Encoding Decoding Test'.bytes()
	assert retrieved_blob.size_bytes == 'Encoding Decoding Test'.len

	mut expected_blob_for_hash := FsBlob{
		data:       'Encoding Decoding Test'.bytes()
		size_bytes: 'Encoding Decoding Test'.len
	}
	expected_blob_for_hash.calculate_hash()
	assert retrieved_blob.hash == expected_blob_for_hash.hash

	println('✓ FsBlob encoding/decoding test passed!')
}

fn test_fs_blob_type_name() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Type Name Test'.bytes()
	}

	blob := db_fs_blob.new(args)!

	type_name := blob.type_name()
	assert type_name == 'fs_blob'

	println('✓ FsBlob type_name test passed!')
}

fn test_fs_blob_description() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Description Test'.bytes()
	}

	blob := db_fs_blob.new(args)!

	assert blob.description('set') == 'Create or update a blob. Returns the ID of the blob.'
	assert blob.description('get') == 'Retrieve a blob by ID. Returns the blob object.'
	assert blob.description('delete') == 'Delete a blob by ID. Returns true if successful.'
	assert blob.description('exist') == 'Check if a blob exists by ID. Returns true or false.'
	assert blob.description('list') == 'List all blobs. Returns an array of blob objects.'
	assert blob.description('get_by_hash') == 'Retrieve a blob by its hash. Returns the blob object.'
	assert blob.description('exists_by_hash') == 'Check if a blob exists by its hash. Returns true or false.'
	assert blob.description('verify') == 'Verify the integrity of a blob by its hash. Returns true or false.'
	assert blob.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'

	println('✓ FsBlob description test passed!')
}

fn test_fs_blob_example() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Example Test'.bytes()
	}

	blob := db_fs_blob.new(args)!

	set_call, set_result := blob.example('set')
	assert set_call == '{"data": "SGVsbG8gV29ybGQh"}'
	assert set_result == '1'

	get_call, get_result := blob.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"hash": "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b27796d9ad9587", "data": "SGVsbG8gV29ybGQh", "size_bytes": 12}'

	delete_call, delete_result := blob.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := blob.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := blob.example('list')
	assert list_call == '{}'
	assert list_result == '[{"hash": "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b27796d9ad9587", "data": "SGVsbG8gV29ybGQh", "size_bytes": 12}]'

	get_by_hash_call, get_by_hash_result := blob.example('get_by_hash')
	assert get_by_hash_call == '{"hash": "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b27796d9ad9587"}'
	assert get_by_hash_result == '{"hash": "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b27796d9ad9587", "data": "SGVsbG8gV29ybGQh", "size_bytes": 12}'

	exists_by_hash_call, exists_by_hash_result := blob.example('exists_by_hash')
	assert exists_by_hash_call == '{"hash": "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b27796d9ad9587"}'
	assert exists_by_hash_result == 'true'

	verify_call, verify_result := blob.example('verify')
	assert verify_call == '{"hash": "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b27796d9ad9587"}'
	assert verify_result == 'true'

	unknown_call, unknown_result := blob.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ FsBlob example test passed!')
}

fn test_fs_blob_list() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args1 := FsBlobArg{
		data: 'Blob 1'.bytes()
	}
	mut blob1 := db_fs_blob.new(args1)!
	blob1 = db_fs_blob.set(blob1)!

	mut args2 := FsBlobArg{
		data: 'Blob 2'.bytes()
	}
	mut blob2 := db_fs_blob.new(args2)!
	blob2 = db_fs_blob.set(blob2)!

	list_of_blobs := db_fs_blob.list()!
	assert list_of_blobs.len == 2
	assert list_of_blobs[0].data == 'Blob 1'.bytes() || list_of_blobs[0].data == 'Blob 2'.bytes()
	assert list_of_blobs[1].data == 'Blob 1'.bytes() || list_of_blobs[1].data == 'Blob 2'.bytes()

	println('✓ FsBlob list test passed!')
}

fn test_fs_blob_handle_get() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Handle Get Test'.bytes()
	}
	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	params := json.encode(blob.id)
	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'get', params)!
	assert resp.result.string() == json.encode(blob)

	println('✓ FsBlob handle get test passed!')
}

fn test_fs_blob_handle_set() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	mut args := FsBlobArg{
		data: 'Handle Set Test'.bytes()
	}
	mut blob := db_fs_blob.new(args)!

	params := json.encode(blob)
	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'set', params)!
	assert resp.result.int() == 1 // Assuming ID 1 for the first set operation

	println('✓ FsBlob handle set test passed!')
}

fn test_fs_blob_handle_delete() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Handle Delete Test'.bytes()
	}
	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	params := json.encode(blob.id)
	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'delete', params)!
	assert resp.result.string() == 'true'

	exists := db_fs_blob.exist(blob.id)!
	assert exists == false

	println('✓ FsBlob handle delete test passed!')
}

fn test_fs_blob_handle_exist() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Handle Exist Test'.bytes()
	}
	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	params := json.encode(blob.id)
	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'exist', params)!
	assert resp.result.string() == 'true'

	db_fs_blob.delete(blob.id)!
	resp_false := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'exist', params)!
	assert resp_false.result.string() == 'false'

	println('✓ FsBlob handle exist test passed!')
}

fn test_fs_blob_handle_list() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args1 := FsBlobArg{
		data: 'Handle List Test 1'.bytes()
	}
	mut blob1 := db_fs_blob.new(args1)!
	blob1 = db_fs_blob.set(blob1)!

	mut args2 := FsBlobArg{
		data: 'Handle List Test 2'.bytes()
	}
	mut blob2 := db_fs_blob.new(args2)!
	blob2 = db_fs_blob.set(blob2)!

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'list', '{}')!
	mut expected_list := [FsBlob(blob1), FsBlob(blob2)]
	assert resp.result.string() == json.encode(expected_list)

	println('✓ FsBlob handle list test passed!')
}

fn test_fs_blob_handle_get_by_hash() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Handle Get By Hash Test'.bytes()
	}
	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	params := json.encode(blob.hash)
	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'get_by_hash', params)!
	assert resp.result.string() == json.encode(blob)

	println('✓ FsBlob handle get_by_hash test passed!')
}

fn test_fs_blob_handle_exists_by_hash() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Handle Exists By Hash Test'.bytes()
	}
	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	params := json.encode(blob.hash)
	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'exists_by_hash',
		params)!
	assert resp.result.string() == 'true'

	println('✓ FsBlob handle exists_by_hash test passed!')
}

fn test_fs_blob_handle_verify() ! {
	mut mydb := db.new_test()!
	mut db_fs_blob := DBFsBlob{
		db: &mydb
	}

	mut args := FsBlobArg{
		data: 'Handle Verify Test'.bytes()
	}
	mut blob := db_fs_blob.new(args)!
	blob = db_fs_blob.set(blob)!

	mut f := FSFactory{
		fs_blob: db_fs_blob
	}

	params := json.encode(blob.hash)
	resp := fs_blob_handle(mut f, 1, map[string]string{}, UserRef{}, 'verify', params)!
	assert resp.result.string() == 'true'

	println('✓ FsBlob handle verify test passed!')
}
