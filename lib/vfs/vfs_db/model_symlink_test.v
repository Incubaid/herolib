module vfs_db

import incubaid.herolib.vfs as vfs_mod

fn test_symlink_get_metadata() {
	// Create a symlink with metadata
	metadata := vfs_mod.Metadata{
		id:          1
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

	symlink := Symlink{
		metadata:  metadata
		target:    '/path/to/target'
		parent_id: 0
	}

	// Test get_metadata
	retrieved_metadata := symlink.get_metadata()
	assert retrieved_metadata.id == 1
	assert retrieved_metadata.name == 'test_link'
	assert retrieved_metadata.file_type == .symlink
	assert retrieved_metadata.size == 0
	assert retrieved_metadata.mode == 0o777
	assert retrieved_metadata.owner == 'user'
	assert retrieved_metadata.group == 'user'
}

fn test_symlink_is_symlink() {
	// Create a symlink with metadata
	metadata := vfs_mod.Metadata{
		id:          1
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

	symlink := Symlink{
		metadata:  metadata
		target:    '/path/to/target'
		parent_id: 0
	}

	// Test is_symlink
	assert symlink.is_symlink() == true
	assert symlink.is_dir() == false
	assert symlink.is_file() == false
}

fn test_symlink_update_target() ! {
	// Create a symlink with metadata
	metadata := vfs_mod.Metadata{
		id:          1
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

	mut symlink := Symlink{
		metadata:  metadata
		target:    '/path/to/target'
		parent_id: 0
	}

	// Test update_target
	symlink.update_target('/new/target/path')!
	assert symlink.target == '/new/target/path'
}

fn test_symlink_get_target() ! {
	// Create a symlink with metadata
	metadata := vfs_mod.Metadata{
		id:          1
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

	mut symlink := Symlink{
		metadata:  metadata
		target:    '/path/to/target'
		parent_id: 0
	}

	// Test get_target
	target := symlink.get_target()!
	assert target == '/path/to/target'
}

fn test_symlink_with_parent() {
	// Create a symlink with a parent
	metadata := vfs_mod.Metadata{
		id:          2
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

	symlink := Symlink{
		metadata:  metadata
		target:    '/path/to/target'
		parent_id: 1
	}

	// Test parent_id
	assert symlink.parent_id == 1
}
