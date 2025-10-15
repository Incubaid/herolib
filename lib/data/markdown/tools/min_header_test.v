module tools

import os
import incubaid.herolib.ui.console

fn test_markdown_min_header_basic() {
	txt := '
# Header 1
## Header 2
### Header 3
'
	expected := '
## Header 1
### Header 2
#### Header 3
'
	result := min_header(txt, 2)
	assert result == expected
}

fn test_markdown_min_header_no_change() {
	txt := '
## Header 2
### Header 3
'
	expected := '
## Header 2
### Header 3
'
	result := min_header(txt, 2)
	assert result == expected
}

fn test_markdown_min_header_multiple_levels() {
	txt := '
# Title
Some txt here.
## Subtitle
More txt.
### Sub-subtitle
'
	expected := '
### Title
Some txt here.
#### Subtitle
More txt.
##### Sub-subtitle
'
	result := min_header(txt, 3)
	assert result == expected
}

fn test_markdown_min_header_no_headers() {
	txt := '
This is some plain txt.
No headers here.
'
	expected := '
This is some plain txt.
No headers here.
'
	result := min_header(txt, 1)
	assert result == expected
}

fn test_markdown_min_header_empty_input() {
	txt := ''
	expected := ''
	result := min_header(txt, 1)
	assert result == expected
}

fn test_markdown_min_header_with_txt_before_header() {
	txt := '
Some intro txt
# Header 1
## Header 2
'
	expected := '
Some intro txt
## Header 1
### Header 2
'
	result := min_header(txt, 2)
	assert result == expected
}
