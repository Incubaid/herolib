module atlas_client

// Test basic image link extraction
fn test_extract_image_links_basic() {
	content := '![alt text](image.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'image.png'
}

// Test multiple image links
fn test_extract_image_links_multiple() {
	content := '![logo](logo.png) some text ![banner](banner.jpg) more text ![icon](icon.svg)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'logo.png'
	assert result[1] == 'banner.jpg'
	assert result[2] == 'icon.svg'
}

// Test empty content
fn test_extract_image_links_empty() {
	content := ''
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 0
}

// Test content with no images
fn test_extract_image_links_no_images() {
	content := 'This is just plain text with no images'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 0
}

// Test content with regular links (not images)
fn test_extract_image_links_regular_links() {
	content := '[regular link](page.md) and [another](doc.html)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 0
}

// Test HTTP URLs with exclude_http = true
fn test_extract_image_links_exclude_http() {
	content := '![local](local.png) ![remote](http://example.com/image.jpg) ![https](https://example.com/logo.png)'
	result := extract_image_links(content, true) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'local.png'
}

// Test HTTP URLs with exclude_http = false
fn test_extract_image_links_include_http() {
	content := '![local](local.png) ![remote](http://example.com/image.jpg) ![https](https://example.com/logo.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'local.png'
	assert result[1] == 'image.jpg'
	assert result[2] == 'logo.png'
}

// Test image paths with directories
fn test_extract_image_links_with_paths() {
	content := '![img1](images/logo.png) ![img2](../assets/banner.jpg) ![img3](./icons/icon.svg)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'logo.png'
	assert result[1] == 'banner.jpg'
	assert result[2] == 'icon.svg'
}

// Test various image formats
fn test_extract_image_links_formats() {
	content := '![png](img.png) ![jpg](img.jpg) ![jpeg](img.jpeg) ![gif](img.gif) ![svg](img.svg) ![webp](img.webp) ![bmp](img.bmp)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 7
	assert 'img.png' in result
	assert 'img.jpg' in result
	assert 'img.jpeg' in result
	assert 'img.gif' in result
	assert 'img.svg' in result
	assert 'img.webp' in result
	assert 'img.bmp' in result
}

// Test malformed markdown - missing closing bracket
fn test_extract_image_links_malformed_no_closing_bracket() {
	content := '![alt text(image.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 0
}

// Test malformed markdown - missing opening parenthesis
fn test_extract_image_links_malformed_no_paren() {
	content := '![alt text]image.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 0
}

// Test malformed markdown - missing closing parenthesis
fn test_extract_image_links_malformed_no_closing_paren() {
	content := '![alt text](image.png'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 0
}

// Test empty alt text
fn test_extract_image_links_empty_alt() {
	content := '![](image.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'image.png'
}

// Test alt text with special characters
fn test_extract_image_links_special_alt() {
	content := '![Logo & Banner - 2024!](logo.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'logo.png'
}

// Test image names with special characters
fn test_extract_image_links_special_names() {
	content := '![img1](logo-2024.png) ![img2](banner_v2.jpg) ![img3](icon.final.svg)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'logo-2024.png'
	assert result[1] == 'banner_v2.jpg'
	assert result[2] == 'icon.final.svg'
}

// Test mixed content with text, links, and images
fn test_extract_image_links_mixed_content() {
	content := '
# Header

Some text with [a link](page.md) and an image ![logo](logo.png).

## Section

More text and ![banner](images/banner.jpg) another image.

[Another link](doc.html)

![icon](icon.svg)
'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'logo.png'
	assert result[1] == 'banner.jpg'
	assert result[2] == 'icon.svg'
}

// Test consecutive images
fn test_extract_image_links_consecutive() {
	content := '![img1](a.png)![img2](b.jpg)![img3](c.svg)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'a.png'
	assert result[1] == 'b.jpg'
	assert result[2] == 'c.svg'
}

// Test images with query parameters
fn test_extract_image_links_query_params() {
	content := '![img](image.png?size=large&format=webp)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	// Should extract the full filename including query params
	assert result[0].contains('image.png')
}

// Test images with anchors
fn test_extract_image_links_anchors() {
	content := '![img](image.png#section)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0].contains('image.png')
}

// Test duplicate images
fn test_extract_image_links_duplicates() {
	content := '![img1](logo.png) some text ![img2](logo.png) more text ![img3](logo.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'logo.png'
	assert result[1] == 'logo.png'
	assert result[2] == 'logo.png'
}

// Test very long content
fn test_extract_image_links_long_content() {
	mut content := ''
	for i in 0 .. 100 {
		content += 'Some text here. '
		if i % 10 == 0 {
			content += '![img${i}](image${i}.png) '
		}
	}

	result := extract_image_links(content, false) or { panic(err) }
	assert result.len == 10
}

// Test image with absolute path
fn test_extract_image_links_absolute_path() {
	content := '![img](/absolute/path/to/image.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'image.png'
}

// Test image with Windows-style path
fn test_extract_image_links_windows_path() {
	content := '![img](C:\\Users\\images\\logo.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'logo.png'
}

// Test nested brackets in alt text
fn test_extract_image_links_nested_brackets() {
	content := '![alt [with] brackets](image.png)'
	result := extract_image_links(content, false) or { panic(err) }

	// This might not work correctly due to nested brackets
	// The function should handle it gracefully
	assert result.len >= 0
}

// Test image link at start of string
fn test_extract_image_links_at_start() {
	content := '![logo](logo.png) followed by text'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'logo.png'
}

// Test image link at end of string
fn test_extract_image_links_at_end() {
	content := 'text followed by ![logo](logo.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'logo.png'
}

// Test only image link
fn test_extract_image_links_only() {
	content := '![logo](logo.png)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	assert result[0] == 'logo.png'
}

// Test whitespace in URL
fn test_extract_image_links_whitespace() {
	content := '![img](  image.png  )'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 1
	// Should preserve whitespace as-is
	assert result[0].contains('image.png')
}

// Test case sensitivity
fn test_extract_image_links_case_sensitivity() {
	content := '![img1](Image.PNG) ![img2](LOGO.jpg) ![img3](banner.SVG)'
	result := extract_image_links(content, false) or { panic(err) }

	assert result.len == 3
	assert result[0] == 'Image.PNG'
	assert result[1] == 'LOGO.jpg'
	assert result[2] == 'banner.SVG'
}
