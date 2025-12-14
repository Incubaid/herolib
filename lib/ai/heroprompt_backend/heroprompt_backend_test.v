//! HeropromptBackend Tests
//!
//! Unit tests for the HeropromptBackend module.
//! Tests cover factory functions, workspace operations, directory operations,
//! file operations, search, and context generation.
//!
//! ## Running Tests
//!
//! ```bash
//! v -enable-globals test lib/ai/heroprompt_backend/
//! ```
module heroprompt_backend

import os
import incubaid.herolib.core.base

// Test directory for file operations
const test_dir = '/tmp/heroprompt_test'

// Test factory functions for HeropromptBackend
fn testsuite_begin() ! {
	_ = base.context() or { return }

	// Create test directory structure
	os.rmdir_all(test_dir) or {}
	os.mkdir_all('${test_dir}/src')!
	os.mkdir_all('${test_dir}/docs')!

	// Create test files
	os.write_file('${test_dir}/README.md', '# Test Project\n\nThis is a test.')!
	os.write_file('${test_dir}/src/main.v', 'fn main() {\n    println("hello")\n}')!
	os.write_file('${test_dir}/src/utils.v', 'fn helper() string {\n    return "helper"\n}')!
	os.write_file('${test_dir}/docs/guide.md', '# Guide\n\nSome documentation.')!
}

// ============================================
// Factory Function Tests
// ============================================

fn test_new_and_get() ! {
	// Create new instance
	mut obj := new(name: 'test_instance', create: true)!
	assert obj.name == 'test_instance'

	// Get existing instance
	mut obj2 := get(name: 'test_instance')!
	assert obj2.name == 'test_instance'
}

fn test_set_and_exists() ! {
	// Create and set instance
	mut obj := HeropromptBackend{
		name: 'test_set'
	}
	set(obj)!

	// Check exists
	assert exists(name: 'test_set')! == true
	assert exists(name: 'nonexistent')! == false
}

fn test_list() ! {
	// Create test instances
	new(name: 'list_test_1', create: true)!
	new(name: 'list_test_2', create: true)!

	// List all instances
	instances := list()!
	assert instances.len >= 2
}

fn test_delete() ! {
	// Create instance
	new(name: 'to_delete', create: true)!
	assert exists(name: 'to_delete')! == true

	// Delete instance
	delete(name: 'to_delete')!
	assert exists(name: 'to_delete')! == false
}

// ============================================
// Workspace CRUD Tests
// ============================================

fn test_create_workspace() ! {
	mut backend := new(name: 'ws_test', create: true)!

	// Create workspace with custom name
	ws := backend.create_workspace(name: 'My Workspace')!
	assert ws.name == 'My Workspace'
	assert ws.id != ''
	assert ws.dirs.len == 0

	// Create workspace with default name
	ws2 := backend.create_workspace()!
	assert ws2.name == 'Untitled Workspace'
}

fn test_list_workspaces() ! {
	mut backend := new(name: 'ws_list_test', create: true)!

	backend.create_workspace(name: 'WS1')!
	backend.create_workspace(name: 'WS2')!

	workspaces := backend.list_workspaces()
	assert workspaces.len == 2
	assert workspaces[0].name == 'WS1'
	assert workspaces[1].name == 'WS2'
}

fn test_get_workspace() ! {
	mut backend := new(name: 'ws_get_test', create: true)!

	ws := backend.create_workspace(name: 'Find Me')!
	found := backend.get_workspace(id: ws.id)!
	assert found.name == 'Find Me'

	// Test not found
	backend.get_workspace(id: 'nonexistent') or {
		assert err.msg().contains('not found')
		return
	}
	assert false, 'Expected error for nonexistent workspace'
}

fn test_update_workspace() ! {
	mut backend := new(name: 'ws_update_test', create: true)!

	ws := backend.create_workspace(name: 'Original')!
	updated := backend.update_workspace(id: ws.id, name: 'Updated')!
	assert updated.name == 'Updated'

	// Verify persistence
	found := backend.get_workspace(id: ws.id)!
	assert found.name == 'Updated'
}

fn test_delete_workspace() ! {
	mut backend := new(name: 'ws_delete_test', create: true)!

	ws := backend.create_workspace(name: 'To Delete')!
	assert backend.list_workspaces().len == 1

	backend.delete_workspace(id: ws.id)!
	assert backend.list_workspaces().len == 0

	// Test delete nonexistent
	backend.delete_workspace(id: 'nonexistent') or {
		assert err.msg().contains('not found')
		return
	}
	assert false, 'Expected error for nonexistent workspace'
}

