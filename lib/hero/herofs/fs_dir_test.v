module herofs

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.hero.user
import json
// FsDir, FsDirArg, FsFileArg, MimeType, FsBlobArg are part of the same module, no need to import explicitly
// import freeflowuniverse.herolib.hero.herofs { FsDir, FsDirArg, FsFileArg, MimeType, FsBlobArg }

fn test_fs_dir_new() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'test_fs_dir_new')!

	mut args := FsDirArg{
		name: 'test_dir'
		description: 'Test directory for new function'
		fs_id: fs.id
		parent_id: fs.root_dir_id
	}

	dir := db_fs_dir.new(args)!

	assert dir.name == 'test_dir'
	assert dir.description == 'Test directory for new function'
	assert dir.fs_id == fs.id
	assert dir.parent_id == fs.root_dir_id
	assert dir.created_at > 0
	assert dir.updated_at > 0

	println('✓ FsDir new test passed!')
}

fn test_fs_dir_crud_operations() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'crud_test_fs_dir')!
	root_dir := fs.root_dir()!

	mut args := FsDirArg{
		name: 'crud_dir'
		description: 'CRUD Test Directory'
		fs_id: fs.id
		parent_id: root_dir.id
	}

	mut dir := db_fs_dir.new(args)!
	dir = db_fs_dir.set(dir)!
	original_id := dir.id

	retrieved_dir := db_fs_dir.get(original_id)!
	assert retrieved_dir.name == 'crud_dir'
	assert retrieved_dir.id == original_id

	exists := db_fs_dir.exist(original_id)!
	assert exists == true

	// Update directory
	mut updated_dir_obj := retrieved_dir
	updated_dir_obj.description = 'Updated CRUD Test Directory'
	updated_dir_obj = db_fs_dir.set(updated_dir_obj)!

	final_dir := db_fs_dir.get(original_id)!
	assert final_dir.description == 'Updated CRUD Test Directory'

	db_fs_dir.delete(original_id)!
	exists_after_delete := db_fs_dir.exist(original_id)!
	assert exists_after_delete == false

	println('✓ FsDir CRUD operations test passed!')
}

fn test_fs_dir_create_path() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'create_path_fs')!

	path_id := db_fs_dir.create_path(fs.id, '/path/to/new/dir')!
	assert path_id > 0

	// Verify the path was created
	dir_new := db_fs_dir.get(path_id)!
	assert dir_new.name == 'dir'

	dir_to := db_fs_dir.get(dir_new.parent_id)!
	assert dir_to.name == 'new'

	dir_path := db_fs_dir.get(dir_to.parent_id)!
	assert dir_path.name == 'to'

	dir_root := db_fs_dir.get(dir_path.parent_id)!
	assert dir_root.name == 'path'

	println('✓ FsDir create_path test passed!')
}

fn test_fs_dir_list() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'fs_dir_list_test')!
	mut root_dir := fs.root_dir()!

	mut dir1 := db_fs_dir.new(name: 'list_dir1', fs_id: fs.id, parent_id: root_dir.id)!
	dir1 = db_fs_dir.set(dir1)!
	root_dir.directories << dir1.id
	root_dir = db_fs_dir.set(root_dir)!

	mut dir2 := db_fs_dir.new(name: 'list_dir2', fs_id: fs.id, parent_id: root_dir.id)!
	dir2 = db_fs_dir.set(dir2)!
	root_dir.directories << dir2.id
	root_dir = db_fs_dir.set(root_dir)!

	list_of_dirs := db_fs_dir.list()!
	// Should be root_dir, dir1, dir2
	assert list_of_dirs.len == 3

	println('✓ FsDir list test passed!')
}

