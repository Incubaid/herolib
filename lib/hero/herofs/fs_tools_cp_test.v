module herofs

import os
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.core.redisclient

fn test_cp_file() ! {
	mut fs := new_fs_test() or { panic(err) }
	defer {
		delete_fs_test() or {}
	}

	// 1. Create a source directory and a file
	src_dir_id := fs.factory.fs_dir.create_path(fs.id, '/src')!
	mut blob := fs.factory.fs_blob.new(data: 'file content')!
	blob = fs.factory.fs_blob.set(blob)!
	mut file := fs.factory.fs_file.new(
		name: 'test_file.txt'
		fs_id: fs.id
		blobs: [blob.id]
		mime_type: .text_plain
	)!
	file = fs.factory.fs_file.set(file)!
	fs.factory.fs_file.add_to_directory(file.id, src_dir_id)!

	// 2. Create a destination directory
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!

	// 3. Copy the file
	fs.cp('/src/test_file.txt', '/dest/', FindOptions{}, CopyOptions{})!

	// 4. Verify the file is copied
	dest_dir := fs.factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.files.len == 1
	copied_file := fs.factory.fs_file.get(dest_dir.files[0])!
	assert copied_file.name == 'test_file.txt'
	assert copied_file.blobs[0] == blob.id // Should reference the same blob by default
}

fn test_cp_file_overwrite() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create a source directory and a file
	src_dir_id := fs.factory.fs_dir.create_path(fs.id, '/src')!
	mut blob1 := fs.factory.fs_blob.new(data: 'original content')!
	blob1 = fs.factory.fs_blob.set(blob1)!
	mut file1 := fs.factory.fs_file.new(
		name: 'overwrite_file.txt'
		fs_id: fs.id
		blobs: [blob1.id]
		mime_type: .text_plain
	)!
	file1 = fs.factory.fs_file.set(file1)!
	fs.factory.fs_file.add_to_directory(file1.id, src_dir_id)!

	// 2. Create a destination directory and an existing file with the same name
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!
	mut blob_existing := fs.factory.fs_blob.new(data: 'existing content')!
	blob_existing = fs.factory.fs_blob.set(blob_existing)!
	mut existing_file := fs.factory.fs_file.new(
		name: 'overwrite_file.txt'
		fs_id: fs.id
		blobs: [blob_existing.id]
		mime_type: .text_plain
	)!
	existing_file = fs.factory.fs_file.set(existing_file)!
	fs.factory.fs_file.add_to_directory(existing_file.id, dest_dir_id)!

	// 3. Copy the file with overwrite enabled
	fs.cp('/src/overwrite_file.txt', '/dest/', FindOptions{}, CopyOptions{overwrite: true})!

	// 4. Verify the file is overwritten
	dest_dir := fs.factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.files.len == 1
	copied_file := fs.factory.fs_file.get(dest_dir.files[0])!
	assert copied_file.name == 'overwrite_file.txt'
	assert copied_file.blobs[0] == blob1.id // Should now reference the new blob
}

fn test_cp_file_no_overwrite_error() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create a source directory and a file
	src_dir_id := fs.factory.fs_dir.create_path(fs.id, '/src')!
	mut blob1 := fs.factory.fs_blob.new(data: 'original content')!
	blob1 = fs.factory.fs_blob.set(blob1)!
	mut file1 := fs.factory.fs_file.new(
		name: 'no_overwrite_file.txt'
		fs_id: fs.id
		blobs: [blob1.id]
		mime_type: .text_plain
	)!
	file1 = fs.factory.fs_file.set(file1)!
	fs.factory.fs_file.add_to_directory(file1.id, src_dir_id)!

	// 2. Create a destination directory and an existing file with the same name
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!
	mut blob_existing := fs.factory.fs_blob.new(data: 'existing content')!
	blob_existing = fs.factory.fs_blob.set(blob_existing)!
	mut existing_file := fs.factory.fs_file.new(
		name: 'no_overwrite_file.txt'
		fs_id: fs.id
		blobs: [blob_existing.id]
		mime_type: .text_plain
	)!
	existing_file = fs.factory.fs_file.set(existing_file)!
	fs.factory.fs_file.add_to_directory(existing_file.id, dest_dir_id)!

	// 3. Attempt to copy the file without overwrite (should error)
	res := fs.cp('/src/no_overwrite_file.txt', '/dest/', FindOptions{}, CopyOptions{overwrite: false})
	assert res.err().msg().contains('already exists')
}

