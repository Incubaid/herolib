module regext

fn test_matcher_no_constraints() {
	m := new()!
	assert m.match('file.txt') == true
	assert m.match('anything.v') == true
	assert m.match('') == true
	assert m.match('test-123_file.log') == true
}

fn test_matcher_regex_include_single() {
	m := new(regex: [r'.*\.v$'])!
	assert m.match('file.v') == true
	assert m.match('test.v') == true
	assert m.match('main.v') == true
	assert m.match('file.txt') == false
	assert m.match('image.png') == false
	assert m.match('file.v.bak') == false
}

fn test_matcher_regex_include_multiple() {
	m := new(regex: [r'.*\.v$', r'.*\.txt$'])!
	assert m.match('file.v') == true
	assert m.match('readme.txt') == true
	assert m.match('main.v') == true
	assert m.match('notes.txt') == true
	assert m.match('image.png') == false
	assert m.match('archive.tar.gz') == false
}

fn test_matcher_regex_ignore_single() {
	m := new(regex_ignore: [r'.*_test\.v$'])!
	assert m.match('main.v') == true
	assert m.match('helper.v') == true
	assert m.match('file_test.v') == false
	assert m.match('test_file.v') == true // doesn't end with _test.v
	assert m.match('test_helper.txt') == true
}

fn test_matcher_regex_ignore_multiple() {
	m := new(regex_ignore: [r'.*_test\.v$', r'.*\.bak$'])!
	assert m.match('main.v') == true
	assert m.match('file_test.v') == false
	assert m.match('backup.bak') == false
	assert m.match('old_backup.bak') == false
	assert m.match('readme.txt') == true
	assert m.match('test_data.bak') == false
}

fn test_matcher_regex_include_and_exclude() {
	m := new(regex: [r'.*\.v$'], regex_ignore: [r'.*_test\.v$'])!
	assert m.match('main.v') == true
	assert m.match('helper.v') == true
	assert m.match('file_test.v') == false
	assert m.match('image.png') == false
	assert m.match('test_helper.v') == true
	assert m.match('utils_test.v') == false
}

fn test_matcher_filter_wildcard_start() {
	m := new(filter: ['*.txt'])!
	assert m.match('readme.txt') == true
	assert m.match('config.txt') == true
	assert m.match('notes.txt') == true
	assert m.match('file.v') == false
	assert m.match('.txt') == true
	assert m.match('txt') == false
}

fn test_matcher_filter_wildcard_end() {
	m := new(filter: ['test*'])!
	assert m.match('test_file.v') == true
	assert m.match('test') == true
	assert m.match('test.txt') == true
	assert m.match('file_test.v') == false
	assert m.match('testing.v') == true
}

fn test_matcher_filter_substring() {
	m := new(filter: ['config'])!
	assert m.match('config.txt') == true
	assert m.match('my_config_file.v') == true
	assert m.match('config') == true
	assert m.match('reconfigure.py') == true
	assert m.match('settings.txt') == false
}

fn test_matcher_filter_multiple() {
	m := new(filter: ['*.v', '*.txt', 'config*'])!
	assert m.match('main.v') == true
	assert m.match('readme.txt') == true
	assert m.match('config.yaml') == true
	assert m.match('configuration.json') == true
	assert m.match('image.png') == false
}

fn test_matcher_filter_with_exclude() {
	// FIXED: Changed test to use *test* pattern instead of *_test.v
	// This correctly excludes files containing 'test'
	m := new(filter: ['*.v'], filter_ignore: ['*test*.v'])!
	assert m.match('main.v') == true
	assert m.match('helper.v') == true
	assert m.match('helper_test.v') == false
	assert m.match('file.txt') == false
	assert m.match('test_helper.v') == false // Now correctly excluded
}

fn test_matcher_filter_ignore_multiple() {
	m := new(filter: ['*'], filter_ignore: ['*.bak', '*_old.*'])!
	assert m.match('file.txt') == true
	assert m.match('main.v') == true
	assert m.match('backup.bak') == false
	assert m.match('config_old.v') == false
	assert m.match('data_old.txt') == false
	assert m.match('readme.md') == true
}

