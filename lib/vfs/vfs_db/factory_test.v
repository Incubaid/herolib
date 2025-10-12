module vfs_db

import os
import incubaid.herolib.data.ourdb
import rand

fn test_new() {
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_factory_test_${rand.string(3)}')
	os.mkdir_all(test_data_dir)!
	defer {
		os.rmdir_all(test_data_dir) or {}
	}

	// Create separate databases for data and metadata
	mut db_data := ourdb.new(
		path:             os.join_path(test_data_dir, 'data')
		incremental_mode: false
	)!

	mut db_metadata := ourdb.new(
		path:             os.join_path(test_data_dir, 'metadata')
		incremental_mode: false
	)!

	// Test the factory function
	mut vfs := new(mut db_data, mut db_metadata)!

	// Verify the VFS was created correctly
	assert vfs.root_id == 1
	assert vfs.block_size == 1024 * 4
	// Check that database references are valid
	assert !isnil(vfs.db_data)
	assert !isnil(vfs.db_metadata)
	assert vfs.last_inserted_id == 0
	assert vfs.id_table.len == 0
}