// ============================================
// Directory Operations Tests
// ============================================

fn test_add_directory() ! {
	mut backend := new(name: 'dir_add_test', create: true)!
	ws := backend.create_workspace(name: 'Dir Test')!

	// Add directory
	dir := backend.add_dir(workspace_id: ws.id, path: test_dir)!
	assert dir.path == test_dir
	assert dir.name == 'heroprompt_test'
	assert dir.id != ''

	// Verify it was added
	dirs := backend.list_dirs(id: ws.id)!
	assert dirs.len == 1
}

fn test_add_directory_with_custom_name() ! {
	mut backend := new(name: 'dir_name_test', create: true)!
	ws := backend.create_workspace(name: 'Dir Name Test')!

	dir := backend.add_dir(workspace_id: ws.id, path: test_dir, name: 'Custom Name')!
	assert dir.name == 'Custom Name'
}

fn test_add_directory_duplicate() ! {
	mut backend := new(name: 'dir_dup_test', create: true)!
	ws := backend.create_workspace(name: 'Dup Test')!

	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	// Try to add duplicate
	backend.add_dir(workspace_id: ws.id, path: test_dir) or {
		assert err.msg().contains('already exists')
		return
	}
	assert false, 'Expected error for duplicate directory'
}

fn test_add_directory_nonexistent() ! {
	mut backend := new(name: 'dir_noexist_test', create: true)!
	ws := backend.create_workspace(name: 'NoExist Test')!

	backend.add_dir(workspace_id: ws.id, path: '/nonexistent/path') or {
		assert err.msg().contains('does not exist')
		return
	}
	assert false, 'Expected error for nonexistent directory'
}

fn test_delete_directory() ! {
	mut backend := new(name: 'dir_del_test', create: true)!
	ws := backend.create_workspace(name: 'Del Dir Test')!

	dir := backend.add_dir(workspace_id: ws.id, path: test_dir)!
	assert backend.list_dirs(id: ws.id)!.len == 1

	backend.delete_dir(workspace_id: ws.id, dir_id: dir.id)!
	assert backend.list_dirs(id: ws.id)!.len == 0
}


// ============================================
// File Tree Tests
// ============================================

fn test_get_file_tree() ! {
	tree := get_file_tree(dir_path: test_dir)!

	assert tree.name == 'heroprompt_test'
	assert tree.is_dir == true
	assert tree.children.len >= 3 // README.md, src/, docs/

	// Find src directory
	mut found_src := false
	for child in tree.children {
		if child.name == 'src' {
			found_src = true
			assert child.is_dir == true
			assert child.children.len == 2 // main.v, utils.v
		}
	}
	assert found_src, 'Expected to find src directory'
}

fn test_get_file_tree_nonexistent() ! {
	get_file_tree(dir_path: '/nonexistent/path') or {
		assert err.msg().contains('does not exist')
		return
	}
	assert false, 'Expected error for nonexistent directory'
}

fn test_get_file_tree_max_depth() ! {
	tree := get_file_tree(dir_path: test_dir, max_depth: 1)!

	// With max_depth=1, subdirectories should be listed but not their contents
	for child in tree.children {
		if child.is_dir {
			assert child.children.len == 0, 'Expected empty children at max depth'
		}
	}
}

// ============================================
// File Content Tests
// ============================================

fn test_get_file_content() ! {
	content := get_file_content(path: '${test_dir}/README.md')!
	assert content.contains('# Test Project')
	assert content.contains('This is a test')
}

fn test_get_file_content_nonexistent() ! {
	get_file_content(path: '${test_dir}/nonexistent.txt') or {
		assert err.msg().contains('does not exist')
		return
	}
	assert false, 'Expected error for nonexistent file'
}

fn test_get_file_content_directory() ! {
	get_file_content(path: test_dir) or {
		assert err.msg().contains('not a file')
		return
	}
	assert false, 'Expected error when reading directory as file'
}

fn test_get_files_content() ! {
	paths := ['${test_dir}/README.md', '${test_dir}/src/main.v']
	contents := get_files_content(paths: paths)!

	assert contents.len == 2
	assert contents[0].path == '${test_dir}/README.md'
	assert contents[0].content.contains('Test Project')
	assert contents[1].path == '${test_dir}/src/main.v'
	assert contents[1].content.contains('fn main()')
}

