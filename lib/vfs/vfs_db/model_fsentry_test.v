module vfs_db

import incubaid.herolib.vfs as vfs_mod

fn test_fsentry_directory() {
	// Create a directory entry
	dir := Directory{
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

	// Convert to FSEntry
	entry := FSEntry(dir)

	// Test methods
	assert entry.get_metadata().id == 1
	assert entry.get_metadata().name == 'test_dir'
	assert entry.get_metadata().file_type == .directory
	assert entry.is_dir() == true
	assert entry.is_file() == false
	assert entry.is_symlink() == false
}

fn test_fsentry_file() {
	// Create a file entry
	file := File{
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
		parent_id: 0
		chunk_ids: []
	}

	// Convert to FSEntry
	entry := FSEntry(file)

	// Test methods
	assert entry.get_metadata().id == 2
	assert entry.get_metadata().name == 'test_file.txt'
	assert entry.get_metadata().file_type == .file
	assert entry.is_dir() == false
	assert entry.is_file() == true
	assert entry.is_symlink() == false
}

fn test_fsentry_symlink() {
	// Create a symlink entry
	symlink := Symlink{
		metadata:  vfs_mod.Metadata{
			id:          3
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

	// Convert to FSEntry
	entry := FSEntry(symlink)

	// Test methods
	assert entry.get_metadata().id == 3
	assert entry.get_metadata().name == 'test_link'
	assert entry.get_metadata().file_type == .symlink
	assert entry.is_dir() == false
	assert entry.is_file() == false
	assert entry.is_symlink() == true
}

fn test_fsentry_match() {
	// Create entries of different types
	dir := Directory{
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

	file := File{
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

	symlink := Symlink{
		metadata:  vfs_mod.Metadata{
			id:          3
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

	// Test match with directory
	dir_entry := FSEntry(dir)
	match dir_entry {
		Directory {
			assert dir_entry.metadata.id == 1
			assert dir_entry.metadata.name == 'test_dir'
		}
		File, Symlink {
			assert false, 'Expected Directory type'
		}
	}

	// Test match with file
	file_entry := FSEntry(file)
	match file_entry {
		File {
			assert file_entry.metadata.id == 2
			assert file_entry.metadata.name == 'test_file.txt'
		}
		Directory, Symlink {
			assert false, 'Expected File type'
		}
	}

	// Test match with symlink
	symlink_entry := FSEntry(symlink)
	match symlink_entry {
		Symlink {
			assert symlink_entry.metadata.id == 3
			assert symlink_entry.metadata.name == 'test_link'
			assert symlink_entry.target == '/path/to/target'
		}
		Directory, File {
			assert false, 'Expected Symlink type'
		}
	}
}
