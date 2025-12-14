module regext

fn test_escape_regex_chars_special_chars() {
	assert escape_regex_chars('.') == '\\.'
	assert escape_regex_chars('^') == '\\^'
	assert escape_regex_chars('$') == '\\$'
	assert escape_regex_chars('*') == '\\*'
	assert escape_regex_chars('+') == '\\+'
	assert escape_regex_chars('?') == '\\?'
	assert escape_regex_chars('{') == '\\{'
	assert escape_regex_chars('}') == '\\}'
	assert escape_regex_chars('[') == '\\['
	assert escape_regex_chars(']') == '\\]'
	assert escape_regex_chars('\\') == '\\\\'
	assert escape_regex_chars('|') == '\\|'
	assert escape_regex_chars('(') == '\\('
	assert escape_regex_chars(')') == '\\)'
}

fn test_escape_regex_chars_normal_chars() {
	assert escape_regex_chars('a') == 'a'
	assert escape_regex_chars('1') == '1'
	assert escape_regex_chars('hello') == 'hello'
	assert escape_regex_chars('test_123') == 'test_123'
}

fn test_escape_regex_chars_mixed() {
	assert escape_regex_chars('file.txt') == 'file\\.txt'
	assert escape_regex_chars('test[1]') == 'test\\[1\\]'
	assert escape_regex_chars('a.b*c') == 'a\\.b\\*c'
}

fn test_escape_regex_chars_empty() {
	assert escape_regex_chars('') == ''
}

fn test_wildcard_to_regex_no_wildcard() {
	// Pattern without wildcards returns literal pattern (no implicit substring matching)
	assert wildcard_to_regex('config') == 'config'
	assert wildcard_to_regex('test.txt') == 'test\\.txt'
	assert wildcard_to_regex('hello') == 'hello'
}

fn test_wildcard_to_regex_start_wildcard() {
	// Pattern starting with *
	assert wildcard_to_regex('*.txt') == '.*\\.txt'
	assert wildcard_to_regex('*.v') == '.*\\.v'
	assert wildcard_to_regex('*.log') == '.*\\.log'
}

fn test_wildcard_to_regex_end_wildcard() {
	// Pattern ending with *
	assert wildcard_to_regex('test*') == 'test.*'
	assert wildcard_to_regex('log*') == 'log.*'
	assert wildcard_to_regex('file_*') == 'file_.*'
}

fn test_wildcard_to_regex_middle_wildcard() {
	// Pattern with * in the middle
	assert wildcard_to_regex('test*file') == 'test.*file'
	assert wildcard_to_regex('src*main.v') == 'src.*main\\.v'
}

fn test_wildcard_to_regex_multiple_wildcards() {
	// Pattern with multiple wildcards
	assert wildcard_to_regex('*test*') == '.*test.*'
	assert wildcard_to_regex('*src*.v') == '.*src.*\\.v'
	assert wildcard_to_regex('*a*b*c*') == '.*a.*b.*c.*'
}

fn test_wildcard_to_regex_only_wildcard() {
	// Pattern with only wildcard(s)
	assert wildcard_to_regex('*') == '.*'
	assert wildcard_to_regex('**') == '.*.*'
}

fn test_wildcard_to_regex_special_chars_in_pattern() {
	// Patterns containing special regex characters should be escaped (no implicit substring matching)
	assert wildcard_to_regex('[test]') == '\\[test\\]'
	assert wildcard_to_regex('test.file') == 'test\\.file'
	assert wildcard_to_regex('(test)') == '\\(test\\)'
}

fn test_wildcard_to_regex_edge_cases() {
	assert wildcard_to_regex('') == ''
	assert wildcard_to_regex('a') == 'a'
	assert wildcard_to_regex('.') == '\\.'
}
