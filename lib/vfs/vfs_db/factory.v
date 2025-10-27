module vfs_db

import incubaid.herolib.data.encoder
import log

// Factory method for creating a new DatabaseVFS instance
pub fn new(mut data_db Database, mut metadata_db Database) !&DatabaseVFS {
	mut fs := &DatabaseVFS{
		root_id:          1
		block_size:       1024 * 4
		db_data:          data_db
		db_metadata:      metadata_db
		last_inserted_id: 0
		id_table:         map[u32]u32{}
	}

	// Try to load the id_table from the database
	// The id_table is ALWAYS stored at DB ID 1 (the first entry in the metadata database)
	// We ensure this by saving an empty id_table first if the database is new
	fs.load_id_table() or {
		// Save an empty id_table to reserve DB ID 1
		// This ensures all VFS entries start from DB ID 2 onwards
		fs.save_id_table()!
	}

	return fs
}

// Save the databases to disk (persist lookup tables and id_table)
pub fn (mut fs DatabaseVFS) save() ! {
	// Save the id_table mapping
	fs.save_id_table()!

	// Save the database lookup tables
	fs.db_data.save()!
	fs.db_metadata.save()!
}

// Save the id_table to the database
// IMPORTANT: The id_table is ALWAYS stored at DB ID 1 (reserved)
// This is ensured by saving an empty id_table during initialization
fn (mut fs DatabaseVFS) save_id_table() ! {
	mut enc := encoder.new()

	// Filter out the special entry for id_table itself (VFS ID 0)
	// We don't want to save the id_table's own DB ID in the id_table
	mut real_entries := map[u32]u32{}
	for vfs_id, db_id in fs.id_table {
		if vfs_id != 0 {
			real_entries[vfs_id] = db_id
		}
	}

	// Encode the map size (excluding the id_table entry itself)
	enc.add_u32(u32(real_entries.len))
	// Encode last_inserted_id
	enc.add_u32(fs.last_inserted_id)
	// Encode each key-value pair
	for vfs_id, db_id in real_entries {
		enc.add_u32(vfs_id)
		enc.add_u32(db_id)
	}

	// Always save/update at DB ID 1 (reserved for id_table)
	if id_table_db_id := fs.id_table[0] {
		// Update existing id_table at DB ID 1
		fs.db_metadata.set(id: id_table_db_id, data: enc.data)!
	} else {
		// Create new id_table - this MUST get DB ID 1 (first auto-increment)
		id_table_db_id := fs.db_metadata.set(data: enc.data)!
		if id_table_db_id != 1 {
			return error('id_table must be stored at DB ID 1, but got ${id_table_db_id}')
		}
		fs.id_table[0] = id_table_db_id
	}
}

// Load the id_table from the database
fn (mut fs DatabaseVFS) load_id_table() ! {
	// Try to get the id_table - it should be at DB ID 1 (first entry)
	data := fs.db_metadata.get(1) or { return error('No id_table found in database: ${err}') }

	// Remember that the id_table itself is stored at DB ID 1
	fs.id_table[0] = 1

	mut dec := encoder.decoder_new(data)
	// Decode the map size
	map_size := dec.get_u32()!
	// Decode last_inserted_id
	fs.last_inserted_id = dec.get_u32()!
	// Decode each key-value pair
	for i in 0 .. map_size {
		vfs_id := dec.get_u32()!
		db_id := dec.get_u32()!
		fs.id_table[vfs_id] = db_id
	}
}
