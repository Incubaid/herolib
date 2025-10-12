module herofs

import incubaid.herolib.hero.db
import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.schemas.jsonrpc
import incubaid.herolib.hero.user
import json
import time // Added for time.sleep
// FsFile, FsFileArg, MimeType, FsBlobArg are part of the same module, no need to import explicitly
// import incubaid.herolib.hero.herofs { FsFile, FsFileArg, MimeType, FsBlobArg }

fn test_fs_file_new() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file

	mut fs := db_fs.new_get_set(name: 'test_fs_file_new')!

	mut args := FsFileArg{
		name:        'test_file.txt'
		description: 'Test file for new function'
		fs_id:       fs.id
		mime_type:   .txt
	}

	file := db_fs_file.new(args)!

	assert file.name == 'test_file.txt'
	assert file.description == 'Test file for new function'
	assert file.fs_id == fs.id
	assert file.mime_type == .txt
	assert file.size_bytes == 0
	assert file.updated_at > 0

	println('✓ FsFile new test passed!')
}

fn test_fs_file_crud_operations() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'crud_test_fs_file')!

	// Create a blob for the file
	mut blob_args := FsBlobArg{
		data: 'File Content'.bytes()
	}
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut args := FsFileArg{
		name:        'crud_file.txt'
		description: 'CRUD Test File'
		fs_id:       fs.id
		blobs:       [blob.id]
		mime_type:   .txt
	}

	mut file := db_fs_file.new(args)!
	file = db_fs_file.set(file)!
	original_id := file.id

	retrieved_file := db_fs_file.get(original_id)!
	assert retrieved_file.name == 'crud_file.txt'
	assert retrieved_file.id == original_id
	assert retrieved_file.blobs.len == 1
	assert retrieved_file.blobs[0] == blob.id
	assert retrieved_file.size_bytes == u64('File Content'.len)

	exists := db_fs_file.exist(original_id)!
	assert exists == true

	// Update file
	mut updated_blob_args := FsBlobArg{
		data: 'Updated File Content'.bytes()
	}
	mut updated_blob := db_fs_blob.new(updated_blob_args)!
	updated_blob = db_fs_blob.set(updated_blob)!

	mut updated_file_obj := retrieved_file
	updated_file_obj.description = 'Updated CRUD Test File'
	updated_file_obj.blobs = [updated_blob.id]
	updated_file_obj.size_bytes = u64('Updated File Content'.len)
	updated_file_obj = db_fs_file.set(updated_file_obj)!

	final_file := db_fs_file.get(original_id)!
	assert final_file.description == 'Updated CRUD Test File'
	assert final_file.blobs.len == 1
	assert final_file.blobs[0] == updated_blob.id
	assert final_file.size_bytes == u64('Updated File Content'.len)

	db_fs_file.delete(original_id)!
	exists_after_delete := db_fs_file.exist(original_id)!
	assert exists_after_delete == false

	println('✓ FsFile CRUD operations test passed!')
}

fn test_fs_file_add_to_directory() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_dir := factory.fs_dir
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'add_to_dir_fs')!
	root_dir := fs.root_dir()!

	mut blob_args := FsBlobArg{
		data: 'File for directory'.bytes()
	}
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut file_args := FsFileArg{
		name:      'dir_file.txt'
		fs_id:     fs.id
		blobs:     [blob.id]
		mime_type: .txt
	}
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!

	db_fs_file.add_to_directory(file.id, root_dir.id)!

	updated_root_dir := db_fs_dir.get(root_dir.id)!
	assert file.id in updated_root_dir.files

	println('✓ FsFile add_to_directory test passed!')
}

fn test_fs_file_list() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'fs_file_list_test')!

	mut blob_args1 := FsBlobArg{
		data: 'File 1'.bytes()
	}
	mut blob1 := db_fs_blob.new(blob_args1)!
	blob1 = db_fs_blob.set(blob1)!

	mut blob_args2 := FsBlobArg{
		data: 'File 2'.bytes()
	}
	mut blob2 := db_fs_blob.new(blob_args2)!
	blob2 = db_fs_blob.set(blob2)!

	mut file_args1 := FsFileArg{
		name:      'list_file1.txt'
		fs_id:     fs.id
		blobs:     [blob1.id]
		mime_type: .txt
	}
	mut file1 := db_fs_file.new(file_args1)!
	file1 = db_fs_file.set(file1)!

	mut file_args2 := FsFileArg{
		name:      'list_file2.txt'
		fs_id:     fs.id
		blobs:     [blob2.id]
		mime_type: .txt
	}
	mut file2 := db_fs_file.new(file_args2)!
	file2 = db_fs_file.set(file2)!

	list_of_files := db_fs_file.list()!
	assert list_of_files.len == 2
	assert list_of_files[0].name == 'list_file1.txt' || list_of_files[0].name == 'list_file2.txt'
	assert list_of_files[1].name == 'list_file1.txt' || list_of_files[1].name == 'list_file2.txt'

	println('✓ FsFile list test passed!')
}

