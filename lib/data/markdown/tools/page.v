module tools

// extract_title extracts the highest level markdown title from a page string.
// It returns the first one found, or an empty string if none are present.
pub fn extract_title(page string) string {
	lines := page.split_into_lines()
	for line in lines {
		mut hash_count := 0
		for char_idx, r in line.runes() {
			if r == ` ` {
				continue
			}
			if r == `#` {
				hash_count++
			} else {
				if hash_count > 0 {
					// Found a title, extract the text after the hashes and spaces
					return line[char_idx..].trim_space()
				}
				break // Not a title line
			}
		}
	}
	return ''
}

// set_titles renumbers markdown titles in a page string up to a specified maximum level.
// If maxnr is not set, it defaults to 3.
pub fn set_titles(page string, maxnr int) string {
	mut result_lines := []string{}
	mut current_numbers := []int{len: 6, init: 0} // Support up to H6, initialize with 0s
	mut has_h1 := false

	mut effective_maxnr := if maxnr > 0 { maxnr } else { 6 }
	autonumber := maxnr > 0

	lines := page.split_into_lines()
	for line in lines {
		mut hash_count := 0
		mut first_char_idx := 0
		        for _, r in line.runes() {
			if r == ` ` {
				first_char_idx++
				continue
			}
			if r == `#` {
				hash_count++
				first_char_idx++
			} else {
				break
			}
		}

		if hash_count > 0 {
			// This is a title within the effective_maxnr
			mut display_hash_count := hash_count
			mut numbering_hash_count := hash_count
			if hash_count == 1 {
				has_h1 = true
			} else if !has_h1 {
				display_hash_count = hash_count - 1
				numbering_hash_count = hash_count - 1
			}

			if numbering_hash_count > effective_maxnr {
				result_lines << line
				continue
			}

			current_numbers[numbering_hash_count - 1]++ // Increment current level based on numbering hash count
			// Reset lower levels
			for i := numbering_hash_count; i < current_numbers.len; i++ {
				current_numbers[i] = 0
			}

			mut new_prefix := ''
			if autonumber {
				for i := 0; i < numbering_hash_count; i++ {
					if i > 0 && current_numbers[i] == 0 && current_numbers[i - 1] > 0 {
						current_numbers[i] = 1
					}
					new_prefix += '${current_numbers[i]}.'
				}
			}

			// Extract the original title text (after hashes and spaces)
			mut original_title_text := line[first_char_idx..].trim_space()

			// Remove existing numbering (e.g., "1. ", "1.1. ")
			mut skip_chars := 0
			mut in_numbering := true
			for _, r in original_title_text.runes() {
				if in_numbering {
					if (r >= `0` && r <= `9`) || r == `.` || r == ` ` {
						skip_chars++
					} else {
						in_numbering = false
					}
				} else {
					break
				}
			}
			original_title_text = original_title_text[skip_chars..].trim_space()

			// Construct the new line
			mut new_line := ''
			for _ in 0 .. display_hash_count {
				new_line += '#'
			}

			if autonumber {
				new_line += ' ${new_prefix} ${original_title_text}'
			} else {
				new_line += ' ${original_title_text}'
			}
			result_lines << new_line
		} else {
			result_lines << line
		}
	}

	return result_lines.join_lines() + '\n'
}