fn test_cp_directory_recursive() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create source directory structure
	src_root_id := fs.factory.fs_dir.create_path(fs.id, '/src_root')!
	src_subdir_id := fs.factory.fs_dir.create_path(fs.id, '/src_root/subdir')!

	mut blob1 := fs.factory.fs_blob.new(data: 'file1 content')!
	blob1 = fs.factory.fs_blob.set(blob1)!
	mut file1 := fs.factory.fs_file.new(
		name: 'file1.txt'
		fs_id: fs.id
		blobs: [blob1.id]
		mime_type: .text_plain
	)!
	file1 = fs.factory.fs_file.set(file1)!
	fs.factory.fs_file.add_to_directory(file1.id, src_root_id)!

	mut blob2 := fs.factory.fs_blob.new(data: 'file2 content')!
	blob2 = fs.factory.fs_blob.set(blob2)!
	mut file2 := fs.factory.fs_file.new(
		name: 'file2.txt'
		fs_id: fs.id
		blobs: [blob2.id]
		mime_type: .text_plain
	)!
	file2 = fs.factory.fs_file.set(file2)!
	fs.factory.fs_file.add_to_directory(file2.id, src_subdir_id)!

	// 2. Create destination root
	dest_root_id := fs.factory.fs_dir.create_path(fs.id, '/dest_root')!

	// 3. Copy source_root to dest_root recursively
	fs.cp('/src_root', '/dest_root/', FindOptions{}, CopyOptions{recursive: true})!

	// 4. Verify destination structure
	dest_root := fs.factory.fs_dir.get(dest_root_id)!
	assert dest_root.directories.len == 1 // Should contain 'src_root'
	copied_src_root_dir := fs.factory.fs_dir.get(dest_root.directories[0])!
	assert copied_src_root_dir.name == 'src_root'
	assert copied_src_root_dir.files.len == 1 // Should contain file1.txt

	copied_subdir := fs.factory.fs_dir.get(copied_src_root_dir.directories[0])!
	assert copied_subdir.name == 'subdir'
	assert copied_subdir.files.len == 1 // Should contain file2.txt
}

fn test_cp_directory_merge_overwrite() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create source directory structure
	src_dir_id := fs.factory.fs_dir.create_path(fs.id, '/src')!
	mut blob1 := fs.factory.fs_blob.new(data: 'src file content')!
	blob1 = fs.factory.fs_blob.set(blob1)!
	mut file1 := fs.factory.fs_file.new(
		name: 'file1.txt'
		fs_id: fs.id
		blobs: [blob1.id]
		mime_type: .text_plain
	)!
	file1 = fs.factory.fs_file.set(file1)!
	fs.factory.fs_file.add_to_directory(file1.id, src_dir_id)!

	// 2. Create destination directory with an existing file and a new file
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!
	mut blob_existing := fs.factory.fs_blob.new(data: 'existing file content')!
	blob_existing = fs.factory.fs_blob.set(blob_existing)!
	mut existing_file := fs.factory.fs_file.new(
		name: 'file1.txt' // Same name as source file
		fs_id: fs.id
		blobs: [blob_existing.id]
		mime_type: .text_plain
	)!
	existing_file = fs.factory.fs_file.set(existing_file)!
	fs.factory.fs_file.add_to_directory(existing_file.id, dest_dir_id)!

	mut blob_new_dest := fs.factory.fs_blob.new(data: 'new dest file content')!
	blob_new_dest = fs.factory.fs_blob.set(blob_new_dest)!
	mut new_dest_file := fs.factory.fs_file.new(
		name: 'file_only_in_dest.txt'
		fs_id: fs.id
		blobs: [blob_new_dest.id]
		mime_type: .text_plain
	)!
	new_dest_file = fs.factory.fs_file.set(new_dest_file)!
	fs.factory.fs_file.add_to_directory(new_dest_file.id, dest_dir_id)!

	// 3. Copy source directory to destination with overwrite (should merge and overwrite file1.txt)
	fs.cp('/src', '/dest/', FindOptions{}, CopyOptions{recursive: true, overwrite: true})!

	// 4. Verify destination contents
	dest_dir := fs.factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.files.len == 2 // Should have file1.txt (overwritten) and file_only_in_dest.txt
	
	mut found_file1 := false
	mut found_file_only_in_dest := false

	for file_id in dest_dir.files {
		file := fs.factory.fs_file.get(file_id)!
		if file.name == 'file1.txt' {
			assert file.blobs[0] == blob1.id // Should be overwritten with source content
			found_file1 = true
		} else if file.name == 'file_only_in_dest.txt' {
			assert file.blobs[0] == blob_new_dest.id
			found_file_only_in_dest = true
		}
	}
	assert found_file1
	assert found_file_only_in_dest
}

