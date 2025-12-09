module heroprompt

import os
import incubaid.herolib.core.base

// Test workspace: add directory
fn test_workspace_add_directory() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_add_repo_hp') or {}

	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_add_repo')
	os.mkdir_all(test_dir)!
	os.write_file(os.join_path(test_dir, 'test.txt'), 'test content')!

	defer {
		os.rmdir_all(test_dir) or {}
		delete(name: 'test_add_repo_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_add_repo_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add directory
	repo := ws.add_directory(path: test_dir, name: 'Test Repo')!

	assert ws.directories.len == 1
	assert repo.name == 'Test Repo'
	assert repo.path == os.real_path(test_dir)
	assert repo.id.len > 0
}

// Test workspace: add directory without custom name
fn test_workspace_add_directory_auto_name() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_auto_name_hp') or {}

	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'my_custom_dir_name')
	os.mkdir_all(test_dir)!

	defer {
		os.rmdir_all(test_dir) or {}
		delete(name: 'test_auto_name_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_auto_name_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add directory without custom name
	repo := ws.add_directory(path: test_dir)!

	// Name should be extracted from directory name
	assert repo.name == 'my_custom_dir_name'
}

// Test workspace: add duplicate directory
fn test_workspace_add_duplicate_directory() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_dup_repo_hp') or {}

	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_dup_repo')
	os.mkdir_all(test_dir)!

	defer {
		os.rmdir_all(test_dir) or {}
		delete(name: 'test_dup_repo_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_dup_repo_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add directory
	ws.add_directory(path: test_dir)!

	// Try to add same directory again
	ws.add_directory(path: test_dir) or {
		assert err.msg().contains('already added')
		return
	}

	assert false, 'Expected error when adding duplicate directory'
}

// Test workspace: remove directory by ID
fn test_workspace_remove_directory_by_id() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_remove_repo_hp') or {}

	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_remove_repo')
	os.mkdir_all(test_dir)!

	defer {
		os.rmdir_all(test_dir) or {}
		delete(name: 'test_remove_repo_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_remove_repo_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add directory
	repo := ws.add_directory(path: test_dir)!
	assert ws.directories.len == 1

	// Remove by ID
	ws.remove_directory(id: repo.id)!
	assert ws.directories.len == 0
}

// Test workspace: remove directory by path
fn test_workspace_remove_directory_by_path() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_remove_path_hp') or {}

	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_remove_path')
	os.mkdir_all(test_dir)!

	defer {
		os.rmdir_all(test_dir) or {}
		delete(name: 'test_remove_path_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_remove_path_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add directory
	ws.add_directory(path: test_dir)!
	assert ws.directories.len == 1

	// Remove by path
	ws.remove_directory(path: test_dir)!
	assert ws.directories.len == 0
}

// Test workspace: get directory
fn test_workspace_get_directory() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_get_repo_hp') or {}

	// Create temp directory
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_get_repo')
	os.mkdir_all(test_dir)!

	defer {
		os.rmdir_all(test_dir) or {}
		delete(name: 'test_get_repo_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_get_repo_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add directory
	repo := ws.add_directory(path: test_dir)!

	// Get directory
	retrieved_repo := ws.get_directory(repo.id)!
	assert retrieved_repo.id == repo.id
	assert retrieved_repo.path == repo.path
}

// Test workspace: list directories
fn test_workspace_list_directories() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_list_repos_hp') or {}

	// Create temp directories
	temp_base := os.temp_dir()
	test_dir1 := os.join_path(temp_base, 'test_heroprompt_list_1')
	test_dir2 := os.join_path(temp_base, 'test_heroprompt_list_2')
	os.mkdir_all(test_dir1)!
	os.mkdir_all(test_dir2)!

	defer {
		os.rmdir_all(test_dir1) or {}
		os.rmdir_all(test_dir2) or {}
		delete(name: 'test_list_repos_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_list_repos_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add directories
	ws.add_directory(path: test_dir1)!
	ws.add_directory(path: test_dir2)!

	// List directories
	repos := ws.list_directories()
	assert repos.len == 2
}

// Test workspace: add file
fn test_workspace_add_file() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_add_file_hp') or {}

	// Create temp file
	temp_base := os.temp_dir()
	test_file := os.join_path(temp_base, 'test_heroprompt_add_file.txt')
	os.write_file(test_file, 'test file content')!

	defer {
		os.rm(test_file) or {}
		delete(name: 'test_add_file_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_add_file_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Add file
	file := ws.add_file(path: test_file)!

	assert ws.files.len == 1
	assert file.content == 'test file content'
	assert file.path == os.real_path(test_file)
}

// Test workspace: item count
fn test_workspace_item_count() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_count_hp') or {}

	// Create temp directory and file
	temp_base := os.temp_dir()
	test_dir := os.join_path(temp_base, 'test_heroprompt_count_dir')
	test_file := os.join_path(temp_base, 'test_heroprompt_count_file.txt')
	os.mkdir_all(test_dir)!
	os.write_file(test_file, 'content')!

	defer {
		os.rmdir_all(test_dir) or {}
		os.rm(test_file) or {}
		delete(name: 'test_count_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_count_hp', create: true)!
	hp.run_in_tests = true // Suppress logging during tests
	mut ws := hp.new_workspace(name: 'test_ws')!

	// Initially empty
	assert ws.item_count() == 0

	// Add directory
	ws.add_directory(path: test_dir)!
	assert ws.item_count() == 1

	// Add file
	ws.add_file(path: test_file)!
	assert ws.item_count() == 2
}