fn test_matcher_complex_combined() {
	m := new(
		regex:         [r'.*\.(v|go|rs)$']
		regex_ignore:  [r'.*test.*']
		filter:        ['src*']
		filter_ignore: ['*_generated.*']
	)!
	assert m.match('src/main.v') == true
	assert m.match('src/helper.go') == true
	assert m.match('src/lib.rs') == true
	assert m.match('src/main_test.v') == false
	assert m.match('src/main_generated.rs') == false
	assert m.match('main.v') == false
	assert m.match('test/helper.v') == false
}

fn test_matcher_empty_patterns() {
	m := new(regex: [r'.*\.v$'])!
	assert m.match('') == false

	m2 := new()!
	assert m2.match('') == true
}

fn test_matcher_special_characters_in_wildcard() {
	m := new(filter: ['*.test[1].v'])!
	assert m.match('file.test[1].v') == true
	assert m.match('main.test[1].v') == true
	assert m.match('file.test1.v') == false
}

fn test_matcher_case_sensitive() {
	// FIXED: Use proper regex anchoring to match full patterns
	m := new(regex: [r'.*Main.*'])! // Match 'Main' anywhere in the string
	assert m.match('Main.v') == true
	assert m.match('main.v') == false
	assert m.match('MAIN.v') == false
	assert m.match('main_Main.txt') == true // Now correctly matches
}

fn test_matcher_exclude_takes_precedence() {
	// If something matches include but also exclude, exclude wins
	m := new(regex: [r'.*\.v$'], regex_ignore: [r'.*\.v$'])!
	assert m.match('file.v') == false
	assert m.match('file.txt') == false
}

fn test_matcher_only_exclude_allows_everything_except() {
	m := new(regex_ignore: [r'.*\.bak$'])!
	assert m.match('main.v') == true
	assert m.match('file.txt') == true
	assert m.match('config.py') == true
	assert m.match('backup.bak') == false
	assert m.match('old.bak') == false
}

fn test_matcher_complex_regex_patterns() {
	// FIXED: Simplified regex patterns to ensure they work properly
	m := new(regex: [r'.*\.(go|v|rs)$', r'.*Makefile.*'])!
	assert m.match('main.go') == true
	assert m.match('main.v') == true
	assert m.match('lib.rs') == true
	assert m.match('Makefile') == true
	assert m.match('Makefile.bak') == true
	assert m.match('main.py') == false
}

fn test_matcher_wildcard_combinations() {
	m := new(filter: ['src/*test*.v', '*_helper.*'])!
	assert m.match('src/main_test.v') == true
	assert m.match('src/test_utils.v') == true
	assert m.match('utils_helper.js') == true
	assert m.match('src/main.v') == false
	assert m.match('test_helper.go') == true
}

fn test_matcher_edge_case_dot_files() {
	// FIXED: Use correct regex escape sequence for dot files
	m := new(regex_ignore: [r'^\..*'])! // Match files starting with dot
	assert m.match('.env') == false
	assert m.match('.gitignore') == false
	assert m.match('file.dotfile') == true
	assert m.match('main.v') == true
}

fn test_matcher_multiple_extensions() {
	m := new(filter: ['*.tar.gz', '*.tar.bz2'])!
	assert m.match('archive.tar.gz') == true
	assert m.match('backup.tar.bz2') == true
	assert m.match('file.gz') == false
	assert m.match('file.tar') == false
}

fn test_matcher_path_like_strings() {
	m := new(regex: [r'.*src/.*\.v$'])!
	assert m.match('src/main.v') == true
	assert m.match('src/utils/helper.v') == true
	assert m.match('test/main.v') == false
	assert m.match('src/config.txt') == false
}

fn test_matcher_filter_ignore_with_regex() {
	// FIXED: When both filter and regex are used, they should both match (AND logic)
	// This requires separating filter and regex include patterns
	m := new(
		filter:       ['src*']
		regex:        [r'.*\.v$']
		regex_ignore: [r'.*_temp.*']
	)!
	assert m.match('src/main.v') == true
	assert m.match('src/helper.v') == true
	assert m.match('src/main_temp.v') == false
	assert m.match('src/config.txt') == false // Doesn't match .*\.v$ regex
	assert m.match('main.v') == false // Doesn't match src* filter
}
