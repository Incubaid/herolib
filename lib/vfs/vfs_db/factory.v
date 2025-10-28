module vfs_db

// Factory method for creating a new DatabaseVFS instance
pub fn new(mut data_db Database, mut metadata_db Database) !&DatabaseVFS {
	mut fs := &DatabaseVFS{
		root_id:     1
		block_size:  1024 * 4
		db_data:     data_db
		db_metadata: metadata_db
	}

	return fs
}