fn test_fs_dir_list_by_filesystem() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs1 := db_fs.new_get_set(name: 'list_by_fs_dir_1')!
	mut fs2 := db_fs.new_get_set(name: 'list_by_fs_dir_2')!

	mut dir1 := db_fs_dir.new(name: 'fs1_dir', fs_id: fs1.id, parent_id: fs1.root_dir_id)!
	dir1 = db_fs_dir.set(dir1)!
	mut root_fs1 := db_fs_dir.get(fs1.root_dir_id)!
	root_fs1.directories << dir1.id
	root_fs1 = db_fs_dir.set(root_fs1)!

	mut dir2 := db_fs_dir.new(name: 'fs2_dir', fs_id: fs2.id, parent_id: fs2.root_dir_id)!
	dir2 = db_fs_dir.set(dir2)!
	mut root_fs2 := db_fs_dir.get(fs2.root_dir_id)!
	root_fs2.directories << dir2.id
	root_fs2 = db_fs_dir.set(root_fs2)!

	dirs_in_fs1 := db_fs_dir.list_by_filesystem(fs1.id)!
	assert dirs_in_fs1.len == 2 // root_fs1 and dir1
	assert dirs_in_fs1[0].name == 'root' || dirs_in_fs1[0].name == 'fs1_dir'
	assert dirs_in_fs1[1].name == 'root' || dirs_in_fs1[1].name == 'fs1_dir'

	dirs_in_fs2 := db_fs_dir.list_by_filesystem(fs2.id)!
	assert dirs_in_fs2.len == 2 // root_fs2 and dir2
	assert dirs_in_fs2[0].name == 'root' || dirs_in_fs2[0].name == 'fs2_dir'
	assert dirs_in_fs2[1].name == 'root' || dirs_in_fs2[1].name == 'fs2_dir'

	println('✓ FsDir list_by_filesystem test passed!')
}

fn test_fs_dir_list_children() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'list_children_fs')!
	mut root_dir := fs.root_dir()!

	mut child_dir1 := db_fs_dir.new(name: 'child1', fs_id: fs.id, parent_id: root_dir.id)!
	child_dir1 = db_fs_dir.set(child_dir1)!
	root_dir.directories << child_dir1.id
	root_dir = db_fs_dir.set(root_dir)!

	mut child_dir2 := db_fs_dir.new(name: 'child2', fs_id: fs.id, parent_id: root_dir.id)!
	child_dir2 = db_fs_dir.set(child_dir2)!
	root_dir.directories << child_dir2.id
	root_dir = db_fs_dir.set(root_dir)!

	children := db_fs_dir.list_children(root_dir.id)!
	assert children.len == 2
	assert children[0].name == 'child1' || children[0].name == 'child2'
	assert children[1].name == 'child1' || children[1].name == 'child2'

	println('✓ FsDir list_children test passed!')
}

fn test_fs_dir_has_children() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'has_children_fs')!
	mut root_dir := fs.root_dir()!

	// Directory with no children
	mut empty_dir := db_fs_dir.new(name: 'empty', fs_id: fs.id, parent_id: root_dir.id)!
	empty_dir = db_fs_dir.set(empty_dir)!
	root_dir.directories << empty_dir.id
	root_dir = db_fs_dir.set(root_dir)!

	assert db_fs_dir.has_children(empty_dir.id)! == false

	// Directory with a child directory
	mut parent_dir := db_fs_dir.new(name: 'parent', fs_id: fs.id, parent_id: root_dir.id)!
	parent_dir = db_fs_dir.set(parent_dir)!
	root_dir.directories << parent_dir.id
	root_dir = db_fs_dir.set(root_dir)!

	mut child_dir := db_fs_dir.new(name: 'child', fs_id: fs.id, parent_id: parent_dir.id)!
	child_dir = db_fs_dir.set(child_dir)!
	parent_dir.directories << child_dir.id
	parent_dir = db_fs_dir.set(parent_dir)!

	assert db_fs_dir.has_children(parent_dir.id)! == true

	// Directory with a child file
	mut file_dir := db_fs_dir.new(name: 'file_dir', fs_id: fs.id, parent_id: root_dir.id)!
	file_dir = db_fs_dir.set(file_dir)!
	root_dir.directories << file_dir.id
	root_dir = db_fs_dir.set(root_dir)!

	mut blob_args := FsBlobArg{ data: 'Child File'.bytes() }
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut file_args := FsFileArg{ name: 'child_file.txt', fs_id: fs.id, blobs: [blob.id], mime_type: .txt }
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!
	db_fs_file.add_to_directory(file.id, file_dir.id)!

	assert db_fs_dir.has_children(file_dir.id)! == true

	println('✓ FsDir has_children test passed!')
}

