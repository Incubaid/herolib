module tests

import incubaid.herolib.develop.gittools
import incubaid.herolib.osal.core as osal
import os
import time

__global (
	branch_name_tests string
	tag_name_tests    string
	repo_path_tests   string
	repo_tests        &gittools.GitRepo
	repo_setup_tests  GittoolsTests
)

fn testsuite_begin() {
	runtime := time.now().unix()
	branch_name_tests = 'branch_${runtime}'
	tag_name_tests = 'tag_${runtime}'
}

fn testsuite_end() {
	repo_setup_tests.clean()!
}

// Helper to clean repo state using git directly (avoids cache issues).
fn git_clean(repo_path string) ! {
	osal.execute_silent('cd ${repo_path} && git reset --hard HEAD && git clean -fdx')!
}

// Test cloning a Git repository and verifying that it exists locally.
@[test]
fn test_clone_repo() {
	repo_setup_tests = setup_repo()!
	mut gs := gittools.new(coderoot: repo_setup_tests.coderoot)!
	repo_tests = gs.get_repo(url: repo_setup_tests.repo_url)!
	repo_path_tests = repo_tests.path()
	assert os.exists(repo_path_tests) == true
}

// Test creating a new branch in the Git repository.
@[test]
fn test_branch_create() {
	repo_tests.branch_create(branch_name_tests)!
	// After creating a branch, we're still on the original branch
	assert repo_tests.status.branch != branch_name_tests
}

// Test switching to an existing branch in the repository.
@[test]
fn test_branch_switch() {
	repo_tests.branch_switch(branch_name_tests)!
	repo_tests.status_update()!
	assert repo_tests.status.branch == branch_name_tests
}

// Test creating a tag in the Git repository.
@[test]
fn test_tag_create() {
	repo_tests.tag_create(tag_name_tests)!
	assert repo_tests.tag_exists(tag_name_tests)! == true
}

// Test detecting unstaged and staged changes using direct git queries.
@[test]
fn test_detect_changes() {
	// Ensure clean state
	git_clean(repo_path_tests)!

	// Create a new file
	_ := create_new_file(repo_path_tests)!

	// detect_changes() directly queries git, bypassing cache
	assert repo_tests.detect_changes()! == true

	mut unstaged := repo_tests.get_changes_unstaged()!
	assert unstaged.len == 1

	mut staged := repo_tests.get_changes_staged()!
	assert staged.len == 0

	// Clean up
	git_clean(repo_path_tests)!
	assert repo_tests.detect_changes()! == false
}

// Test get_changes_unstaged and get_changes_staged methods.
@[test]
fn test_get_changes() {
	// Ensure clean state
	git_clean(repo_path_tests)!

	// No changes initially
	mut unstaged := repo_tests.get_changes_unstaged()!
	assert unstaged.len == 0

	mut staged := repo_tests.get_changes_staged()!
	assert staged.len == 0

	// Create a file - should show as unstaged
	_ := create_new_file(repo_path_tests)!

	unstaged = repo_tests.get_changes_unstaged()!
	assert unstaged.len == 1

	staged = repo_tests.get_changes_staged()!
	assert staged.len == 0

	// Clean up
	git_clean(repo_path_tests)!
}

// Test pushing to remote (no-op when nothing to push).
@[test]
fn test_push_no_changes() {
	git_clean(repo_path_tests)!
	repo_tests.push() or { assert false, 'Push should succeed: ${err}' }
}
