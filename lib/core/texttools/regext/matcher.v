module regext

import regex

// Arguments for creating a matcher
@[params]
pub struct MatcherArgs {
pub mut:
	// Include if matches any regex pattern
	regex []string
	// Exclude if matches any regex pattern
	regex_ignore []string
	// Include if matches any wildcard pattern (* = any sequence)
	filter []string
	// Exclude if matches any wildcard pattern
	filter_ignore []string
}

// Matcher matches strings against include/exclude regex patterns
pub struct Matcher {
mut:
	regex_include  []regex.RE
	filter_include []regex.RE
	regex_exclude  []regex.RE
}

// Create a new matcher from arguments
//
// Parameters:
//   - regex: Include if matches regex pattern (e.g., $r'.*\.v'$)
//   - regex_ignore: Exclude if matches regex pattern
//   - filter: Include if matches wildcard pattern (e.g., $r'*.txt'$, $r'test*'$, $r'config'$)
//   - filter_ignore: Exclude if matches wildcard pattern
//
// Logic:
//   - If both regex and filter patterns are provided, BOTH must match (AND logic)
//   - If only regex patterns are provided, any regex pattern can match (OR logic)
//   - If only filter patterns are provided, any filter pattern can match (OR logic)
//   - Exclude patterns take precedence over include patterns
//
// Examples:
//   $m := regex.new(regex: [r'.*\.v$'])!$
//   $m := regex.new(filter: ['*.txt'], filter_ignore: ['*.bak'])!$
//   $m := regex.new(regex: [r'.*test.*'], regex_ignore: [r'.*_test\.v$'])!$
pub fn new(args_ MatcherArgs) !Matcher {
	mut regex_include := []regex.RE{}
	mut filter_include := []regex.RE{}

	// Add regex patterns
	for regexstr in args_.regex {
		mut re := regex.regex_opt(regexstr) or {
			return error("cannot create regex for:'${regexstr}'")
		}
		regex_include << re
	}

	// Convert wildcard filters to regex and add separately
	for filter_pattern in args_.filter {
		regex_pattern := wildcard_to_regex(filter_pattern)
		mut re := regex.regex_opt(regex_pattern) or {
			return error("cannot create regex from filter:'${filter_pattern}'")
		}
		filter_include << re
	}

	mut regex_exclude := []regex.RE{}

	// Add regex ignore patterns
	for regexstr in args_.regex_ignore {
		mut re := regex.regex_opt(regexstr) or {
			return error("cannot create ignore regex for:'${regexstr}'")
		}
		regex_exclude << re
	}

	// Convert wildcard ignore filters to regex and add
	for filter_pattern in args_.filter_ignore {
		regex_pattern := wildcard_to_regex(filter_pattern)
		mut re := regex.regex_opt(regex_pattern) or {
			return error("cannot create ignore regex from filter:'${filter_pattern}'")
		}
		regex_exclude << re
	}

	return Matcher{
		regex_include:  regex_include
		filter_include: filter_include
		regex_exclude:  regex_exclude
	}
}

// match checks if a string matches the include patterns and not the exclude patterns
//
// Logic:
//   - If both regex and filter patterns exist, string must match BOTH (AND logic)
//   - If only regex patterns exist, string must match at least one (OR logic)
//   - If only filter patterns exist, string must match at least one (OR logic)
//   - Then check if string matches any exclude pattern; if yes, return false
//   - Otherwise return true
//
// Examples:
//   $m := regex.new(regex: [r'.*\.v$'])!$
//   $result := m.match('file.v')  // true$
//   $result := m.match('file.txt')  // false$
//
//   $m2 := regex.new(filter: ['*.txt'], filter_ignore: ['*.bak'])!$
//   $result := m2.match('readme.txt')  // true$
//   $result := m2.match('backup.bak')  // false$
//
//   $m3 := regex.new(filter: ['src*'], regex: [r'.*\.v$'])!$
//   $result := m3.match('src/main.v')  // true (matches both)$
//   $result := m3.match('src/config.txt')  // false (doesn't match regex)$
//   $result := m3.match('main.v')  // false (doesn't match filter)$
pub fn (m Matcher) match(text string) bool {
	// Determine if we have both regex and filter patterns
	has_regex := m.regex_include.len > 0
	has_filter := m.filter_include.len > 0

	// If both regex and filter patterns exist, string must match BOTH
	if has_regex && has_filter {
		mut regex_matched := false
		for re in m.regex_include {
			if re.matches_string(text) {
				regex_matched = true
				break
			}
		}
		if !regex_matched {
			return false
		}

		mut filter_matched := false
		for re in m.filter_include {
			if re.matches_string(text) {
				filter_matched = true
				break
			}
		}
		if !filter_matched {
			return false
		}
	} else if has_regex {
		// Only regex patterns: string must match at least one
		mut matched := false
		for re in m.regex_include {
			if re.matches_string(text) {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	} else if has_filter {
		// Only filter patterns: string must match at least one
		mut matched := false
		for re in m.filter_include {
			if re.matches_string(text) {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	} else {
		// If no include patterns are defined, everything matches initially
		// unless there are explicit exclude patterns.
		// This handles the case where new() is called without any include patterns.
		if m.regex_exclude.len == 0 {
			return true // No includes and no excludes, so everything matches.
		}
		// If no include patterns but there are exclude patterns,
		// we defer to the exclude patterns check below.
	}

	// Check exclude patterns - if matches any, return false
	for re in m.regex_exclude {
		if re.matches_string(text) {
			return false
		}
	}

	// If we reach here, it either matched includes (or no includes were set and
	// no excludes were set, or no includes were set but it didn't match any excludes)
	// and didn't match any excludes
	return true
}