fn test_fs_dir_rename() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'rename_fs_dir')!
	mut root_dir := fs.root_dir()!

	mut dir := db_fs_dir.new(name: 'old_name', fs_id: fs.id, parent_id: root_dir.id)!
	dir = db_fs_dir.set(dir)!
	root_dir.directories << dir.id
	root_dir = db_fs_dir.set(root_dir)!

	db_fs_dir.rename(dir.id, 'new_name')!
	renamed_dir := db_fs_dir.get(dir.id)!

	assert renamed_dir.name == 'new_name'

	println('✓ FsDir rename test passed!')
}

fn test_fs_dir_move() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'move_fs_dir')!
	mut root_dir := fs.root_dir()!

	mut dir_to_move := db_fs_dir.new(name: 'to_move', fs_id: fs.id, parent_id: root_dir.id)!
	dir_to_move = db_fs_dir.set(dir_to_move)!
	root_dir.directories << dir_to_move.id
	root_dir = db_fs_dir.set(root_dir)!

	mut new_parent := db_fs_dir.new(name: 'new_parent', fs_id: fs.id, parent_id: root_dir.id)!
	new_parent = db_fs_dir.set(new_parent)!
	root_dir.directories << new_parent.id
	root_dir = db_fs_dir.set(root_dir)!

	// Move dir_to_move from root_dir to new_parent
	db_fs_dir.move(dir_to_move.id, new_parent.id)!

	root_dir_after_move := db_fs_dir.get(root_dir.id)!
	new_parent_after_move := db_fs_dir.get(new_parent.id)!
	dir_to_move_after_move := db_fs_dir.get(dir_to_move.id)!

	assert !(dir_to_move.id in root_dir_after_move.directories)
	assert dir_to_move.id in new_parent_after_move.directories
	assert dir_to_move_after_move.parent_id == new_parent.id

	println('✓ FsDir move test passed!')
}

fn test_fs_dir_description() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'fs_dir_description_test')!

	mut args := FsDirArg{
		name: 'description_dir'
		fs_id: fs.id
		parent_id: fs.root_dir_id
	}

	dir := db_fs_dir.new(args)!

	assert dir.description('set') == 'Create or update a directory. Returns the ID of the directory.'
	assert dir.description('get') == 'Retrieve a directory by ID. Returns the directory object.'
	assert dir.description('delete') == 'Delete a directory by ID. Returns true if successful.'
	assert dir.description('exist') == 'Check if a directory exists by ID. Returns true or false.'
	assert dir.description('list') == 'List all directories. Returns an array of directory objects.'
	assert dir.description('create_path') == 'Create a directory path. Returns the ID of the created directory.'
	assert dir.description('unknown') == 'This is generic method for the directory object.'

	println('✓ FsDir description test passed!')
}

fn test_fs_dir_example() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_dir := factory.fs_dir

	mut fs := db_fs.new_get_set(name: 'fs_dir_example_test')!

	mut args := FsDirArg{
		name: 'example_dir'
		fs_id: fs.id
		parent_id: fs.root_dir_id
	}

	dir := db_fs_dir.new(args)!

	set_call, set_result := dir.example('set')
	assert set_call == '{"dir": {"name": "documents", "fs_id": 1, "parent_id": 2}}'
	assert set_result == '1'

	get_call, get_result := dir.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"name": "documents", "fs_id": 1, "parent_id": 2, "directories": [], "files": [], "symlinks": []}'

	delete_call, delete_result := dir.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := dir.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := dir.example('list')
	assert list_call == '{}'
	assert list_result == '[{"name": "documents", "fs_id": 1, "parent_id": 2, "directories": [], "files": [], "symlinks": []}]'

	create_path_call, create_path_result := dir.example('create_path')
	assert create_path_call == '{"fs_id": 1, "path": "/projects/web/frontend"}'
	assert create_path_result == '5'

	unknown_call, unknown_result := dir.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ FsDir example test passed!')
}