fn test_fs_file_get_by_path() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_dir := factory.fs_dir
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'get_by_path_fs')!
	root_dir := fs.root_dir()!

	mut blob_args := FsBlobArg{
		data: 'Path File'.bytes()
	}
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut file_args := FsFileArg{
		name:      'path_file.txt'
		fs_id:     fs.id
		blobs:     [blob.id]
		mime_type: .txt
	}
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!

	db_fs_file.add_to_directory(file.id, root_dir.id)!

	retrieved_file := db_fs_file.get_by_path(root_dir.id, 'path_file.txt')!
	assert retrieved_file.id == file.id
	assert retrieved_file.name == 'path_file.txt'

	println('✓ FsFile get_by_path test passed!')
}

fn test_fs_file_list_by_directory() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_dir := factory.fs_dir
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'list_by_dir_fs')!
	root_dir := fs.root_dir()!

	mut blob_args1 := FsBlobArg{
		data: 'Dir File 1'.bytes()
	}
	mut blob1 := db_fs_blob.new(blob_args1)!
	blob1 = db_fs_blob.set(blob1)!

	mut blob_args2 := FsBlobArg{
		data: 'Dir File 2'.bytes()
	}
	mut blob2 := db_fs_blob.new(blob_args2)!
	blob2 = db_fs_blob.set(blob2)!

	mut file_args1 := FsFileArg{
		name:      'dir_file1.txt'
		fs_id:     fs.id
		blobs:     [blob1.id]
		mime_type: .txt
	}
	mut file1 := db_fs_file.new(file_args1)!
	file1 = db_fs_file.set(file1)!

	mut file_args2 := FsFileArg{
		name:      'dir_file2.txt'
		fs_id:     fs.id
		blobs:     [blob2.id]
		mime_type: .txt
	}
	mut file2 := db_fs_file.new(file_args2)!
	file2 = db_fs_file.set(file2)!

	db_fs_file.add_to_directory(file1.id, root_dir.id)!
	db_fs_file.add_to_directory(file2.id, root_dir.id)!

	files_in_dir := db_fs_file.list_by_directory(root_dir.id)!
	assert files_in_dir.len == 2
	assert files_in_dir[0].name == 'dir_file1.txt' || files_in_dir[0].name == 'dir_file2.txt'
	assert files_in_dir[1].name == 'dir_file1.txt' || files_in_dir[1].name == 'dir_file2.txt'

	println('✓ FsFile list_by_directory test passed!')
}

fn test_fs_file_list_by_filesystem() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs1 := db_fs.new_get_set(name: 'list_by_fs_1')!
	mut fs2 := db_fs.new_get_set(name: 'list_by_fs_2')!

	mut blob_args1 := FsBlobArg{
		data: 'FS1 File'.bytes()
	}
	mut blob1 := db_fs_blob.new(blob_args1)!
	blob1 = db_fs_blob.set(blob1)!

	mut blob_args2 := FsBlobArg{
		data: 'FS2 File'.bytes()
	}
	mut blob2 := db_fs_blob.new(blob_args2)!
	blob2 = db_fs_blob.set(blob2)!

	mut file_args1 := FsFileArg{
		name:      'fs1_file.txt'
		fs_id:     fs1.id
		blobs:     [blob1.id]
		mime_type: .txt
	}
	mut file1 := db_fs_file.new(file_args1)!
	file1 = db_fs_file.set(file1)!

	mut file_args2 := FsFileArg{
		name:      'fs2_file.txt'
		fs_id:     fs2.id
		blobs:     [blob2.id]
		mime_type: .txt
	}
	mut file2 := db_fs_file.new(file_args2)!
	file2 = db_fs_file.set(file2)!

	files_in_fs1 := db_fs_file.list_by_filesystem(fs1.id)!
	assert files_in_fs1.len == 1
	assert files_in_fs1[0].name == 'fs1_file.txt'

	files_in_fs2 := db_fs_file.list_by_filesystem(fs2.id)!
	assert files_in_fs2.len == 1
	assert files_in_fs2[0].name == 'fs2_file.txt'

	println('✓ FsFile list_by_filesystem test passed!')
}

