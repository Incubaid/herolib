#!/usr/bin/env -S v -n -w -gc none run

import incubaid.herolib.data.markdownparser2

// Sample markdown text
text := '# Heading 1

This is a paragraph with **bold** and *italic* text.

## Heading 2

- List item 1
- List item 2
  - Nested item
- List item 3

```v
fn main() {
	println("Hello, world!")
}
```

> This is a blockquote
> with multiple lines

| Column 1 | Column 2 | Column 3 |
|----------|:--------:|---------:|
| Left     | Center   | Right    |
| Cell 1   | Cell 2   | Cell 3   |

[Link to V language](https://vlang.io)

![Image](https://vlang.io/img/v-logo.png)

Footnote reference[^1]

[^1]: This is a footnote.
'

// Example 1: Using the plain text renderer
println('=== PLAINTEXT RENDERING ===')
println(markdownparser2.to_plain(text))
println('')

// Example 2: Using the structure renderer to show markdown structure
println('=== STRUCTURE RENDERING ===')
println(markdownparser2.to_structure(text))

// Example 3: Using the navigator to find specific elements
println('\n=== NAVIGATION EXAMPLE ===')

// Parse the markdown text
doc := markdownparser2.parse(text)

// Create a navigator
mut nav := markdownparser2.new_navigator(doc)

// Find all headings
headings := nav.find_all_by_type(.heading)
println('Found ${headings.len} headings:')
for heading in headings {
	level := heading.attributes['level']
	println('  ${'#'.repeat(level.int())} ${heading.content}')
}

// Find all code blocks
code_blocks := nav.find_all_by_type(.code_block)
println('\nFound ${code_blocks.len} code blocks:')
for block in code_blocks {
	language := block.attributes['language']
	println('  Language: ${language}')
	println('  Content length: ${block.content.len} characters')
}

// Find all list items
list_items := nav.find_all_by_type(.list_item)
println('\nFound ${list_items.len} list items:')
for item in list_items {
	println('  - ${item.content}')
}

// Find content containing specific text
if element := nav.find_by_content('blockquote') {
	println('\nFound element containing "blockquote":')
	println('  Type: ${element.typ}')
	println('  Content: ${element.content}')
}

// Find all footnotes
println('\nFootnotes:')
for id, footnote in nav.footnotes() {
	println('  [^${id}]: ${footnote.content}')
}