fn test_cp_file_to_non_existent_path() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create a source file
	mut blob := fs.factory.fs_blob.new(data: 'content')!
	blob = fs.factory.fs_blob.set(blob)!
	mut file := fs.factory.fs_file.new(
		name: 'source.txt'
		fs_id: fs.id
		blobs: [blob.id]
		mime_type: .text_plain
	)!
	file = fs.factory.fs_file.set(file)!
	fs.factory.fs_file.add_to_directory(file.id, fs.root_dir_id)!

	// 2. Copy the file to a non-existent path
	fs.cp('/source.txt', '/new_dir/new_file.txt', FindOptions{}, CopyOptions{})!

	// 3. Verify the directory and file are created
	new_dir := fs.get_dir_by_absolute_path('/new_dir')!
	assert new_dir.files.len == 1
	copied_file := fs.factory.fs_file.get(new_dir.files[0])!
	assert copied_file.name == 'new_file.txt'
	assert copied_file.blobs[0] == blob.id
}

fn test_cp_symlink() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create a target file
	mut blob := fs.factory.fs_blob.new(data: 'target content')!
	blob = fs.factory.fs_blob.set(blob)!
	mut target_file := fs.factory.fs_file.new(
		name: 'target.txt'
		fs_id: fs.id
		blobs: [blob.id]
		mime_type: .text_plain
	)!
	target_file = fs.factory.fs_file.set(target_file)!
	fs.factory.fs_file.add_to_directory(target_file.id, fs.root_dir_id)!

	// 2. Create a source symlink
	mut symlink := fs.factory.fs_symlink.new(
		name: 'link_to_target.txt'
		fs_id: fs.id
		parent_id: fs.root_dir_id
		target_id: target_file.id
		target_type: .file
	)!
	symlink = fs.factory.fs_symlink.set(symlink)!
	mut root_dir := fs.root_dir()!
	root_dir.symlinks << symlink.id
	fs.factory.fs_dir.set(root_dir)!

	// 3. Create a destination directory
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!

	// 4. Copy the symlink
	fs.cp('/link_to_target.txt', '/dest/', FindOptions{}, CopyOptions{})!

	// 5. Verify the symlink is copied
	dest_dir := fs.factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.symlinks.len == 1
	copied_symlink := fs.factory.fs_symlink.get(dest_dir.symlinks[0])!
	assert copied_symlink.name == 'link_to_target.txt'
	assert copied_symlink.target_id == target_file.id
	assert copied_symlink.target_type == .file
}

