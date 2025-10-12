module heroprompt

import freeflowuniverse.herolib.core.base

// Test HeroPrompt: new_workspace
fn test_heroprompt_new_workspace() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_new_ws_hp') or {}

	defer {
		delete(name: 'test_new_ws_hp') or {}
	}

	// Create heroprompt instance
	mut hp := get(name: 'test_new_ws_hp', create: true)!
	hp.run_in_tests = true

	// Create workspace
	ws := hp.new_workspace(name: 'test_workspace', description: 'Test workspace')!

	assert ws.name == 'test_workspace'
	assert ws.description == 'Test workspace'
	assert ws.id.len == 36 // UUID length
	assert hp.workspaces.len == 1
}

// Test HeroPrompt: get_workspace
fn test_heroprompt_get_workspace() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_get_ws_hp') or {}

	defer {
		delete(name: 'test_get_ws_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_get_ws_hp', create: true)!
	hp.run_in_tests = true
	hp.new_workspace(name: 'test_workspace')!

	// Get workspace
	ws := hp.get_workspace('test_workspace')!
	assert ws.name == 'test_workspace'

	// Try to get non-existent workspace
	hp.get_workspace('nonexistent') or {
		assert err.msg().contains('workspace not found')
		return
	}
	assert false, 'Expected error when getting non-existent workspace'
}

// Test HeroPrompt: list_workspaces
fn test_heroprompt_list_workspaces() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_list_ws_hp') or {}

	defer {
		delete(name: 'test_list_ws_hp') or {}
	}

	// Create heroprompt instance
	mut hp := get(name: 'test_list_ws_hp', create: true)!
	hp.run_in_tests = true

	// Initially empty
	assert hp.list_workspaces().len == 0

	// Create workspaces
	hp.new_workspace(name: 'workspace1')!
	hp.new_workspace(name: 'workspace2')!
	hp.new_workspace(name: 'workspace3')!

	// List workspaces
	workspaces := hp.list_workspaces()
	assert workspaces.len == 3
}

// Test HeroPrompt: delete_workspace
fn test_heroprompt_delete_workspace() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_del_ws_hp') or {}

	defer {
		delete(name: 'test_del_ws_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_del_ws_hp', create: true)!
	hp.run_in_tests = true
	hp.new_workspace(name: 'test_workspace')!

	assert hp.workspaces.len == 1

	// Delete workspace
	hp.delete_workspace('test_workspace')!
	assert hp.workspaces.len == 0

	// Try to delete non-existent workspace
	hp.delete_workspace('nonexistent') or {
		assert err.msg().contains('workspace not found')
		return
	}
	assert false, 'Expected error when deleting non-existent workspace'
}

// Test HeroPrompt: duplicate workspace
fn test_heroprompt_duplicate_workspace() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_dup_ws_hp') or {}

	defer {
		delete(name: 'test_dup_ws_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_dup_ws_hp', create: true)!
	hp.run_in_tests = true
	hp.new_workspace(name: 'test_workspace')!

	// Try to create duplicate workspace
	hp.new_workspace(name: 'test_workspace') or {
		assert err.msg().contains('workspace already exists')
		return
	}
	assert false, 'Expected error when creating duplicate workspace'
}

// Test HeroPrompt: auto-save after workspace operations
fn test_heroprompt_auto_save() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_autosave_hp') or {}

	defer {
		delete(name: 'test_autosave_hp') or {}
	}

	// Create heroprompt instance and workspace
	mut hp := get(name: 'test_autosave_hp', create: true)!
	hp.run_in_tests = true
	mut ws := hp.new_workspace(name: 'test_workspace')!

	// Get fresh instance from Redis to verify save
	hp2 := get(name: 'test_autosave_hp', fromdb: true)!
	assert hp2.workspaces.len == 1
	assert 'test_workspace' in hp2.workspaces
}

// Test HeroPrompt: logging suppression in tests
fn test_heroprompt_logging_suppression() ! {
	mut ctx := base.context()!
	mut r := ctx.redis()!

	// Clean up
	r.hdel('context:heroprompt', 'test_logging_hp') or {}

	defer {
		delete(name: 'test_logging_hp') or {}
	}

	// Create heroprompt instance
	mut hp := get(name: 'test_logging_hp', create: true)!

	// Test with logging enabled (should not crash)
	hp.run_in_tests = false
	hp.log(.info, 'Test log message')

	// Test with logging disabled
	hp.run_in_tests = true
	hp.log(.info, 'This should be suppressed')

	// If we get here without crashing, logging works
	assert true
}
