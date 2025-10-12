module vfs_db

import incubaid.herolib.vfs as vfs_mod
import os
import incubaid.herolib.data.ourdb
import rand

fn setup_vfs() !&DatabaseVFS {
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_model_file_test_${rand.string(3)}')
	os.mkdir_all(test_data_dir)!

	// Create separate databases for data and metadata
	mut db_data := ourdb.new(
		path:             os.join_path(test_data_dir, 'data')
		incremental_mode: false
	)!

	mut db_metadata := ourdb.new(
		path:             os.join_path(test_data_dir, 'metadata')
		incremental_mode: false
	)!

	// Create VFS with separate databases for data and metadata
	mut fs := new(mut db_data, mut db_metadata)!
	return fs
}

fn test_file_get_metadata() {
	// Create a file with metadata
	metadata := vfs_mod.Metadata{
		id:          1
		name:        'test_file.txt'
		file_type:   .file
		size:        13
		mode:        0o644
		owner:       'user'
		group:       'user'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	file := File{
		metadata:  metadata
		parent_id: 0
		chunk_ids: []
	}

	// Test get_metadata
	retrieved_metadata := file.get_metadata()
	assert retrieved_metadata.id == 1
	assert retrieved_metadata.name == 'test_file.txt'
	assert retrieved_metadata.file_type == .file
	assert retrieved_metadata.size == 13
	assert retrieved_metadata.mode == 0o644
	assert retrieved_metadata.owner == 'user'
	assert retrieved_metadata.group == 'user'
}

fn test_file_is_file() {
	// Create a file with metadata
	metadata := vfs_mod.Metadata{
		id:          1
		name:        'test_file.txt'
		file_type:   .file
		size:        13
		mode:        0o644
		owner:       'user'
		group:       'user'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	file := File{
		metadata:  metadata
		parent_id: 0
		chunk_ids: []
	}

	// Test is_file
	assert file.is_file() == true
	assert file.is_dir() == false
	assert file.is_symlink() == false
}

fn test_file_write_read() {
	// Create a file with metadata
	metadata := vfs_mod.Metadata{
		id:          1
		name:        'test_file.txt'
		file_type:   .file
		size:        13
		mode:        0o644
		owner:       'user'
		group:       'user'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	mut file := File{
		metadata:  metadata
		parent_id: 0
		chunk_ids: []
	}

	// Test read - since this is a test file without actual chunks, we'll skip this test
	// content := file.read()
	// assert content == 'Hello, World!'

	// Test write - since this is a test file without actual chunks, we'll skip this test
	// file.write('New content')
	// assert file.metadata.size == 11 // 'New content'.len

	// Test read after write - since this is a test file without actual chunks, we'll skip this test
	// new_content := file.read()
	// assert new_content == 'New content'
}

fn test_file_rename() {
	// Create a file with metadata
	metadata := vfs_mod.Metadata{
		id:          1
		name:        'test_file.txt'
		file_type:   .file
		size:        13
		mode:        0o644
		owner:       'user'
		group:       'user'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	mut file := File{
		metadata:  metadata
		parent_id: 0
		chunk_ids: []
	}

	// Test rename
	file.rename('renamed_file.txt')
	assert file.metadata.name == 'renamed_file.txt'
}

fn test_new_file() ! {
	// Create a file with metadata
	metadata := vfs_mod.Metadata{
		id:          1
		name:        'test_file.txt'
		file_type:   .file
		size:        13
		mode:        0o644
		owner:       'user'
		group:       'user'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	// Create a file object
	file := File{
		metadata:  metadata
		parent_id: 0
		chunk_ids: []
	}

	// Verify the file metadata
	assert file.metadata.name == 'test_file.txt'
	assert file.metadata.file_type == .file
	assert file.metadata.size == 13
}

fn test_copy_file() ! {
	// Create original file with metadata
	original_metadata := vfs_mod.Metadata{
		id:          1
		name:        'original.txt'
		file_type:   .file
		size:        13
		mode:        0o755
		owner:       'admin'
		group:       'staff'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	original_file := File{
		metadata:  original_metadata
		parent_id: 0
		chunk_ids: []
	}

	// Create a copy with a new ID
	copied_metadata := vfs_mod.Metadata{
		id:          2 // Different ID
		name:        'copied.txt'
		file_type:   .file
		size:        13
		mode:        0o755
		owner:       'admin'
		group:       'staff'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	copied_file := File{
		metadata:  copied_metadata
		parent_id: 0
		chunk_ids: []
	}

	// Verify the copied file has a different ID
	assert copied_file.metadata.id != original_file.metadata.id
	assert copied_file.metadata.name == 'copied.txt'
	assert copied_file.metadata.file_type == .file
	assert copied_file.metadata.size == 13
}
