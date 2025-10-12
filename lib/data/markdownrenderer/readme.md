# Markdown Renderer Module

This module provides functionality for rendering Markdown content in various formats.

## Features

- Supports multiple rendering formats (e.g., HTML, plain text, structure)
- Utilizes the V language Markdown parser
- Customizable rendering options

## Usage

```v
import incubaid.herolib.data.markdownrenderer

// Example usage
md_text := '# Hello World\n\nThis is a paragraph.'
html_output := markdownrenderer.to_html(md_text)
plain_output := markdownrenderer.to_plain(md_text)
structure_output := markdownrenderer.to_structure(md_text)
```

## Dependencies

This module depends on the V language Markdown parser:
<https://github.com/vlang/markdown/tree/master>

For more detailed information, refer to the individual renderer implementations in this module.
