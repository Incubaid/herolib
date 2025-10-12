module markdown

import incubaid.herolib.data.markdown { new }
import incubaid.herolib.data.markdown.elements { Frontmatter2 }
import os

fn test_get_content_without_frontmatter() {
	markdown_with_frontmatter := '
---
title: My Document
author: Roo
---
# Hello World

This is some content.
'
	expected_content := '# Hello World

This is some content.
'
	mut doc := new(content: markdown_with_frontmatter)!
	mut result := ''
	for element in doc.children {
		if element is Frontmatter2 {
			continue
		}
		result += element.markdown()!
	}
	assert result.trim_space() == expected_content.trim_space()

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
