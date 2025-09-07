module heroprompt

import os

fn test_multiple_dirs_same_name() ! {
	// Create two temporary folders with the same basename "proj"
	temp_base := os.temp_dir()
	dir1 := os.join_path(temp_base, 'test_heroprompt_1', 'proj')
	dir2 := os.join_path(temp_base, 'test_heroprompt_2', 'proj')

	// Ensure directories exist
	os.mkdir_all(dir1)!
	os.mkdir_all(dir2)!

	// Create test files in each directory
	os.write_file(os.join_path(dir1, 'file1.txt'), 'content1')!
	os.write_file(os.join_path(dir2, 'file2.txt'), 'content2')!

	defer {
		// Cleanup
		os.rmdir_all(os.join_path(temp_base, 'test_heroprompt_1')) or {}
		os.rmdir_all(os.join_path(temp_base, 'test_heroprompt_2')) or {}
	}

	mut ws := Workspace{
		name:     'testws'
		children: []HeropromptChild{}
	}

	// First dir – should succeed
	child1 := ws.add_dir(path: dir1)!
	assert ws.children.len == 1
	assert child1.name == 'proj'
	assert child1.path.path == os.real_path(dir1)

	// Second dir – same basename, different absolute path – should also succeed
	child2 := ws.add_dir(path: dir2)!
	assert ws.children.len == 2
	assert child2.name == 'proj'
	assert child2.path.path == os.real_path(dir2)

	// Verify both children have different absolute paths
	assert child1.path.path != child2.path.path

	// Try to add the same directory again – should fail
	ws.add_dir(path: dir1) or {
		assert err.msg().contains('already added to the workspace')
		return
	}
	assert false, 'Expected error when adding same directory twice'
}

fn test_build_file_map_multiple_roots() ! {
	// Create temporary directories
	temp_base := os.temp_dir()
	dir1 := os.join_path(temp_base, 'test_map_1', 'src')
	dir2 := os.join_path(temp_base, 'test_map_2', 'src')

	os.mkdir_all(dir1)!
	os.mkdir_all(dir2)!

	// Create test files
	os.write_file(os.join_path(dir1, 'main.v'), 'fn main() { println("hello from dir1") }')!
	os.write_file(os.join_path(dir2, 'app.v'), 'fn app() { println("hello from dir2") }')!

	defer {
		os.rmdir_all(os.join_path(temp_base, 'test_map_1')) or {}
		os.rmdir_all(os.join_path(temp_base, 'test_map_2')) or {}
	}

	mut ws := Workspace{
		name:     'testws_map'
		children: []HeropromptChild{}
	}

	// Add both directories
	ws.add_dir(path: dir1)!
	ws.add_dir(path: dir2)!

	// Build file map
	file_map := ws.build_file_map()

	// Should contain both directory paths in the parent_path
	assert file_map.contains(os.real_path(dir1))
	assert file_map.contains(os.real_path(dir2))

	// Should show correct file count (2 files total)
	assert file_map.contains('Selected Files: 2')

	// Should contain both file extensions
	assert file_map.contains('v(2)')
}

fn test_single_dir_backward_compatibility() ! {
	// Test that single directory workspaces still work as before
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_single', 'myproject')

	os.mkdir_all(test_dir)!
	os.write_file(os.join_path(test_dir, 'main.v'), 'fn main() { println("single dir test") }')!

	defer {
		os.rmdir_all(os.join_path(temp_base, 'test_single')) or {}
	}

	mut ws := Workspace{
		name:     'testws_single'
		children: []HeropromptChild{}
	}

	// Add single directory
	child := ws.add_dir(path: test_dir)!
	assert ws.children.len == 1
	assert child.name == 'myproject'

	// Build file map - should work as before for single directory
	file_map := ws.build_file_map()
	assert file_map.contains('Selected Files: 1')
	// Just check that the file map is not empty and contains some content
	assert file_map.len > 0
}