fn test_fs_file_list_by_mime_type() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'list_by_mime_fs')!

	mut blob_args1 := FsBlobArg{
		data: 'Text File'.bytes()
	}
	mut blob1 := db_fs_blob.new(blob_args1)!
	blob1 = db_fs_blob.set(blob1)!

	mut blob_args2 := FsBlobArg{
		data: 'Image File'.bytes()
	}
	mut blob2 := db_fs_blob.new(blob_args2)!
	blob2 = db_fs_blob.set(blob2)!

	mut file_args1 := FsFileArg{
		name:      'text.txt'
		fs_id:     fs.id
		blobs:     [blob1.id]
		mime_type: .txt
	}
	mut file1 := db_fs_file.new(file_args1)!
	file1 = db_fs_file.set(file1)!

	mut file_args2 := FsFileArg{
		name:      'image.png'
		fs_id:     fs.id
		blobs:     [blob2.id]
		mime_type: .png
	}
	mut file2 := db_fs_file.new(file_args2)!
	file2 = db_fs_file.set(file2)!

	text_files := db_fs_file.list_by_mime_type(.txt)!
	assert text_files.len == 1
	assert text_files[0].name == 'text.txt'

	image_files := db_fs_file.list_by_mime_type(.png)!
	assert image_files.len == 1
	assert image_files[0].name == 'image.png'

	println('✓ FsFile list_by_mime_type test passed!')
}

fn test_fs_file_update_accessed() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'update_accessed_fs')!

	mut blob_args := FsBlobArg{
		data: 'Accessed File'.bytes()
	}
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut file_args := FsFileArg{
		name:      'accessed.txt'
		fs_id:     fs.id
		blobs:     [blob.id]
		mime_type: .txt
	}
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!

	// Manually set updated_at to a past value to ensure a change
	mut file_to_update := file
	file_to_update.updated_at = 1
	file_to_update = db_fs_file.set(file_to_update)!

	db_fs_file.update_accessed(file_to_update.id)!
	updated_file := db_fs_file.get(file_to_update.id)!

	assert updated_file.updated_at > 1

	println('✓ FsFile update_accessed test passed!')
}

fn test_fs_file_update_metadata() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'update_metadata_fs')!

	mut blob_args := FsBlobArg{
		data: 'Metadata File'.bytes()
	}
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut file_args := FsFileArg{
		name:      'metadata.txt'
		fs_id:     fs.id
		blobs:     [blob.id]
		mime_type: .txt
	}
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!

	db_fs_file.update_metadata(file.id, 'author', 'John Doe')!
	updated_file := db_fs_file.get(file.id)!

	assert updated_file.metadata['author'] == 'John Doe'

	println('✓ FsFile update_metadata test passed!')
}

fn test_fs_file_rename() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'rename_fs')!

	mut blob_args := FsBlobArg{
		data: 'Rename File'.bytes()
	}
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut file_args := FsFileArg{
		name:      'old_name.txt'
		fs_id:     fs.id
		blobs:     [blob.id]
		mime_type: .txt
	}
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!

	db_fs_file.rename(file.id, 'new_name.txt')!
	renamed_file := db_fs_file.get(file.id)!

	assert renamed_file.name == 'new_name.txt'

	println('✓ FsFile rename test passed!')
}