fn test_cp_symlink_overwrite() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create a target file
	mut blob := fs.factory.fs_blob.new(data: 'target content')!
	blob = fs.factory.fs_blob.set(blob)!
	mut target_file := fs.factory.fs_file.new(
		name: 'target.txt'
		fs_id: fs.id
		blobs: [blob.id]
		mime_type: .text_plain
	)!
	target_file = fs.factory.fs_file.set(target_file)!
	fs.factory.fs_file.add_to_directory(target_file.id, fs.root_dir_id)!

	// 2. Create a source symlink
	mut symlink1 := fs.factory.fs_symlink.new(
		name: 'link_to_target.txt'
		fs_id: fs.id
		parent_id: fs.root_dir_id
		target_id: target_file.id
		target_type: .file
	)!
	symlink1 = fs.factory.fs_symlink.set(symlink1)!
	mut root_dir := fs.root_dir()!
	root_dir.symlinks << symlink1.id
	fs.factory.fs_dir.set(root_dir)!

	// 3. Create a destination directory and an existing symlink with the same name
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!
	mut other_target_file := fs.factory.fs_file.new(
		name: 'other_target.txt'
		fs_id: fs.id
		blobs: [blob.id]
		mime_type: .text_plain
	)!
	other_target_file = fs.factory.fs_file.set(other_target_file)!
	fs.factory.fs_file.add_to_directory(other_target_file.id, fs.root_dir_id)!

	mut existing_symlink := fs.factory.fs_symlink.new(
		name: 'link_to_target.txt'
		fs_id: fs.id
		parent_id: dest_dir_id
		target_id: other_target_file.id
		target_type: .file
	)!
	existing_symlink = fs.factory.fs_symlink.set(existing_symlink)!
	mut dest_dir := fs.factory.fs_dir.get(dest_dir_id)!
	dest_dir.symlinks << existing_symlink.id
	fs.factory.fs_dir.set(dest_dir)!

	// 4. Copy the symlink with overwrite enabled
	fs.cp('/link_to_target.txt', '/dest/', FindOptions{}, CopyOptions{overwrite: true})!

	// 5. Verify the symlink is overwritten
	dest_dir = fs.factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.symlinks.len == 1
	copied_symlink := fs.factory.fs_symlink.get(dest_dir.symlinks[0])!
	assert copied_symlink.name == 'link_to_target.txt'
	assert copied_symlink.target_id == target_file.id // Should now point to the original target
}

fn test_cp_file_copy_blobs_false() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {}
	}

	// 1. Create a source directory and a file
	src_dir_id := fs.factory.fs_dir.create_path(fs.id, '/src')!
	mut blob := fs.factory.fs_blob.new(data: 'file content')!
	blob = fs.factory.fs_blob.set(blob)!
	mut file := fs.factory.fs_file.new(
		name: 'test_file.txt'
		fs_id: fs.id
		blobs: [blob.id]
		mime_type: .text_plain
	)!
	file = fs.factory.fs_file.set(file)!
	fs.factory.fs_file.add_to_directory(file.id, src_dir_id)!

	// 2. Create a destination directory
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!

	// 3. Copy the file with copy_blobs set to false
	fs.cp('/src/test_file.txt', '/dest/', FindOptions{}, CopyOptions{copy_blobs: false})!

	// 4. Verify the file is copied and references the same blob
	dest_dir := fs.factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.files.len == 1
	copied_file := fs.factory.fs_file.get(dest_dir.files[0])!
	assert copied_file.name == 'test_file.txt'
	assert copied_file.blobs[0] == blob.id // Should reference the same blob
}

fn test_cp_file_copy_blobs_true() ! {
	mut fs := delete_fs_test() or {panic("bug")}
	defer {
		delete_fs_test() or {panic("bug")}
	}

	// 1. Create a source directory and a file
	src_dir_id := fs.factory.fs_dir.create_path(fs.id, '/src')!
	mut blob := fs.factory.fs_blob.new(data: 'file content')!
	blob = fs.factory.fs_blob.set(blob)!
	mut file := fs.factory.fs_file.new(
		name: 'test_file.txt'
		fs_id: fs.id
		blobs: [blob.id]
		mime_type: .text_plain
	)!
	file = fs.factory.fs_file.set(file)!
	fs.factory.fs_file.add_to_directory(file.id, src_dir_id)!

	// 2. Create a destination directory
	dest_dir_id := fs.factory.fs_dir.create_path(fs.id, '/dest')!

	// 3. Copy the file with copy_blobs set to true
	fs.cp('/src/test_file.txt', '/dest/', FindOptions{}, CopyOptions{copy_blobs: true})!

	// 4. Verify the file is copied and has a new blob
	dest_dir := fs.factory.fs_dir.get(dest_dir_id)!
	assert dest_dir.files.len == 1
	copied_file := fs.factory.fs_file.get(dest_dir.files[0])!
	assert copied_file.name == 'test_file.txt'
	assert copied_file.blobs[0] != blob.id // Should have a new blob ID
	
	// Verify the content of the new blob is the same
	new_blob := fs.factory.fs_blob.get(copied_file.blobs[0])!
	assert new_blob.data == 'file content'
}
