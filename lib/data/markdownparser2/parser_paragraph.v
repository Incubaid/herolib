module markdownparser2

// Parse a paragraph element
fn (mut p Parser) parse_paragraph() ?&MarkdownElement {
	// Save starting position for potential rollback
	start_pos := p.pos // Unused but kept for consistency
	start_line := p.line
	start_column := p.column

	mut content := ''
	mut lines := []string{}

	// Read the first line
	for p.pos < p.text.len && p.text[p.pos] != `\n` {
		mut currentchar := p.text[p.pos]
		content += currentchar.ascii_str()
		p.pos++
		p.column++
	}
	lines << content

	// Skip the newline
	if p.pos < p.text.len && p.text[p.pos] == `\n` {
		p.pos++
		p.line++
		p.column = 1
	}

	// Read additional lines of the paragraph
	for p.pos < p.text.len {
		// Check if the line is empty (end of paragraph)
		if p.text[p.pos] == `\n` {
			p.pos++
			p.line++
			p.column = 1
			break
		}

		// Check if the line starts with a block element
		mut currentchar := p.text[p.pos]
		if currentchar == `#` || currentchar == `>`
			|| (currentchar == `-` && p.peek(1) == `-` && p.peek(2) == `-`)
			|| (currentchar == `\`` && p.peek(1) == `\`` && p.peek(2) == `\``)
			|| p.is_list_start() || p.is_table_start() || p.is_footnote_definition() {
			break
		}

		// Read the line
		mut line := ''
		for p.pos < p.text.len && p.text[p.pos] != `\n` {
			line += p.text[p.pos].ascii_str()
			p.pos++
			p.column++
		}
		lines << line

		// Skip the newline
		if p.pos < p.text.len && p.text[p.pos] == `\n` {
			p.pos++
			p.line++
			p.column = 1
		}
	}

	// Join the lines with spaces
	content = lines.join(' ')

	// Create the paragraph element
	mut paragraph := &MarkdownElement{
		typ:         .paragraph
		content:     content
		line_number: start_line
		column:      start_column
	}

	// Parse inline elements within the paragraph
	paragraph.children = p.parse_inline(content)

	return paragraph
}
