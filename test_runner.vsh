#!/usr/bin/env -S v -cc gcc -n -w -gc none  -d use_openssl -enable-globals run

import os
import flag
import time
import json

const cache_file = '/tmp/herolib_tests.json'
const test_expiry_seconds = 3600 // 1 hour



// can use // inside this list as well to ignore temporary certain dirs, useful for testing
const tests_ci := '
lib/data
lib/osal
lib/lang
lib/clients
lib/core
lib/develop
// lib/vfs The vfs folder is not exists on the development branch, so we need to uncomment it after merging this PR https://github.com/freeflowuniverse/herolib/pull/68
// lib/crypt
'

const tests_basic := '

'

const tests_advanced := '

'


// the following tests have no prio and can be ignored
const mut tests_ignore := '
notifier_test.v
clients/meilisearch
clients/zdb
clients/openai
systemd_process_test.v
data/graphdb
data/radixtree
clients/livekit
clients/rclone
clients/jina
clients/qdrant
data/radixtree
data/dedupestor
core/playcmds
tst/
rust/
'


const tests_error := '
tmux_window_test.v
tmux_test.v
startupmanager_test.v
python_test.v
flist_test.v
mnemonic_test.v
decode_test.v
codegen_test.v
generate_test.v
dbfs_test.v
namedb_test.v
timetools_test.v
encoderhero/encoder_test.v
encoderhero/decoder_test.v
code/codeparser
gittools_test.v
'


struct TestCache {
mut:
	tests map[string]i64 // Map of test paths to last successful run timestamp
}

// Load the test cache from JSON file
fn load_test_cache() TestCache {
	if !os.exists(cache_file) {
		return TestCache{
			tests: map[string]i64{}
		}
	}

	content := os.read_file(cache_file) or { return TestCache{
		tests: map[string]i64{}
	} }

	return json.decode(TestCache, content) or { return TestCache{
		tests: map[string]i64{}
	} }
}

fn in_github_actions() bool {
	a := os.environ()['GITHUB_ACTIONS'] or { return false }
	return true
}

// Save the test cache to JSON file
fn save_test_cache(cache TestCache) {
	json_str := json.encode_pretty(cache)
	os.write_file(cache_file, json_str) or { eprintln('Failed to save test cache: ${err}') }
}

// Check if a test needs to be rerun based on timestamp
fn should_rerun_test(cache TestCache, test_key string) bool {
	last_run := cache.tests[test_key] or { return true }
	now := time.now().unix()
	return (now - last_run) > test_expiry_seconds
}

// Update test timestamp in cache
fn update_test_cache(mut cache TestCache, test_key string) {
	cache.tests[test_key] = time.now().unix()
	save_test_cache(cache)
}

// Normalize a path for consistent handling
fn normalize_path(path string) string {
	mut norm_path := os.abs_path(path)
	norm_path = norm_path.replace('//', '/') // Remove any double slashes
	return norm_path
}

// Get normalized and relative path
fn get_normalized_paths(path string, base_dir_norm string) (string, string) {
	// base_dir_norm is already normalized
	norm_path := normalize_path(path)
	rel_path := norm_path.replace(base_dir_norm + '/', '')
	return norm_path, rel_path
}

// Generate a cache key from a path
fn get_cache_key(path string, base_dir string) string {
	_, rel_path := get_normalized_paths(path, base_dir)
	// Create consistent key format
	return rel_path.replace('/', '_').trim('_').to_lower()
}

// Check if a file should be ignored or marked as error based on its path
fn process_test_file(path string, base_dir string, test_files_ignore []string, test_files_error []string, mut cache TestCache) ! {
	// Get normalized paths
	norm_path, rel_path := get_normalized_paths(path, base_dir)

	mut should_ignore := false
	mut is_error := false

	if !path.to_lower().contains('_test.v') {
		return
	}

	// Check if any ignore pattern matches the path
	for pattern in test_files_ignore {
		println('Check ignore test: ${pattern} -- ${rel_path} ::: ${rel_path.contains(pattern.trim_space())}')
		if pattern.trim_space() != '' && rel_path.contains(pattern.trim_space()) {
			println('Ignoring test: ${rel_path}')
			return
		}
	}

	// Check if any error pattern matches the path
	for pattern in test_files_error {
		if pattern.trim_space() != '' && rel_path.contains(pattern.trim_space()) {
			println('Ignoring test because is error: ${rel_path}')
			return
		}
	}
	dotest(norm_path, base_dir, mut cache)!
}

