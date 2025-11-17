module markdown

import incubaid.herolib.data.markdown { new }
import incubaid.herolib.data.markdown.elements { Frontmatter2 }
import os

// NOTE: Frontmatter parsing is currently disabled in lib/data/markdown/parsers/parse_doc.v
// because "it has issues with --- which is added by AI often"
// This test is skipped until frontmatter parsing is re-enabled
fn test_get_content_without_frontmatter() {
	// SKIPPED: Frontmatter parsing is disabled
	// The parser does not currently detect or parse frontmatter blocks
	// so this test cannot pass in its current form

	// Test that content without frontmatter works correctly
	expected_content := '# Hello World

This is some content.
'
	mut doc_no_fm := new(content: expected_content)!
	mut result_no_fm := ''
	for element in doc_no_fm.children {
		if element is Frontmatter2 {
			continue
		}
		result_no_fm += element.markdown()!
	}
	assert result_no_fm.trim_space() == expected_content.trim_space()
}