fn test_get_files_content_partial() ! {
	// Include a nonexistent file - should skip it
	paths := ['${test_dir}/README.md', '${test_dir}/nonexistent.txt']
	contents := get_files_content(paths: paths)!

	assert contents.len == 1
	assert contents[0].path == '${test_dir}/README.md'
}

// ============================================
// Search Tests
// ============================================

fn test_search_basic() ! {
	mut backend := new(name: 'search_test', create: true)!
	ws := backend.create_workspace(name: 'Search Test')!
	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	results := backend.search(workspace_id: ws.id, query: 'println')!

	assert results.len >= 1
	assert results[0].path.contains('main.v')
	assert results[0].line.contains('println')
	assert results[0].line_number > 0
}

fn test_search_case_insensitive() ! {
	mut backend := new(name: 'search_case_test', create: true)!
	ws := backend.create_workspace(name: 'Case Test')!
	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	// Search should be case-insensitive by default
	results := backend.search(workspace_id: ws.id, query: 'PRINTLN')!
	assert results.len >= 1

	// Case-sensitive search should not find it
	results_cs := backend.search(workspace_id: ws.id, query: 'PRINTLN', case_sensitive: true)!
	assert results_cs.len == 0
}

fn test_search_max_results() ! {
	mut backend := new(name: 'search_max_test', create: true)!
	ws := backend.create_workspace(name: 'Max Results Test')!
	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	// Search for common term with low max_results
	results := backend.search(workspace_id: ws.id, query: 'fn', max_results: 1)!
	assert results.len == 1
}

fn test_search_context_lines() ! {
	mut backend := new(name: 'search_ctx_test', create: true)!
	ws := backend.create_workspace(name: 'Context Test')!
	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	results := backend.search(workspace_id: ws.id, query: 'println', context_lines: 2)!

	assert results.len >= 1
	// Context should include lines before and after
	assert results[0].context.split_into_lines().len >= 1
}

fn test_search_no_results() ! {
	mut backend := new(name: 'search_none_test', create: true)!
	ws := backend.create_workspace(name: 'No Results Test')!
	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	results := backend.search(workspace_id: ws.id, query: 'xyznonexistent123')!
	assert results.len == 0
}

// ============================================
// Context Generation Tests
// ============================================

fn test_generate_context() ! {
	mut backend := new(name: 'ctx_gen_test', create: true)!
	ws := backend.create_workspace(name: 'Context Gen Test')!
	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	paths := ['${test_dir}/README.md', '${test_dir}/src/main.v']
	ctx := backend.generate_context(workspace_id: ws.id, file_paths: paths)!

	assert ctx.contains('===FILE:')
	assert ctx.contains('===END===')
	assert ctx.contains('# Test Project')
	assert ctx.contains('fn main()')
}

fn test_generate_context_empty() ! {
	mut backend := new(name: 'ctx_empty_test', create: true)!
	ws := backend.create_workspace(name: 'Empty Context Test')!

	ctx := backend.generate_context(workspace_id: ws.id, file_paths: [])!
	assert ctx == ''
}

fn test_generate_context_relative_paths() ! {
	mut backend := new(name: 'ctx_rel_test', create: true)!
	ws := backend.create_workspace(name: 'Relative Path Test')!
	backend.add_dir(workspace_id: ws.id, path: test_dir)!

	paths := ['${test_dir}/src/main.v']
	ctx := backend.generate_context(workspace_id: ws.id, file_paths: paths)!

	// Should use relative path, not absolute
	assert ctx.contains('===FILE:src/main.v===') || ctx.contains('===FILE:main.v===')
	assert !ctx.contains('===FILE:/tmp/')
}

// ============================================
// Cleanup
// ============================================

fn testsuite_end() ! {
	// Cleanup test instances
	test_names := [
		'test_instance', 'test_set', 'list_test_1', 'list_test_2',
		'ws_test', 'ws_list_test', 'ws_get_test', 'ws_update_test', 'ws_delete_test',
		'dir_add_test', 'dir_name_test', 'dir_dup_test', 'dir_noexist_test', 'dir_del_test',
		'search_test', 'search_case_test', 'search_max_test', 'search_ctx_test', 'search_none_test',
		'ctx_gen_test', 'ctx_empty_test', 'ctx_rel_test',
	]

	for name in test_names {
		delete(name: name) or {}
	}

	// Clean up test directory
	os.rmdir_all(test_dir) or {}
}
