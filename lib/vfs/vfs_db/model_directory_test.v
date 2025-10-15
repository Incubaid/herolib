module vfs_db

import incubaid.herolib.vfs as vfs_mod

fn test_directory_get_metadata() {
	// Create a directory with metadata
	metadata := vfs_mod.Metadata{
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

	dir := Directory{
		metadata:  metadata
		children:  []
		parent_id: 0
	}

	// Test get_metadata
	retrieved_metadata := dir.get_metadata()
	assert retrieved_metadata.id == 1
	assert retrieved_metadata.name == 'test_dir'
	assert retrieved_metadata.file_type == .directory
	assert retrieved_metadata.size == 0
	assert retrieved_metadata.mode == 0o755
	assert retrieved_metadata.owner == 'user'
	assert retrieved_metadata.group == 'user'
}

fn test_directory_is_dir() {
	// Create a directory with metadata
	metadata := vfs_mod.Metadata{
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

	dir := Directory{
		metadata:  metadata
		children:  []
		parent_id: 0
	}

	// Test is_dir
	assert dir.is_dir() == true
	assert dir.is_file() == false
	assert dir.is_symlink() == false
}

fn test_directory_with_children() {
	// Create a directory with children
	metadata := vfs_mod.Metadata{
		id:          1
		name:        'parent_dir'
		file_type:   .directory
		size:        0
		mode:        0o755
		owner:       'user'
		group:       'user'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	dir := Directory{
		metadata:  metadata
		children:  [u32(2), 3, 4]
		parent_id: 0
	}

	// Test children
	assert dir.children.len == 3
	assert dir.children[0] == 2
	assert dir.children[1] == 3
	assert dir.children[2] == 4
}

fn test_directory_with_parent() {
	// Create a directory with a parent
	metadata := vfs_mod.Metadata{
		id:          2
		name:        'child_dir'
		file_type:   .directory
		size:        0
		mode:        0o755
		owner:       'user'
		group:       'user'
		created_at:  0
		modified_at: 0
		accessed_at: 0
	}

	dir := Directory{
		metadata:  metadata
		children:  []
		parent_id: 1
	}

	// Test parent_id
	assert dir.parent_id == 1
}