fn dotest(path string, base_dir string, mut cache TestCache) ! {
	norm_path, _ := get_normalized_paths(path, base_dir)
	test_key := get_cache_key(norm_path, base_dir)

	// Check if test result is cached and still valid
	if !should_rerun_test(cache, test_key) {
		println('Test cached (passed): ${path}')
		return
	}

	cmd := 'v -stats -enable-globals -n -w -gc none  test ${norm_path}'
	println(cmd)
	result := os.execute(cmd)
	eprintln(result)
	if result.exit_code != 0 {
		eprintln('Test failed: ${path}')
		eprintln(result.output)
		exit(1)
	}

	// Update cache with successful test run
	update_test_cache(mut cache, test_key)
	println('Test passed: ${path}')
}

/////////////////////////
/////////////////////////

// Parse command line flags
mut fp := flag.new_flag_parser(os.args)
fp.application('test_basic')
fp.description('Run tests for herolib')
remove_cache := fp.bool('r', `r`, false, 'Remove cache file before running tests')
test_level := fp.string('level', `l`, 'basic', 'Set test level: basic, ci, or advanced. Default is basic.')
fp.finalize() or {
	eprintln(err)
	exit(1)
}

// Remove cache file if -r flag is set
if remove_cache && os.exists(cache_file) {
	os.rm(cache_file) or {
		eprintln('Failed to remove cache file: ${err}')
		exit(1)
	}
	println('Removed cache file: ${cache_file}')
}

abs_dir_of_script := dir(@FILE)
norm_dir_of_script := normalize_path(abs_dir_of_script)
os.chdir(abs_dir_of_script) or { panic(err) }


if in_github_actions() {
	println('**** WE ARE IN GITHUB ACTION')
	tests_ignore += '\nosal/tmux\n'
	test_level="ci"
}

// Determine which tests to run based on test_level and environment
mut tests_to_run := ''
if in_github_actions() {
	println('**** WE ARE IN GITHUB ACTION, setting test level to CI')
	tests_to_run = tests_ci
} else {
	match test_level {
		'basic' {
			tests_to_run = tests_basic
		}
		'ci' {
			tests_to_run = tests_ci
		}
		'advanced' {
			tests_to_run = tests_advanced
		}
		else {
			eprintln('Invalid test level: ${test_level}. Supported levels are basic, ci, advanced.')
			exit(1)
		}
	}
}

// Split tests into array and remove empty lines
test_files := tests_to_run.split('\n').filter(it.trim_space() != '')
test_files_ignore := tests_ignore.split('\n').filter(it.trim_space() != '')
test_files_error := tests_error.split('\n').filter(it.trim_space() != '')

// Load test cache
mut cache := load_test_cache()
println('Test cache loaded from ${cache_file}')

println('tests to ignore')
println(tests_ignore)

// Run each test with proper v command flags
for test in test_files {
	if test.trim_space() == '' || test.trim_space().starts_with('//')
		|| test.trim_space().starts_with('#') {
		continue
	}

	full_path := os.join_path(abs_dir_of_script, test)

	if !os.exists(full_path) {
		eprintln('Path does not exist: ${full_path}')
		exit(1)
	}

	if os.is_dir(full_path) {
		// If directory, run tests for each .v file in it recursively
		files := os.walk_ext(full_path, '.v')
		for file in files {
			process_test_file(file, norm_dir_of_script, test_files_ignore, test_files_error, mut
				cache)!
		}
	} else if os.is_file(full_path) {
		process_test_file(full_path, norm_dir_of_script, test_files_ignore, test_files_error, mut
			cache)!
	}
}

println('All (non skipped) tests ok')
