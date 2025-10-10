module herofs

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.hero.user
import json
// Fs and FsArg are part of the same module, no need to import explicitly
// import freeflowuniverse.herolib.hero.herofs { Fs, FsArg }

fn test_fs_new() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args := FsArg{
		name: 'test_fs_new'
		description: 'Test filesystem for new function'
		quota_bytes: 1000
	}

	fs := db_fs.new(args)!

	assert fs.name == 'test_fs_new'
	assert fs.description == 'Test filesystem for new function'
	assert fs.quota_bytes == 1000
	assert fs.used_bytes == 0
	assert fs.updated_at > 0
	assert fs.root_dir_id == 0 // Should be 0 before setting

	println('✓ Fs new test passed!')
}

fn test_fs_new_get_set() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args1 := FsArg{
		name: 'test_fs_new_get_set'
		description: 'Test filesystem for new_get_set function'
		quota_bytes: 2000
	}

	mut fs1 := db_fs.new_get_set(args1)!
	assert fs1.name == 'test_fs_new_get_set'
	assert fs1.description == 'Test filesystem for new_get_set function'
	assert fs1.quota_bytes == 2000
	assert fs1.used_bytes == 0
	assert fs1.root_dir_id > 0 // Should be set after new_get_set

	mut args2 := FsArg{
		name: 'test_fs_new_get_set'
		description: 'Updated description'
		quota_bytes: 3000
	}

	mut fs2 := db_fs.new_get_set(args2)!
	assert fs2.id == fs1.id
	assert fs2.name == 'test_fs_new_get_set'
	assert fs2.description == 'Updated description'
	assert fs2.quota_bytes == 3000
	assert fs2.used_bytes == 0
	assert fs2.root_dir_id == fs1.root_dir_id

	println('✓ Fs new_get_set test passed!')
}

fn test_fs_crud_operations() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args := FsArg{
		name: 'crud_test_fs'
		description: 'CRUD Test Filesystem'
		quota_bytes: 5000
	}

	mut fs := db_fs.new(args)!
	fs = db_fs.set(fs)!
	original_id := fs.id

	retrieved_fs := db_fs.get(original_id)!
	assert retrieved_fs.name == 'crud_test_fs'
	assert retrieved_fs.id == original_id

	exists := db_fs.exist(original_id)!
	assert exists == true

	mut updated_args := FsArg{
		name: 'crud_test_fs'
		description: 'Updated CRUD Test Filesystem'
		quota_bytes: 6000
	}
	mut updated_fs := db_fs.new(updated_args)!
	updated_fs.id = original_id
	updated_fs = db_fs.set(updated_fs)!

	final_fs := db_fs.get(original_id)!
	assert final_fs.description == 'Updated CRUD Test Filesystem'
	assert final_fs.quota_bytes == 6000

	db_fs.delete(original_id)!
	exists_after_delete := db_fs.exist(original_id)!
	assert exists_after_delete == false

	println('✓ Fs CRUD operations test passed!')
}

fn test_fs_list() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args1 := FsArg{
		name: 'fs_list_test_1'
		description: 'Filesystem for list test 1'
	}
	mut fs1 := db_fs.new_get_set(args1)!

	mut args2 := FsArg{
		name: 'fs_list_test_2'
		description: 'Filesystem for list test 2'
	}
	mut fs2 := db_fs.new_get_set(args2)!

	list_of_fss := db_fs.list(FsListArg{})!
	assert list_of_fss.len == 2
	assert list_of_fss[0].name == 'fs_list_test_1' || list_of_fss[0].name == 'fs_list_test_2'
	assert list_of_fss[1].name == 'fs_list_test_1' || list_of_fss[1].name == 'fs_list_test_2'

	println('✓ Fs list test passed!')
}

fn test_fs_get_by_name() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args := FsArg{
		name: 'fs_by_name'
		description: 'Filesystem for get_by_name test'
	}
	mut fs := db_fs.new_get_set(args)!

	retrieved_fs := db_fs.get_by_name('fs_by_name')!
	assert retrieved_fs.id == fs.id
	assert retrieved_fs.name == 'fs_by_name'

	println('✓ Fs get_by_name test passed!')
}

fn test_fs_check_quota() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args := FsArg{
		name: 'fs_quota_test'
		quota_bytes: 100
		used_bytes: 50
	}
	mut fs := db_fs.new_get_set(args)!

	// Check within quota
	can_add := db_fs.check_quota(fs.id, 40)!
	assert can_add == true

	// Check exactly at quota limit
	can_add_exact := db_fs.check_quota(fs.id, 50)!
	assert can_add_exact == true

	// Check exceeding quota
	cannot_add := db_fs.check_quota(fs.id, 51)!
	assert cannot_add == false

	println('✓ Fs check_quota test passed!')
}

fn test_fs_root_dir() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args := FsArg{
		name: 'fs_root_dir_test'
	}
	mut fs := db_fs.new_get_set(args)!

	root_dir := fs.root_dir()!
	assert root_dir.id == fs.root_dir_id
	assert root_dir.name == 'root'
	assert root_dir.fs_id == fs.id
	assert root_dir.parent_id == 0

	println('✓ Fs root_dir test passed!')
}

fn test_fs_description() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args := FsArg{
		name: 'fs_description_test'
	}

	fs := db_fs.new(args)!

	assert fs.description('set') == 'Create or update a filesystem. Returns the ID of the filesystem.'
	assert fs.description('get') == 'Retrieve a filesystem by ID. Returns the filesystem object.'
	assert fs.description('delete') == 'Delete a filesystem by ID. Returns true if successful.'
	assert fs.description('exist') == 'Check if a filesystem exists by ID. Returns true or false.'
	assert fs.description('list') == 'List all filesystems. Returns an array of filesystem objects.'
	assert fs.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'

	println('✓ Fs description test passed!')
}

fn test_fs_example() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs

	mut args := FsArg{
		name: 'fs_example_test'
	}

	fs := db_fs.new(args)!

	set_call, set_result := fs.example('set')
	assert set_call == '{"fs": {"name": "myfs", "description": "My filesystem", "quota_bytes": 1073741824}}'
	assert set_result == '1'

	get_call, get_result := fs.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"name": "myfs", "description": "My filesystem", "quota_bytes": 1073741824, "used_bytes": 0}'

	delete_call, delete_result := fs.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := fs.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := fs.example('list')
	assert list_call == '{}'
	assert list_result == '[{"name": "myfs", "description": "My filesystem", "quota_bytes": 1073741824, "used_bytes": 0}]'

	unknown_call, unknown_result := fs.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ Fs example test passed!')
}