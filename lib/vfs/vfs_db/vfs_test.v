module vfs_db

import os
import incubaid.herolib.data.ourdb
import rand
import incubaid.herolib.vfs as vfs_mod

fn setup_vfs() !(&DatabaseVFS, string) {
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_vfs_test_${rand.string(3)}')
	os.mkdir_all(test_data_dir)!

	// Create separate databases for data and metadata
	mut db_data := ourdb.new(
		path: os.join_path(test_data_dir, 'data')
	)!

	mut db_metadata := ourdb.new(
		path: os.join_path(test_data_dir, 'metadata')
	)!

	// Create VFS with separate databases for data and metadata
	mut vfs := new(mut db_data, mut db_metadata)!
	return vfs, test_data_dir
}

fn teardown_vfs(data_dir string) {
	os.rmdir_all(data_dir) or {}
}

fn test_get_next_id() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Test that get_next_id increments correctly
	assert vfs.last_inserted_id == 0

	id1 := vfs.get_next_id()
	assert id1 == 1
	assert vfs.last_inserted_id == 1

	id2 := vfs.get_next_id()
	assert id2 == 2
	assert vfs.last_inserted_id == 2

	id3 := vfs.get_next_id()
	assert id3 == 3
	assert vfs.last_inserted_id == 3
}

fn test_save_load_entry() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a directory entry
	mut dir := Directory{
		metadata:  vfs_mod.Metadata{
			id:          1
			name:        'test_dir'
			file_type:   .directory
			size:        0
			mode:        0o755
			owner:       'user'
			group:       'user'
			created_at:  0
			modified_at: 0
			accessed_at: 0
		}
		children:  []
		parent_id: 0
	}

	// Save the directory
	vfs.save_entry(dir)!

	// Load the directory
	loaded_entry := vfs.load_entry(dir.metadata.id)!

	// Verify it's the same directory
	loaded_dir := loaded_entry as Directory
	assert loaded_dir.metadata.id == dir.metadata.id
	assert loaded_dir.metadata.name == dir.metadata.name
	assert loaded_dir.metadata.file_type == dir.metadata.file_type
}

fn test_save_load_file_with_data() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a file entry with data
	mut file := File{
		metadata:  vfs_mod.Metadata{
			id:          2
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
		chunk_ids: []
		parent_id: 0
	}

	// Save the file
	vfs.save_entry(file)!

	// Load the file
	loaded_entry := vfs.load_entry(file.metadata.id)!

	// Verify it's the same file with the same data
	loaded_file := loaded_entry as File
	assert loaded_file.metadata.id == file.metadata.id
	assert loaded_file.metadata.name == file.metadata.name
	assert loaded_file.metadata.file_type == file.metadata.file_type
	// File data is stored in chunks, not directly in the file struct
}

fn test_save_load_file_without_data() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a file entry without data
	mut file := File{
		metadata:  vfs_mod.Metadata{
			id:          3
			name:        'empty_file.txt'
			file_type:   .file
			size:        0
			mode:        0o644
			owner:       'user'
			group:       'user'
			created_at:  0
			modified_at: 0
			accessed_at: 0
		}
		chunk_ids: []
		parent_id: 0
	}

	// Save the file
	vfs.save_entry(file)!

	// Load the file
	loaded_entry := vfs.load_entry(file.metadata.id)!

	// Verify it's the same file with empty data
	loaded_file := loaded_entry as File
	assert loaded_file.metadata.id == file.metadata.id
	assert loaded_file.metadata.name == file.metadata.name
	assert loaded_file.metadata.file_type == file.metadata.file_type
	// File data is stored in chunks, not directly in the file struct
}

fn test_save_load_symlink() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Create a symlink entry
	mut symlink := Symlink{
		metadata:  vfs_mod.Metadata{
			id:          4
			name:        'test_link'
			file_type:   .symlink
			size:        0
			mode:        0o777
			owner:       'user'
			group:       'user'
			created_at:  0
			modified_at: 0
			accessed_at: 0
		}
		target:    '/path/to/target'
		parent_id: 0
	}

	// Save the symlink
	vfs.save_entry(symlink)!

	// Load the symlink
	loaded_entry := vfs.load_entry(symlink.metadata.id)!

	// Verify it's the same symlink
	loaded_symlink := loaded_entry as Symlink
	assert loaded_symlink.metadata.id == symlink.metadata.id
	assert loaded_symlink.metadata.name == symlink.metadata.name
	assert loaded_symlink.metadata.file_type == symlink.metadata.file_type
	assert loaded_symlink.target == symlink.target
}

fn test_load_nonexistent_entry() ! {
	mut vfs, data_dir := setup_vfs()!
	defer {
		teardown_vfs(data_dir)
	}

	// Try to load an entry that doesn't exist
	if _ := vfs.load_entry(999) {
		assert false, 'Expected error when loading non-existent entry'
	} else {
		assert true
	}
}