fn test_fs_file_move() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_dir := factory.fs_dir
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'move_fs')!
	root_dir := fs.root_dir()!

	mut dir1 := db_fs_dir.new(name: 'dir1', fs_id: fs.id, parent_id: root_dir.id)!
	dir1 = db_fs_dir.set(dir1)!
	mut updated_root_dir_for_dir1 := db_fs_dir.get(root_dir.id)!
	updated_root_dir_for_dir1.directories << dir1.id
	updated_root_dir_for_dir1 = db_fs_dir.set(updated_root_dir_for_dir1)!

	mut dir2 := db_fs_dir.new(name: 'dir2', fs_id: fs.id, parent_id: root_dir.id)!
	dir2 = db_fs_dir.set(dir2)!
	mut updated_root_dir_for_dir2 := db_fs_dir.get(root_dir.id)!
	updated_root_dir_for_dir2.directories << dir2.id
	updated_root_dir_for_dir2 = db_fs_dir.set(updated_root_dir_for_dir2)!

	mut blob_args := FsBlobArg{
		data: 'Move File'.bytes()
	}
	mut blob := db_fs_blob.new(blob_args)!
	blob = db_fs_blob.set(blob)!

	mut file_args := FsFileArg{
		name:      'move_file.txt'
		fs_id:     fs.id
		blobs:     [blob.id]
		mime_type: .txt
	}
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!

	db_fs_file.add_to_directory(file.id, dir1.id)!

	// Move file from dir1 to dir2
	db_fs_file.move(file.id, [dir2.id])!

	dir1_after_move := db_fs_dir.get(dir1.id)!
	dir2_after_move := db_fs_dir.get(dir2.id)!

	assert file.id !in dir1_after_move.files
	assert file.id in dir2_after_move.files

	println('✓ FsFile move test passed!')
}

fn test_fs_file_append_blob() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file
	mut db_fs_blob := factory.fs_blob

	mut fs := db_fs.new_get_set(name: 'append_blob_fs')!

	mut blob_args1 := FsBlobArg{
		data: 'Part 1'.bytes()
	}
	mut blob1 := db_fs_blob.new(blob_args1)!
	blob1 = db_fs_blob.set(blob1)!

	mut file_args := FsFileArg{
		name:      'append.txt'
		fs_id:     fs.id
		blobs:     [blob1.id]
		mime_type: .txt
	}
	mut file := db_fs_file.new(file_args)!
	file = db_fs_file.set(file)!

	original_size := file.size_bytes
	assert file.blobs.len == 1

	mut blob_args2 := FsBlobArg{
		data: 'Part 2'.bytes()
	}
	mut blob2 := db_fs_blob.new(blob_args2)!
	blob2 = db_fs_blob.set(blob2)!

	db_fs_file.append_blob(file.id, blob2.id)!
	updated_file := db_fs_file.get(file.id)!

	assert updated_file.blobs.len == 2
	assert updated_file.blobs[1] == blob2.id
	assert updated_file.size_bytes == original_size + u64('Part 2'.len)

	println('✓ FsFile append_blob test passed!')
}

fn test_fs_file_description() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file

	mut fs := db_fs.new_get_set(name: 'fs_file_description_test')!

	mut args := FsFileArg{
		name:      'description_file.txt'
		fs_id:     fs.id
		mime_type: .txt
	}

	file := db_fs_file.new(args)!

	assert file.description('set') == 'Create or update a file. Returns the ID of the file.'
	assert file.description('get') == 'Retrieve a file by ID. Returns the file object.'
	assert file.description('delete') == 'Delete a file by ID. Returns true if successful.'
	assert file.description('exist') == 'Check if a file exists by ID. Returns true or false.'
	assert file.description('list') == 'List all files. Returns an array of file objects.'
	assert file.description('rename') == 'Rename a file. Returns true if successful.'
	assert file.description('unknown') == 'This is generic method for the file object.'

	println('✓ FsFile description test passed!')
}

fn test_fs_file_example() ! {
	mut factory := new_test()!
	mut db_fs := factory.fs
	mut db_fs_file := factory.fs_file

	mut fs := db_fs.new_get_set(name: 'fs_file_example_test')!

	mut args := FsFileArg{
		name:      'example_file.txt'
		fs_id:     fs.id
		mime_type: .txt
	}

	file := db_fs_file.new(args)!

	set_call, set_result := file.example('set')
	assert set_call == '{"file": {"name": "document.txt", "fs_id": 1, "blobs": [1], "mime_type": "txt"}}'
	assert set_result == '1'

	get_call, get_result := file.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"name": "document.txt", "fs_id": 1, "blobs": [1], "size_bytes": 1024, "mime_type": "txt"}'

	delete_call, delete_result := file.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := file.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := file.example('list')
	assert list_call == '{}'
	assert list_result == '[{"name": "document.txt", "fs_id": 1, "blobs": [1], "size_bytes": 1024, "mime_type": "txt"}]'

	rename_call, rename_result := file.example('rename')
	assert rename_call == '{"id": 1, "new_name": "renamed_document.txt"}'
	assert rename_result == 'true'

	unknown_call, unknown_result := file.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ FsFile example test passed!')
}
